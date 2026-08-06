//
//  ContentView.swift
//  sample-native-app
//
//  Created by Muvaffak on 1/16/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Hello, Baymetrics!")
                NavigationLink("Profile") {
                    ProfileView()
                }
                .padding(.top)
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
