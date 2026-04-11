import MetalKit
import SwiftUI

final class CarGameController: ObservableObject {
    @Published private(set) var score = 0
    @Published private(set) var bestScore = 0
    @Published private(set) var isGameOver = false

    var moveHandler: (Int) -> Void = { _ in }
    var restartHandler: () -> Void = {}

    func moveLeft() {
        moveHandler(-1)
    }

    func moveRight() {
        moveHandler(1)
    }

    func restart() {
        restartHandler()
    }

    func apply(snapshot: CarGameSnapshot) {
        score = snapshot.score
        bestScore = snapshot.bestScore
        isGameOver = snapshot.isGameOver
    }
}

struct CarGameView: View {
    @StateObject private var controller = CarGameController()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.07, blue: 0.14),
                    Color(red: 0.09, green: 0.12, blue: 0.22)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                header

                ZStack {
                    MetalCarGameView(controller: controller)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                        }

                    if controller.isGameOver {
                        gameOverOverlay
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .shadow(color: .black.opacity(0.25), radius: 24, y: 10)

                controls
            }
            .padding(20)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Lane Racer")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                        .accessibilityIdentifier("titleLabel")

                    Text(controller.isGameOver ? "Crash detected. Tap restart to run again." : "Tap left or right to dodge traffic.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                        .accessibilityIdentifier("statusLabel")
                }

                Spacer(minLength: 16)

                VStack(alignment: .trailing, spacing: 4) {
                    scoreBadge(title: "Distance", value: "\(controller.score)m", identifier: "scoreLabel")
                    scoreBadge(title: "Best", value: "\(controller.bestScore)m", identifier: "bestScoreLabel")
                }
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 14) {
            controlButton(title: "Left", systemImage: "arrow.left", identifier: "moveLeftButton") {
                controller.moveLeft()
            }

            controlButton(title: "Right", systemImage: "arrow.right", identifier: "moveRightButton") {
                controller.moveRight()
            }
        }
    }

    private var gameOverOverlay: some View {
        VStack(spacing: 14) {
            Text("Run Over")
                .font(.title.bold())
                .foregroundStyle(.white)
                .accessibilityIdentifier("gameOverLabel")

            Text("You made it \(controller.score)m through traffic.")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.82))

            Button(action: controller.restart) {
                Label("Restart", systemImage: "arrow.clockwise")
                    .font(.headline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(CarControlButtonStyle(fill: Color(red: 0.96, green: 0.46, blue: 0.18)))
            .accessibilityIdentifier("restartButton")
        }
        .padding(24)
        .frame(maxWidth: 320)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding()
    }

    private func scoreBadge(title: String, value: String, identifier: String) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.6))

            Text(value)
                .font(.headline.monospacedDigit().weight(.bold))
                .foregroundStyle(.white)
                .accessibilityIdentifier(identifier)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func controlButton(title: String, systemImage: String, identifier: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.headline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .buttonStyle(CarControlButtonStyle(fill: Color.white.opacity(0.12)))
        .accessibilityIdentifier(identifier)
    }
}

private struct MetalCarGameView: UIViewRepresentable {
    @ObservedObject var controller: CarGameController

    func makeCoordinator() -> Coordinator {
        Coordinator(controller: controller)
    }

    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView(frame: .zero, device: MTLCreateSystemDefaultDevice())
        mtkView.clearColor = MTLClearColor(red: 0.07, green: 0.08, blue: 0.13, alpha: 1)
        mtkView.preferredFramesPerSecond = 60
        mtkView.isPaused = false
        mtkView.enableSetNeedsDisplay = false
        mtkView.framebufferOnly = true
        mtkView.autoResizeDrawable = true

        context.coordinator.attach(to: mtkView)
        return mtkView
    }

    func updateUIView(_ uiView: MTKView, context: Context) {}

    final class Coordinator {
        let renderer: CarGameRenderer
        private let controller: CarGameController

        init(controller: CarGameController) {
            self.controller = controller
            self.renderer = CarGameRenderer()

            renderer.onStateChange = { [weak controller] snapshot in
                DispatchQueue.main.async {
                    controller?.apply(snapshot: snapshot)
                }
            }

            controller.moveHandler = { [weak renderer] step in
                renderer?.movePlayer(by: step)
            }

            controller.restartHandler = { [weak renderer] in
                renderer?.restartGame()
            }
        }

        func attach(to view: MTKView) {
            renderer.configure(view: view)
            view.delegate = renderer
        }
    }
}

private struct CarControlButtonStyle: ButtonStyle {
    let fill: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(fill.opacity(configuration.isPressed ? 0.7 : 1))
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
