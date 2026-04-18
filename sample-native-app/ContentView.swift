//
//  ContentView.swift
//  sample-native-app
//
//  Speedy Circles — tap circles before time runs out!
//

import SwiftUI
import Observation

// MARK: - Game State

enum GameState: Equatable {
    case start
    case playing
    case gameOver
}

// MARK: - Color Palette

private let kCircleColors: [Color] = [
    .red,
    .orange,
    Color(red: 0.95, green: 0.8, blue: 0.1),  // vivid yellow
    .green,
    .mint,
    .cyan,
    .blue,
    .indigo,
    .purple,
    .pink,
    Color(red: 1.0, green: 0.4, blue: 0.4),   // salmon
    Color(red: 0.3, green: 0.85, blue: 0.6),   // seafoam
]

// MARK: - GameViewModel

@Observable
class GameViewModel {
    var gameState: GameState = .start
    var score: Int = 0
    var timeRemaining: Double = 3.0
    var circlePosition: CGPoint = CGPoint(x: 200, y: 400)
    var circleRadius: CGFloat = 60
    var circleColorIndex: Int = 0
    var selectedInterval: Double = 3.0

    var screenSize: CGSize = CGSize(width: 390, height: 844)

    let minCircleRadius: CGFloat = 26
    let maxCircleRadius: CGFloat = 62
    let timerTickInterval: Double = 0.033   // ~30fps

    private var gameTimer: Timer?

    var circleColor: Color { kCircleColors[circleColorIndex] }

    // MARK: Game Actions

    func startGame() {
        score = 0
        circleRadius = maxCircleRadius
        circleColorIndex = Int.random(in: 0..<kCircleColors.count)
        timeRemaining = selectedInterval
        placeCircle(animated: false)
        gameState = .playing
        startCountdown()
    }

    func placeCircle(animated: Bool = true) {
        let pad = circleRadius + 20
        let topPad: CGFloat = 150   // clear HUD
        let botPad: CGFloat = 50

        guard screenSize.width > 0, screenSize.height > 0 else { return }

        let minX = pad
        let maxX = max(minX + 1, screenSize.width - pad)
        let minY = topPad + pad
        let maxY = max(minY + 1, screenSize.height - botPad - pad)

        let newPos = CGPoint(
            x: CGFloat.random(in: minX...maxX),
            y: CGFloat.random(in: minY...maxY)
        )

        if animated {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                circlePosition = newPos
            }
        } else {
            circlePosition = newPos
        }
    }

    func handleCircleTap() {
        score += 1

        let newRadius = max(minCircleRadius, circleRadius - 4)
        var newIdx = circleColorIndex
        if kCircleColors.count > 1 {
            while newIdx == circleColorIndex {
                newIdx = Int.random(in: 0..<kCircleColors.count)
            }
        }
        withAnimation(.easeInOut(duration: 0.15)) {
            circleRadius = newRadius
            circleColorIndex = newIdx
        }

        timeRemaining = selectedInterval
        placeCircle()
    }

    private func startCountdown() {
        gameTimer?.invalidate()
        gameTimer = Timer.scheduledTimer(withTimeInterval: timerTickInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.timeRemaining = max(0, self.timeRemaining - self.timerTickInterval)
            if self.timeRemaining <= 0 {
                self.endGame()
            }
        }
    }

    func endGame() {
        gameTimer?.invalidate()
        gameTimer = nil
        withAnimation(.easeInOut(duration: 0.4)) {
            gameState = .gameOver
        }
    }

    func resetToStart() {
        gameTimer?.invalidate()
        gameTimer = nil
        withAnimation(.easeInOut(duration: 0.3)) {
            gameState = .start
        }
    }
}

// MARK: - ContentView

struct ContentView: View {
    @State private var vm = GameViewModel()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                switch vm.gameState {
                case .start:
                    StartView(vm: vm)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.96)),
                            removal: .opacity.combined(with: .scale(scale: 1.04))
                        ))
                case .playing:
                    GameView(vm: vm)
                        .transition(.opacity)
                case .gameOver:
                    GameOverView(vm: vm)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.96)),
                            removal: .opacity
                        ))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: vm.gameState)
            .onAppear { vm.screenSize = geo.size }
            .onChange(of: geo.size) { _, newSize in
                vm.screenSize = newSize
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Start View

struct StartView: View {
    var vm: GameViewModel

    private let intervals: [(value: Double, label: String)] = [
        (2.0, "Fast"),
        (3.0, "Normal"),
        (5.0, "Easy"),
    ]

    var body: some View {
        ZStack {
            // Deep space background
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.04, blue: 0.18),
                    Color(red: 0.08, green: 0.02, blue: 0.16),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Decorative ambient circles
            ForEach(0..<5, id: \.self) { i in
                let sizes: [CGFloat] = [220, 160, 300, 130, 190]
                let xOffsets: [CGFloat] = [-130, 140, 60, -50, 160]
                let yOffsets: [CGFloat] = [-220, -100, 180, 260, -320]
                Circle()
                    .fill(Color.white.opacity(0.025))
                    .frame(width: sizes[i])
                    .offset(x: xOffsets[i], y: yOffsets[i])
            }

            VStack(spacing: 0) {
                Spacer()

                // Title
                VStack(spacing: 4) {
                    Text("SPEEDY")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .tracking(10)
                        .foregroundStyle(.white.opacity(0.55))

                    Text("Circles")
                        .font(.system(size: 74, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.25, green: 0.75, blue: 1.0),
                                    Color(red: 0.5, green: 0.3, blue: 1.0),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color(red: 0.3, green: 0.5, blue: 1).opacity(0.6), radius: 24)
                }

                // Color dots
                HStack(spacing: 10) {
                    ForEach(
                        [Color.red, Color.orange, Color(red: 0.95, green: 0.8, blue: 0.1),
                         Color.green, Color.cyan, Color.blue, Color.purple],
                        id: \.self
                    ) { c in
                        Circle()
                            .fill(c)
                            .frame(width: 13, height: 13)
                            .shadow(color: c.opacity(0.7), radius: 5)
                    }
                }
                .padding(.top, 22)

                Spacer()

                // Instructions
                VStack(spacing: 6) {
                    Label("Tap circles before time runs out", systemImage: "hand.tap.fill")
                    Label("Miss once and it's game over!", systemImage: "xmark.circle")
                }
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.38))
                .padding(.bottom, 32)

                // Interval selector
                VStack(spacing: 14) {
                    Text("TAP INTERVAL")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(3)
                        .foregroundStyle(.white.opacity(0.45))

                    HStack(spacing: 12) {
                        ForEach(intervals, id: \.value) { item in
                            IntervalButton(
                                seconds: item.value,
                                label: item.label,
                                isSelected: vm.selectedInterval == item.value
                            ) {
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.7)) {
                                    vm.selectedInterval = item.value
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 32)

                // Start button
                Button(action: vm.startGame) {
                    HStack(spacing: 10) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 17, weight: .bold))
                        Text("Start Game")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.18, green: 0.58, blue: 1.0),
                                Color(red: 0.48, green: 0.18, blue: 0.92),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(color: Color(red: 0.3, green: 0.4, blue: 0.9).opacity(0.5), radius: 18, x: 0, y: 8)
                }
                .padding(.horizontal, 32)
                .padding(.top, 28)
                .accessibilityIdentifier("startButton")

                Spacer(minLength: 50)
            }
        }
    }
}

// MARK: - Interval Button

struct IntervalButton: View {
    let seconds: Double
    let label: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 5) {
                Text(String(format: "%.0fs", seconds))
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(isSelected ? Color.black : Color.white)
                Text(label)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(isSelected ? Color.black.opacity(0.6) : Color.white.opacity(0.4))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.cyan : Color.white.opacity(0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? Color.cyan : Color.white.opacity(0.12),
                                lineWidth: 1.5
                            )
                    )
            )
            .shadow(color: isSelected ? Color.cyan.opacity(0.5) : .clear, radius: 12)
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("interval_\(Int(seconds))s")
    }
}

// MARK: - Game View

struct GameView: View {
    var vm: GameViewModel

    var timerProgress: Double {
        guard vm.selectedInterval > 0 else { return 0 }
        return max(0, min(1, vm.timeRemaining / vm.selectedInterval))
    }

    var timerColor: Color {
        if timerProgress > 0.5 { return Color(red: 0.2, green: 0.88, blue: 0.5) }
        if timerProgress > 0.25 { return Color(red: 1.0, green: 0.65, blue: 0.1) }
        return Color(red: 1.0, green: 0.25, blue: 0.25)
    }

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.06, blue: 0.11)
                .ignoresSafeArea()

            // HUD
            VStack(spacing: 0) {
                // Spacer for status bar
                Color.clear.frame(height: 55)

                // Score + Timer
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("SCORE")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .tracking(2)
                            .foregroundStyle(.white.opacity(0.4))
                        Text("\(vm.score)")
                            .font(.system(size: 40, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.2), value: vm.score)
                    }
                    .accessibilityIdentifier("scoreLabel")

                    Spacer()

                    VStack(alignment: .trailing, spacing: 1) {
                        Text("TIME")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .tracking(2)
                            .foregroundStyle(.white.opacity(0.4))
                        Text(String(format: "%.1f", max(0, vm.timeRemaining)))
                            .font(.system(size: 40, weight: .black, design: .monospaced))
                            .foregroundStyle(timerColor)
                            .animation(.easeInOut(duration: 0.1), value: timerColor == Color(red: 1, green: 0.25, blue: 0.25))
                    }
                    .accessibilityIdentifier("timerLabel")
                }
                .padding(.horizontal, 26)

                // Timer bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 6)
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [timerColor.opacity(0.7), timerColor],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(0, geo.size.width * timerProgress), height: 6)
                            .animation(.linear(duration: vm.timerTickInterval), value: timerProgress)
                    }
                }
                .frame(height: 6)
                .padding(.horizontal, 26)
                .padding(.top, 10)

                Spacer()
            }
            .zIndex(1)

            // The circle
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(stops: [
                            .init(color: vm.circleColor.opacity(0.9), location: 0),
                            .init(color: vm.circleColor, location: 0.65),
                            .init(color: vm.circleColor.opacity(0.75), location: 1.0),
                        ]),
                        center: UnitPoint(x: 0.35, y: 0.28),
                        startRadius: 0,
                        endRadius: vm.circleRadius * 1.6
                    )
                )
                .frame(width: vm.circleRadius * 2, height: vm.circleRadius * 2)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.22), lineWidth: 1.5)
                )
                .overlay(
                    // Specular highlight
                    Ellipse()
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.35), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: vm.circleRadius * 0.55, height: vm.circleRadius * 0.32)
                        .offset(x: -vm.circleRadius * 0.12, y: -vm.circleRadius * 0.28)
                        .clipped()
                        .allowsHitTesting(false)
                )
                .shadow(color: vm.circleColor.opacity(0.55), radius: 22)
                .shadow(color: vm.circleColor.opacity(0.28), radius: 40)
                .position(vm.circlePosition)
                .onTapGesture { vm.handleCircleTap() }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: vm.circleRadius)
                .zIndex(0)
                .accessibilityIdentifier("gameCircle")
        }
    }
}

// MARK: - Game Over View

struct GameOverView: View {
    var vm: GameViewModel

    var ratingInfo: (text: String, color: Color) {
        switch vm.score {
        case 0:       return ("Keep practicing!", .gray)
        case 1...4:   return ("Nice try!", .mint)
        case 5...9:   return ("Good job!", Color(red: 0.4, green: 0.85, blue: 0.45))
        case 10...19: return ("Great reflexes!", .orange)
        case 20...29: return ("Impressive!", Color(red: 1, green: 0.6, blue: 0.2))
        default:      return ("Outstanding!", Color(red: 1, green: 0.82, blue: 0.2))
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.04, blue: 0.16),
                    Color(red: 0.09, green: 0.03, blue: 0.13),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // "Time's Up!"
                VStack(spacing: 6) {
                    Text("TIME'S UP!")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .tracking(5)
                        .foregroundStyle(.white.opacity(0.45))
                    Text(ratingInfo.text)
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(ratingInfo.color)
                        .shadow(color: ratingInfo.color.opacity(0.45), radius: 12)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                // Score card
                VStack(spacing: 6) {
                    Text("\(vm.score)")
                        .font(.system(size: 104, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.88, blue: 0.22),
                                    Color(red: 1.0, green: 0.48, blue: 0.08),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Color(red: 1, green: 0.55, blue: 0.1).opacity(0.4), radius: 22)
                        .contentTransition(.numericText())

                    Text(vm.score == 1 ? "circle tapped" : "circles tapped")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.38))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 36)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(.white.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(.white.opacity(0.08), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 32)
                .accessibilityIdentifier("finalScoreView")

                Spacer()

                // Play again button
                Button(action: vm.resetToStart) {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 16, weight: .bold))
                        Text("Play Again")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.38, blue: 0.1),
                                Color(red: 0.9, green: 0.08, blue: 0.28),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(color: Color(red: 1, green: 0.2, blue: 0.1).opacity(0.45), radius: 18, x: 0, y: 8)
                }
                .padding(.horizontal, 32)
                .accessibilityIdentifier("retryButton")

                Spacer(minLength: 50)
            }
        }
    }
}

#Preview {
    ContentView()
}
