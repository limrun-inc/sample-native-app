//
//  ContentView.swift
//  sample-native-app
//
//  Created by Muvaffak on 1/16/26.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house", value: 0) {
                VStack {
                    Spacer()
                    Text("hello cursor")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            Tab("More", systemImage: "ellipsis.circle", value: 1) {
                VStack {
                    Spacer()
                    Text("More")
                        .font(.title2)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        // System tab bar on iOS 26+ uses the Liquid Glass material when using the new Tab API.
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}

#Preview {
    ContentView()
}
