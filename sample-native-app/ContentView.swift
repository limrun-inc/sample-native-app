import SwiftUI
import Combine

struct ContentView: View {
    private enum GameState {
        case setup
        case playing
        case gameOver
    }

    private let intervals: [Double] = [0.5, 1.0, 2.0, 3.0, 5.0]
    private let minimumCircleDiameter: CGFloat = 64
    private let initialCircleDiameter: CGFloat = 150
    private let circleShrinkFactor: CGFloat = 0.92
    private let circleColors: [Color] = [.red, .orange, .yellow, .green, .mint, .blue, .purple, .pink, .indigo]
    private let tickRate: Double = 0.02

    @State private var selectedInterval: Double = 5.0
    @State private var gameState: GameState = .setup
    @State private var score = 0
    @State private var remainingTime = 5.0

    @State private var circleDiameter: CGFloat = 150
    @State private var circlePosition: CGPoint = .zero
    @State private var circleColor: Color = .blue
    @State private var playAreaSize: CGSize = .zero

    @State private var isTimerRunning = false

    private var gameTimer: Publishers.Autoconnect<Timer.TimerPublisher> {
        Timer.publish(every: tickRate, on: .main, in: .common).autoconnect()
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                switch gameState {
                case .setup:
                    setupView
                case .playing:
                    playingView
                case .gameOver:
                    gameOverView
                }
            }
            .onAppear {
                playAreaSize = geometry.size
            }
            .onChange(of: geometry.size) { _, newSize in
                playAreaSize = newSize
                if gameState == .playing {
                    moveCircle(animate: false)
                }
            }
        }
        .onReceive(gameTimer) { _ in
            guard gameState == .playing, isTimerRunning else { return }

            remainingTime = max(0, remainingTime - tickRate)
            if remainingTime <= 0 {
                finishGame()
            }
        }
    }

    private var setupView: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 10) {
                Text("Speedy Circles")
                    .font(.largeTitle.bold())

                Text("Tap each circle before time runs out.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 12) {
                Text("Time per round")
                    .font(.headline)

                Picker("Time per round", selection: $selectedInterval) {
                    ForEach(intervals, id: \.self) { interval in
                        Text(String(format: "%.1fs", interval)).tag(interval)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("intervalPicker")
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

            Button(action: startGame) {
                Text("Start")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .accessibilityIdentifier("startButton")

            Spacer()
        }
        .padding(24)
        .animation(.easeInOut(duration: 0.25), value: selectedInterval)
    }

    private var playingView: some View {
        ZStack {
            VStack(spacing: 8) {
                HStack {
                    scoreTile(title: "Score", value: "\(score)")
                    scoreTile(title: "Time", value: String(format: "%.2fs", remainingTime))
                }

                Spacer()
            }
            .padding(20)

            Button(action: handleCircleTap) {
                Circle()
                    .fill(circleColor.gradient)
                    .overlay {
                        Circle()
                            .stroke(.white.opacity(0.35), lineWidth: 2)
                    }
                    .frame(width: circleDiameter, height: circleDiameter)
                    .shadow(color: circleColor.opacity(0.45), radius: 24, x: 0, y: 12)
            }
            .buttonStyle(.plain)
            .position(circlePosition)
            .accessibilityIdentifier("gameCircle")
            .accessibilityLabel("Speedy Circle Target")
        }
        .padding(.bottom, 8)
    }

    private var gameOverView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "flag.checkered")
                .font(.system(size: 48, weight: .semibold))
                 .foregroundStyle(Color.accentColor)

            Text("Time's Up")
                .font(.largeTitle.bold())

            Text("Final Score: \(score)")
                .font(.title3.weight(.semibold))
                .accessibilityIdentifier("finalScoreLabel")

            Button(action: resetToSetup) {
                Text("Retry")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .accessibilityIdentifier("retryButton")

            Spacer()
        }
        .padding(24)
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }

    private func scoreTile(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.monospacedDigit().bold())
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func startGame() {
        score = 0
        remainingTime = selectedInterval
        circleDiameter = initialCircleDiameter
        circleColor = randomColor()

        withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
            gameState = .playing
            moveCircle(animate: false)
        }

        isTimerRunning = true
    }

    private func handleCircleTap() {
        guard gameState == .playing else { return }

        score += 1
        remainingTime = selectedInterval

        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            circleDiameter = max(minimumCircleDiameter, circleDiameter * circleShrinkFactor)
            circleColor = randomColor()
            moveCircle(animate: false)
        }
    }

    private func finishGame() {
        isTimerRunning = false

        withAnimation(.easeInOut(duration: 0.35)) {
            gameState = .gameOver
        }
    }

    private func resetToSetup() {
        withAnimation(.easeInOut(duration: 0.3)) {
            gameState = .setup
        }
    }

    private func moveCircle(animate: Bool) {
        let updatePosition = {
            let safePadding: CGFloat = 18
            let radius = circleDiameter / 2
            let minX = radius + safePadding
            let maxX = max(minX, playAreaSize.width - radius - safePadding)
            let minY = radius + safePadding + 68 // Reserve top score area.
            let maxY = max(minY, playAreaSize.height - radius - safePadding)

            circlePosition = CGPoint(
                x: CGFloat.random(in: minX...maxX),
                y: CGFloat.random(in: minY...maxY)
            )
        }

        if animate {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                updatePosition()
            }
        } else {
            updatePosition()
        }
    }

    private func randomColor() -> Color {
        circleColors.randomElement() ?? .blue
    }
}

#Preview {
    ContentView()
}
