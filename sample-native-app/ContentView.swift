import SwiftUI
import Combine

struct ContentView: View {
    private enum GameState {
        case ready
        case running
        case gameOver
    }

    private let lanePositions: [CGFloat] = [0.2, 0.5, 0.8]
    private let obstacleSpeed: CGFloat = 0.018

    @State private var gameState: GameState = .ready
    @State private var playerLane: Int = 1
    @State private var obstacles: [Obstacle] = []
    @State private var score: Int = 0
    @State private var tickCount: Int = 0

    private let gameTimer = Timer.publish(every: 0.03, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let roadWidth = min(width * 0.82, 360)
            let roadLeft = (width - roadWidth) / 2
            let laneX = lanePositions.map { roadLeft + ($0 * roadWidth) }
            let playerY = height * 0.83

            ZStack {
                LinearGradient(colors: [.green.opacity(0.6), .green.opacity(0.85)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                RoundedRectangle(cornerRadius: 24)
                    .fill(.black.opacity(0.87))
                    .frame(width: roadWidth, height: height * 0.95)

                laneLines(roadWidth: roadWidth, roadHeight: height * 0.95)

                ForEach(obstacles) { obstacle in
                    obstacleView
                        .position(x: laneX[obstacle.lane], y: obstacle.y * height)
                }

                playerCarView
                    .position(x: laneX[playerLane], y: playerY)

                overlayUI(width: width)
            }
            .onReceive(gameTimer) { _ in
                updateGame()
            }
        }
        .accessibilityIdentifier("gameScreen")
    }

    private var playerCarView: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(.blue)
            .frame(width: 48, height: 88)
            .overlay(
                VStack(spacing: 6) {
                    Capsule()
                        .fill(.white.opacity(0.8))
                        .frame(width: 30, height: 16)
                    HStack(spacing: 18) {
                        Circle().fill(.white).frame(width: 8, height: 8)
                        Circle().fill(.white).frame(width: 8, height: 8)
                    }
                }
            )
            .accessibilityIdentifier("playerCar")
    }

    private var obstacleView: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(.red)
            .frame(width: 48, height: 88)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.black.opacity(0.35), lineWidth: 2)
            )
            .accessibilityIdentifier("obstacleCar")
    }

    private func laneLines(roadWidth: CGFloat, roadHeight: CGFloat) -> some View {
        HStack(spacing: roadWidth * 0.3) {
            ForEach(0..<2, id: \.self) { _ in
                Rectangle()
                    .fill(.white.opacity(0.85))
                    .frame(width: 6)
            }
        }
        .frame(height: roadHeight)
        .overlay {
            VStack {
                ForEach(0..<10, id: \.self) { _ in
                    Color.clear.frame(height: 24)
                    Rectangle()
                        .fill(.black.opacity(0.8))
                        .frame(height: 24)
                }
            }
        }
    }

    @ViewBuilder
    private func overlayUI(width: CGFloat) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Score: \(score)")
                    .font(.headline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.black.opacity(0.6), in: Capsule())
                    .accessibilityIdentifier("scoreLabel")

                Spacer()

                Text(statusText)
                    .font(.headline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.black.opacity(0.6), in: Capsule())
                    .accessibilityIdentifier("statusLabel")
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.top, 18)

            Spacer()

            if gameState == .ready || gameState == .gameOver {
                Button(action: startGame) {
                    Text(gameState == .gameOver ? "Restart" : "Start Game")
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.white)
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .accessibilityIdentifier("startButton")
                .padding(.horizontal, 32)
            }

            HStack(spacing: 16) {
                Button(action: moveLeft) {
                    Label("Left", systemImage: "arrow.left")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.blue.opacity(0.8), in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)
                }
                .accessibilityIdentifier("leftButton")

                Button(action: moveRight) {
                    Label("Right", systemImage: "arrow.right")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.blue.opacity(0.8), in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)
                }
                .accessibilityIdentifier("rightButton")
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .disabled(gameState != .running)
            .opacity(gameState == .running ? 1 : 0.65)
        }
        .frame(width: width)
    }

    private var statusText: String {
        switch gameState {
        case .ready:
            return "Ready"
        case .running:
            return "Driving"
        case .gameOver:
            return "Crash!"
        }
    }

    private func startGame() {
        gameState = .running
        playerLane = 1
        obstacles.removeAll()
        score = 0
        tickCount = 0
    }

    private func moveLeft() {
        playerLane = max(0, playerLane - 1)
    }

    private func moveRight() {
        playerLane = min(lanePositions.count - 1, playerLane + 1)
    }

    private func updateGame() {
        guard gameState == .running else { return }

        tickCount += 1

        obstacles = obstacles
            .map { obstacle in
                var updated = obstacle
                updated.y += obstacleSpeed
                return updated
            }
            .filter { $0.y < 1.15 }

        if tickCount % 38 == 0 {
            let randomLane = Int.random(in: 0..<lanePositions.count)
            obstacles.append(Obstacle(lane: randomLane, y: -0.12))
        }

        if obstacles.contains(where: { $0.lane == playerLane && $0.y > 0.73 && $0.y < 0.93 }) {
            gameState = .gameOver
            return
        }

        if tickCount % 12 == 0 {
            score += 1
        }
    }
}

private struct Obstacle: Identifiable {
    let id = UUID()
    let lane: Int
    var y: CGFloat
}

#Preview {
    ContentView()
}
