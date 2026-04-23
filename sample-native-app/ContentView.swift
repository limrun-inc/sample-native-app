import SwiftUI
import Combine

struct Obstacle: Identifiable {
    let id = UUID()
    var lane: Int
    var y: CGFloat
}

struct ContentView: View {
    @State private var playerLane = 1
    @State private var obstacles: [Obstacle] = []
    @State private var tickCount = 0
    @State private var score = 0
    @State private var isRunning = false
    @State private var isGameOver = false

    private let laneCount = 3
    private let roadPadding: CGFloat = 24
    private let carSize = CGSize(width: 52, height: 88)
    private let obstacleSize = CGSize(width: 48, height: 80)
    private let gameTick = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                roadBackground

                VStack(spacing: 12) {
                    HStack {
                        Text("Score: \(score)")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .accessibilityIdentifier("scoreLabel")
                        Spacer()
                        if isGameOver {
                            Text("Crashed")
                                .font(.headline)
                                .foregroundStyle(.red)
                                .accessibilityIdentifier("gameOverLabel")
                        } else if isRunning {
                            Text("Driving")
                                .font(.headline)
                                .foregroundStyle(.green)
                                .accessibilityIdentifier("statusLabel")
                        } else {
                            Text("Ready")
                                .font(.headline)
                                .foregroundStyle(.yellow)
                                .accessibilityIdentifier("statusLabel")
                        }
                    }
                    .padding(.horizontal)

                    ZStack {
                        ForEach(0..<laneCount, id: \.self) { lane in
                            laneStripe(in: geo.size, lane: lane)
                        }

                        ForEach(obstacles) { obstacle in
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.orange)
                                .frame(width: obstacleSize.width, height: obstacleSize.height)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.white.opacity(0.8), lineWidth: 2)
                                )
                                .position(x: laneCenterX(in: geo.size, lane: obstacle.lane), y: obstacle.y)
                                .accessibilityIdentifier("obstacle")
                        }

                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue)
                            .frame(width: carSize.width, height: carSize.height)
                            .overlay(
                                VStack(spacing: 4) {
                                    Rectangle()
                                        .fill(.white.opacity(0.8))
                                        .frame(width: 24, height: 14)
                                    Circle()
                                        .fill(.black)
                                        .frame(width: 12, height: 12)
                                }
                            )
                            .position(x: laneCenterX(in: geo.size, lane: playerLane), y: playerY(in: geo.size))
                            .accessibilityIdentifier("playerCar")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    HStack(spacing: 16) {
                        Button("◀ Left") {
                            playerLane = max(0, playerLane - 1)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.teal)
                        .accessibilityIdentifier("leftButton")
                        .disabled(!isRunning)

                        Button(isRunning ? "Restart" : "Start") {
                            startGame(screenSize: geo.size)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        .accessibilityIdentifier("startButton")

                        Button("Right ▶") {
                            playerLane = min(laneCount - 1, playerLane + 1)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.teal)
                        .accessibilityIdentifier("rightButton")
                        .disabled(!isRunning)
                    }
                    .padding(.bottom)
                }
            }
            .onReceive(gameTick) { _ in
                guard isRunning else { return }
                gameLoop(screenSize: geo.size)
            }
        }
    }

    private var roadBackground: some View {
        LinearGradient(
            colors: [Color(red: 0.06, green: 0.09, blue: 0.15), Color(red: 0.13, green: 0.15, blue: 0.2)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private func laneStripe(in size: CGSize, lane: Int) -> some View {
        Rectangle()
            .fill(Color.white.opacity(0.2))
            .frame(width: lane == 0 ? 0 : 3)
            .position(x: laneDividerX(in: size, lane: lane), y: size.height / 2)
    }

    private func laneCenterX(in size: CGSize, lane: Int) -> CGFloat {
        let roadWidth = size.width - roadPadding * 2
        let laneWidth = roadWidth / CGFloat(laneCount)
        return roadPadding + laneWidth * (CGFloat(lane) + 0.5)
    }

    private func laneDividerX(in size: CGSize, lane: Int) -> CGFloat {
        let roadWidth = size.width - roadPadding * 2
        let laneWidth = roadWidth / CGFloat(laneCount)
        return roadPadding + laneWidth * CGFloat(lane)
    }

    private func playerY(in size: CGSize) -> CGFloat {
        size.height * 0.78
    }

    private func startGame(screenSize: CGSize) {
        playerLane = 1
        obstacles = []
        tickCount = 0
        score = 0
        isGameOver = false
        isRunning = true
        _ = screenSize
    }

    private func gameLoop(screenSize: CGSize) {
        tickCount += 1

        if tickCount % 18 == 0 {
            spawnObstacle()
        }

        obstacles = obstacles
            .map { Obstacle(lane: $0.lane, y: $0.y + 10) }
            .filter { $0.y < screenSize.height + 100 }

        score += 1

        if hasCollision(screenSize: screenSize) {
            isRunning = false
            isGameOver = true
        }
    }

    private func spawnObstacle() {
        obstacles.append(Obstacle(lane: Int.random(in: 0..<laneCount), y: -60))
    }

    private func hasCollision(screenSize: CGSize) -> Bool {
        let carY = playerY(in: screenSize)

        return obstacles.contains { obstacle in
            guard obstacle.lane == playerLane else { return false }
            let yOverlap = abs(obstacle.y - carY) < (carSize.height + obstacleSize.height) / 2 - 10
            return yOverlap
        }
    }
}

#Preview {
    ContentView()
}
