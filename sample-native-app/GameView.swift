//
//  GameView.swift
//  sample-native-app
//
//  SwiftUI wrapper for the Metal MTKView and gesture handling.
//

import SwiftUI
import MetalKit
import UIKit

@MainActor
final class GameViewState: ObservableObject {
    @Published var score: Int = 0
    @Published var speed: Float = 0
    @Published var isGameOver: Bool = false
}

struct GameView: UIViewRepresentable {
    @ObservedObject var state: GameViewState
    /// Bumping this value triggers a reset of the underlying scene.
    var resetToken: Int

    func makeCoordinator() -> Coordinator {
        Coordinator(state: state)
    }

    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView(frame: .zero)
        mtkView.isOpaque = true
        mtkView.backgroundColor = UIColor(red: 0.55, green: 0.78, blue: 0.95, alpha: 1.0)
        mtkView.translatesAutoresizingMaskIntoConstraints = false
        mtkView.accessibilityIdentifier = "gameMetalView"

        if let renderer = MetalRenderer(mtkView: mtkView) {
            mtkView.delegate = renderer
            context.coordinator.renderer = renderer
            renderer.onFrame = { [weak coordinator = context.coordinator] scene in
                coordinator?.publish(scene: scene)
            }
        } else {
            print("Failed to initialize MetalRenderer")
        }

        // Gesture recognizers for swipes and taps (jump).
        let leftSwipe = UISwipeGestureRecognizer(target: context.coordinator,
                                                 action: #selector(Coordinator.onSwipeLeft))
        leftSwipe.direction = .left
        mtkView.addGestureRecognizer(leftSwipe)

        let rightSwipe = UISwipeGestureRecognizer(target: context.coordinator,
                                                  action: #selector(Coordinator.onSwipeRight))
        rightSwipe.direction = .right
        mtkView.addGestureRecognizer(rightSwipe)

        let upSwipe = UISwipeGestureRecognizer(target: context.coordinator,
                                               action: #selector(Coordinator.onSwipeUp))
        upSwipe.direction = .up
        mtkView.addGestureRecognizer(upSwipe)

        let tap = UITapGestureRecognizer(target: context.coordinator,
                                         action: #selector(Coordinator.onTap))
        mtkView.addGestureRecognizer(tap)

        return mtkView
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        if context.coordinator.lastResetToken != resetToken {
            context.coordinator.lastResetToken = resetToken
            context.coordinator.renderer?.scene.reset()
        }
    }

    @MainActor
    final class Coordinator: NSObject {
        weak var state: GameViewState?
        var renderer: MetalRenderer?
        var lastResetToken: Int = 0

        init(state: GameViewState) {
            self.state = state
        }

        func publish(scene: GameScene) {
            // Avoid SwiftUI re-renders when nothing visible changed.
            guard let state = state else { return }
            if state.score != scene.score { state.score = scene.score }
            if abs(state.speed - scene.speed) > 0.05 { state.speed = scene.speed }
            if state.isGameOver != scene.isGameOver { state.isGameOver = scene.isGameOver }
        }

        @objc func onSwipeLeft() { renderer?.scene.swipeLeft() }
        @objc func onSwipeRight() { renderer?.scene.swipeRight() }
        @objc func onSwipeUp() { renderer?.scene.jump() }
        @objc func onTap() { renderer?.scene.jump() }
    }
}
