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
    var selectedInterval: Double = 3.0
    var circlePosition: CGPoint = CGPoint(x: 200, y: 400)
    var circleSize: CGFloat = 100
    var circleColor: Color = .blue
    var deadline: Date = .distantFuture

    private let minimumSize: CGFloat = 44
    private let shrinkStep: CGFloat = 4
    private let startSize: CGFloat = 100

    func startGame(in size: CGSize) {
        score = 0
        circleSize = startSize
        moveCircle(in: size)
        deadline = Date().addingTimeInterval(selectedInterval)
        phase = .playing
    }

    func circleTapped(in size: CGSize) {
        guard phase == .playing else { return }
        score += 1
        circleSize = max(minimumSize, circleSize - shrinkStep)
        moveCircle(in: size)
        deadline = Date().addingTimeInterval(selectedInterval)
    }

    func checkTimeout(at date: Date) {
        if phase == .playing && date >= deadline {
            phase = .gameOver
        }
    }

    func retry() {
        phase = .start
    }

    private func moveCircle(in size: CGSize) {
        let r = circleSize / 2
        let topPadding: CGFloat = 80
        let edgePadding: CGFloat = 8
        let minX = r + edgePadding
        let maxX = max(minX + 1, size.width - r - edgePadding)
        let minY = r + topPadding
        let maxY = max(minY + 1, size.height - r - edgePadding)

        circlePosition = CGPoint(
            x: .random(in: minX...maxX),
            y: .random(in: minY...maxY)
        )

        let palette: [Color] = [
            .red, .blue, .green, .orange, .purple,
            .pink, .cyan, .yellow, .mint, .indigo,
        ]
        var next = circleColor
        while next == circleColor {
            next = palette.randomElement()!
        }
        circleColor = next
    }
}
