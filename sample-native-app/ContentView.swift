//
//  ContentView.swift
//  sample-native-app
//
//  Created by Muvaffak on 1/16/26.
//

import SwiftUI

struct ContentView: View {
    @State private var count = 0

    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 12) {
                Text("Number Counter")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .accessibilityIdentifier("counterTitle")

                Text("Tap the buttons to count up or down.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Text("\(count)")
                .font(.system(size: 96, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .accessibilityLabel("Current count")
                .accessibilityValue("\(count)")
                .accessibilityIdentifier("countValue")

            HStack(spacing: 16) {
                Button {
                    count -= 1
                } label: {
                    Label("Decrease", systemImage: "minus.circle.fill")
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .accessibilityIdentifier("decreaseButton")

                Button {
                    count += 1
                } label: {
                    Label("Increase", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityIdentifier("increaseButton")
            }

            Button("Reset") {
                count = 0
            }
            .buttonStyle(.borderless)
            .font(.headline)
            .accessibilityIdentifier("resetButton")
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [Color(.systemBackground), Color.blue.opacity(0.12)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

#Preview {
    ContentView()
}
