//
//  sample_native_appApp.swift
//  sample-native-app
//
//  Created by Muvaffak on 1/16/26.
//

import SwiftUI

@main
struct sample_native_appApp: App {
    @StateObject private var auth = AuthState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(auth)
        }
    }
}
