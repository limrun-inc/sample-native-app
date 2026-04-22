import SwiftUI
import Combine

struct ContentView: View {
    private enum GameConstants {
        static let laneCount = 3
        static let tickInterval = 0.18
        static let obstacleStep: CGFloat = 0.085
        static let carVerticalPosition: CGFloat = 0.87
    }

    private struct Obstacle: Identifiable {
        let id = UUID()
        let lane: Int
        var progress: CGFloat
    }

    @State private var isRunning = false
    @State private var isGameOver = false
    @State private var score = 0
    @State private var carLane = 1
    @State private var tick = 0
    @State private var obstacles: [Obstacle] = []

    private let gameTimer = Timer.publish(every: GameConstants.tickInterval, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 16) {
            Text("Score: \(score)")
                .font(.title2.bold())
                .accessibilityIdentifier("scoreLabel")

            gameTrack
                .frame(height: 420)
                .overlay(alignment: .center) {
                    if isGameOver {
                        Text("Crash! Tap Start to try again")
                            .font(.headline)
                            .padding(10)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                            .accessibilityIdentifier("gameOverLabel")
                    }
                }
                .accessibilityIdentifier("gameCanvas")

            HStack(spacing: 12) {
                Button("◀︎ Left") {
                    moveCar(by: -1)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("leftButton")

                Button(isRunning ? "Restart" : "Start") {
                    startGame()
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .accessibilityIdentifier("startButton")

                Button("Right ▶︎") {
                    moveCar(by: 1)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("rightButton")
            }
        }
        .padding()
        .onReceive(gameTimer) { _ in
            guard isRunning else { return }
            advanceGame()
        }
    }

    private var gameTrack: some View {
        GeometryReader { geo in
            let laneWidth = geo.size.width / CGFloat(GameConstants.laneCount)
            let carY = geo.size.height * GameConstants.carVerticalPosition

            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [.black.opacity(0.85), .gray.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                ForEach(1..<GameConstants.laneCount, id: \.self) { divider in
                    Rectangle()
                        .fill(.white.opacity(0.35))
                        .frame(width: 3)
                        .position(x: laneWidth * CGFloat(divider), y: geo.size.height / 2)
                }

                ForEach(obstacles) { obstacle in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.red)
                        .frame(width: laneWidth * 0.5, height: 44)
                        .position(
                            x: laneCenterX(for: obstacle.lane, laneWidth: laneWidth),
                            y: geo.size.height * obstacle.progress
                        )
                }

                RoundedRectangle(cornerRadius: 8)
                    .fill(.blue)
                    .frame(width: laneWidth * 0.52, height: 56)
                    .position(x: laneCenterX(for: carLane, laneWidth: laneWidth), y: carY)
            }
            .clipped()
        }
    }

    private func laneCenterX(for lane: Int, laneWidth: CGFloat) -> CGFloat {
        laneWidth * (CGFloat(lane) + 0.5)
    }

    private func startGame() {
        score = 0
        tick = 0
        carLane = 1
        obstacles = []
        isGameOver = false
        isRunning = true
    }

    private func moveCar(by delta: Int) {
        guard isRunning else { return }
        carLane = min(max(carLane + delta, 0), GameConstants.laneCount - 1)
    }

    private func advanceGame() {
        tick += 1
        score += 1

        obstacles = obstacles
            .map { obstacle in
                var copy = obstacle
                copy.progress += GameConstants.obstacleStep
                return copy
            }
            .filter { $0.progress < 1.05 }

        if tick.isMultiple(of: 3) {
            obstacles.append(Obstacle(lane: Int.random(in: 0..<GameConstants.laneCount), progress: 0.08))
        }

        if detectCollision() {
            isRunning = false
            isGameOver = true
        }
    }

    private func detectCollision() -> Bool {
        let carProgress = GameConstants.carVerticalPosition
        return obstacles.contains { obstacle in
            obstacle.lane == carLane && abs(obstacle.progress - carProgress) < 0.09
        }
    }
}

#Preview {
    ContentView()
}
