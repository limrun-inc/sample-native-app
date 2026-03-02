//
//  ContentView.swift
//  sample-native-app
//
//  Created by Muvaffak on 1/16/26.
//

import SwiftUI
import Combine

struct ContentView: View {
    @State private var showAlternate = false

    private let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text(showAlternate ? "Hello Cursor Cloud Agent" : "Hello world")
                .animation(.easeInOut, value: showAlternate)
        }
        .padding()
        .onReceive(timer) { _ in
            showAlternate.toggle()
        }
    }
}

#Preview {
    ContentView()
}
