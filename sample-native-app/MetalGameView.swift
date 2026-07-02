//
//  MetalGameView.swift
//  sample-native-app
//
//  SwiftUI wrapper hosting the MTKView that runs the runner game.
//

import SwiftUI
import MetalKit

struct MetalGameView: UIViewRepresentable {
    let world: GameWorld

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView(frame: .zero)
        view.backgroundColor = .clear
        view.framebufferOnly = true
        view.isOpaque = true
        view.enableSetNeedsDisplay = false
        view.isPaused = false
        view.preferredFramesPerSecond = 60

        let renderer = Renderer(view: view, world: world)
        context.coordinator.renderer = renderer
        view.delegate = renderer
        return view
    }

    func updateUIView(_ uiView: MTKView, context: Context) {}

    final class Coordinator {
        var renderer: Renderer?
    }
}
