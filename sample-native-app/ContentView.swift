import SwiftUI
import Combine

struct ContentView: View {
    private let intervalOptions: [Double] = [0.5, 1.0, 2.0, 3.0, 5.0]
    private let minimumCircleSize: CGFloat = 64
    private let initialCircleSize: CGFloat = 170
    private let shrinkFactor: CGFloat = 0.9

    @State private var selectedInterval: Double = 5.0
    @State private var gameState: GameState = .start
    @State private var score = 0

    @State private var circleSize: CGFloat = 170
    @State private var circlePosition: CGPoint = .zero
    @State private var circleColor: Color = .blue

    @State private var remainingTime: Double = 1.0
    @State private var deadline: Date?
    @State private var containerSize: CGSize = .zero

    private let clock = Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    colors: [Color(.systemIndigo).opacity(0.12), Color(.systemBackground)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                switch gameState {
                case .start:
                    startView
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                case .playing:
                    playingView(in: geo.size)
                        .transition(.opacity)
                case .gameOver:
                    gameOverView
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: gameState)
            .onReceive(clock) { _ in
                guard gameState == .playing, let deadline else { return }
                let remaining = deadline.timeIntervalSinceNow
                remainingTime = max(remaining, 0)

                if remaining <= 0 {
                    gameState = .gameOver
                    self.deadline = nil
                }
            }
            .onAppear {
                containerSize = geo.size
                configureNewCircle(in: geo.size, shouldShrink: false)
            }
            .onChange(of: geo.size) { _, newSize in
                containerSize = newSize
            }
        }
    }

    private var startView: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 10) {
                Text("Speedy Circles")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                Text("Tap the circle before time runs out.")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 16) {
                Text("Time per round")
                    .font(.headline)

                Picker("Interval", selection: $selectedInterval) {
                    ForEach(intervalOptions, id: \.self) { interval in
                        Text(String(format: "%.1f s", interval)).tag(interval)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("intervalPicker")
            }
            .padding(20)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(.horizontal)

            Button {
                startGame()
            } label: {
                Text("Start")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .tint(.accentColor)
            .padding(.horizontal)
            .accessibilityIdentifier("startButton")

            Spacer()
        }
        .padding(.vertical)
    }

    private func playingView(in size: CGSize) -> some View {
        ZStack {
            VStack {
                HStack {
                    statCard(title: "Score", value: "\(score)")
                    statCard(title: "Time", value: String(format: "%.2f s", remainingTime))
                }
                .padding(.horizontal)
                .padding(.top, 10)

                Spacer()
            }

            Circle()
                .fill(circleColor.gradient)
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.4), lineWidth: 3)
                }
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
                .frame(width: circleSize, height: circleSize)
                .position(circlePosition)
                .contentShape(Circle())
                .onTapGesture {
                    handleCircleTap(in: size)
                }
                .accessibilityIdentifier("gameCircle")
                .animation(.spring(response: 0.32, dampingFraction: 0.82), value: circlePosition)
                .animation(.spring(response: 0.3, dampingFraction: 0.75), value: circleSize)
                .animation(.easeInOut(duration: 0.25), value: circleColor)
        }
    }

    private var gameOverView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "timer")
                .font(.system(size: 52))
                .foregroundStyle(.orange)

            Text("Time's up!")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))

            Text("Final Score: \(score)")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("finalScoreLabel")

            Button {
                retry()
            } label: {
                Text("Retry")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
            .accessibilityIdentifier("retryButton")

            Spacer()
        }
    }

    private func statCard(title: String, value: String) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.monospacedDigit().weight(.bold))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func startGame() {
        score = 0
        circleSize = initialCircleSize
        remainingTime = selectedInterval
        deadline = Date().addingTimeInterval(selectedInterval)
        configureNewCircle(in: containerSize, shouldShrink: false)
        gameState = .playing
    }

    private func retry() {
        gameState = .start
        score = 0
        circleSize = initialCircleSize
        remainingTime = selectedInterval
    }

    private func handleCircleTap(in size: CGSize) {
        guard gameState == .playing else { return }
        score += 1
        configureNewCircle(in: size, shouldShrink: true)
        deadline = Date().addingTimeInterval(selectedInterval)
        remainingTime = selectedInterval
    }

    private func configureNewCircle(in size: CGSize, shouldShrink: Bool) {
        if shouldShrink {
            circleSize = max(minimumCircleSize, circleSize * shrinkFactor)
        }

        circleColor = Color(
            hue: .random(in: 0...1),
            saturation: .random(in: 0.65...0.95),
            brightness: .random(in: 0.85...1.0)
        )

        let radius = circleSize / 2
        let horizontalPadding: CGFloat = 16
        let topPadding: CGFloat = 80
        let bottomPadding: CGFloat = 40

        let minX = max(radius + horizontalPadding, 0)
        let maxX = max(minX, size.width - radius - horizontalPadding)

        let minY = max(radius + topPadding, 0)
        let maxY = max(minY, size.height - radius - bottomPadding)

        circlePosition = CGPoint(
            x: CGFloat.random(in: minX...maxX),
            y: CGFloat.random(in: minY...maxY)
        )
    }
}

private enum GameState {
    case start
    case playing
    case gameOver
}

#Preview {
    ContentView()
}
