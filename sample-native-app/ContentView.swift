//
//  ContentView.swift
//  sample-native-app
//
//  Created by Muvaffak on 1/16/26.
//

import SwiftUI

private enum DemoPalette {
    static let ink = Color(red: 0.06, green: 0.09, blue: 0.16)
    static let paper = Color(red: 0.96, green: 0.97, blue: 0.99)
    static let mist = Color(red: 0.88, green: 0.91, blue: 0.96)
    static let internalRoute = Color(red: 0.31, green: 0.35, blue: 0.95)
    static let intranetRoute = Color(red: 0.55, green: 0.27, blue: 0.85)
    static let localRoute = Color(red: 0.96, green: 0.42, blue: 0.20)
    static let success = Color(red: 0.12, green: 0.64, blue: 0.42)
}

struct ContentView: View {
    @ObservedObject var model: ConnectivityModel
    @State private var showingConfiguration = false
    @State private var checkedInitialConfiguration = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    pathDiagram
                    routeSummary

                    ServiceCard(
                        title: "Local API",
                        endpoint: model.internalEndpoint,
                        accent: DemoPalette.internalRoute,
                        state: model.internalState
                    )

                    ServiceCard(
                        title: "Internal-only API",
                        endpoint: model.intranetEndpoint,
                        accent: DemoPalette.intranetRoute,
                        state: model.intranetState
                    )

                    ServiceCard(
                        title: "Public egress IP",
                        endpoint: model.egressEndpoint,
                        accent: DemoPalette.localRoute,
                        state: model.egressState
                    )

                    Label(
                        "Only the three destinations above are declared.",
                        systemImage: "checkmark.shield"
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
                }
                .padding(16)
            }
            .background(DemoPalette.paper.ignoresSafeArea())
            .safeAreaInset(edge: .bottom, spacing: 0) {
                checkButton
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingConfiguration = true
                    } label: {
                        Label("Routes", systemImage: "slider.horizontal.3")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .labelStyle(.titleAndIcon)
                    }
                    .accessibilityLabel("Route settings")
                }
            }
            .sheet(isPresented: $showingConfiguration) {
                ConfigurationView(model: model)
            }
            .onAppear {
                guard model.isConfigured, !checkedInitialConfiguration else {
                    return
                }
                checkedInitialConfiguration = true
                model.checkAllServices()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                Circle()
                    .fill(DemoPalette.internalRoute)
                    .frame(width: 7, height: 7)
                Text("LIMRUN / LIVE TUNNEL")
                    .font(.system(.caption, design: .monospaced, weight: .semibold))
                    .tracking(1.4)
                    .foregroundStyle(DemoPalette.internalRoute)
            }

            Text("Your localhost.\nOn a cloud iPhone.")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(DemoPalette.ink)
                .minimumScaleFactor(0.8)

            Text("The app keeps its URLs: a localhost port, an internal-only hostname, and ifconfig.me. Limrun carries all three back to this Mac.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    private var checkButton: some View {
        Button {
            model.checkAllServices()
        } label: {
            Label(
                model.isChecking ? "Checking live routes…" : "Run live check",
                systemImage: "arrow.trianglehead.2.clockwise"
            )
            .font(.system(.headline, design: .rounded, weight: .semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .background(model.isConfigured ? DemoPalette.ink : Color.gray)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .disabled(!model.isConfigured || model.isChecking)
        .accessibilityIdentifier("check-services")
    }

    private var pathDiagram: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ONE TUNNEL, SAME URLS")
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .tracking(1.1)
                .foregroundStyle(.white.opacity(0.55))

            HStack(spacing: 8) {
                pathStop(icon: "iphone", label: "CLOUD\nIPHONE")
                pathConnector
                pathStop(icon: "point.3.connected.trianglepath.dotted", label: "LIMRUN\nTUNNEL")
                pathConnector
                pathStop(icon: "laptopcomputer", label: "THIS\nMAC")
            }
        }
        .padding(16)
        .background(DemoPalette.ink)
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(summary.color.opacity(0.65), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .animation(.easeInOut(duration: 0.25), value: summary.label)
    }

    private func pathStop(icon: String, label: String) -> some View {
        VStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(.white)
                .frame(height: 24)
            Text(label)
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.72))
        }
        .frame(width: 70)
    }

    private var pathConnector: some View {
        HStack(spacing: 3) {
            Rectangle()
                .fill(summary.color)
                .frame(height: 2)
            Image(systemName: "chevron.right")
                .font(.caption2.bold())
                .foregroundStyle(summary.color)
        }
        .frame(maxWidth: .infinity)
    }

    private var routeSummary: some View {
        HStack(spacing: 10) {
            Image(systemName: summary.icon)
            Text(summary.label)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
            Spacer()
            Circle()
                .fill(summary.color)
                .frame(width: 9, height: 9)
        }
        .foregroundStyle(DemoPalette.ink)
        .padding(14)
        .background(summary.color.opacity(0.10))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(summary.color.opacity(0.18), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .animation(.easeInOut(duration: 0.2), value: summary.label)
    }

    private var summary: (label: String, icon: String, color: Color) {
        guard model.isConfigured else {
            return ("Waiting for route configuration", "lock.open", .orange)
        }

        let states = [model.internalState, model.intranetState, model.egressState]
        let failures = states.filter(\.isFailure).count
        if failures > 0 {
            return (
                "\(failures) of 3 destinations unreachable",
                "exclamationmark.triangle.fill",
                .red
            )
        }
        if states.contains(where: \.isLoading) {
            return ("Checking both destinations", "arrow.trianglehead.2.clockwise", DemoPalette.internalRoute)
        }
        if states.allSatisfy(\.isSuccess) {
            return ("3 destinations reachable", "checkmark.shield.fill", DemoPalette.success)
        }
        return ("3 destinations ready to check", "point.3.connected.trianglepath.dotted", DemoPalette.internalRoute)
    }
}

private struct ServiceCard: View {
    let title: String
    let endpoint: String
    let accent: Color
    let state: ServiceCheckState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                Spacer()
                HStack(spacing: 6) {
                    statusIcon
                    Text(statusLabel)
                        .font(.system(.caption, design: .rounded, weight: .bold))
                }
                .foregroundStyle(statusColor)
            }

            EndpointRow(
                label: "Destination",
                value: endpointLabel,
                accent: accent
            )
            .padding(9)
            .background(accent.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            statusMessage
        }
        .padding(14)
        .background(.white)
        .overlay(alignment: .leading) {
            Capsule()
                .fill(accent)
                .frame(width: 5)
                .padding(.vertical, 18)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: DemoPalette.ink.opacity(0.08), radius: 16, y: 8)
    }

    private var endpointLabel: String {
        guard let url = URL(string: endpoint), let host = url.host else {
            return "not configured"
        }
        let port = url.port.map { ":\($0)" } ?? ""
        let path = url.path == "/" ? "" : url.path
        return "\(host)\(port)\(path)"
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch state {
        case .idle:
            Image(systemName: "minus.circle")
                .foregroundStyle(.secondary)
        case .loading:
            ProgressView()
        case .success:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(DemoPalette.success)
        case .failure:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
        }
    }

    private var statusLabel: String {
        switch state {
        case .idle:
            return "NOT CHECKED"
        case .loading:
            return "CHECKING"
        case .success(let result):
            return result.recovered ? "RECOVERED" : "REACHABLE"
        case .failure:
            return "UNREACHABLE"
        }
    }

    private var statusColor: Color {
        switch state {
        case .success:
            return DemoPalette.success
        case .failure:
            return .red
        case .idle, .loading:
            return .secondary
        }
    }

    @ViewBuilder
    private var statusMessage: some View {
        switch state {
        case .idle:
            Text(endpoint.isEmpty ? "Add a destination to begin." : "Ready to check.")
                .foregroundStyle(.secondary)
        case .loading:
            Text("Connecting through the tunnel…")
                .foregroundStyle(.secondary)
        case .success(let result):
            Text(result.message)
                .font(.subheadline)
                .lineLimit(1)
        case .failure(let message):
            Text(message)
                .font(.subheadline)
                .lineLimit(1)
                .foregroundStyle(.red)
        }
    }
}

private struct EndpointRow: View {
    let label: String
    let value: String
    let accent: Color
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 3) {
                labelText
                valueText
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                labelText
                    .frame(width: 105, alignment: .leading)
                valueText
                Spacer()
            }
        }
    }

    private var labelText: some View {
        Text(label)
            .font(.system(.caption, design: .rounded, weight: .semibold))
            .foregroundStyle(accent)
    }

    private var valueText: some View {
        Text(value)
            .font(.system(.caption, design: .monospaced))
            .foregroundStyle(DemoPalette.ink)
            .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
            .minimumScaleFactor(0.8)
    }
}

private struct ConfigurationView: View {
    @ObservedObject var model: ConnectivityModel
    @Environment(\.dismiss) private var dismiss
    @State private var internalEndpoint = ""
    @State private var intranetEndpoint = ""
    @State private var egressEndpoint = ""
    @State private var showsValidationError = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Local API destination") {
                    TextField("http://localhost:4100", text: $internalEndpoint)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .accessibilityIdentifier("internal-endpoint")
                }

                Section("Internal-only API destination") {
                    TextField("http://api.demo.internal:4200", text: $intranetEndpoint)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .accessibilityIdentifier("intranet-endpoint")
                }

                Section("Egress IP destination") {
                    TextField("http://ifconfig.me/ip", text: $egressEndpoint)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .accessibilityIdentifier("egress-endpoint")
                }

                if showsValidationError {
                    Text("Enter HTTP URLs with a localhost, IP, or domain host.")
                        .foregroundStyle(.red)
                }

                Section {
                    Text("These are the app's real destinations. They stay unchanged before, during and after the tunnel.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Connection settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if model.configure(
                            internalEndpoint: internalEndpoint,
                            intranetEndpoint: intranetEndpoint,
                            egressEndpoint: egressEndpoint
                        ) {
                            dismiss()
                            model.checkAllServices()
                        } else {
                            showsValidationError = true
                        }
                    }
                }
            }
            .onAppear {
                internalEndpoint = model.internalEndpoint
                intranetEndpoint = model.intranetEndpoint
                egressEndpoint = model.egressEndpoint
            }
        }
    }
}

#Preview {
    ContentView(model: ConnectivityModel())
}
