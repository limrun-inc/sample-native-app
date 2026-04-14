//
//  ContentView.swift
//  sample-native-app
//

import SwiftUI
import Combine

// MARK: - Game State

enum GameState {
    case start
    case playing
    case gameOver
}

// MARK: - Game View Model

class GameViewModel: ObservableObject {
    @Published var gameState: GameState = .start
    @Published var score: Int = 0
    @Published var selectedInterval: Double = 3.0
    @Published var timeRemaining: Double = 3.0
    @Published var circlePosition: CGPoint = .zero
    @Published var circleSize: CGFloat = 120
    @Published var circleColor: Color = .blue
    @Published var circleScale: CGFloat = 1.0

    private var timer: Timer?
    private var screenSize: CGSize = .zero

    let minCircleSize: CGFloat = 44
    let maxCircleSize: CGFloat = 120
    let intervals: [Double] = [2.0, 3.0, 5.0]

    private let palette: [Color] = [
        Color(red: 0.98, green: 0.36, blue: 0.35),
        Color(red: 0.20, green: 0.60, blue: 0.86),
        Color(red: 0.18, green: 0.80, blue: 0.44),
        Color(red: 1.00, green: 0.76, blue: 0.03),
        Color(red: 0.61, green: 0.35, blue: 0.71),
        Color(red: 0.99, green: 0.57, blue: 0.13),
        Color(red: 0.09, green: 0.63, blue: 0.52),
        Color(red: 0.94, green: 0.27, blue: 0.57)
    ]

    var progress: Double {
        guard selectedInterval > 0 else { return 0 }
        return timeRemaining / selectedInterval
    }

    func setScreenSize(_ size: CGSize) {
        screenSize = size
    }

    func startGame() {
        score = 0
        circleSize = maxCircleSize
        timeRemaining = selectedInterval
        placeCircle()
        gameState = .playing
        startTimer()
    }

    func tapCircle() {
        guard gameState == .playing else { return }
        score += 1
        let newSize = max(circleSize - 8, minCircleSize)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            circleScale = 1.3
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                self.circleScale = 1.0
            }
        }
        circleSize = newSize
        timeRemaining = selectedInterval
        placeCircle()
    }

    private func placeCircle() {
        let padding = circleSize / 2 + 20
        let safeWidth = screenSize.width - padding * 2
        let safeHeight = screenSize.height - padding * 2 - 160

        guard safeWidth > 0, safeHeight > 0 else { return }

        let x = CGFloat.random(in: padding...(padding + safeWidth))
        let y = CGFloat.random(in: (padding + 80)...(padding + 80 + safeHeight))

        withAnimation(.easeInOut(duration: 0.35)) {
            circlePosition = CGPoint(x: x, y: y)
            circleColor = randomColor()
        }
    }

    private func randomColor() -> Color {
        let candidate = palette.randomElement() ?? .blue
        return candidate == circleColor ? (palette.filter { $0 != circleColor }.randomElement() ?? .blue) : candidate
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.timeRemaining -= 0.05
                if self.timeRemaining <= 0 {
                    self.timeRemaining = 0
                    self.endGame()
                }
            }
        }
    }

    func endGame() {
        timer?.invalidate()
        timer = nil
        withAnimation(.easeInOut(duration: 0.4)) {
            gameState = .gameOver
        }
    }

    func resetToStart() {
        timer?.invalidate()
        timer = nil
        gameState = .start
        score = 0
        circleSize = maxCircleSize
        timeRemaining = selectedInterval
    }
}

// MARK: - Content View

struct ContentView: View {
    @StateObject private var vm = GameViewModel()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()

                switch vm.gameState {
                case .start:
                    StartScreen(vm: vm)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.95)),
                            removal: .opacity.combined(with: .scale(scale: 1.05))
                        ))
                case .playing:
                    GameScreen(vm: vm)
                        .transition(.opacity)
                case .gameOver:
                    GameOverScreen(vm: vm)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.9)),
                            removal: .opacity
                        ))
                }
            }
            .animation(.easeInOut(duration: 0.4), value: vm.gameState)
            .onAppear {
                vm.setScreenSize(geo.size)
            }
            .onChange(of: geo.size) { _, newSize in
                vm.setScreenSize(newSize)
            }
        }
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.07, green: 0.07, blue: 0.12),
                Color(red: 0.10, green: 0.10, blue: 0.20)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Start Screen

struct StartScreen: View {
    @ObservedObject var vm: GameViewModel
    @State private var animateLogo = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.20, green: 0.60, blue: 0.86).opacity(0.25))
                        .frame(width: 110, height: 110)
                        .scaleEffect(animateLogo ? 1.12 : 1.0)
                        .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: animateLogo)

                    Circle()
                        .fill(Color(red: 0.20, green: 0.60, blue: 0.86))
                        .frame(width: 72, height: 72)

                    Image(systemName: "bolt.fill")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.white)
                }

                Text("Speedy Circles")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("Tap the circle before time runs out!")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .onAppear { animateLogo = true }

            Spacer().frame(height: 52)

            // Interval Picker
            VStack(spacing: 12) {
                Text("COUNTDOWN DURATION")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.45))
                    .tracking(1.5)

                HStack(spacing: 12) {
                    ForEach(vm.intervals, id: \.self) { interval in
                        IntervalButton(
                            label: String(format: "%.0fs", interval),
                            isSelected: vm.selectedInterval == interval
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                vm.selectedInterval = interval
                            }
                        }
                    }
                }
            }

            Spacer().frame(height: 44)

            // Start Button
            Button(action: {
                withAnimation {
                    vm.startGame()
                }
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 18, weight: .bold))
                    Text("Start Game")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.20, green: 0.60, blue: 0.86), Color(red: 0.09, green: 0.45, blue: 0.72)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Color(red: 0.20, green: 0.60, blue: 0.86).opacity(0.5), radius: 16, y: 6)
            }
            .padding(.horizontal, 36)
            .accessibilityIdentifier("startButton")

            Spacer()
        }
    }
}

// MARK: - Interval Button

struct IntervalButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .frame(width: 72, height: 52)
                .background(
                    isSelected
                        ? AnyView(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(red: 0.20, green: 0.60, blue: 0.86))
                                .shadow(color: Color(red: 0.20, green: 0.60, blue: 0.86).opacity(0.5), radius: 8, y: 3)
                          )
                        : AnyView(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.white.opacity(0.10))
                          )
                )
                .foregroundColor(isSelected ? .white : .white.opacity(0.55))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(isSelected ? Color.clear : Color.white.opacity(0.12), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.0 : 0.97)
    }
}

// MARK: - Game Screen

struct GameScreen: View {
    @ObservedObject var vm: GameViewModel

    var body: some View {
        ZStack(alignment: .top) {
            // HUD
            VStack(spacing: 0) {
                HUD(vm: vm)
                    .padding(.top, 60)
                    .padding(.horizontal, 24)
                Spacer()
            }

            // Circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [vm.circleColor.opacity(0.95), vm.circleColor],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: vm.circleSize
                    )
                )
                .frame(width: vm.circleSize, height: vm.circleSize)
                .shadow(color: vm.circleColor.opacity(0.55), radius: 18, y: 6)
                .scaleEffect(vm.circleScale)
                .position(vm.circlePosition)
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: vm.circlePosition)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: vm.circleScale)
                .onTapGesture {
                    vm.tapCircle()
                }
                .accessibilityIdentifier("gameCircle")
        }
    }
}

// MARK: - HUD

struct HUD: View {
    @ObservedObject var vm: GameViewModel

    private var timerColor: Color {
        if vm.progress > 0.5 { return Color(red: 0.18, green: 0.80, blue: 0.44) }
        if vm.progress > 0.25 { return Color(red: 1.00, green: 0.76, blue: 0.03) }
        return Color(red: 0.98, green: 0.36, blue: 0.35)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            // Score
            VStack(alignment: .leading, spacing: 2) {
                Text("SCORE")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.45))
                    .tracking(1.5)
                Text("\(vm.score)")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3), value: vm.score)
                    .accessibilityIdentifier("scoreLabel")
            }

            Spacer()

            // Timer ring
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.12), lineWidth: 5)
                        .frame(width: 58, height: 58)

                    Circle()
                        .trim(from: 0, to: vm.progress)
                        .stroke(timerColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .frame(width: 58, height: 58)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.05), value: vm.progress)

                    Text(String(format: "%.1f", max(vm.timeRemaining, 0)))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(timerColor)
                        .animation(.none, value: vm.timeRemaining)
                        .accessibilityIdentifier("timerLabel")
                }

                Text("TIME")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.45))
                    .tracking(1.5)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.25), radius: 12, y: 4)
        )
    }
}

// MARK: - Game Over Screen

struct GameOverScreen: View {
    @ObservedObject var vm: GameViewModel
    @State private var appear = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color(red: 0.98, green: 0.36, blue: 0.35).opacity(0.18))
                        .frame(width: 100, height: 100)

                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(Color(red: 0.98, green: 0.36, blue: 0.35))
                }
                .scaleEffect(appear ? 1.0 : 0.4)
                .opacity(appear ? 1 : 0)

                VStack(spacing: 8) {
                    Text("Time's Up!")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("You didn't tap in time")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.55))
                }
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 20)

                // Score card
                VStack(spacing: 6) {
                    Text("FINAL SCORE")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.45))
                        .tracking(1.5)

                    Text("\(vm.score)")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text(scoreMessage(vm.score))
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 28)
                .padding(.horizontal, 40)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .padding(.horizontal, 28)
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 30)
                .accessibilityIdentifier("finalScoreCard")
            }

            Spacer().frame(height: 48)

            // Retry Button
            Button(action: {
                withAnimation {
                    vm.resetToStart()
                }
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 17, weight: .bold))
                    Text("Retry")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.98, green: 0.36, blue: 0.35), Color(red: 0.85, green: 0.20, blue: 0.20)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Color(red: 0.98, green: 0.36, blue: 0.35).opacity(0.45), radius: 14, y: 6)
            }
            .padding(.horizontal, 36)
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 20)
            .accessibilityIdentifier("retryButton")

            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.75).delay(0.05)) {
                appear = true
            }
        }
        .onDisappear {
            appear = false
        }
    }

    private func scoreMessage(_ score: Int) -> String {
        switch score {
        case 0: return "Give it another shot!"
        case 1...4: return "Nice start! Keep going."
        case 5...9: return "Great reflexes!"
        case 10...19: return "Impressive speed!"
        default: return "You're a circle master!"
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
