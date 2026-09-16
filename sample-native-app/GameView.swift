//
//  GameView.swift
//  sample-native-app
//

import SwiftUI
import SceneKit

struct SceneKitView: UIViewRepresentable {
    let controller: GameController
    let state: GameState

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = controller.scene
        view.delegate = controller
        view.isPlaying = true
        view.rendersContinuously = true
        view.antialiasingMode = .multisampling4X
        view.backgroundColor = UIColor(red: 0.53, green: 0.81, blue: 0.98, alpha: 1)

        let left = UISwipeGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.swipeLeft))
        left.direction = .left
        let right = UISwipeGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.swipeRight))
        right.direction = .right
        let up = UISwipeGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.swipeUp))
        up.direction = .up
        let down = UISwipeGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.swipeDown))
        down.direction = .down
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.tapped))
        for g in [left, right, up, down, tap] { view.addGestureRecognizer(g) }
        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(controller: controller, state: state)
    }

    final class Coordinator: NSObject {
        let controller: GameController
        let state: GameState

        init(controller: GameController, state: GameState) {
            self.controller = controller
            self.state = state
        }

        @objc func swipeLeft() { controller.moveLeft() }
        @objc func swipeRight() { controller.moveRight() }
        @objc func swipeUp() { controller.jump() }
        @objc func swipeDown() { controller.roll() }
        @objc func tapped() {
            if state.phase != .running {
                controller.start()
            }
        }
    }
}

struct GameView: View {
    @StateObject private var state: GameState
    private let controller: GameController

    init() {
        let state = GameState()
        _state = StateObject(wrappedValue: state)
        controller = GameController(state: state)
    }

    var body: some View {
        ZStack {
            SceneKitView(controller: controller, state: state)
                .ignoresSafeArea()

            VStack {
                HStack(spacing: 24) {
                    Text("Score \(state.score)")
                        .accessibilityIdentifier("scoreLabel")
                    Text("Coins \(state.coins)")
                        .accessibilityIdentifier("coinsLabel")
                }
                .font(.title2.bold())
                .foregroundStyle(.white)
                .shadow(radius: 3)
                .padding(.top, 16)

                Spacer()

                if state.phase == .running {
                    HStack(spacing: 20) {
                        controlButton(id: "leftButton", label: "Left", symbol: "chevron.left") {
                            controller.moveLeft()
                        }
                        controlButton(id: "jumpButton", label: "Jump", symbol: "arrow.up") {
                            controller.jump()
                        }
                        controlButton(id: "rollButton", label: "Roll", symbol: "arrow.down") {
                            controller.roll()
                        }
                        controlButton(id: "rightButton", label: "Right", symbol: "chevron.right") {
                            controller.moveRight()
                        }
                    }
                    .padding(.bottom, 32)
                }
            }

            if state.phase == .ready {
                VStack(spacing: 20) {
                    Text("Subway Runner")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                        .shadow(radius: 4)
                        .accessibilityIdentifier("titleLabel")
                    Button("Tap to Start") { controller.start() }
                        .font(.title3.bold())
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(.white.opacity(0.9), in: Capsule())
                        .accessibilityIdentifier("startButton")
                }
            }

            if state.phase == .gameOver {
                VStack(spacing: 16) {
                    Text("Game Over")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                        .shadow(radius: 4)
                        .accessibilityIdentifier("gameOverLabel")
                    Text("Best \(state.best)")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .shadow(radius: 3)
                    Button("Play Again") { controller.start() }
                        .font(.title3.bold())
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(.white.opacity(0.9), in: Capsule())
                        .accessibilityIdentifier("restartButton")
                }
            }
        }
    }

    private func controlButton(id: String, label: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.title2.bold())
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(.black.opacity(0.35), in: Circle())
        }
        .accessibilityLabel(label)
        .accessibilityIdentifier(id)
    }
}
