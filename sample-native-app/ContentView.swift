//
//  ContentView.swift
//  sample-native-app
//
//  Created by Muvaffak on 1/16/26.
//

import SwiftUI

struct ContentView: View {
    @State private var name = ""
    @State private var greeting = "Hello, world!"
    @FocusState private var nameFocused: Bool

    var body: some View {
        VStack(spacing: 28) {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 220)
                .padding(.bottom, 12)
                .accessibilityLabel("Limrun")

            VStack(spacing: 8) {
                Text(greeting)
                    .font(.largeTitle.bold())
                    .accessibilityIdentifier("greeting")
                Text("Type your name and tap Say hello.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                TextField("Your name", text: $name)
                    .focused($nameFocused)
                    .submitLabel(.done)
                    .onSubmit(greet)
                    .padding(.horizontal, 16)
                    .frame(height: 50)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .accessibilityIdentifier("nameField")
                Button(action: greet) {
                    Text("Say hello")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .buttonBorderShape(.roundedRectangle(radius: 14))
                .accessibilityIdentifier("greetButton")
            }
        }
        .padding(24)
        .frame(maxWidth: 420, maxHeight: .infinity)
        .animation(.snappy, value: greeting)
    }

    // The log line lets the docs show that app output is readable from the
    // simulator, next to the change on screen.
    private func greet() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        greeting = trimmed.isEmpty ? "Hello, world!" : "Hello, \(trimmed)!"
        nameFocused = false
        print("[sample] greeted \(trimmed.isEmpty ? "world" : trimmed)")
    }
}

#Preview {
    ContentView()
}
