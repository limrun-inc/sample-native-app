//
//  sample_native_appApp.swift
//  sample-native-app
//
//  Created by Muvaffak on 1/16/26.
//

import SwiftUI

@main
struct sample_native_appApp: App {
    @StateObject private var connectivity = ConnectivityModel()

    var body: some Scene {
        WindowGroup {
            ContentView(model: connectivity)
                .onOpenURL { url in
                    if connectivity.applyConfiguration(url) {
                        connectivity.checkAllServices()
                    }
                }
        }
    }
}
