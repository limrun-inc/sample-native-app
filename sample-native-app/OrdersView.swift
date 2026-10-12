import SwiftUI

enum Loadable<Value> {
    case loading
    case loaded(Value)
    case failed(String)

    init(_ fetch: () async throws -> Value) async {
        do {
            self = .loaded(try await fetch())
        } catch {
            self = .failed(error.localizedDescription)
        }
    }
}

struct OrdersView: View {
    let api: OrdersAPI
    @Binding var path: [String]
    @State private var orders: Loadable<[Order]> = .loading

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section {
                    switch orders {
                    case .loading:
                        ProgressView()
                    case .failed(let message):
                        FailureRow(message: message)
                    case .loaded(let orders):
                        ForEach(orders) { order in
                            NavigationLink(value: order.id) {
                                OrderRow(order: order)
                            }
                        }
                    }
                } footer: {
                    SourceFooter(url: api.apiURL)
                }
            }
            .navigationTitle("Orders")
            .navigationDestination(for: String.self) { id in
                OrderDetailView(api: api, id: id)
            }
            .task { await load() }
            .toolbar { RefreshButton(action: load) }
        }
    }

    // A cancelled load (the view went away mid-request) keeps the old state
    // instead of showing the cancellation as a failure.
    private func load() async {
        let orders = await Loadable { try await api.orders() }
        if !Task.isCancelled {
            self.orders = orders
        }
    }
}

struct OrderDetailView: View {
    let api: OrdersAPI
    let id: String
    @State private var order: Loadable<Order> = .loading
    @State private var estimate: Loadable<DeliveryEstimate> = .loading

    var body: some View {
        List {
            Section {
                switch order {
                case .loading:
                    ProgressView()
                case .failed(let message):
                    FailureRow(message: message)
                case .loaded(let order):
                    LabeledContent("Customer", value: order.customer)
                    LabeledContent("Status") {
                        StatusBadge(status: order.status)
                    }
                    ForEach(order.items, id: \.self) { item in
                        LabeledContent(item.name, value: "× \(item.quantity)")
                    }
                    LabeledContent("Total") {
                        Text(order.total.formatted(.dollars))
                            .bold()
                    }
                }
            } header: {
                Text("Order")
            } footer: {
                SourceFooter(url: api.apiURL)
            }

            Section {
                switch estimate {
                case .loading:
                    ProgressView()
                case .failed(let message):
                    FailureRow(message: message)
                case .loaded(let estimate):
                    HStack(spacing: 14) {
                        Image(systemName: "scooter")
                            .font(.title)
                            .foregroundStyle(.tint)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Arrives in \(estimate.minutes) min")
                                .font(.title3.bold())
                            Text("Courier: \(estimate.courier)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("Delivery")
            } footer: {
                SourceFooter(url: api.etaURL)
            }
        }
        .navigationTitle("Order #\(id)")
        .task { await load() }
        .toolbar { RefreshButton(action: load) }
    }

    // The order and its estimate come from different services and fail
    // independently.
    private func load() async {
        async let order = Loadable { try await api.order(id) }
        async let estimate = Loadable { try await api.estimate(for: id) }
        let loaded = await (order, estimate)
        if !Task.isCancelled {
            (self.order, self.estimate) = loaded
        }
    }
}

private struct OrderRow: View {
    let order: Order

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("#\(order.id)")
                    .font(.headline)
                Spacer()
                Text(order.total.formatted(.dollars))
                    .font(.headline)
                    .monospacedDigit()
            }
            HStack {
                Text(order.customer)
                    .foregroundStyle(.secondary)
                Spacer()
                StatusBadge(status: order.status)
            }
            .font(.subheadline)
        }
        .padding(.vertical, 2)
    }
}

private struct StatusBadge: View {
    let status: String

    var body: some View {
        Text(status)
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .foregroundStyle(color)
            .background(color.opacity(0.12), in: Capsule())
    }

    private var color: Color {
        switch status {
        case "Out for delivery": .blue
        case "Preparing": .orange
        default: .secondary
        }
    }
}

// A visible button, because pull-to-refresh is unreliable to drive on a
// streamed simulator. The spinner shows that a tap did something.
private struct RefreshButton: View {
    let action: () async -> Void
    @State private var isRefreshing = false

    var body: some View {
        Button {
            Task {
                isRefreshing = true
                await action()
                isRefreshing = false
            }
        } label: {
            if isRefreshing {
                ProgressView()
            } else {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
        }
        .disabled(isRefreshing)
    }
}

private struct FailureRow: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .foregroundStyle(.red)
    }
}

private struct SourceFooter: View {
    let url: URL

    var body: some View {
        Label("From \(url.hostAndPort)", systemImage: "point.3.connected.trianglepath.dotted")
            .font(.caption.monospaced())
    }
}

extension FormatStyle where Self == Decimal.FormatStyle.Currency {
    // The orders are priced in dollars, so render them as $18.50 whatever
    // region the simulator is set to.
    static var dollars: Self {
        .currency(code: "USD").locale(Locale(identifier: "en_US"))
    }
}
