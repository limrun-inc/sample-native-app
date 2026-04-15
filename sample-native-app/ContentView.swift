import SwiftUI
import Combine

struct ContentView: View {
    private let intervals: [Double] = [0.5, 1.0, 2.0, 3.0, 5.0]
    private let initialCircleSize: CGFloat = 140
    private let minimumCircleSize: CGFloat = 72
    private let timerTick: TimeInterval = 0.02

    @State private var phase: GamePhase = .start
    @State private var selectedInterval: Double = 2.0
    @State private var score: Int = 0
    @State private var remainingTime: Double = 1.0

    @State private var circleColor: Color = .pink
    @State private var circleSize: CGFloat = 140
    @State private var circlePosition: CGPoint = .zero
    @State private var playfieldSize: CGSize = .zero

    private let countdownTimer = Timer.publish(every: 0.02, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.10, green: 0.12, blue: 0.20),
                        Color(red: 0.07, green: 0.25, blue: 0.33)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                switch phase {
                case .start:
                    startScreen
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                case .playing:
                    gameplayScreen(in: proxy)
                        .transition(.opacity)
                case .gameOver:
                    gameOverScreen
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }
            }
            .animation(.easeInOut(duration: 0.28), value: phase)
            .onAppear {
                playfieldSize = proxy.size
                ensureCirclePositionIfNeeded(in: proxy.size)
            }
            .onChange(of: proxy.size) { _, newSize in
                playfieldSize = newSize
                ensureCirclePositionIfNeeded(in: newSize)
            }
            .onReceive(countdownTimer) { _ in
                tickTimer()
            }
        }
    }

    private var startScreen: some View {
        VStack(spacing: 22) {
            Spacer()

            VStack(spacing: 12) {
                Text("Speedy Circles")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)

                Text("Tap the circle before time runs out.")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(.white)

            VStack(spacing: 14) {
                Text("Time Interval")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.9))

                Picker("Time Interval", selection: $selectedInterval) {
                    ForEach(intervals, id: \.self) { interval in
                        Text("\(interval, specifier: "%.1f")s")
                            .tag(interval)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(18)
            .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(.horizontal, 20)

            Button {
                startGameplay(in: playfieldSize)
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    phase = .playing
                }
            } label: {
                Text("Start")
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .foregroundStyle(.black)
            }
            .padding(.horizontal, 20)
            .buttonStyle(.plain)
            .accessibilityIdentifier("startButton")

            Spacer()
        }
        .padding(.vertical, 30)
        .onAppear {
            prepareNewGame()
        }
    }

    private func gameplayScreen(in proxy: GeometryProxy) -> some View {
        ZStack {
            Button {
                handleSuccessfulTap(in: proxy.size)
            } label: {
                Circle()
                    .fill(circleColor.gradient)
                    .frame(width: circleSize, height: circleSize)
                    .overlay {
                        Circle()
                            .stroke(.white.opacity(0.35), lineWidth: 2)
                    }
                    .shadow(color: circleColor.opacity(0.4), radius: 14, y: 4)
            }
            .buttonStyle(.plain)
            .position(circlePosition)
            .contentShape(Circle())
            .accessibilityLabel("Target Circle")
            .accessibilityIdentifier("targetCircle")
            .animation(.spring(response: 0.33, dampingFraction: 0.76), value: circlePosition)
            .animation(.spring(response: 0.3, dampingFraction: 0.76), value: circleSize)
            .animation(.easeInOut(duration: 0.22), value: circleColor)

            VStack(spacing: 10) {
                scoreCard

                ProgressView(value: remainingTime, total: selectedInterval)
                    .tint(.white)
                    .padding(.horizontal, 22)
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.top, 18)
        }
    }

    private var scoreCard: some View {
        HStack(spacing: 24) {
            labelValueView(label: "Score", value: "\(score)")
            labelValueView(label: "Time Left", value: String(format: "%.2fs", max(remainingTime, 0)))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .padding(.horizontal, 18)
    }

    private func labelValueView(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(label.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.78))

            Text(value)
                .font(.headline.monospacedDigit())
                .foregroundStyle(.white)
                .accessibilityIdentifier(label == "Score" ? "scoreValue" : "timeLeftValue")
        }
    }

    private var gameOverScreen: some View {
        VStack(spacing: 16) {
            Spacer()

            Text("Time's Up")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Final Score: \(score)")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.92))

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                    phase = .start
                }
            } label: {
                Text("Retry")
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .foregroundStyle(.black)
            }
            .padding(.horizontal, 20)
            .buttonStyle(.plain)
            .accessibilityIdentifier("retryButton")

            Spacer()
        }
        .padding(.vertical, 30)
    }

    private func prepareNewGame() {
        score = 0
        circleSize = initialCircleSize
        remainingTime = selectedInterval
        circleColor = randomColor()
    }

    private func startGameplay(in size: CGSize) {
        score = 0
        circleSize = initialCircleSize
        remainingTime = selectedInterval
        circleColor = randomColor()
        moveCircle(in: size)
    }

    private func handleSuccessfulTap(in size: CGSize) {
        guard phase == .playing else { return }

        score += 1
        remainingTime = selectedInterval
        circleSize = max(minimumCircleSize, circleSize * 0.9)
        circleColor = randomColor()
        moveCircle(in: size)
    }

    private func tickTimer() {
        guard phase == .playing else { return }

        remainingTime -= timerTick

        if remainingTime <= 0 {
            remainingTime = 0
            withAnimation(.easeInOut(duration: 0.24)) {
                phase = .gameOver
            }
        }
    }

    private func moveCircle(in size: CGSize) {
        let topReserved: CGFloat = 150
        let radius = circleSize / 2

        let safeMinX = radius + 12
        let safeMaxX = max(safeMinX, size.width - radius - 12)

        let safeMinY = max(radius + 12, topReserved + radius)
        let safeMaxY = max(safeMinY, size.height - radius - 12)

        let newX = CGFloat.random(in: safeMinX...safeMaxX)
        let newY = CGFloat.random(in: safeMinY...safeMaxY)

        circlePosition = CGPoint(x: newX, y: newY)
    }

    private func ensureCirclePositionIfNeeded(in size: CGSize) {
        guard circlePosition == .zero else { return }
        moveCircle(in: size)
    }

    private func randomColor() -> Color {
        Color(
            red: Double.random(in: 0.2...1.0),
            green: Double.random(in: 0.2...1.0),
            blue: Double.random(in: 0.2...1.0)
        )
    }
}

private enum GamePhase {
    case start
    case playing
    case gameOver
}

#Preview {
    ContentView()
}
