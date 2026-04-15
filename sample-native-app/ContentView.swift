import SwiftUI
import Combine

struct ContentView: View {
    private let intervals: [Double] = [0.5, 1.0, 2.0, 3.0, 5.0]
    private let timer = Timer.publish(every: 0.02, on: .main, in: .common).autoconnect()

    @State private var selectedInterval: Double = 5.0
    @State private var gameState: GameState = .start
    @State private var score: Int = 0
    @State private var remainingTime: Double = 1.0
    @State private var circleSize: CGFloat = 140
    @State private var circleCenter: CGPoint = .zero
    @State private var circleColor: Color = .blue

    private let minimumCircleSize: CGFloat = 64
    private let maximumCircleSize: CGFloat = 150

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    colors: [Color(.systemIndigo).opacity(0.85), Color(.systemBlue), Color(.systemTeal).opacity(0.9)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                switch gameState {
                case .start:
                    startView
                        .transition(.opacity.combined(with: .scale(scale: 0.97)))
                case .playing:
                    gameView(in: geometry)
                        .transition(.opacity)
                case .gameOver:
                    gameOverView
                        .transition(.opacity.combined(with: .scale(scale: 1.03)))
                }
            }
            .onAppear {
                if circleCenter == .zero {
                    moveCircle(in: geometry.size)
                }
            }
            .onReceive(timer) { _ in
                guard gameState == .playing else { return }

                remainingTime -= 0.02
                if remainingTime <= 0 {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
                        gameState = .gameOver
                    }
                }
            }
        }
    }

    private var startView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 10) {
                Text("Speedy Circles")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Tap the circle before time runs out.")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.9))
            }

            VStack(spacing: 12) {
                Text("Time per round")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.95))

                Picker("Time per round", selection: $selectedInterval) {
                    ForEach(intervals, id: \.self) { interval in
                        Text(String(format: "%.1fs", interval))
                            .tag(interval)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("intervalPicker")
            }

            Button {
                startGame()
            } label: {
                Text("Start")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(.white)
            .foregroundStyle(.indigo)
            .accessibilityIdentifier("startButton")
        }
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(.horizontal, 24)
    }

    private func gameView(in geometry: GeometryProxy) -> some View {
        ZStack {
            VStack(spacing: 8) {
                Text("Score: \(score)")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .accessibilityIdentifier("scoreLabel")

                Text("Time: \(remainingTime, specifier: "%.2f")s")
                    .font(.title3.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.95))
                    .accessibilityIdentifier("timeLabel")
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.top, 24)

            Circle()
                .fill(circleColor.gradient)
                .frame(width: circleSize, height: circleSize)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.65), lineWidth: 3)
                )
                .shadow(color: .black.opacity(0.2), radius: 16, x: 0, y: 10)
                .position(circleCenter)
                .onTapGesture {
                    hitCircle(in: geometry.size)
                }
                .accessibilityIdentifier("targetCircle")
        }
        .clipped()
    }

    private var gameOverView: some View {
        VStack(spacing: 18) {
            Text("Time’s Up")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Final Score: \(score)")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.96))
                .accessibilityIdentifier("finalScoreLabel")

            Button {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.88)) {
                    gameState = .start
                }
            } label: {
                Text("Retry")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(.white)
            .foregroundStyle(.indigo)
            .accessibilityIdentifier("retryButton")
        }
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(.horizontal, 24)
    }

    private func startGame() {
        score = 0
        circleSize = maximumCircleSize
        remainingTime = selectedInterval
        circleColor = randomColor(excluding: nil)

        withAnimation(.spring(response: 0.45, dampingFraction: 0.88)) {
            gameState = .playing
        }
    }

    private func hitCircle(in availableSize: CGSize) {
        guard gameState == .playing else { return }

        score += 1
        remainingTime = selectedInterval

        let newSize = max(minimumCircleSize, circleSize * 0.9)
        let nextColor = randomColor(excluding: circleColor)

        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            circleSize = newSize
            circleColor = nextColor
            moveCircle(in: availableSize)
        }
    }

    private func moveCircle(in availableSize: CGSize) {
        let margin: CGFloat = 16
        let safeTopPadding: CGFloat = 100
        let radius = circleSize / 2

        let minX = radius + margin
        let maxX = max(minX, availableSize.width - radius - margin)

        let minY = radius + margin + safeTopPadding
        let maxY = max(minY, availableSize.height - radius - margin)

        circleCenter = CGPoint(
            x: CGFloat.random(in: minX ... maxX),
            y: CGFloat.random(in: minY ... maxY)
        )
    }

    private func randomColor(excluding current: Color?) -> Color {
        let palette: [Color] = [.red, .orange, .yellow, .green, .mint, .blue, .indigo, .purple, .pink]
        let filtered = palette.filter { $0 != current }
        return filtered.randomElement() ?? .blue
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
