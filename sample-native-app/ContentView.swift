//
//  ContentView.swift
//  sample-native-app
//
//  Created by Muvaffak on 1/16/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image("SampleImage")
                .resizable()
                .scaledToFit()
                .frame(width: 240, height: 240)
                .accessibilityLabel("Mountains and sun")
            Text("Hello, world!")
            if let flag = ProcessInfo.processInfo.arguments.firstIndex(of: "--limrun-app-value"),
               ProcessInfo.processInfo.arguments.indices.contains(flag + 1) {
                Text("Launch argument: \(ProcessInfo.processInfo.arguments[flag + 1])")
                Text("Launch environment: \(ProcessInfo.processInfo.environment["LIMRUN_APP_VALUE"] ?? "missing")")
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
