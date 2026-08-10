//
//  TradingView.swift
//  sample-native-app
//

import SwiftUI
import Charts

struct Trade: Identifiable {
    let id = UUID()
    let symbol: String
    let name: String
    let price: Double
    let changePercent: Double
    let history: [Double]
    let open: Double
    let previousClose: Double
    let dayLow: Double
    let dayHigh: Double
    let yearLow: Double
    let yearHigh: Double
    let volume: Int
    let avgVolume: Int
    let marketCap: Double
    let peRatio: Double
}

private let sampleTrades: [Trade] = [
    Trade(symbol: "AAPL", name: "Apple Inc.", price: 227.52, changePercent: 0.0124,
          history: [219.1, 221.4, 220.8, 223.6, 225.0, 224.2, 226.8, 227.52],
          open: 224.80, previousClose: 224.72, dayLow: 223.90, dayHigh: 228.10,
          yearLow: 164.08, yearHigh: 237.23, volume: 48_213_000, avgVolume: 52_400_000,
          marketCap: 3_450_000_000_000, peRatio: 35.2),
    Trade(symbol: "MSFT", name: "Microsoft Corp.", price: 421.10, changePercent: -0.0038,
          history: [430.2, 428.5, 425.9, 427.1, 424.3, 422.6, 423.0, 421.10],
          open: 423.50, previousClose: 422.71, dayLow: 419.80, dayHigh: 424.90,
          yearLow: 362.90, yearHigh: 468.35, volume: 19_845_000, avgVolume: 22_100_000,
          marketCap: 3_130_000_000_000, peRatio: 34.8),
    Trade(symbol: "GOOGL", name: "Alphabet Inc.", price: 176.84, changePercent: 0.0091,
          history: [170.5, 171.9, 173.2, 172.6, 174.8, 175.1, 176.0, 176.84],
          open: 175.20, previousClose: 175.24, dayLow: 174.60, dayHigh: 177.30,
          yearLow: 130.67, yearHigh: 191.75, volume: 24_567_000, avgVolume: 27_800_000,
          marketCap: 2_180_000_000_000, peRatio: 23.6),
    Trade(symbol: "AMZN", name: "Amazon.com Inc.", price: 189.32, changePercent: -0.0105,
          history: [196.4, 194.8, 193.1, 192.5, 190.9, 191.4, 190.0, 189.32],
          open: 191.80, previousClose: 191.33, dayLow: 188.70, dayHigh: 192.40,
          yearLow: 151.61, yearHigh: 201.20, volume: 33_120_000, avgVolume: 35_900_000,
          marketCap: 1_980_000_000_000, peRatio: 41.4),
    Trade(symbol: "TSLA", name: "Tesla Inc.", price: 248.67, changePercent: 0.0342,
          history: [225.3, 229.6, 233.8, 231.2, 238.5, 242.1, 245.9, 248.67],
          open: 240.10, previousClose: 240.44, dayLow: 238.90, dayHigh: 250.20,
          yearLow: 138.80, yearHigh: 288.53, volume: 92_450_000, avgVolume: 78_300_000,
          marketCap: 793_000_000_000, peRatio: 68.9),
    Trade(symbol: "NVDA", name: "NVIDIA Corp.", price: 118.05, changePercent: 0.0217,
          history: [108.7, 110.2, 109.5, 112.8, 114.6, 115.9, 116.8, 118.05],
          open: 115.40, previousClose: 115.55, dayLow: 114.90, dayHigh: 119.20,
          yearLow: 39.23, yearHigh: 140.76, volume: 210_340_000, avgVolume: 195_600_000,
          marketCap: 2_890_000_000_000, peRatio: 52.1),
]

private struct Sparkline: View {
    let history: [Double]
    let isPositive: Bool

    var body: some View {
        Chart(Array(history.enumerated()), id: \.offset) { point in
            LineMark(x: .value("Step", point.offset), y: .value("Price", point.element))
        }
        .foregroundStyle(isPositive ? .green : .red)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartYScale(domain: (history.min() ?? 0)...(history.max() ?? 1))
        .frame(width: 70, height: 32)
    }
}

struct TradingView: View {
    var body: some View {
        NavigationStack {
            List(sampleTrades) { trade in
                NavigationLink(value: trade.id) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(trade.symbol)
                                .font(.headline)
                            Text(trade.name)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Sparkline(history: trade.history, isPositive: trade.changePercent >= 0)
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text(trade.price, format: .currency(code: "USD"))
                                .font(.body.monospacedDigit())
                            Text(trade.changePercent, format: .percent.precision(.fractionLength(2)))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(trade.changePercent >= 0 ? .green : .red)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Trading")
            .navigationDestination(for: UUID.self) { id in
                if let trade = sampleTrades.first(where: { $0.id == id }) {
                    TradeDetailView(trade: trade)
                }
            }
        }
    }
}

private struct StatItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.monospacedDigit())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct TradeDetailView: View {
    let trade: Trade

    private static let compactCurrency: FloatingPointFormatStyle<Double>.Currency = {
        .currency(code: "USD").notation(.compactName)
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading) {
                    Text(trade.symbol)
                        .font(.largeTitle.bold())
                    Text(trade.name)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text(trade.price, format: .currency(code: "USD"))
                        .font(.title2.monospacedDigit())
                    Text(trade.changePercent, format: .percent.precision(.fractionLength(2)))
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(trade.changePercent >= 0 ? .green : .red)
                }

                Chart(Array(trade.history.enumerated()), id: \.offset) { point in
                    LineMark(x: .value("Step", point.offset), y: .value("Price", point.element))
                        .interpolationMethod(.catmullRom)
                    AreaMark(x: .value("Step", point.offset), y: .value("Price", point.element))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(.linearGradient(
                            colors: [(trade.changePercent >= 0 ? Color.green : Color.red).opacity(0.3), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                }
                .foregroundStyle(trade.changePercent >= 0 ? .green : .red)
                .frame(height: 220)

                Divider()

                Text("Day Range")
                    .font(.headline)
                DayRangeBar(low: trade.dayLow, high: trade.dayHigh, current: trade.price)

                Text("52 Week Range")
                    .font(.headline)
                DayRangeBar(low: trade.yearLow, high: trade.yearHigh, current: trade.price)

                Divider()

                Text("Statistics")
                    .font(.headline)

                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 16) {
                    GridRow {
                        StatItem(label: "Open", value: trade.open.formatted(.currency(code: "USD")))
                        StatItem(label: "Previous Close", value: trade.previousClose.formatted(.currency(code: "USD")))
                    }
                    GridRow {
                        StatItem(label: "Day Low", value: trade.dayLow.formatted(.currency(code: "USD")))
                        StatItem(label: "Day High", value: trade.dayHigh.formatted(.currency(code: "USD")))
                    }
                    GridRow {
                        StatItem(label: "Volume", value: trade.volume.formatted(.number.notation(.compactName)))
                        StatItem(label: "Avg Volume", value: trade.avgVolume.formatted(.number.notation(.compactName)))
                    }
                    GridRow {
                        StatItem(label: "Market Cap", value: trade.marketCap.formatted(Self.compactCurrency))
                        StatItem(label: "P/E Ratio", value: trade.peRatio.formatted(.number.precision(.fractionLength(1))))
                    }
                }
            }
            .padding()
        }
        .navigationTitle(trade.symbol)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct DayRangeBar: View {
    let low: Double
    let high: Double
    let current: Double

    private var fraction: Double {
        guard high > low else { return 0.5 }
        return (current - low) / (high - low)
    }

    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 4)
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 10, height: 10)
                        .offset(x: max(0, min(geo.size.width - 10, geo.size.width * fraction - 5)))
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 16)

            HStack {
                Text(low, format: .currency(code: "USD"))
                Spacer()
                Text(high, format: .currency(code: "USD"))
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    TradingView()
}
