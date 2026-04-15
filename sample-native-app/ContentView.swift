import SwiftUI

struct ContentView: View {
    private enum GamePhase {
        case start
        case playing
        case gameOver
    }

    private let intervalOptions: [Double] = [0.5, 1.0, 2.0, 3.0, 5.0]
    private let palette: [Color] = [
        .pink, .purple, .blue, .cyan, .mint, .green, .orange, .red, .indigo
    ]
    private let minimumCircleSize: CGFloat = 72
    private let initialCircleSize: CGFloat = 168

    @State private var phase: GamePhase = .start
    @State private var selectedInterval: Double = 1.0

    @State private var score = 0
    @State private var remainingTime: Double = 1.0

    @State private var circleSize: CGFloat = 168
    @State private var circlePosition: CGPoint = .zero
    @State private var circleColor: Color = .blue

    @State private var timer: Timer?
    @State private var lastTickDate = Date()

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                background

                switch phase {
                case .start:
                    startScreen
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                case .playing:
                    gameScreen(in: proxy.size)
                        .transition(.opacity)
                case .gameOver:
                    gameOverScreen
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }
            }
            .padding(20)
        }
        .onDisappear {
            stopTimer()
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var startScreen: some View {
        VStack(spacing: 22) {
            Spacer()

            VStack(spacing: 10) {
                Text("Speedy Circles")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))

                Text("Tap each circle before time runs out.")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            intervalPicker

            Button(action: startGame) {
                Label("Start", systemImage: "play.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .accessibilityIdentifier("startButton")

            Spacer()
        }
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var intervalPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Time per circle")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 10)], spacing: 10) {
                ForEach(intervalOptions, id: \.self) { option in
                    let isSelected = selectedInterval == option
                    Button {
                        withAnimation(.smooth(duration: 0.2)) {
                            selectedInterval = option
                        }
                    } label: {
                        Text(String(format: "%.1fs", option))
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(isSelected ? Color.accentColor.opacity(0.22) : Color(.tertiarySystemFill))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func gameScreen(in size: CGSize) -> some View {
        ZStack {
            VStack(spacing: 12) {
                hud
                Spacer()
            }

            Button {
                circleTapped(in: size)
            } label: {
                Circle()
                    .fill(circleColor.gradient)
                    .overlay {
                        Circle()
                            .stroke(.white.opacity(0.55), lineWidth: 2)
                    }
            }
            .buttonStyle(.plain)
            .frame(width: circleSize, height: circleSize)
            .position(circlePosition)
            .shadow(color: circleColor.opacity(0.25), radius: 16, x: 0, y: 8)
            .contentShape(Circle())
            .accessibilityIdentifier("gameCircle")
            .accessibilityLabel("Game Circle")
            .animation(.spring(response: 0.36, dampingFraction: 0.82), value: circlePosition)
            .animation(.spring(response: 0.28, dampingFraction: 0.76), value: circleSize)
            .animation(.easeInOut(duration: 0.22), value: circleColor)
            .onAppear {
                if circlePosition == .zero {
                    circlePosition = randomCirclePosition(in: size, diameter: circleSize)
                }
            }
        }
    }

    private var hud: some View {
        HStack(spacing: 14) {
            metricCard(title: "Score", value: "\(score)", icon: "star.fill")
                .accessibilityIdentifier("scoreLabel")

            metricCard(
                title: "Time",
                value: String(format: "%.2fs", max(remainingTime, 0)),
                icon: "timer"
            )
            .accessibilityIdentifier("remainingTimeLabel")
        }
    }

    private func metricCard(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.headline.monospacedDigit())
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var gameOverScreen: some View {
        VStack(spacing: 18) {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.red)

                Text("Time's up")
                    .font(.system(.title, design: .rounded, weight: .bold))

                Text("Final score: \(score)")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Button(action: resetToStart) {
                Label("Retry", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .accessibilityIdentifier("retryButton")

            Spacer()
        }
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func startGame() {
        stopTimer()
        score = 0
        circleSize = initialCircleSize
        remainingTime = selectedInterval
        circleColor = randomColor(excluding: nil)

        withAnimation(.smooth(duration: 0.32)) {
            phase = .playing
        }

        startTimer()
    }

    private func circleTapped(in size: CGSize) {
        guard phase == .playing else { return }

        score += 1
        remainingTime = selectedInterval

        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            circleSize = max(minimumCircleSize, circleSize * 0.9)
            circleColor = randomColor(excluding: circleColor)
            circlePosition = randomCirclePosition(in: size, diameter: circleSize)
        }
    }

    private func startTimer() {
        stopTimer()
        lastTickDate = Date()

        timer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in
            DispatchQueue.main.async {
                guard phase == .playing else { return }
                let now = Date()
                let delta = now.timeIntervalSince(lastTickDate)
                lastTickDate = now

                remainingTime -= delta
                if remainingTime <= 0 {
                    remainingTime = 0
                    endGame()
                }
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func endGame() {
        stopTimer()
        withAnimation(.smooth(duration: 0.28)) {
            phase = .gameOver
        }
    }

    private func resetToStart() {
        stopTimer()
        withAnimation(.smooth(duration: 0.28)) {
            phase = .start
        }
    }

    private func randomColor(excluding current: Color?) -> Color {
        let available = palette.filter { color in
            guard let current else { return true }
            return color != current
        }
        return available.randomElement() ?? .blue
    }

    private func randomCirclePosition(in size: CGSize, diameter: CGFloat) -> CGPoint {
        let topInset: CGFloat = 120
        let sidePadding: CGFloat = 12
        let bottomInset: CGFloat = 24

        let radius = diameter / 2
        let minX = radius + sidePadding
        let maxX = max(minX, size.width - radius - sidePadding)

        let minY = radius + topInset
        let maxY = max(minY, size.height - radius - bottomInset)

        return CGPoint(
            x: CGFloat.random(in: minX...maxX),
            y: CGFloat.random(in: minY...maxY)
        )
    }
}

#Preview {
    ContentView()
}
