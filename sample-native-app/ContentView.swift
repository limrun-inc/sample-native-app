import Combine
import SwiftUI

struct ContentView: View {
    @State private var game = GameModel()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()

                switch game.phase {
                case .start:
                    StartScreen(game: game, screenSize: geo.size)
                        .transition(.opacity)
                case .playing:
                    PlayingScreen(game: game, screenSize: geo.size)
                        .transition(.opacity)
                case .gameOver:
                    GameOverScreen(game: game)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: game.phase)
        }
    }
}

// MARK: - Start Screen

struct StartScreen: View {
    var game: GameModel
    let screenSize: CGSize
    private let intervals: [Double] = [2.0, 3.0, 5.0]

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "circle.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue)
                .symbolEffect(.pulse)

            Text("Speedy Circles")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)

            Text("Tap the circles before time runs out!")
                .font(.subheadline)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                Text("Time Interval")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.7))

                HStack(spacing: 16) {
                    ForEach(intervals, id: \.self) { interval in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                game.selectedInterval = interval
                            }
                        } label: {
                            Text(String(format: "%.1fs", interval))
                                .font(.title3.bold())
                                .frame(width: 80, height: 48)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            game.selectedInterval == interval
                                                ? Color.blue : Color.white.opacity(0.15)
                                        )
                                )
                                .foregroundStyle(.white)
                        }
                        .accessibilityIdentifier("interval_\(String(format: "%.1f", interval))")
                    }
                }
            }

            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    game.startGame(in: screenSize)
                }
            } label: {
                Text("Start")
                    .font(.title2.bold())
                    .frame(width: 200, height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.green)
                    )
                    .foregroundStyle(.white)
            }
            .accessibilityIdentifier("startButton")

            Spacer()
        }
        .padding()
    }
}

// MARK: - Playing Screen

struct PlayingScreen: View {
    var game: GameModel
    let screenSize: CGSize
    @State private var now = Date()

    private var remaining: Double {
        max(0, game.deadline.timeIntervalSince(now))
    }

    private var fraction: Double {
        game.selectedInterval > 0 ? remaining / game.selectedInterval : 0
    }

    var body: some View {
        ZStack {
            VStack(spacing: 4) {
                HStack {
                    Label("\(game.score)", systemImage: "star.fill")
                        .font(.title2.bold())
                        .foregroundStyle(.yellow)
                        .accessibilityIdentifier("scoreLabel")

                    Spacer()

                    Text(String(format: "%.1f", remaining))
                        .font(.title2.monospacedDigit().bold())
                        .foregroundStyle(fraction < 0.3 ? .red : .white)
                        .contentTransition(.numericText())
                        .accessibilityIdentifier("timerLabel")
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                GeometryReader { barGeo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 3)
                            .fill(fraction < 0.3 ? Color.red : Color.green)
                            .frame(width: barGeo.size.width * fraction, height: 6)
                            .animation(.easeInOut(duration: 0.3), value: fraction < 0.3)
                    }
                }
                .frame(height: 6)
                .padding(.horizontal, 20)

                Spacer()
            }

            Circle()
                .fill(game.circleColor.gradient)
                .shadow(color: game.circleColor.opacity(0.5), radius: 10)
                .frame(width: game.circleSize, height: game.circleSize)
                .contentShape(Circle())
                .position(game.circlePosition)
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        game.circleTapped(in: screenSize)
                    }
                }
                .accessibilityIdentifier("targetCircle")
        }
        .onReceive(
            Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()
        ) { date in
            now = date
            if game.deadline.timeIntervalSince(date) <= 0 {
                withAnimation(.easeInOut(duration: 0.3)) {
                    game.checkTimeout(at: date)
                }
            }
        }
    }
}

// MARK: - Game Over Screen

struct GameOverScreen: View {
    var game: GameModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.red)

            Text("Game Over")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)

            Text("\(game.score)")
                .font(.system(size: 80, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .accessibilityIdentifier("finalScore")

            Text(game.score == 1 ? "circle tapped" : "circles tapped")
                .font(.title3)
                .foregroundStyle(.gray)

            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    game.retry()
                }
            } label: {
                Text("Retry")
                    .font(.title2.bold())
                    .frame(width: 200, height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.blue)
                    )
                    .foregroundStyle(.white)
            }
            .accessibilityIdentifier("retryButton")

            Spacer()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
