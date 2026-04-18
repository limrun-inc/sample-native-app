//
//  ContentView.swift
//  sample-native-app
//
//  Speedy Circles – tap the circle before time runs out!
//

import SwiftUI
import Combine

// MARK: - Game State

enum GamePhase: Equatable {
    case start
    case playing
    case gameOver
}

// MARK: - Game View Model

@MainActor
final class GameViewModel: ObservableObject {

    // Configuration
    @Published var selectedInterval: Double = 3.0
    let intervalOptions: [Double] = [2.0, 3.0, 5.0]

    // Gameplay
    @Published var phase: GamePhase = .start
    @Published var score: Int = 0
    @Published var timeRemaining: Double = 3.0
    @Published var circlePosition: CGPoint = .zero
    @Published var circleRadius: CGFloat = 80
    @Published var circleColor: Color = .blue

    // Animation flag for circle appearance
    @Published var circleOpacity: Double = 0
    @Published var circleScale: CGFloat = 0.1

    private var timer: Timer?
    private var playAreaSize: CGSize = .zero
    private let minRadius: CGFloat = 28
    private let maxRadius: CGFloat = 80
    private let tickInterval: Double = 0.05
    // Generation counter to discard stale async callbacks
    private var tapGeneration: Int = 0
    private var isRepositioning: Bool = false

    private let palette: [Color] = [
        .blue, .red, .orange, .purple, .green, .pink, .cyan, .indigo
    ]

    // MARK: - Public API

    private var needsCirclePlacement: Bool = false

    func setPlayArea(_ size: CGSize) {
        let changed = size != playAreaSize
        playAreaSize = size
        // Place circle and start timer if deferred from startGame()
        if changed && needsCirclePlacement && phase == .playing {
            needsCirclePlacement = false
            placeCircle(animated: true)
            // Timer was paused waiting for layout; start now
            if timer == nil {
                startTimer()
            }
        }
    }

    func startGame() {
        score = 0
        circleRadius = maxRadius
        circleColor = randomColor(excluding: nil)
        isRepositioning = false
        tapGeneration = 0
        circleOpacity = 0
        circleScale = 0.1
        timeRemaining = selectedInterval
        phase = .playing
        if playAreaSize != .zero {
            needsCirclePlacement = false
            placeCircle(animated: true)
            startTimer()
        } else {
            // Defer placement and timer until PlayView reports its size
            needsCirclePlacement = true
        }
    }

    func circleTapped() {
        // Ignore taps during repositioning or when not playing
        guard phase == .playing, !isRepositioning else { return }

        isRepositioning = true
        score += 1

        // Immediately stop the current timer to prevent timeout during repositioning
        stopTimer()

        // Bump generation so any in-flight asyncAfter callbacks are stale
        tapGeneration += 1
        let myGeneration = tapGeneration

        // Shrink the circle (floor at minRadius)
        let newRadius = max(minRadius, circleRadius - 6)
        // Pick a new color, avoiding the current one
        let newColor = randomColor(excluding: circleColor)

        // Animate out, reposition, animate in
        withAnimation(.easeIn(duration: 0.12)) {
            circleOpacity = 0
            circleScale = 0.1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) { [weak self] in
            guard let self,
                  self.phase == .playing,
                  self.tapGeneration == myGeneration else { return }
            self.circleRadius = newRadius
            self.circleColor = newColor
            self.placeCircle(animated: true)
            self.timeRemaining = self.selectedInterval
            self.isRepositioning = false
            // Restart timer for the new circle
            self.startTimer()
        }
    }

    func retry() {
        stopTimer()
        isRepositioning = false
        tapGeneration = 0
        needsCirclePlacement = false
        phase = .start
    }

    // MARK: - Private helpers

    private func placeCircle(animated: Bool) {
        guard playAreaSize != .zero else { return }
        let margin = circleRadius + 16
        let minX = margin
        let maxX = playAreaSize.width - margin
        let minY = margin
        let maxY = playAreaSize.height - margin

        guard maxX > minX, maxY > minY else { return }

        let x = CGFloat.random(in: minX...maxX)
        let y = CGFloat.random(in: minY...maxY)
        circlePosition = CGPoint(x: x, y: y)

        if animated {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                circleOpacity = 1
                circleScale = 1
            }
        } else {
            circleOpacity = 1
            circleScale = 1
        }
    }

    private func randomColor(excluding current: Color?) -> Color {
        var available = palette
        if let current, let idx = available.firstIndex(of: current) {
            available.remove(at: idx)
        }
        return available.randomElement() ?? .blue
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: tickInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.timeRemaining -= self.tickInterval
                if self.timeRemaining <= 0 {
                    self.timeRemaining = 0
                    self.handleTimeout()
                }
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func handleTimeout() {
        stopTimer()
        withAnimation(.easeIn(duration: 0.18)) {
            circleOpacity = 0
            circleScale = 0.1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.phase = .gameOver
        }
    }
}

// MARK: - Root View

struct ContentView: View {
    @StateObject private var vm = GameViewModel()

    var body: some View {
        ZStack {
            if vm.phase == .start {
                StartView(vm: vm)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.97)),
                        removal: .opacity.combined(with: .scale(scale: 1.03))
                    ))
                    .zIndex(1)
            } else if vm.phase == .playing {
                PlayView(vm: vm)
                    .transition(.opacity)
                    .zIndex(2)
            } else {
                GameOverView(vm: vm)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .bottom)),
                        removal: .opacity
                    ))
                    .zIndex(3)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: vm.phase)
    }
}

// MARK: - Start Screen

struct StartView: View {
    @ObservedObject var vm: GameViewModel

    var body: some View {
        ZStack {
            backgroundGradient
            VStack(spacing: 36) {
                Spacer()

                // Title
                VStack(spacing: 8) {
                    Text("Speedy")
                        .font(.system(size: 54, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Circles")
                        .font(.system(size: 54, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)

                // Decorative circles
                decorativeCircles

                // Interval picker
                VStack(spacing: 12) {
                    Text("Time per circle")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.75))
                        .textCase(.uppercase)
                        .tracking(1.2)

                    HStack(spacing: 12) {
                        ForEach(vm.intervalOptions, id: \.self) { interval in
                            IntervalButton(
                                label: String(format: "%.0fs", interval),
                                isSelected: vm.selectedInterval == interval
                            ) {
                                withAnimation(.spring(response: 0.3)) {
                                    vm.selectedInterval = interval
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 32)

                Spacer()

                // Start button
                Button {
                    vm.startGame()
                } label: {
                    Text("Start")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(.white.opacity(0.22))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .stroke(.white.opacity(0.35), lineWidth: 1.5)
                                )
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 32)
                .accessibilityIdentifier("startButton")

                Spacer().frame(height: 36)
            }
        }
        .ignoresSafeArea()
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color(red: 0.25, green: 0.1, blue: 0.7),
                     Color(red: 0.6, green: 0.1, blue: 0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var decorativeCircles: some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.12))
                .frame(width: 120, height: 120)
                .offset(x: -50, y: 10)
            Circle()
                .fill(.white.opacity(0.18))
                .frame(width: 80, height: 80)
                .offset(x: 40, y: -20)
            Circle()
                .fill(.white.opacity(0.10))
                .frame(width: 50, height: 50)
                .offset(x: 10, y: 30)
        }
        .frame(height: 120)
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
                .foregroundStyle(isSelected ? Color(red: 0.25, green: 0.1, blue: 0.7) : .white)
                .frame(minWidth: 72, minHeight: 48)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(isSelected ? .white : .white.opacity(0.18))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(.white.opacity(isSelected ? 0 : 0.35), lineWidth: 1.2)
                )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.06 : 1.0)
        .animation(.spring(response: 0.25), value: isSelected)
    }
}

// MARK: - Play Screen

struct PlayView: View {
    @ObservedObject var vm: GameViewModel

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background
                Color(red: 0.09, green: 0.09, blue: 0.15)
                    .ignoresSafeArea()

                // Circle (behind HUD)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [vm.circleColor.opacity(0.9), vm.circleColor],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: vm.circleRadius
                        )
                    )
                    .frame(width: vm.circleRadius * 2, height: vm.circleRadius * 2)
                    .shadow(color: vm.circleColor.opacity(0.6), radius: 20, x: 0, y: 6)
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.25), lineWidth: 2.5)
                    )
                    .scaleEffect(vm.circleScale)
                    .opacity(vm.circleOpacity)
                    .position(vm.circlePosition)
                    .onTapGesture {
                        vm.circleTapped()
                    }
                    .accessibilityIdentifier("gameCircle")
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: vm.circleRadius)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: vm.circleColor)

                // HUD on top
                VStack {
                    hud(safeArea: geo.safeAreaInsets)
                    Spacer()
                }
            }
            .onAppear {
                vm.setPlayArea(geo.size)
            }
            .onChange(of: geo.size) { _, newSize in
                vm.setPlayArea(newSize)
            }
        }
    }

    @ViewBuilder
    private func hud(safeArea: EdgeInsets) -> some View {
        HStack(alignment: .center) {
            // Score pill
            Label {
                Text("\(vm.score)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
            } icon: {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(.white.opacity(0.12))
                    .overlay(Capsule().stroke(.white.opacity(0.2), lineWidth: 1))
            )
            .accessibilityIdentifier("scoreLabel")

            Spacer()

            // Timer ring
            TimerRing(timeRemaining: vm.timeRemaining, total: vm.selectedInterval)
                .frame(width: 64, height: 64)
        }
        .padding(.horizontal, 20)
        .padding(.top, max(safeArea.top, 16) + 8)
    }
}

struct TimerRing: View {
    let timeRemaining: Double
    let total: Double

    private var progress: Double {
        guard total > 0 else { return 0 }
        return max(0, min(1, timeRemaining / total))
    }

    private var ringColor: Color {
        switch progress {
        case 0.5...: return .green
        case 0.25...: return .orange
        default: return .red
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.12), lineWidth: 5)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    ringColor,
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.05), value: progress)

            Text(timeRemaining > 0 ? String(format: "%.1f", timeRemaining) : "0.0")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .accessibilityIdentifier("timerLabel")
                .contentTransition(.numericText())
        }
    }
}

// MARK: - Game Over Screen

struct GameOverView: View {
    @ObservedObject var vm: GameViewModel
    @State private var pulsing = false

    var body: some View {
        ZStack {
            backgroundGradient

            VStack(spacing: 40) {
                Spacer()

                // Failure icon
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.12))
                        .frame(width: 110, height: 110)
                        .scaleEffect(pulsing ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulsing)

                    Image(systemName: "timer")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .onAppear { pulsing = true }

                // Title
                VStack(spacing: 6) {
                    Text("Time's Up!")
                        .font(.system(size: 42, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Better luck next time")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.white.opacity(0.65))
                }

                // Score card
                VStack(spacing: 6) {
                    Text("Your Score")
                        .font(.system(.callout, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.65))
                        .textCase(.uppercase)
                        .tracking(1.2)

                    Text("\(vm.score)")
                        .font(.system(size: 80, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .accessibilityIdentifier("finalScoreLabel")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.white.opacity(0.14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(.white.opacity(0.25), lineWidth: 1.5)
                        )
                )
                .padding(.horizontal, 32)

                Spacer()

                // Retry button
                Button {
                    vm.retry()
                } label: {
                    Label("Retry", systemImage: "arrow.clockwise")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 0.6, green: 0.1, blue: 0.8))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(.white)
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 32)
                .accessibilityIdentifier("retryButton")

                Spacer().frame(height: 36)
            }
        }
        .ignoresSafeArea()
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color(red: 0.7, green: 0.1, blue: 0.15),
                     Color(red: 0.6, green: 0.1, blue: 0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
