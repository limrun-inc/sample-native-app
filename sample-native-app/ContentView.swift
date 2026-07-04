//
//  ContentView.swift
//  sample-native-app
//
//  Created by Muvaffak on 1/16/26.
//

import Foundation
import SwiftUI

struct ContentView: View {
    @State private var snapshot: DiskSpaceSnapshot?
    @State private var loadError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                if let snapshot {
                    DiskUsageSummary(snapshot: snapshot)
                    metricGrid(snapshot: snapshot)
                    DiskAlertCard(snapshot: snapshot)
                } else if let loadError {
                    ErrorCard(message: loadError, retryAction: refreshSnapshot)
                } else {
                    ProgressView("Loading disk metrics...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 48)
                }
            }
            .padding(24)
        }
        .background(Color(.systemGroupedBackground))
        .onAppear(perform: refreshSnapshot)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Disk Space")
                        .font(.largeTitle.weight(.bold))
                        .accessibilityIdentifier("diskSpaceTitle")
                    Text("Live device storage metrics with threshold-based alerts.")
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(action: refreshSnapshot) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("refreshDiskMetricsButton")
            }
        }
    }

    private func metricGrid(snapshot: DiskSpaceSnapshot) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MetricCard(
                title: "Used",
                value: ByteCountFormatter.diskSpace.string(fromByteCount: snapshot.usedBytes),
                systemImage: "internaldrive.fill"
            )
            MetricCard(
                title: "Free",
                value: ByteCountFormatter.diskSpace.string(fromByteCount: snapshot.availableBytes),
                systemImage: "externaldrive.badge.checkmark"
            )
            MetricCard(
                title: "Total",
                value: ByteCountFormatter.diskSpace.string(fromByteCount: snapshot.totalBytes),
                systemImage: "internaldrive"
            )
            MetricCard(
                title: "Updated",
                value: snapshot.timestamp.formatted(date: .omitted, time: .shortened),
                systemImage: "clock"
            )
        }
    }

    private func refreshSnapshot() {
        do {
            snapshot = try DiskSpaceSnapshot.current()
            loadError = nil
        } catch {
            snapshot = nil
            loadError = error.localizedDescription
        }
    }
}

#Preview {
    ContentView()
}

private struct DiskUsageSummary: View {
    let snapshot: DiskSpaceSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text(snapshot.usedFraction, format: .percent.precision(.fractionLength(1)))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(snapshot.level.color)
                    .accessibilityIdentifier("diskUsagePercent")
                Text("used")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: snapshot.usedFraction)
                .tint(snapshot.level.color)
                .scaleEffect(x: 1, y: 1.8, anchor: .center)
                .accessibilityIdentifier("diskUsageProgress")

            Text("\(ByteCountFormatter.diskSpace.string(fromByteCount: snapshot.availableBytes)) free of \(ByteCountFormatter.diskSpace.string(fromByteCount: snapshot.totalBytes))")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .cardStyle()
    }
}

private struct DiskAlertCard: View {
    let snapshot: DiskSpaceSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text(snapshot.level.title)
                    .font(.headline)
            } icon: {
                Image(systemName: snapshot.level.systemImage)
                    .foregroundStyle(snapshot.level.color)
            }
            .accessibilityIdentifier("diskAlertStatus")

            Text(snapshot.level.message)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                Text("Alert thresholds")
                    .font(.subheadline.weight(.semibold))
                Text("Warning at 80% used or 10% free. Critical at 90% used or 5% free.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .cardStyle()
    }
}

private struct MetricCard: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(.tint)
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

private struct ErrorCard: View {
    let message: String
    let retryAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Unable to load disk metrics", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.red)
            Text(message)
                .foregroundStyle(.secondary)
            Button("Try Again", action: retryAction)
                .buttonStyle(.borderedProminent)
        }
        .cardStyle()
    }
}

private struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(18)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
}

private struct DiskSpaceSnapshot {
    let totalBytes: Int64
    let availableBytes: Int64
    let timestamp: Date

    var usedBytes: Int64 {
        max(totalBytes - availableBytes, 0)
    }

    var usedFraction: Double {
        guard totalBytes > 0 else { return 0 }
        return min(max(Double(usedBytes) / Double(totalBytes), 0), 1)
    }

    var availableFraction: Double {
        guard totalBytes > 0 else { return 0 }
        return min(max(Double(availableBytes) / Double(totalBytes), 0), 1)
    }

    var level: DiskSpaceAlertLevel {
        DiskSpaceAlertLevel.evaluate(usedFraction: usedFraction, availableFraction: availableFraction)
    }

    static func current(fileManager: FileManager = .default) throws -> DiskSpaceSnapshot {
        let volumeURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory())
        let resourceKeys: Set<URLResourceKey> = [
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeAvailableCapacityKey,
            .volumeTotalCapacityKey
        ]
        let values = try volumeURL.resourceValues(forKeys: resourceKeys)
        let totalBytes = Int64(values.volumeTotalCapacity ?? 0)
        let availableBytes = values.volumeAvailableCapacityForImportantUsage
            ?? Int64(values.volumeAvailableCapacity ?? 0)

        guard totalBytes > 0 else {
            throw DiskSpaceSnapshotError.missingCapacity
        }

        return DiskSpaceSnapshot(
            totalBytes: totalBytes,
            availableBytes: min(max(availableBytes, 0), totalBytes),
            timestamp: Date()
        )
    }
}

private enum DiskSpaceSnapshotError: LocalizedError {
    case missingCapacity

    var errorDescription: String? {
        "The current volume did not report total storage capacity."
    }
}

private enum DiskSpaceAlertLevel {
    case healthy
    case warning
    case critical

    static func evaluate(usedFraction: Double, availableFraction: Double) -> DiskSpaceAlertLevel {
        if usedFraction >= 0.90 || availableFraction <= 0.05 {
            return .critical
        }

        if usedFraction >= 0.80 || availableFraction <= 0.10 {
            return .warning
        }

        return .healthy
    }

    var title: String {
        switch self {
        case .healthy:
            return "Storage healthy"
        case .warning:
            return "Disk space warning"
        case .critical:
            return "Disk space critical"
        }
    }

    var message: String {
        switch self {
        case .healthy:
            return "No disk-space alerts are active."
        case .warning:
            return "Free space is getting low. Review stored files before usage reaches the critical threshold."
        case .critical:
            return "Immediate attention recommended. Available disk space is below the critical threshold."
        }
    }

    var color: Color {
        switch self {
        case .healthy:
            return .green
        case .warning:
            return .orange
        case .critical:
            return .red
        }
    }

    var systemImage: String {
        switch self {
        case .healthy:
            return "checkmark.seal.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .critical:
            return "xmark.octagon.fill"
        }
    }
}

private extension ByteCountFormatter {
    static let diskSpace: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        formatter.includesUnit = true
        formatter.isAdaptive = true
        return formatter
    }()
}
