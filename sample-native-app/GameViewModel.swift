import SwiftUI
import Combine

enum GameState {
    case start
    case playing
    case gameOver
}

@Observable
final class GameViewModel {

    // MARK: - Constants
    static let minCircleSize: CGFloat = 60
    static let maxCircleSize: CGFloat = 130
    static let circleShrinkAmount: CGFloat = 12

    // MARK: - Published State
    var gameState: GameState = .start
    var score: Int = 0
    var circlePosition: CGPoint = .zero
    var circleSize: CGFloat = maxCircleSize
    var circleColor: Color = GameViewModel.randomColor()
    var timeRemaining: Double = 3.0
    var selectedInterval: Double = 3.0

    // MARK: - Private
    private var timer: AnyCancellable?
    private var screenSize: CGSize = .zero

    // MARK: - API

    func configure(screenSize: CGSize) {
        self.screenSize = screenSize
    }

    func startGame(interval: Double) {
        selectedInterval = interval
        timeRemaining = interval
        score = 0
        circleSize = GameViewModel.maxCircleSize
        gameState = .playing
        placeCircle()
        startTimer()
    }

    func circleTapped() {
        guard gameState == .playing else { return }
        score += 1
        circleSize = max(circleSize - GameViewModel.circleShrinkAmount, GameViewModel.minCircleSize)
        circleColor = GameViewModel.randomColor()
        timeRemaining = selectedInterval
        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
            placeCircle()
        }
    }

    func retry() {
        timer?.cancel()
        gameState = .start
    }

    // MARK: - Private Helpers

    private func placeCircle() {
        let padding = circleSize / 2 + 8
        let safeWidth = max(screenSize.width - padding * 2, 1)
        let safeHeight = max(screenSize.height - padding * 2 - 120, 1) // leave room for HUD
        let x = CGFloat.random(in: padding...(padding + safeWidth))
        let y = CGFloat.random(in: (padding + 80)...(padding + 80 + safeHeight))
        circlePosition = CGPoint(x: x, y: y)
    }

    private func startTimer() {
        timer?.cancel()
        let tickInterval = 0.05
        timer = Timer.publish(every: tickInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.timeRemaining -= tickInterval
                if self.timeRemaining <= 0 {
                    self.timeRemaining = 0
                    self.timer?.cancel()
                    self.gameState = .gameOver
                }
            }
    }

    private static func randomColor() -> Color {
        let colors: [Color] = [
            .red, .orange, .yellow, .green, .teal, .blue, .indigo, .purple, .pink
        ]
        return colors.randomElement() ?? .blue
    }
}
