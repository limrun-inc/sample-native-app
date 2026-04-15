import SwiftUI

struct ContentView: View {
    private let intervals: [Double] = [0.5, 1.0, 2.0, 3.0, 5.0]
    private let minimumCircleSize: CGFloat = 64
    private let startingCircleSize: CGFloat = 150

    @State private var selectedInterval: Double = 1.0
    @State private var screen: ScreenState = .start

    @State private var score: Int = 0
    @State private var remainingTime: Double = 1.0
    @State private var circleSize: CGFloat = 150
    @State private var circleColor: Color = .blue
    @State private var circlePosition: CGPoint = .zero
    @State private var roundDeadline: Date?
    @State private var hasPlacedCircle = false

    @State private var tickTask: Task<Void, Never>?

    enum ScreenState {
        case start
        case playing
        case gameOver
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.09, green: 0.10, blue: 0.2), Color(red: 0.13, green: 0.31, blue: 0.42)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                switch screen {
                case .start:
                    startView
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                case .playing:
                    gameplayView(proxy: proxy)
                        .transition(.opacity)
                        .onAppear {
                            if !hasPlacedCircle {
                                resetRound(in: proxy.size)
                                hasPlacedCircle = true
                            }
                        }
                case .gameOver:
                    gameOverView
                        .transition(.opacity.combined(with: .scale))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: screen)
            .onDisappear {
                stopTicker()
            }
        }
    }

    private var startView: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 12) {
                Text("Speedy Circles")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Tap the circle before the timer expires.")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 14) {
                Text("Select Interval")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)

                HStack(spacing: 10) {
                    ForEach(intervals, id: \.self) { interval in
                        Button {
                            selectedInterval = interval
                        } label: {
                            Text(String(format: "%.1fs", interval))
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .foregroundStyle(selectedInterval == interval ? .black : .white)
                                .background(selectedInterval == interval ? Color.white : Color.white.opacity(0.15))
                                .clipShape(Capsule())
                        }
                        .accessibilityIdentifier("interval_\(interval)")
                    }
                }
            }
            .padding(20)
            .background(.thinMaterial.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .padding(.horizontal)

            Button {
                startGame()
            } label: {
                Text("Start")
                    .font(.title3.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .tint(.mint)
            .padding(.horizontal)
            .accessibilityIdentifier("startButton")

            Spacer()
        }
        .padding()
    }

    private func gameplayView(proxy: GeometryProxy) -> some View {
        ZStack {
            VStack(spacing: 12) {
                HStack {
                    statusPill(title: "Score", value: "\(score)", valueIdentifier: "scoreValue")
                    Spacer()
                    statusPill(title: "Time", value: String(format: "%.2fs", max(remainingTime, 0)), valueIdentifier: "timeLabel")
                }
                .padding(.horizontal)
                .padding(.top, 6)

                Spacer()
            }

            Button {
                handleSuccessfulTap(in: proxy.size)
            } label: {
                Circle()
                    .fill(circleColor.gradient)
                    .frame(width: circleSize, height: circleSize)
                    .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 8)
            }
            .buttonStyle(.plain)
            .position(circlePosition)
            .accessibilityIdentifier("targetCircle")
            .animation(.spring(response: 0.35, dampingFraction: 0.78), value: circleSize)
            .animation(.easeInOut(duration: 0.25), value: circleColor)
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: circlePosition)
        }
        .onChange(of: proxy.size) {
            if screen == .playing {
                clampCirclePosition(in: proxy.size)
            }
        }
    }

    private var gameOverView: some View {
        VStack(spacing: 18) {
            Spacer()

            VStack(spacing: 8) {
                Text("Time's up!")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Final Score: \(score)")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))
                    .accessibilityIdentifier("finalScore")
            }
            .padding(28)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .padding(.horizontal)

            Button {
                resetToStart()
            } label: {
                Text("Retry")
                    .font(.title3.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .padding(.horizontal)
            .accessibilityIdentifier("retryButton")

            Spacer()
        }
        .padding()
    }

    private func statusPill(title: String, value: String, valueIdentifier: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.72))
            Text(value)
                .font(.title3.monospacedDigit().weight(.bold))
                .foregroundStyle(.white)
                .accessibilityIdentifier(valueIdentifier ?? "")
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(.ultraThinMaterial.opacity(0.45))
        .clipShape(Capsule())
    }

    private func startGame() {
        score = 0
        circleSize = startingCircleSize
        remainingTime = selectedInterval
        hasPlacedCircle = false
        screen = .playing
        startTicker()
    }

    private func resetRound(in size: CGSize) {
        roundDeadline = Date().addingTimeInterval(selectedInterval)
        remainingTime = selectedInterval
        moveCircle(toRandomPointIn: size)
    }

    private func handleSuccessfulTap(in size: CGSize) {
        guard screen == .playing else { return }

        score += 1
        circleSize = max(minimumCircleSize, circleSize * 0.9)
        circleColor = randomPlayableColor()
        resetRound(in: size)
    }

    private func startTicker() {
        stopTicker()
        tickTask = Task {
            while !Task.isCancelled {
                await MainActor.run {
                    guard screen == .playing, let deadline = roundDeadline else { return }
                    let time = max(0, deadline.timeIntervalSinceNow)
                    remainingTime = time
                    if time <= 0 {
                        endGame()
                    }
                }
                try? await Task.sleep(for: .milliseconds(16))
            }
        }
    }

    private func stopTicker() {
        tickTask?.cancel()
        tickTask = nil
    }

    private func endGame() {
        stopTicker()
        screen = .gameOver
    }

    private func resetToStart() {
        stopTicker()
        screen = .start
    }

    private func clampCirclePosition(in size: CGSize) {
        guard circlePosition != .zero else { return }
        let clampedX = min(max(circlePosition.x, circleSize / 2), size.width - circleSize / 2)
        let topPadding: CGFloat = 120
        let clampedY = min(max(circlePosition.y, topPadding + circleSize / 2), size.height - circleSize / 2)
        circlePosition = CGPoint(x: clampedX, y: clampedY)
    }

    private func moveCircle(toRandomPointIn size: CGSize) {
        let radius = circleSize / 2
        let topPadding: CGFloat = 120

        let xRange = radius...(size.width - radius)
        let yMin = topPadding + radius
        let yMax = max(yMin, size.height - radius)
        let yRange = yMin...yMax

        let x = CGFloat.random(in: xRange)
        let y = CGFloat.random(in: yRange)
        circlePosition = CGPoint(x: x, y: y)
    }

    private func randomPlayableColor() -> Color {
        let palette: [Color] = [.pink, .yellow, .mint, .orange, .cyan, .purple, .indigo, .green]
        return palette.randomElement() ?? .blue
    }
}

#Preview {
    ContentView()
}
