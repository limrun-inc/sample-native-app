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
                    .font(.largeTitle.bold())
                    .accessibilityIdentifier("counterTitle")

                Text("Tap the buttons to count up or down.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Text("\(count)")
                .font(.system(size: 88, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
                .accessibilityLabel("Current count \(count)")
                .accessibilityIdentifier("countValue")

            HStack(spacing: 16) {
                CounterButton(title: "Minus", systemImage: "minus") {
                    count -= 1
                }
                .accessibilityIdentifier("decrementButton")

                CounterButton(title: "Plus", systemImage: "plus") {
                    count += 1
                }
                .accessibilityIdentifier("incrementButton")
            }

            Button("Reset") {
                count = 0
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .accessibilityIdentifier("resetButton")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
        .background(Color(.systemGroupedBackground))
    }
}

private struct CounterButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }
}

#Preview {
    ContentView()
}
