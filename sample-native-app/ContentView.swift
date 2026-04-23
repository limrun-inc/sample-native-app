//
//  ContentView.swift
//  sample-native-app
//

import SwiftUI

// MARK: - Game State

enum GamePhase {
    case start
    case playing
    case gameOver
}

// MARK: - Named Color Pair (for easy exclusion)

private struct NamedColor: Equatable {
    let name: String
    let color: Color

    static let all: [NamedColor] = [
        NamedColor(name: "blue",   color: .blue),
        NamedColor(name: "green",  color: .green),
        NamedColor(name: "orange", color: .orange),
        NamedColor(name: "pink",   color: .pink),
        NamedColor(name: "purple", color: .purple),
        NamedColor(name: "red",    color: .red),
        NamedColor(name: "teal",   color: .teal),
        NamedColor(name: "yellow", color: .yellow),
        NamedColor(name: "indigo", color: .indigo),
        NamedColor(name: "mint",   color: .mint),
        NamedColor(name: "cyan",   color: .cyan),
    ]
}

// MARK: - Game Model

@Observable
class GameModel {
    var phase: GamePhase = .start
    var selectedInterval: Double = 3.0
    var score: Int = 0
    var timeRemaining: Double = 3.0
    var circlePosition: CGPoint = .zero
    var circleSize: CGFloat = 120
    var circleColor: Color = .cyan
    var screenSize: CGSize = .zero

    private var currentColorName: String = "cyan"
    private var timer: Timer?
    private let minCircleSize: CGFloat = 50
    private let maxCircleSize: CGFloat = 120
    private let timerTickInterval: Double = 0.05

    func startGame() {
        score = 0
        circleSize = maxCircleSize
        timeRemaining = selectedInterval
        let nc = randomNamedColor(excludingName: nil)
        circleColor = nc.color
        currentColorName = nc.name
        circlePosition = randomPosition(for: circleSize)
        phase = .playing
        startTimer()
    }

    func tapCircle() {
        guard phase == .playing else { return }
        score += 1
        let nc = randomNamedColor(excludingName: currentColorName)
        circleColor = nc.color
        currentColorName = nc.name
        circleSize = max(circleSize - 8, minCircleSize)
        circlePosition = randomPosition(for: circleSize)
        timeRemaining = selectedInterval
    }

    func retry() {
        stopTimer()
        phase = .start
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: timerTickInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.timeRemaining -= self.timerTickInterval
            if self.timeRemaining <= 0 {
                self.timeRemaining = 0
                self.failGame()
            }
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func failGame() {
        stopTimer()
        phase = .gameOver
    }

    private func randomNamedColor(excludingName: String?) -> NamedColor {
        var available = NamedColor.all
        if let excludingName {
            available.removeAll { $0.name == excludingName }
        }
        return available.randomElement() ?? NamedColor.all[0]
    }

    private func randomPosition(for size: CGFloat) -> CGPoint {
        let padding = size / 2 + 20
        let safeWidth  = max(screenSize.width  - padding * 2, 1)
        let safeHeight = max(screenSize.height - padding * 2, 1)
        let x = CGFloat.random(in: 0...safeWidth)  + padding
        let y = CGFloat.random(in: 0...safeHeight) + padding
        return CGPoint(x: x, y: y)
    }
}

// MARK: - Root View

struct ContentView: View {
    @State private var game = GameModel()

    var body: some View {
        ZStack {
            switch game.phase {
            case .start:
                StartView(game: game)
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            case .playing:
                GameView(game: game)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity
                    ))
            case .gameOver:
                GameOverView(game: game)
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.4), value: game.phase)
    }
}

// MARK: - Start Screen

struct StartView: View {
    var game: GameModel
    @State private var pulseScale: CGFloat = 1.0

    private let intervals: [Double] = [2.0, 3.0, 5.0]

    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                heroCircle
                    .padding(.bottom, 28)

                Text("Speedy Circles")
                    .font(.system(size: 38, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.bottom, 6)

                Text("Tap the circle before time runs out!")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 44)

                intervalPicker
                    .padding(.bottom, 40)

                startButton

                Spacer()
            }
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color(red: 0.06, green: 0.06, blue: 0.18),
                     Color(red: 0.12, green: 0.04, blue: 0.26)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var heroCircle: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(0.25), .clear],
                        center: .center, startRadius: 10, endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .scaleEffect(pulseScale)
                .onAppear {
                    withAnimation(
                        .easeInOut(duration: 1.2)
                        .repeatForever(autoreverses: true)
                    ) {
                        pulseScale = 1.15
                    }
                }

            Circle()
                .fill(Color.cyan.opacity(0.85))
                .frame(width: 110, height: 110)
                .shadow(color: .cyan.opacity(0.7), radius: 24)
        }
    }

    private var intervalPicker: some View {
        VStack(spacing: 12) {
            Text("Time per circle")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))
                .textCase(.uppercase)
                .kerning(1.2)

            HStack(spacing: 12) {
                ForEach(intervals, id: \.self) { interval in
                    IntervalButton(
                        label: "\(Int(interval))s",
                        isSelected: game.selectedInterval == interval
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            game.selectedInterval = interval
                        }
                    }
                }
            }
        }
    }

    private var startButton: some View {
        Button {
            withAnimation {
                game.startGame()
            }
        } label: {
            Text("Start")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(
                    LinearGradient(
                        colors: [.cyan, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: .cyan.opacity(0.5), radius: 16, x: 0, y: 8)
        }
        .accessibilityIdentifier("startButton")
        .padding(.horizontal, 36)
    }
}

struct IntervalButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(isSelected ? Color.black : Color.white.opacity(0.75))
                .frame(width: 72, height: 44)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.white : Color.white.opacity(0.12))
                )
                .overlay(
                    Capsule()
                        .strokeBorder(
                            isSelected ? Color.clear : Color.white.opacity(0.2),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Game View

struct GameView: View {
    var game: GameModel
    @State private var circleScale: CGFloat = 0.1
    @State private var circleOpacity: Double = 0

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                LinearGradient(
                    colors: [Color(red: 0.06, green: 0.06, blue: 0.18),
                             Color(red: 0.12, green: 0.04, blue: 0.26)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                HUDView(game: game)
                    .padding(.top, geo.safeAreaInsets.top > 0 ? geo.safeAreaInsets.top : 16)
                    .padding(.horizontal, 24)
                    .zIndex(10)

                gameCircle
                    .position(game.circlePosition)
            }
            .onAppear {
                game.screenSize = geo.size
                withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
                    circleScale = 1.0
                    circleOpacity = 1
                }
            }
            .onChange(of: geo.size) { _, newSize in
                game.screenSize = newSize
            }
        }
        .ignoresSafeArea()
    }

    private var gameCircle: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [game.circleColor.opacity(0.9), game.circleColor],
                    center: UnitPoint(x: 0.35, y: 0.3),
                    startRadius: 4,
                    endRadius: game.circleSize * 0.6
                )
            )
            .frame(width: game.circleSize, height: game.circleSize)
            .shadow(color: game.circleColor.opacity(0.6), radius: 20, x: 0, y: 6)
            .overlay(
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.35), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .padding(game.circleSize * 0.12)
            )
            .scaleEffect(circleScale)
            .opacity(circleOpacity)
            .onTapGesture {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                    circleScale = 0.1
                    circleOpacity = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    game.tapCircle()
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) {
                        circleScale = 1.0
                        circleOpacity = 1
                    }
                }
            }
            .accessibilityIdentifier("gameCircle")
    }
}

// MARK: - HUD

struct HUDView: View {
    var game: GameModel

    private var timerColor: Color {
        let ratio = game.timeRemaining / game.selectedInterval
        if ratio > 0.6 { return .green }
        if ratio > 0.3 { return .orange }
        return .red
    }

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("SCORE")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
                    .kerning(1.2)
                Text("\(game.score)")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText(value: Double(game.score)))
                    .animation(.spring, value: game.score)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text("TIME")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
                    .kerning(1.2)

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 110, height: 10)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [timerColor, timerColor.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: max(0, 110 * CGFloat(game.timeRemaining / game.selectedInterval)),
                            height: 10
                        )
                        .animation(.linear(duration: 0.05), value: game.timeRemaining)
                        .shadow(color: timerColor.opacity(0.8), radius: 6)
                }
                .frame(width: 110)

                Text(String(format: "%.1f", max(0, game.timeRemaining)))
                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                    .foregroundStyle(timerColor)
                    .animation(.none, value: game.timeRemaining)
            }
        }
    }
}

// MARK: - Game Over Screen

struct GameOverView: View {
    var game: GameModel
    @State private var appear = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.06, green: 0.06, blue: 0.18),
                         Color(red: 0.12, green: 0.04, blue: 0.26)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.15))
                        .frame(width: 120, height: 120)

                    Image(systemName: "timer")
                        .font(.system(size: 52, weight: .semibold))
                        .foregroundStyle(.red)
                }
                .scaleEffect(appear ? 1 : 0.4)
                .opacity(appear ? 1 : 0)
                .padding(.bottom, 28)

                Text("Time's Up!")
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 20)
                    .padding(.bottom, 8)

                Text("Final Score")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
                    .textCase(.uppercase)
                    .kerning(1.5)
                    .opacity(appear ? 1 : 0)
                    .padding(.bottom, 4)

                Text("\(game.score)")
                    .font(.system(size: 80, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.cyan, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .opacity(appear ? 1 : 0)
                    .scaleEffect(appear ? 1 : 0.5)
                    .padding(.bottom, 16)

                scoreMessage
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 48)
                    .opacity(appear ? 1 : 0)
                    .padding(.bottom, 52)

                retryButton
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 30)

                Spacer()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.05)) {
                appear = true
            }
        }
    }

    private var retryButton: some View {
        Button {
            withAnimation {
                game.retry()
            }
        } label: {
            Text("Retry")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(
                    LinearGradient(
                        colors: [.cyan, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: .cyan.opacity(0.45), radius: 16, x: 0, y: 8)
        }
        .accessibilityIdentifier("retryButton")
        .padding(.horizontal, 36)
    }

    private var scoreMessage: Text {
        switch game.score {
        case 0:       return Text("Better luck next time!")
        case 1..<5:   return Text("Keep practising!")
        case 5..<10:  return Text("Nice reflexes!")
        case 10..<20: return Text("Great job! You're quick!")
        default:      return Text("Incredible speed!")
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
