import SwiftUI
import Combine

// MARK: - Game State
enum GameState {
    case start
    case playing
    case gameOver
}

// MARK: - Main App View
struct ContentView: View {
    @StateObject private var game = GameViewModel()

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            switch game.state {
            case .start:
                StartView(game: game)
                    .transition(.opacity)
            case .playing:
                GameView(game: game)
                    .transition(.opacity)
            case .gameOver:
                GameOverView(game: game)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: game.state)
    }
}

// MARK: - View Model
class GameViewModel: ObservableObject {
    @Published var state: GameState = .start
    @Published var score: Int = 0
    @Published var selectedInterval: Double = 3.0
    @Published var timeRemaining: Double = 3.0
    @Published var circlePosition: CGPoint = .zero
    @Published var circleRadius: CGFloat = 60
    @Published var circleColor: Color = .blue
    @Published var isCircleVisible: Bool = false
    @Published var timerProgress: Double = 1.0

    private var timer: Timer?
    private var screenSize: CGSize = .zero
    private let minRadius: CGFloat = 30
    private let maxRadius: CGFloat = 80

    let intervalOptions: [Double] = [2.0, 3.0, 5.0]

    func setScreenSize(_ size: CGSize) {
        screenSize = size
    }

    func startGame() {
        score = 0
        circleRadius = maxRadius
        timeRemaining = selectedInterval
        timerProgress = 1.0
        state = .playing
        spawnCircle()
        startTimer()
    }

    func circleWasTapped() {
        score += 1
        shrinkAndMove()
    }

    private func spawnCircle() {
        circlePosition = randomPosition(radius: circleRadius)
        circleColor = randomColor()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            isCircleVisible = true
        }
    }

    private func shrinkAndMove() {
        let newRadius = max(minRadius, circleRadius - 5)
        let newPos = randomPosition(radius: newRadius)
        let newColor = randomColor()

        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            circleRadius = newRadius
            circlePosition = newPos
            circleColor = newColor
        }

        timeRemaining = selectedInterval
        timerProgress = 1.0
    }

    private func randomPosition(radius: CGFloat) -> CGPoint {
        let safeArea: CGFloat = 80
        let minX = radius + 20
        let maxX = screenSize.width - radius - 20
        let minY = radius + safeArea
        let maxY = screenSize.height - radius - safeArea

        let x = CGFloat.random(in: minX...max(minX, maxX))
        let y = CGFloat.random(in: minY...max(minY, maxY))
        return CGPoint(x: x, y: y)
    }

    private func randomColor() -> Color {
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink, .cyan, .mint, .teal]
        return colors.randomElement() ?? .blue
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.timeRemaining -= 0.05
                self.timerProgress = max(0, self.timeRemaining / self.selectedInterval)
                if self.timeRemaining <= 0 {
                    self.handleTimeout()
                }
            }
        }
    }

    private func handleTimeout() {
        timer?.invalidate()
        timer = nil
        withAnimation(.easeInOut(duration: 0.3)) {
            isCircleVisible = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            self.state = .gameOver
        }
    }

    func resetToStart() {
        timer?.invalidate()
        timer = nil
        isCircleVisible = false
        state = .start
    }
}

// MARK: - Start View
struct StartView: View {
    @ObservedObject var game: GameViewModel

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Speedy Circles")
                    .font(.system(size: 36, weight: .bold, design: .rounded))

                Text("Tap the circle before time runs out!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            VStack(spacing: 16) {
                Text("Select Time Interval")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    ForEach(game.intervalOptions, id: \.self) { interval in
                        IntervalButton(
                            interval: interval,
                            isSelected: game.selectedInterval == interval,
                            action: { game.selectedInterval = interval }
                        )
                    }
                }
            }

            Button(action: game.startGame) {
                Text("Start Game")
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 32)
            .accessibilityIdentifier("startButton")

            Spacer()
        }
        .padding()
    }
}

// MARK: - Interval Button
struct IntervalButton: View {
    let interval: Double
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text("\(interval, specifier: "%.1f")s")
                    .font(.title3.weight(.bold))
                Text("seconds")
                    .font(.caption2)
            }
            .frame(width: 80, height: 56)
            .background(isSelected ? Color.blue : Color(.secondarySystemBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .accessibilityIdentifier("interval_\(Int(interval))")
    }
}

// MARK: - Game View
struct GameView: View {
    @ObservedObject var game: GameViewModel

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background
                Color(.systemBackground).ignoresSafeArea()

                // HUD
                VStack {
                    HUD(game: game)
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    Spacer()
                }

                // Circle
                if game.isCircleVisible {
                    CircleButton(game: game)
                }
            }
            .onAppear {
                game.setScreenSize(geo.size)
            }
        }
    }
}

// MARK: - HUD
struct HUD: View {
    @ObservedObject var game: GameViewModel

    var timerColor: Color {
        if game.timerProgress > 0.5 { return .green }
        if game.timerProgress > 0.25 { return .orange }
        return .red
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Score")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text("\(game.score)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .accessibilityIdentifier("scoreLabel")
                        .contentTransition(.numericText())
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Time")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.1f", max(0, game.timeRemaining)))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(timerColor)
                        .accessibilityIdentifier("timerLabel")
                        .contentTransition(.numericText())
                        .animation(.linear(duration: 0.05), value: game.timeRemaining)
                }
            }

            // Timer bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.tertiarySystemBackground))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(timerColor)
                        .frame(width: geo.size.width * game.timerProgress, height: 8)
                        .animation(.linear(duration: 0.05), value: game.timerProgress)
                }
            }
            .frame(height: 8)
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
    }
}

// MARK: - Circle Button
struct CircleButton: View {
    @ObservedObject var game: GameViewModel
    @State private var isPressed = false

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [game.circleColor.opacity(0.9), game.circleColor],
                        center: .init(x: 0.35, y: 0.35),
                        startRadius: 0,
                        endRadius: game.circleRadius
                    )
                )
                .frame(width: game.circleRadius * 2, height: game.circleRadius * 2)
                .shadow(color: game.circleColor.opacity(0.5), radius: 12, y: 6)
                .scaleEffect(isPressed ? 0.9 : 1.0)
                .animation(.spring(response: 0.2, dampingFraction: 0.5), value: isPressed)

            // Shine effect
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.4), Color.clear],
                        center: .init(x: 0.3, y: 0.3),
                        startRadius: 0,
                        endRadius: game.circleRadius * 0.6
                    )
                )
                .frame(width: game.circleRadius * 2, height: game.circleRadius * 2)
                .allowsHitTesting(false)
        }
        .position(game.circlePosition)
        .onTapGesture {
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                game.circleWasTapped()
            }
        }
        .accessibilityIdentifier("gameCircle")
        .transition(.scale(scale: 0.1).combined(with: .opacity))
    }
}

// MARK: - Game Over View
struct GameOverView: View {
    @ObservedObject var game: GameViewModel

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "timer.circle")
                    .font(.system(size: 72))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.red, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Time's Up!")
                    .font(.system(size: 40, weight: .bold, design: .rounded))

                VStack(spacing: 6) {
                    Text("Final Score")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("\(game.score)")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .accessibilityIdentifier("finalScoreLabel")
                }
            }

            Spacer()

            VStack(spacing: 12) {
                Button(action: game.startGame) {
                    Label("Play Again", systemImage: "arrow.clockwise")
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .accessibilityIdentifier("playAgainButton")

                Button(action: game.resetToStart) {
                    Text("Back to Menu")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(.secondarySystemBackground))
                        .foregroundColor(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .accessibilityIdentifier("retryButton")
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
