//
//  BayRow.swift
//  sample-native-app
//

import SwiftUI

struct BayRow: View {
    let bay: Bay

    private var statusColor: Color {
        switch bay.status {
        case .onTrack: return .green
        case .approachingLimit: return .yellow
        case .overLimit: return .red
        }
    }

    var body: some View {
        HStack {
            Circle()
                .fill(statusColor)
                .frame(width: 14, height: 14)
            VStack(alignment: .leading) {
                Text(bay.name)
                    .font(.headline)
                Text(bay.technician)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if bay.elapsedMinutes > 0 {
                Text("\(bay.elapsedMinutes) / \(bay.limitMinutes) min")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                Text("Open")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    List(Bay.sample) { BayRow(bay: $0) }
}
