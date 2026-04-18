import SwiftUI
import Combine

enum GameState: Equatable {
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
    var circlePosition: CGPoint = CGPoint(x: 200, y: 450)
    var circleSize: CGFloat = maxCircleSize
    var circleColor: Color = GameViewModel.randomColor()
    var timeRemaining: Double = 3.0
    var selectedInterval: Double = 3.0

    // MARK: - Private
    private var timer: AnyCancellable?
    private(set) var screenSize: CGSize = .zero
    private(set) var topSafeArea: CGFloat = 0

    // MARK: - API

    /// Called by GameView.onAppear once geometry is known.
    func configure(screenSize: CGSize, topSafeArea: CGFloat) {
        self.screenSize = screenSize
        self.topSafeArea = topSafeArea
    }

    /// Transitions to .playing; actual circle placement + timer start after configure().
    func startGame(interval: Double) {
        selectedInterval = interval
        timeRemaining = interval
        score = 0
        circleSize = GameViewModel.maxCircleSize
        withAnimation(.easeInOut(duration: 0.3)) {
            gameState = .playing
        }
    }

    /// Called by GameView once the screen is configured and game is playing.
    func beginGameplay() {
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
        withAnimation(.easeInOut(duration: 0.3)) {
            gameState = .start
        }
    }

    // MARK: - Private Helpers

    private func placeCircle() {
        guard screenSize != .zero else { return }
        let padding = circleSize / 2 + 8
        let hudHeight: CGFloat = topSafeArea + 80
        let safeWidth = max(screenSize.width - padding * 2, 1)
        let safeHeight = max(screenSize.height - padding - hudHeight - 20, 1)
        let x = CGFloat.random(in: padding...(padding + safeWidth))
        let y = CGFloat.random(in: (hudHeight + padding)...(hudHeight + padding + safeHeight))
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
                    withAnimation(.easeInOut(duration: 0.35)) {
                        self.gameState = .gameOver
                    }
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
