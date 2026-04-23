import MetalKit
import SwiftUI

struct MetalDrivingGameView: UIViewRepresentable {
    @ObservedObject var input: GameInput
    @Binding var speedKph: Int
    @Binding var score: Int
    @Binding var isCrashed: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(input: input, speedKph: $speedKph, score: $score, isCrashed: $isCrashed)
    }

    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView(frame: .zero)
        mtkView.preferredFramesPerSecond = 60
        mtkView.enableSetNeedsDisplay = false
        mtkView.isPaused = false
        mtkView.clearColor = MTLClearColor(red: 0.03, green: 0.06, blue: 0.12, alpha: 1.0)

        context.coordinator.configure(view: mtkView)
        return mtkView
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.updateInput(input)
    }

    final class Coordinator {
        private var renderer: DrivingGameRenderer?
        private var input: GameInput
        private let speedKph: Binding<Int>
        private let score: Binding<Int>
        private let isCrashed: Binding<Bool>

        init(input: GameInput, speedKph: Binding<Int>, score: Binding<Int>, isCrashed: Binding<Bool>) {
            self.input = input
            self.speedKph = speedKph
            self.score = score
            self.isCrashed = isCrashed
        }

        func configure(view: MTKView) {
            renderer = DrivingGameRenderer(mtkView: view, input: input) { [weak self] speed, score, crashed in
                guard let self else { return }
                self.speedKph.wrappedValue = speed
                self.score.wrappedValue = score
                self.isCrashed.wrappedValue = crashed
            }
        }

        func updateInput(_ input: GameInput) {
            self.input = input
            renderer?.input = input
        }
    }
}
