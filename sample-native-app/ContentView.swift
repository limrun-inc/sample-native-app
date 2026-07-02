//
//  ContentView.swift
//  sample-native-app
//
//  Created by Muvaffak on 1/16/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var auth: AuthState

    var body: some View {
        Group {
            if auth.isSignedIn {
                SignedInView()
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut(duration: 0.25), value: auth.isSignedIn)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthState())
}
