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
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
