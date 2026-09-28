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

    var body: some View {
        VStack(spacing: 16) {
            Image("SampleImage")
                .resizable()
                .scaledToFit()
                .frame(width: 240, height: 240)
                .accessibilityLabel("Mountains and sun")
            Text(greeting)
                .font(.title2)
                .accessibilityIdentifier("greeting")
            TextField("Your name", text: $name)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.done)
                .onSubmit(greet)
                .accessibilityIdentifier("nameField")
            Button("Say hello", action: greet)
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("greetButton")
        }
        .padding()
    }

    // The log line lets the docs show that app output is readable from the
    // simulator, next to the change on screen.
    private func greet() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        greeting = trimmed.isEmpty ? "Hello, world!" : "Hello, \(trimmed)!"
        print("[sample] greeted \(trimmed.isEmpty ? "world" : trimmed)")
    }
}

#Preview {
    ContentView()
}
