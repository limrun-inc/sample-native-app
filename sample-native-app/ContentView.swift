//
//  ContentView.swift
//  sample-native-app
//

import SwiftUI

// MARK: - Game State

enum GamePhase {
    case start
    case playing
    case gameOver(score: Int)
}

// MARK: - Main ContentView

struct ContentView: View {
    @State private var gamePhase: GamePhase = .start
    @State private var selectedInterval: Double = 3.0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "1a1a2e"), Color(hex: "16213e"), Color(hex: "0f3460")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            switch gamePhase {
            case .start:
                StartView(selectedInterval: $selectedInterval) {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        gamePhase = .playing
                    }
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.95)),
                    removal: .opacity.combined(with: .scale(scale: 1.05))
                ))

            case .playing:
                GameView(interval: selectedInterval) { finalScore in
                    // Persist high score
                    let best = UserDefaults.standard.integer(forKey: "highScore")
                    if finalScore > best {
                        UserDefaults.standard.set(finalScore, forKey: "highScore")
                    }
                    withAnimation(.easeInOut(duration: 0.4)) {
                        gamePhase = .gameOver(score: finalScore)
                    }
                }
                .transition(.opacity)

            case .gameOver(let score):
                GameOverView(
                    score: score,
                    highScore: UserDefaults.standard.integer(forKey: "highScore")
                ) {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        gamePhase = .start
                    }
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.9)),
                    removal: .opacity
                ))
            }
        }
        .animation(.easeInOut(duration: 0.4), value: phaseTag)
    }

    private var phaseTag: Int {
        switch gamePhase {
        case .start: return 0
        case .playing: return 1
        case .gameOver: return 2
        }
    }
}

// MARK: - Start View

struct StartView: View {
    @Binding var selectedInterval: Double
    let onStart: () -> Void

    private let intervals: [Double] = [2.0, 3.0, 5.0]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(hex: "e94560"), Color(hex: "c0392b")],
                                center: .center,
                                startRadius: 0,
                                endRadius: 50
                            )
                        )
                        .frame(width: 100, height: 100)
                        .shadow(color: Color(hex: "e94560").opacity(0.6), radius: 20)

                    Image(systemName: "circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.9))
                }

                Text("Speedy Circles")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("Tap the circle before time runs out!")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            VStack(spacing: 16) {
                Text("Time Interval")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                    .textCase(.uppercase)
                    .tracking(1.5)

                HStack(spacing: 12) {
                    ForEach(intervals, id: \.self) { interval in
                        IntervalButton(
                            interval: interval,
                            isSelected: selectedInterval == interval,
                            onSelect: { selectedInterval = interval }
                        )
                    }
                }
            }
            .padding(.horizontal, 32)

            Spacer()

            Button(action: onStart) {
                HStack(spacing: 10) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 18, weight: .bold))
                    Text("Start Game")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "e94560"), Color(hex: "c0392b")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: Color(hex: "e94560").opacity(0.5), radius: 12, y: 6)
            }
            .accessibilityIdentifier("startButton")
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
    }
}

struct IntervalButton: View {
    let interval: Double
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 4) {
                Text(String(format: "%.0fs", interval))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                Text("interval")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .opacity(0.8)
            }
            .foregroundColor(isSelected ? .white : Color.white.opacity(0.5))
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected
                        ? LinearGradient(
                            colors: [Color(hex: "e94560"), Color(hex: "c0392b")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          )
                        : LinearGradient(
                            colors: [Color.white.opacity(0.08), Color.white.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(
                                isSelected ? Color.clear : Color.white.opacity(0.12),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(
                color: isSelected ? Color(hex: "e94560").opacity(0.4) : .clear,
                radius: 8, y: 4
            )
            .scaleEffect(isSelected ? 1.0 : 0.97)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .accessibilityIdentifier("interval_\(Int(interval))")
    }
}

// MARK: - Game View

struct GameView: View {
    let interval: Double
    let onGameOver: (Int) -> Void

    @State private var score: Int = 0
    @State private var circlePosition: CGPoint = .zero
    @State private var circleSize: CGFloat = 120
    @State private var circleColor: Color = Color(hex: "e94560")
    @State private var timeRemaining: Double = 0
    @State private var gameTimer: Timer? = nil
    @State private var screenSize: CGSize = .zero
    @State private var circleScale: CGFloat = 0.0
    @State private var circleOpacity: Double = 0.0
    @State private var scoreBump: Bool = false
    @State private var isTransitioning: Bool = false

    private let minCircleSize: CGFloat = 44
    private let maxCircleSize: CGFloat = 120
    private let shrinkAmount: CGFloat = 8

    private let circleColors: [Color] = [
        Color(hex: "e94560"), Color(hex: "f39c12"), Color(hex: "2ecc71"),
        Color(hex: "3498db"), Color(hex: "9b59b6"), Color(hex: "e67e22"),
        Color(hex: "1abc9c"), Color(hex: "e91e63"), Color(hex: "ff6b6b"),
        Color(hex: "ffd93d"),
    ]

    var timerProgress: Double {
        guard interval > 0 else { return 0 }
        return max(0, min(1, timeRemaining / interval))
    }

    var timerColor: Color {
        if timerProgress > 0.6 { return Color(hex: "2ecc71") }
        if timerProgress > 0.3 { return Color(hex: "f39c12") }
        return Color(hex: "e94560")
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.clear
                    .contentShape(Rectangle())

                // HUD overlay
                VStack {
                    hudView
                    Spacer()
                }
                .zIndex(10)

                // Circle
                if screenSize != .zero {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [circleColor.opacity(0.85), circleColor],
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: circleSize
                            )
                        )
                        .frame(width: circleSize, height: circleSize)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.35), lineWidth: 2.5)
                        )
                        .shadow(color: circleColor.opacity(0.65), radius: 18)
                        .scaleEffect(circleScale)
                        .opacity(circleOpacity)
                        .position(circlePosition)
                        .onTapGesture {
                            guard !isTransitioning else { return }
                            handleCircleTap()
                        }
                        .accessibilityIdentifier("gameCircle")
                }
            }
            .onAppear {
                screenSize = geo.size
                startNewRound()
            }
            .onChange(of: geo.size) { _, newSize in
                screenSize = newSize
            }
        }
        .ignoresSafeArea()
    }

    private var hudView: some View {
        HStack(alignment: .center) {
            // Score
            VStack(alignment: .leading, spacing: 2) {
                Text("SCORE")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
                    .tracking(1.5)
                Text("\(score)")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .scaleEffect(scoreBump ? 1.3 : 1.0)
                    .animation(.spring(response: 0.2, dampingFraction: 0.45), value: scoreBump)
            }
            .accessibilityIdentifier("scoreLabel")

            Spacer()

            // Timer ring
            VStack(alignment: .trailing, spacing: 2) {
                Text("TIME")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
                    .tracking(1.5)
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.12), lineWidth: 5)
                        .frame(width: 52, height: 52)
                    Circle()
                        .trim(from: 0, to: timerProgress)
                        .stroke(
                            timerColor,
                            style: StrokeStyle(lineWidth: 5, lineCap: .round)
                        )
                        .frame(width: 52, height: 52)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.05), value: timerProgress)
                    Text(String(format: "%.1f", max(0, timeRemaining)))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(timerColor)
                }
            }
            .accessibilityIdentifier("timerDisplay")
        }
        .padding(.horizontal, 24)
        .padding(.top, 56)
        .padding(.bottom, 16)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.45), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func randomColor(excluding current: Color) -> Color {
        var filtered = circleColors.filter { "\($0)" != "\(current)" }
        if filtered.isEmpty { filtered = circleColors }
        return filtered.randomElement() ?? circleColors[0]
    }

    private func randomPosition(for size: CGFloat) -> CGPoint {
        let pad = size / 2 + 20
        let topPad: CGFloat = 130
        let bottomPad: CGFloat = 48
        let xRange = pad...(screenSize.width - pad)
        let yRange = (topPad + pad)...(screenSize.height - bottomPad - pad)
        guard xRange.lowerBound < xRange.upperBound,
              yRange.lowerBound < yRange.upperBound else {
            return CGPoint(x: screenSize.width / 2, y: screenSize.height / 2)
        }
        return CGPoint(
            x: CGFloat.random(in: xRange),
            y: CGFloat.random(in: yRange)
        )
    }

    private func startNewRound() {
        guard screenSize != .zero else { return }
        circleColor = randomColor(excluding: circleColor)
        circlePosition = randomPosition(for: circleSize)
        timeRemaining = interval

        circleScale = 0.2
        circleOpacity = 0
        withAnimation(.spring(response: 0.38, dampingFraction: 0.62)) {
            circleScale = 1.0
            circleOpacity = 1.0
        }
        startCountdown()
    }

    private func startCountdown() {
        gameTimer?.invalidate()
        let tick: Double = 0.05
        gameTimer = Timer.scheduledTimer(withTimeInterval: tick, repeats: true) { t in
            if timeRemaining <= 0 {
                t.invalidate()
                triggerGameOver()
            } else {
                timeRemaining = max(0, timeRemaining - tick)
            }
        }
    }

    private func handleCircleTap() {
        isTransitioning = true
        gameTimer?.invalidate()
        score += 1

        // Animate score bump
        scoreBump = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { scoreBump = false }

        let nextSize = max(minCircleSize, circleSize - shrinkAmount)

        // Pop outward then disappear
        withAnimation(.spring(response: 0.18, dampingFraction: 0.5)) {
            circleScale = 1.35
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.easeIn(duration: 0.14)) {
                circleScale = 0.0
                circleOpacity = 0.0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            circleSize = nextSize
            circleColor = randomColor(excluding: circleColor)
            circlePosition = randomPosition(for: nextSize)
            timeRemaining = interval

            withAnimation(.spring(response: 0.38, dampingFraction: 0.62)) {
                circleScale = 1.0
                circleOpacity = 1.0
            }
            isTransitioning = false
            startCountdown()
        }
    }

    private func triggerGameOver() {
        isTransitioning = true
        withAnimation(.spring(response: 0.28, dampingFraction: 0.5)) {
            circleScale = 1.5
        }
        withAnimation(.easeOut(duration: 0.38).delay(0.08)) {
            circleScale = 0.0
            circleOpacity = 0.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.48) {
            onGameOver(score)
        }
    }
}

// MARK: - Game Over View

struct GameOverView: View {
    let score: Int
    let highScore: Int
    let onRetry: () -> Void

    var isNewHigh: Bool { score > 0 && score >= highScore }

    @State private var appear: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                // Icon with pulse ring
                ZStack {
                    Circle()
                        .stroke(Color(hex: "e94560").opacity(0.2), lineWidth: 2)
                        .frame(width: 120, height: 120)
                        .scaleEffect(appear ? 1.15 : 0.8)
                        .opacity(appear ? 0 : 1)
                        .animation(
                            .easeOut(duration: 1.0).repeatForever(autoreverses: false).delay(0.3),
                            value: appear
                        )

                    Circle()
                        .fill(Color.white.opacity(0.07))
                        .frame(width: 100, height: 100)

                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 58))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "e94560"), Color(hex: "c0392b")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                .scaleEffect(appear ? 1 : 0.4)
                .opacity(appear ? 1 : 0)

                VStack(spacing: 8) {
                    Text("Time's Up!")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    if isNewHigh {
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill")
                                .foregroundColor(Color(hex: "ffd93d"))
                                .font(.system(size: 14))
                            Text("New High Score!")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(Color(hex: "ffd93d"))
                            Image(systemName: "star.fill")
                                .foregroundColor(Color(hex: "ffd93d"))
                                .font(.system(size: 14))
                        }
                    }
                }
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 20)

                // Score card
                HStack(spacing: 0) {
                    VStack(spacing: 6) {
                        Text("SCORE")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))
                            .tracking(1.5)
                        Text("\(score)")
                            .font(.system(size: 54, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)

                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 1, height: 72)

                    VStack(spacing: 6) {
                        Text("BEST")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))
                            .tracking(1.5)
                        Text("\(highScore)")
                            .font(.system(size: 54, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "ffd93d"))
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 28)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22)
                                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 32)
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 32)
            }

            Spacer()

            Button(action: onRetry) {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 18, weight: .bold))
                    Text("Play Again")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "e94560"), Color(hex: "c0392b")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: Color(hex: "e94560").opacity(0.5), radius: 12, y: 6)
            }
            .accessibilityIdentifier("retryButton")
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 40)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.72).delay(0.1)) {
                appear = true
            }
        }
    }
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    ContentView()
}
