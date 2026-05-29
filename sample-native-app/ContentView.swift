import SwiftUI

enum GamePhase: Equatable {
    case start
    case playing
    case gameOver
}

@Observable
class GameModel {
    var phase: GamePhase = .start
    var score: Int = 0
    var timeRemaining: Double = 0
    var selectedInterval: Double = 3.0
    var circlePosition: CGPoint = CGPoint(x: 200, y: 400)
    var circleSize: CGFloat = 100
    var circleColor: Color = .red
    var gameAreaSize: CGSize = .zero

    private var deadline: Date = .distantFuture
    private let minCircleSize: CGFloat = 30
    private let shrinkAmount: CGFloat = 5
    private let colors: [Color] = [
        .red, .blue, .green, .orange, .purple, .pink, .yellow, .cyan, .mint, .indigo
    ]

    func startGame() {
        score = 0
        circleSize = 100
        circleColor = colors.randomElement() ?? .red
        repositionCircle()
        deadline = Date().addingTimeInterval(selectedInterval)
        timeRemaining = selectedInterval
        phase = .playing
    }

    func updateTime() {
        guard phase == .playing else { return }
        timeRemaining = deadline.timeIntervalSinceNow
        if timeRemaining <= 0 {
            timeRemaining = 0
            phase = .gameOver
        }
    }

    func circleTapped() {
        guard phase == .playing else { return }
        score += 1
        circleSize = max(minCircleSize, circleSize - shrinkAmount)
        circleColor = colors.randomElement() ?? .red
        repositionCircle()
        deadline = Date().addingTimeInterval(selectedInterval)
        timeRemaining = selectedInterval
    }

    func retry() {
        phase = .start
    }

    private func repositionCircle() {
        guard gameAreaSize.width > 0, gameAreaSize.height > 0 else { return }
        let inset = circleSize / 2 + 20
        circlePosition = CGPoint(
            x: CGFloat.random(in: inset...max(inset + 1, gameAreaSize.width - inset)),
            y: CGFloat.random(in: inset...max(inset + 1, gameAreaSize.height - inset))
        )
    }
}

struct ContentView: View {
    @State private var game = GameModel()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()

                switch game.phase {
                case .start:
                    StartView(game: game)
                        .transition(.opacity)
                case .playing:
                    GameplayView(game: game)
                        .transition(.opacity)
                case .gameOver:
                    GameOverView(game: game)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: game.phase)
            .onAppear {
                game.gameAreaSize = geo.size
            }
            .onChange(of: geo.size) { _, newSize in
                game.gameAreaSize = newSize
            }
        }
    }
}

struct StartView: View {
    var game: GameModel
    private let intervals: [Double] = [2.0, 3.0, 5.0]

    var body: some View {
        VStack(spacing: 40) {
            VStack(spacing: 12) {
                Image(systemName: "target")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)

                Text("Speedy Circles")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text("Tap the circle before time runs out!")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }

            VStack(spacing: 16) {
                Text("Time Interval")
                    .font(.headline)
                    .foregroundStyle(.gray)

                HStack(spacing: 16) {
                    ForEach(intervals, id: \.self) { interval in
                        Button {
                            game.selectedInterval = interval
                        } label: {
                            Text(String(format: "%.1fs", interval))
                                .font(.title3.bold())
                                .foregroundStyle(.white)
                                .frame(width: 80, height: 48)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            game.selectedInterval == interval
                                                ? Color.blue : Color.white.opacity(0.15)
                                        )
                                )
                        }
                        .accessibilityIdentifier("interval_\(String(format: "%.1f", interval))")
                    }
                }
            }

            Button {
                game.startGame()
            } label: {
                Text("Start")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .frame(width: 200, height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.green)
                    )
            }
            .accessibilityIdentifier("startButton")
        }
    }
}

struct GameplayView: View {
    var game: GameModel

    private var timerProgress: Double {
        max(0, game.timeRemaining / game.selectedInterval)
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HStack {
                    Text("Score: \(game.score)")
                        .font(.title3.bold().monospacedDigit())
                        .foregroundStyle(.white)
                        .accessibilityIdentifier("scoreLabel")

                    Spacer()

                    Text(String(format: "%.1f", max(0, game.timeRemaining)))
                        .font(.title3.bold().monospacedDigit())
                        .foregroundStyle(game.timeRemaining < 1.0 ? .red : .white)
                        .contentTransition(.numericText())
                        .accessibilityIdentifier("timerLabel")
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                GeometryReader { barGeo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.white.opacity(0.1))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(timerProgress < 0.3 ? .red : .green)
                            .frame(width: barGeo.size.width * timerProgress, height: 6)
                            .animation(.linear(duration: 0.05), value: timerProgress)
                    }
                }
                .frame(height: 6)
                .padding(.horizontal, 20)
                .padding(.top, 8)

                Spacer()
            }

            Circle()
                .fill(
                    RadialGradient(
                        colors: [game.circleColor.opacity(0.7), game.circleColor],
                        center: .center,
                        startRadius: 0,
                        endRadius: game.circleSize / 2
                    )
                )
                .frame(width: game.circleSize, height: game.circleSize)
                .shadow(color: game.circleColor.opacity(0.5), radius: 12)
                .position(game.circlePosition)
                .onTapGesture {
                    withAnimation(.spring(duration: 0.25)) {
                        game.circleTapped()
                    }
                }
                .accessibilityIdentifier("targetCircle")
        }
        .task(id: game.phase) {
            guard game.phase == .playing else { return }
            while game.phase == .playing {
                try? await Task.sleep(for: .milliseconds(50))
                game.updateTime()
            }
        }
    }
}

struct GameOverView: View {
    var game: GameModel

    var body: some View {
        VStack(spacing: 30) {
            Text("Game Over")
                .font(.system(size: 40, weight: .black, design: .rounded))
                .foregroundStyle(.red)

            VStack(spacing: 8) {
                Text("Final Score")
                    .font(.title3)
                    .foregroundStyle(.gray)

                Text("\(game.score)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .accessibilityIdentifier("finalScoreLabel")
            }

            Button {
                game.retry()
            } label: {
                Text("Retry")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .frame(width: 200, height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.blue)
                    )
            }
            .accessibilityIdentifier("retryButton")
        }
    }
}

#Preview {
    ContentView()
}
