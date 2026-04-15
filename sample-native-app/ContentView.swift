import SwiftUI

private enum GamePhase {
    case start
    case playing
    case gameOver
}

struct ContentView: View {
    private let intervalOptions: [Double] = [0.5, 1.0, 2.0, 3.0, 5.0]
    private let minCircleDiameter: CGFloat = 64
    private let initialCircleDiameter: CGFloat = 170
    private let shrinkFactor: CGFloat = 0.9

    @State private var phase: GamePhase = .start
    @State private var selectedInterval: Double = 5.0
    @State private var score: Int = 0
    @State private var remainingTime: Double = 1.0

    @State private var circleDiameter: CGFloat = 170
    @State private var circleCenter: CGPoint = .zero
    @State private var circleColor: Color = .blue

    @State private var timer: Timer?
    @State private var lastTickDate: Date = .now

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.systemGray6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                switch phase {
                case .start:
                    startScreen
                        .transition(.opacity.combined(with: .scale))
                case .playing:
                    gameplayScreen(in: geo)
                        .transition(.opacity)
                case .gameOver:
                    gameOverScreen
                        .transition(.opacity.combined(with: .scale))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: phase)
            .onDisappear {
                stopTimer()
            }
        }
    }

    private var startScreen: some View {
        VStack(spacing: 24) {
            Text("Speedy Circles")
                .font(.largeTitle.weight(.bold))

            Text("Choose your countdown interval")
                .font(.headline)
                .foregroundStyle(.secondary)

            Picker("Time Interval", selection: $selectedInterval) {
                ForEach(intervalOptions, id: \.self) { option in
                    Text(String(format: "%.1fs", option)).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("intervalPicker")

            Button {
                startGame()
            } label: {
                Label("Start", systemImage: "play.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("startButton")

            Text("Tap the circle before time runs out.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(maxWidth: 520)
    }

    private func gameplayScreen(in geo: GeometryProxy) -> some View {
        ZStack(alignment: .top) {
            Button {
                handleSuccessfulTap(in: geo)
            } label: {
                Circle()
                    .fill(circleColor.gradient)
                    .frame(width: circleDiameter, height: circleDiameter)
                    .shadow(color: circleColor.opacity(0.35), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(.plain)
            .position(circleCenter)
            .accessibilityLabel("Target Circle")
            .accessibilityIdentifier("targetCircle")
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: circleDiameter)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: circleCenter)
            .animation(.easeInOut(duration: 0.2), value: circleColor)

            HStack {
                labelCard(title: "Score", value: "\(score)")
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Score \(score)")
                    .accessibilityIdentifier("scoreLabel")
                Spacer()
                labelCard(title: "Time", value: String(format: "%.2f", max(0, remainingTime)))
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Time \(String(format: "%.2f", max(0, remainingTime)))")
                    .accessibilityIdentifier("timeLabel")
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
        .onAppear {
            if circleCenter == .zero {
                repositionCircle(in: geo)
            }
        }
    }

    private var gameOverScreen: some View {
        VStack(spacing: 20) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 58))
                .foregroundStyle(.red)

            Text("Time's Up!")
                .font(.largeTitle.weight(.bold))

            Text("Final Score: \(score)")
                .font(.title2.weight(.semibold))
                .accessibilityIdentifier("finalScoreLabel")

            Button {
                resetToStart()
            } label: {
                Text("Retry")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("retryButton")
        }
        .padding(24)
        .frame(maxWidth: 420)
    }

    private func labelCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.bold))
                .monospacedDigit()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func startGame() {
        stopTimer()
        score = 0
        circleDiameter = initialCircleDiameter
        circleColor = randomColor()
        remainingTime = selectedInterval
        phase = .playing
        lastTickDate = .now
        startTimer()
    }

    private func handleSuccessfulTap(in geo: GeometryProxy) {
        guard phase == .playing else { return }

        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
            score += 1
            circleDiameter = max(minCircleDiameter, circleDiameter * shrinkFactor)
            circleColor = randomColor()
            remainingTime = selectedInterval
            repositionCircle(in: geo)
        }
        lastTickDate = .now
    }

    private func repositionCircle(in geo: GeometryProxy) {
        let radius = circleDiameter / 2
        let horizontalPadding: CGFloat = 18
        let topReservedArea: CGFloat = 110
        let bottomPadding: CGFloat = 18

        let minX = radius + horizontalPadding
        let maxX = max(minX, geo.size.width - radius - horizontalPadding)

        let minY = radius + topReservedArea
        let maxY = max(minY, geo.size.height - radius - bottomPadding)

        circleCenter = CGPoint(
            x: CGFloat.random(in: minX ... maxX),
            y: CGFloat.random(in: minY ... maxY)
        )
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in
            let now = Date()
            let delta = now.timeIntervalSince(lastTickDate)
            lastTickDate = now

            remainingTime -= delta
            if remainingTime <= 0 {
                endGame()
            }
        }
        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func endGame() {
        stopTimer()
        withAnimation {
            phase = .gameOver
        }
    }

    private func resetToStart() {
        stopTimer()
        remainingTime = selectedInterval
        circleCenter = .zero
        circleDiameter = initialCircleDiameter
        withAnimation {
            phase = .start
        }
    }

    private func randomColor() -> Color {
        Color(
            red: Double.random(in: 0.15 ... 0.95),
            green: Double.random(in: 0.15 ... 0.95),
            blue: Double.random(in: 0.15 ... 0.95)
        )
    }
}

#Preview {
    ContentView()
}
