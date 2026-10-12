import Foundation

struct Order: Decodable, Identifiable, Hashable {
    struct Item: Decodable, Hashable {
        let name: String
        let quantity: Int
    }

    let id: String
    let customer: String
    let status: String
    let total: Decimal
    let items: [Item]
}

struct DeliveryEstimate: Decodable {
    let minutes: Int
    let courier: String
}

// The preview link passes API_URL and ETA_URL as launch environment, so one
// build can run against any backend without a rebuild.
struct OrdersAPI {
    let apiURL: URL
    let etaURL: URL

    init?(environment: [String: String] = ProcessInfo.processInfo.environment) {
        guard
            let apiURL = environment["API_URL"].flatMap(URL.init(string:)),
            let etaURL = environment["ETA_URL"].flatMap(URL.init(string:))
        else {
            return nil
        }
        self.apiURL = apiURL
        self.etaURL = etaURL
    }

    func orders() async throws -> [Order] {
        try await get(apiURL.appending(path: "orders"))
    }

    func order(_ id: String) async throws -> Order {
        try await get(apiURL.appending(path: "orders/\(id)"))
    }

    func estimate(for id: String) async throws -> DeliveryEstimate {
        try await get(etaURL.appending(path: "eta/\(id)"))
    }

    // Ephemeral, so every refresh reaches the service instead of a cache.
    private static let session = URLSession(configuration: .ephemeral)

    private func get<T: Decodable>(_ url: URL) async throws -> T {
        let (data, response) = try await Self.session.data(for: URLRequest(url: url, timeoutInterval: 8))
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200 else {
            throw OrdersAPIError.unexpectedStatus(status)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}

enum OrdersAPIError: LocalizedError {
    case unexpectedStatus(Int)

    var errorDescription: String? {
        switch self {
        case .unexpectedStatus(let status):
            "The service answered HTTP \(status)."
        }
    }
}

extension URL {
    // host:port as the app dials it, shown under each section so the viewer
    // sees where the data came from.
    var hostAndPort: String {
        [host(), port.map(String.init)].compactMap(\.self).joined(separator: ":")
    }
}
