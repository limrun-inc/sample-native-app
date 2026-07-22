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
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            #if LIMRUN
            Text("LIMRUN preview build")
            #endif
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
