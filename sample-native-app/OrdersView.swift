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
            .refreshable { await load() }
        }
    }

    private func load() async {
        orders = await Loadable { try await api.orders() }
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
                        Text(order.total, format: .currency(code: "USD"))
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
        .refreshable { await load() }
    }

    // The order and its estimate come from different services and fail
    // independently.
    private func load() async {
        async let order = Loadable { try await api.order(id) }
        async let estimate = Loadable { try await api.estimate(for: id) }
        (self.order, self.estimate) = await (order, estimate)
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
                Text(order.total, format: .currency(code: "USD"))
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
