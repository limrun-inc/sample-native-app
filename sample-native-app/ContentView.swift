//
//  ContentView.swift
//  sample-native-app
//

import SwiftUI
import UIKit

struct GameViewRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> GameViewController {
        return GameViewController()
    }
    func updateUIViewController(_ uiViewController: GameViewController, context: Context) {}
}

struct ContentView: View {
    var body: some View {
        GameViewRepresentable()
            .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
