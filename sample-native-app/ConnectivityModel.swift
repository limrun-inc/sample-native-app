import Combine
import Foundation
import Network

struct ServiceCheckResult {
    let message: String
    let recovered: Bool
}

enum ServiceCheckState {
    case idle
    case loading
    case success(ServiceCheckResult)
    case failure(String)
}

@MainActor
final class ConnectivityModel: ObservableObject {
    @Published private(set) var internalEndpoint: String
    @Published private(set) var intranetEndpoint: String
    @Published private(set) var egressEndpoint: String
    @Published private(set) var internalState: ServiceCheckState = .idle
    @Published private(set) var intranetState: ServiceCheckState = .idle
    @Published private(set) var egressState: ServiceCheckState = .idle

    private var checkGeneration = 0
    private var internalCheckTask: Task<Void, Never>?
    private var intranetCheckTask: Task<Void, Never>?
    private var egressCheckTask: Task<Void, Never>?

    init() {
        internalEndpoint = "http://localhost:4100"
        intranetEndpoint = "http://api.demo.internal:4200"
        egressEndpoint = "http://ifconfig.me/ip"
    }

    var isConfigured: Bool {
        endpointURL(internalEndpoint) != nil &&
            endpointURL(intranetEndpoint) != nil &&
            endpointURL(egressEndpoint) != nil
    }

    var isChecking: Bool {
        internalState.isLoading || intranetState.isLoading || egressState.isLoading
    }

    func configure(
        internalEndpoint: String,
        intranetEndpoint: String,
        egressEndpoint: String
    ) -> Bool {
        guard
            let normalizedInternal = normalizedEndpoint(internalEndpoint),
            let normalizedIntranet = normalizedEndpoint(intranetEndpoint),
            let normalizedEgress = normalizedEndpoint(egressEndpoint)
        else {
            return false
        }
        cancelChecks()
        self.internalEndpoint = normalizedInternal
        self.intranetEndpoint = normalizedIntranet
        self.egressEndpoint = normalizedEgress
        internalState = .idle
        intranetState = .idle
        egressState = .idle
        return true
    }

    func applyConfiguration(_ url: URL) -> Bool {
        guard
            url.scheme == "limrun-demo",
            url.host == "configure",
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let internalEndpoint = components.queryItems?
                .first(where: { $0.name == "internal" })?.value,
            let intranetEndpoint = components.queryItems?
                .first(where: { $0.name == "intranet" })?.value,
            let egressEndpoint = components.queryItems?
                .first(where: { $0.name == "egress" })?.value
        else {
            return false
        }
        return configure(
            internalEndpoint: internalEndpoint,
            intranetEndpoint: intranetEndpoint,
            egressEndpoint: egressEndpoint
        )
    }

    func checkAllServices() {
        guard
            let internalURL = endpointURL(internalEndpoint),
            let intranetURL = endpointURL(intranetEndpoint),
            let egressURL = endpointURL(egressEndpoint)
        else {
            internalState = .failure("Configure all destinations first.")
            intranetState = .failure("Configure all destinations first.")
            egressState = .failure("Configure all destinations first.")
            return
        }

        let internalWasUnreachable = internalState.isFailure
        let intranetWasUnreachable = intranetState.isFailure
        let egressWasUnreachable = egressState.isFailure
        cancelChecks()
        let generation = checkGeneration
        internalState = .loading
        intranetState = .loading
        egressState = .loading
        internalCheckTask = Task { [weak self] in
            guard let self else {
                return
            }
            let result = await check(
                internalURL,
                recoveredAfterFailure: internalWasUnreachable
            )
            guard !Task.isCancelled, generation == checkGeneration else {
                return
            }
            internalState = result
        }
        intranetCheckTask = Task { [weak self] in
            guard let self else {
                return
            }
            let result = await check(
                intranetURL,
                recoveredAfterFailure: intranetWasUnreachable
            )
            guard !Task.isCancelled, generation == checkGeneration else {
                return
            }
            intranetState = result
        }
        egressCheckTask = Task { [weak self] in
            guard let self else {
                return
            }
            let result = await check(
                egressURL,
                recoveredAfterFailure: egressWasUnreachable
            )
            guard !Task.isCancelled, generation == checkGeneration else {
                return
            }
            egressState = result
        }
    }

    private func cancelChecks() {
        checkGeneration += 1
        internalCheckTask?.cancel()
        intranetCheckTask?.cancel()
        egressCheckTask?.cancel()
        internalCheckTask = nil
        intranetCheckTask = nil
        egressCheckTask = nil
    }

    private func endpointURL(_ value: String) -> URL? {
        normalizedEndpoint(value).flatMap(URL.init(string:))
    }

    private func normalizedEndpoint(_ value: String) -> String? {
        guard
            var components = URLComponents(
                string: value.trimmingCharacters(in: .whitespacesAndNewlines)
            ),
            components.scheme == "http",
            components.user == nil,
            components.password == nil,
            components.query == nil,
            components.fragment == nil,
            let host = components.host,
            isSupportedHost(host)
        else {
            return nil
        }
        if let port = components.port, !(1...65_535 ~= port) {
            return nil
        }
        if components.path == "/" {
            components.path = ""
        }
        return components.url?.absoluteString
    }

    private func isSupportedHost(_ host: String) -> Bool {
        if host == "localhost" || IPv4Address(host) != nil || IPv6Address(host) != nil {
            return true
        }
        let labels = host.split(separator: ".", omittingEmptySubsequences: false)
        return labels.count > 1 && labels.allSatisfy { label in
            !label.isEmpty && label.allSatisfy { $0.isLetter || $0.isNumber || $0 == "-" }
        }
    }

    private func check(
        _ url: URL,
        recoveredAfterFailure: Bool
    ) async -> ServiceCheckState {
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 8
            request.httpShouldHandleCookies = false

            let configuration = URLSessionConfiguration.ephemeral
            configuration.httpCookieStorage = nil
            configuration.httpShouldSetCookies = false
            configuration.urlCache = nil
            configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            let delegate = EndpointSessionDelegate(origin: url)
            let session = URLSession(
                configuration: configuration,
                delegate: delegate,
                delegateQueue: nil
            )
            defer {
                session.invalidateAndCancel()
            }

            let (bytes, response) = try await session.bytes(for: request)
            guard let response = response as? HTTPURLResponse,
                  200..<300 ~= response.statusCode
            else {
                return .failure("The service returned a non-success response.")
            }
            var data = Data()
            data.reserveCapacity(1_024)
            for try await byte in bytes {
                guard data.count < 16_384 else {
                    throw DemoRequestError.responseTooLarge
                }
                data.append(byte)
            }
            return .success(
                ServiceCheckResult(
                    message: responseMessage(data),
                    recovered: recoveredAfterFailure
                )
            )
        } catch {
            return .failure(error.localizedDescription)
        }
    }

    private func responseMessage(_ data: Data) -> String {
        if let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let message = object["message"] as? String {
                return message
            }
            if let service = object["service"] as? String {
                return service
            }
        }
        let text = String(decoding: data.prefix(160), as: UTF8.self)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? "Connected" : text
    }
}

private enum DemoRequestError: LocalizedError {
    case responseTooLarge

    var errorDescription: String? {
        "The service response exceeded the 16 KB demo limit."
    }
}

private final class EndpointSessionDelegate: NSObject, URLSessionTaskDelegate {
    private let origin: URL

    init(origin: URL) {
        self.origin = origin
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        guard let destination = request.url,
              destination.scheme == origin.scheme,
              destination.host == origin.host,
              destination.port == origin.port
        else {
            completionHandler(nil)
            return
        }
        completionHandler(request)
    }
}

extension ServiceCheckState {
    var isFailure: Bool {
        if case .failure = self {
            return true
        }
        return false
    }

    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }

    var isSuccess: Bool {
        if case .success = self {
            return true
        }
        return false
    }
}
