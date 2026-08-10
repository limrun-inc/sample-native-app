//
//  ContentView.swift
//  sample-native-app
//
//  Created by Muvaffak on 1/16/26.
//

import SwiftUI

struct ContentView: View {
    @Binding var isLoggedIn: Bool

    var body: some View {
        TabView {
            VStack(spacing: 16) {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("hello ian")
                Button("Log Out") {
                    isLoggedIn = false
                }
            }
            .padding()
            .tabItem {
                Label("Home", systemImage: "house")
            }

            TradingView()
                .tabItem {
                    Label("Trading", systemImage: "chart.line.uptrend.xyaxis")
                }
        }
    }
}

#Preview {
    ContentView(isLoggedIn: .constant(true))
}
