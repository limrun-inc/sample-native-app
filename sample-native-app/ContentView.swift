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
        VStack(spacing: 28) {
            VStack(spacing: 8) {
                Text("Number Counter")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("Tap the buttons to count up or down.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Text("\(count)")
                .font(.system(size: 88, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .accessibilityLabel("Current count")
                .accessibilityValue("\(count)")
                .accessibilityIdentifier("countValue")

            HStack(spacing: 16) {
                Button {
                    count -= 1
                } label: {
                    Label("Decrease", systemImage: "minus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("decreaseButton")

                Button {
                    count += 1
                } label: {
                    Label("Increase", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("increaseButton")
            }

            Button("Reset") {
                count = 0
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .accessibilityIdentifier("resetButton")
        }
        .padding(32)
    }
}

#Preview {
    ContentView()
}
