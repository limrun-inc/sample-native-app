//
//  sample_native_appApp.swift
//  sample-native-app
//
//  Created by Muvaffak on 1/16/26.
//

import SwiftUI

@main
struct sample_native_appApp: App {
    @State private var path: [String] = []
    private let api = OrdersAPI()

    var body: some Scene {
        WindowGroup {
            Group {
                if let api {
                    OrdersView(api: api, path: $path)
                } else {
                    ContentUnavailableView(
                        "No backend configured",
                        systemImage: "server.rack",
                        description: Text("Launch the app with API_URL and ETA_URL set.")
                    )
                }
            }
            // limrun-demo://orders/<id> opens that order, so a preview link
            // lands the reviewer on the screen under review.
            .onOpenURL { url in
                guard url.host() == "orders", let id = url.pathComponents.dropFirst().first else {
                    return
                }
                path = [id]
            }
        }
    }
}
