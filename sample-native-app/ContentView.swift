//
//  ContentView.swift
//  sample-native-app
//
//  Hosts the Metal-based runner game inside a SwiftUI scene with a HUD,
//  swipe / tap gesture handling, and a game-over screen.
//

import SwiftUI

struct ContentView: View {
    // GameWorld is a long-lived reference, not an observable. The HUD reads
    // its state every frame via TimelineView, so we don't need ObservableObject.
    @State private var world: GameWorld = GameWorld()

    var body: some View {
        ZStack {
            MetalGameView(world: world)
                .ignoresSafeArea()
                .accessibilityIdentifier("gameSurface")

            GameHUD(world: world)
                .ignoresSafeArea(edges: .bottom)
        }
        .statusBarHidden(true)
        .preferredColorScheme(.light)
    }
}

private struct GameHUD: View {
    let world: GameWorld

    var body: some View {
        ZStack {
            // Transparent layer that captures swipes / taps for the whole screen.
            GestureCatcher(
                onSwipeLeft:  { world.swipeLeft() },
                onSwipeRight: { world.swipeRight() },
                onSwipeUp:    { world.jump() },
                onTap:        { world.jump() }
            )
            .accessibilityIdentifier("gestureCatcher")

            // TimelineView ticks every frame. We snapshot the live game-state
            // values into the LiveHUD struct so SwiftUI's diff sees a different
            // view input each tick and re-renders the score / game-over panel.
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { _ in
                LiveHUD(score: world.score,
                        speed: world.speed,
                        isGameOver: world.isGameOver,
                        onRestart: { world.restart() })
            }
        }
    }
}

private struct LiveHUD: View {
    let score: Int
    let speed: Float
    let isGameOver: Bool
    let onRestart: () -> Void

    var body: some View {
        VStack {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("SCORE")
                        .font(.caption)
                        .fontWeight(.heavy)
                        .foregroundStyle(.white.opacity(0.85))
                    Text("\(score)")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.5), radius: 3, y: 2)
                        .accessibilityIdentifier("scoreLabel")
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("SPEED")
                        .font(.caption)
                        .fontWeight(.heavy)
                        .foregroundStyle(.white.opacity(0.85))
                    Text(String(format: "%.0f", speed))
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.5), radius: 3, y: 2)
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 18)

            Spacer()

            if !isGameOver {
                Text("Swipe to dodge — Tap or swipe up to jump")
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.black.opacity(0.35), in: Capsule())
                    .padding(.bottom, 28)
                    .accessibilityIdentifier("hintBanner")
            } else {
                gameOverPanel
                    .padding(.bottom, 60)
            }
        }
    }

    private var gameOverPanel: some View {
        VStack(spacing: 14) {
            Text("CAUGHT!")
                .font(.system(size: 44, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.6), radius: 4, y: 3)
                .accessibilityIdentifier("gameOverLabel")

            Text("Final Score: \(score)")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)

            Button(action: onRestart) {
                Text("Tap to Run Again")
                    .font(.headline)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(.yellow, in: Capsule())
            }
            .accessibilityIdentifier("restartButton")
        }
        .padding(20)
        .background(.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .padding(.horizontal, 32)
    }
}

/// A thin UIView-backed gesture recognizer that recognizes single-direction
/// swipes (so the player can quickly switch lanes / jump) plus simple taps.
private struct GestureCatcher: UIViewRepresentable {
    let onSwipeLeft: () -> Void
    let onSwipeRight: () -> Void
    let onSwipeUp: () -> Void
    let onTap: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onSwipeLeft: onSwipeLeft,
                    onSwipeRight: onSwipeRight,
                    onSwipeUp: onSwipeUp,
                    onTap: onTap)
    }

    func makeUIView(context: Context) -> UIView {
        let v = TouchView()
        v.backgroundColor = .clear
        v.isMultipleTouchEnabled = false

        let pan = UIPanGestureRecognizer(target: context.coordinator,
                                         action: #selector(Coordinator.handlePan(_:)))
        pan.maximumNumberOfTouches = 1
        v.addGestureRecognizer(pan)

        let tap = UITapGestureRecognizer(target: context.coordinator,
                                         action: #selector(Coordinator.handleTap(_:)))
        v.addGestureRecognizer(tap)

        return v
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onSwipeLeft = onSwipeLeft
        context.coordinator.onSwipeRight = onSwipeRight
        context.coordinator.onSwipeUp = onSwipeUp
        context.coordinator.onTap = onTap
    }

    final class TouchView: UIView {}

    final class Coordinator: NSObject {
        var onSwipeLeft: () -> Void
        var onSwipeRight: () -> Void
        var onSwipeUp: () -> Void
        var onTap: () -> Void
        private var didFireForCurrentGesture = false

        init(onSwipeLeft: @escaping () -> Void,
             onSwipeRight: @escaping () -> Void,
             onSwipeUp: @escaping () -> Void,
             onTap: @escaping () -> Void) {
            self.onSwipeLeft = onSwipeLeft
            self.onSwipeRight = onSwipeRight
            self.onSwipeUp = onSwipeUp
            self.onTap = onTap
        }

        @objc func handleTap(_ g: UITapGestureRecognizer) {
            onTap()
        }

        @objc func handlePan(_ g: UIPanGestureRecognizer) {
            switch g.state {
            case .began:
                didFireForCurrentGesture = false
            case .changed:
                guard !didFireForCurrentGesture else { return }
                let t = g.translation(in: g.view)
                let threshold: CGFloat = 28
                if abs(t.x) > threshold && abs(t.x) > abs(t.y) {
                    didFireForCurrentGesture = true
                    if t.x < 0 { onSwipeLeft() } else { onSwipeRight() }
                } else if -t.y > threshold && abs(t.y) > abs(t.x) {
                    didFireForCurrentGesture = true
                    onSwipeUp()
                }
            case .ended, .cancelled, .failed:
                didFireForCurrentGesture = false
            default:
                break
            }
        }
    }
}

#Preview {
    ContentView()
}
