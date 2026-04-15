import SwiftUI
import UIKit

private enum GameStage {
    case setup
    case playing
    case gameOver
}

struct ContentView: View {
    private let intervalOptions: [Double] = [0.5, 1.0, 2.0, 3.0, 5.0]
    private let initialCircleSize: CGFloat = 170
    private let minCircleSize: CGFloat = 72
    private let circleShrinkStep: CGFloat = 10

    @State private var gameStage: GameStage = .setup
    @State private var selectedInterval: Double = 5.0
    @State private var score = 0
    @State private var remainingTime: Double = 1.0

    @State private var circleColor: UIColor = .systemBlue
    @State private var circleSize: CGFloat = 170
    @State private var circleCenter: CGPoint = .zero
    @State private var hasPositionedCircle = false
    @State private var playAreaSize: CGSize = .zero

    @State private var timer: Timer?

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                switch gameStage {
                case .setup:
                    setupView
                case .playing:
                    gameplayView(in: proxy)
                case .gameOver:
                    gameOverView
                }
            }
            .onAppear {
                if !hasPositionedCircle {
                    circleCenter = randomPosition(in: proxy.size, circleDiameter: circleSize)
                    hasPositionedCircle = true
                }
            }
            .onDisappear {
                stopTimer()
            }
        }
    }

    private var setupView: some View {
        VStack(spacing: 28) {
            VStack(spacing: 10) {
                Text("Speedy Circles")
                    .font(.largeTitle.weight(.bold))
                    .multilineTextAlignment(.center)
                Text("Tap the circle before the timer runs out.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                Text("Time Per Circle")
                    .font(.headline)

                Picker("Time Per Circle", selection: $selectedInterval) {
                    ForEach(intervalOptions, id: \.self) { option in
                        Text(String(format: "%.1fs", option)).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("intervalPicker")
            }

            Button(action: startGame) {
                Label("Start", systemImage: "play.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("startButton")

            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(maxWidth: 560)
    }

    private func gameplayView(in proxy: GeometryProxy) -> some View {
        ZStack {
            VStack(spacing: 14) {
                HStack {
                    scorePill
                    Spacer()
                    timerPill
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Spacer()
            }

            Button(action: onCircleTap) {
                Circle()
                    .fill(Color(uiColor: circleColor).gradient)
                    .frame(width: circleSize, height: circleSize)
                    .overlay {
                        Circle()
                            .stroke(.white.opacity(0.65), lineWidth: 2)
                    }
                    .shadow(color: .black.opacity(0.15), radius: 12, y: 8)
            }
            .buttonStyle(.plain)
            .position(circleCenter)
            .accessibilityIdentifier("targetCircle")
            .accessibilityLabel("Target Circle")
        }
        .onAppear {
            playAreaSize = proxy.size
            remainingTime = selectedInterval
            repositionCircle(in: proxy.size)
            startTimer()
        }
        .onChange(of: proxy.size) { _, newSize in
            playAreaSize = newSize
            clampCircleToBounds(in: newSize)
        }
    }

    private var gameOverView: some View {
        VStack(spacing: 18) {
            Image(systemName: "flag.checkered.circle.fill")
                .font(.system(size: 58))
                .foregroundStyle(.orange)

            Text("Time's Up!")
                .font(.largeTitle.weight(.bold))

            Text("Final Score: \(score)")
                .font(.title3.weight(.semibold))
                .accessibilityIdentifier("finalScoreLabel")

            Button(action: resetToSetup) {
                Label("Retry", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("retryButton")
            .padding(.top, 6)

            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(maxWidth: 560)
    }

    private var scorePill: some View {
        Label("Score: \(score)", systemImage: "star.fill")
            .font(.headline)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(.ultraThinMaterial, in: Capsule())
            .accessibilityIdentifier("scoreLabel")
    }

    private var timerPill: some View {
        Label(String(format: "%.1fs", max(remainingTime, 0)), systemImage: "timer")
            .font(.headline.monospacedDigit())
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(.ultraThinMaterial, in: Capsule())
            .accessibilityIdentifier("timerLabel")
    }

    private func startGame() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.88)) {
            score = 0
            circleSize = initialCircleSize
            remainingTime = selectedInterval
            circleColor = randomColor(excluding: nil)
            gameStage = .playing
        }
    }

    private func onCircleTap() {
        score += 1

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            circleSize = max(minCircleSize, circleSize - circleShrinkStep)
            circleColor = randomColor(excluding: circleColor)
        }

        remainingTime = selectedInterval

        if playAreaSize != .zero {
            withAnimation(.easeInOut(duration: 0.25)) {
                repositionCircle(in: playAreaSize)
            }
        }
    }

    private func endGame() {
        stopTimer()

        withAnimation(.easeInOut(duration: 0.3)) {
            gameStage = .gameOver
        }
    }

    private func resetToSetup() {
        stopTimer()
        withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) {
            gameStage = .setup
            score = 0
            circleSize = initialCircleSize
            remainingTime = selectedInterval
            circleColor = .systemBlue
        }
    }

    private func startTimer() {
        stopTimer()

        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            remainingTime -= 0.05
            if remainingTime <= 0 {
                endGame()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func repositionCircle(in size: CGSize) {
        circleCenter = randomPosition(in: size, circleDiameter: circleSize)
    }

    private func clampCircleToBounds(in size: CGSize) {
        let margin = circleSize / 2
        let clampedX = min(max(margin, circleCenter.x), max(margin, size.width - margin))
        let clampedY = min(max(margin, circleCenter.y), max(margin, size.height - margin))
        circleCenter = CGPoint(x: clampedX, y: clampedY)
    }

    private func randomPosition(in size: CGSize, circleDiameter: CGFloat) -> CGPoint {
        let horizontalMargin = circleDiameter / 2
        let verticalMargin = circleDiameter / 2

        let safeWidth = max(size.width, circleDiameter + 1)
        let safeHeight = max(size.height, circleDiameter + 1)

        let minX = horizontalMargin
        let maxX = max(horizontalMargin, safeWidth - horizontalMargin)
        let minY = verticalMargin + 56
        let maxY = max(minY, safeHeight - verticalMargin - 20)

        return CGPoint(
            x: CGFloat.random(in: minX ... maxX),
            y: CGFloat.random(in: minY ... maxY)
        )
    }

    private func randomColor(excluding current: UIColor?) -> UIColor {
        let palette: [UIColor] = [
            .systemPink,
            .systemBlue,
            .systemGreen,
            .systemOrange,
            .systemPurple,
            .systemRed,
            .systemMint,
            .systemIndigo
        ]

        guard let current else { return palette.randomElement() ?? .systemBlue }

        let filtered = palette.filter { $0 != current }
        return filtered.randomElement() ?? .systemBlue
    }
}

#Preview {
    ContentView()
}
