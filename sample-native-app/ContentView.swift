//
//  ContentView.swift
//  sample-native-app
//
//  Created by Muvaffak on 1/16/26.
//

import Foundation
import SwiftUI

struct ContentView: View {
    private enum GamePhase {
        case start
        case playing
        case gameOver
    }

    private let intervalOptions: [TimeInterval] = [2, 3, 5]
    private let startingCircleDiameter: CGFloat = 132
    private let minimumCircleDiameter: CGFloat = 44
    private let circleShrinkAmount: CGFloat = 8
    private let timerTickInterval: TimeInterval = 0.02
    private let circlePalette: [Color] = [
        .pink,
        .orange,
        .yellow,
        .green,
        .mint,
        .cyan,
        .blue,
        .purple
    ]

    @State private var selectedInterval: TimeInterval = 3
    @State private var phase: GamePhase = .start
    @State private var score = 0
    @State private var timeRemaining: TimeInterval = 3
    @State private var circleDiameter: CGFloat = 132
    @State private var circleCenter = CGPoint.zero
    @State private var circleColorIndex = 0
    @State private var playAreaSize = CGSize.zero
    @State private var roundStartDate: Date?
    @State private var countdownTimer: Timer?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.07, green: 0.09, blue: 0.17),
                    Color(red: 0.11, green: 0.15, blue: 0.31),
                    Color(red: 0.17, green: 0.10, blue: 0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Group {
                switch phase {
                case .start:
                    startScreen
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                case .playing:
                    gameplayScreen
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                case .gameOver:
                    gameOverScreen
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }
            }
            .animation(.spring(response: 0.45, dampingFraction: 0.86), value: phase)
        }
        .preferredColorScheme(.dark)
        .onDisappear(perform: stopTimer)
    }

    private var startScreen: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 24)

            VStack(spacing: 16) {
                Image(systemName: "circle.grid.cross.fill")
                    .font(.system(size: 62, weight: .semibold))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .cyan, .pink)
                    .shadow(color: .cyan.opacity(0.35), radius: 18)

                VStack(spacing: 10) {
                    Text("Speedy Circles")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)

                    Text("Choose your countdown, then tap each circle before time runs out.")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.72))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }
            }

            VStack(spacing: 16) {
                Text("Round Timer")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.65))
                    .textCase(.uppercase)
                    .tracking(1.2)

                HStack(spacing: 10) {
                    ForEach(intervalOptions, id: \.self) { interval in
                        intervalButton(for: interval)
                    }
                }
            }
            .padding(20)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))

            Button(action: startGame) {
                Label("Start", systemImage: "play.fill")
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(colors: [.cyan, .blue, .purple], startPoint: .leading, endPoint: .trailing),
                        in: RoundedRectangle(cornerRadius: 22, style: .continuous)
                    )
                    .shadow(color: .cyan.opacity(0.32), radius: 22, y: 10)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("startButton")
            .accessibilityLabel("Start")

            Spacer(minLength: 24)
        }
        .padding(.horizontal, 24)
    }

    private func intervalButton(for interval: TimeInterval) -> some View {
        let isSelected = selectedInterval == interval

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                selectedInterval = interval
                timeRemaining = interval
            }
        } label: {
            Text(intervalLabel(interval))
                .font(.headline.weight(.bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(isSelected ? Color(red: 0.06, green: 0.08, blue: 0.16) : .white)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(isSelected ? .white : .white.opacity(0.12))
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.white.opacity(isSelected ? 0 : 0.14), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("interval\(Int(interval))Button")
        .accessibilityLabel(intervalLabel(interval))
    }

    private var gameplayScreen: some View {
        VStack(spacing: 18) {
            scoreboard
                .padding(.horizontal, 18)
                .padding(.top, 10)

            GeometryReader { proxy in
                ZStack {
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .fill(.white.opacity(0.07))
                        .overlay {
                            RoundedRectangle(cornerRadius: 34, style: .continuous)
                                .stroke(.white.opacity(0.12), lineWidth: 1)
                        }
                        .padding(.horizontal, 18)
                        .padding(.bottom, 18)

                    Circle()
                        .fill(circleColor.gradient)
                        .frame(width: circleDiameter, height: circleDiameter)
                        .overlay {
                            Circle()
                                .stroke(.white.opacity(0.62), lineWidth: 3)
                        }
                        .shadow(color: circleColor.opacity(0.45), radius: 24, y: 12)
                        .opacity(circleCenter == .zero ? 0 : 1)
                        .contentShape(Circle())
                        .onTapGesture(perform: circleTapped)
                        .accessibilityLabel("Target circle")
                        .accessibilityIdentifier("targetCircle")
                        .accessibilityAddTraits(.isButton)
                        .position(circleCenter)
                }
                .onAppear {
                    preparePlayArea(proxy.size)
                }
                .onChange(of: proxy.size) { _, newSize in
                    preparePlayArea(newSize)
                }
            }
        }
        .padding(.bottom, 4)
    }

    private var scoreboard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                statPill(title: "Score", value: "\(score)", icon: "star.fill")
                    .accessibilityIdentifier("scoreLabel")

                statPill(title: "Time", value: formattedTimeRemaining, icon: "timer")
                    .accessibilityIdentifier("timeLabel")
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.12))

                    Capsule()
                        .fill(LinearGradient(colors: [.green, .yellow, .orange, .pink], startPoint: .leading, endPoint: .trailing))
                        .frame(width: proxy.size.width * timerProgress)
                }
            }
            .frame(height: 8)
            .animation(.linear(duration: timerTickInterval), value: timerProgress)
            .accessibilityLabel("Time remaining progress")
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func statPill(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(.cyan)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.56))
                    .textCase(.uppercase)
                    .tracking(0.9)

                Text(value)
                    .font(.title2.monospacedDigit().bold())
                    .foregroundStyle(.white)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var gameOverScreen: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 28)

            VStack(spacing: 18) {
                Image(systemName: "flag.checkered.circle.fill")
                    .font(.system(size: 70, weight: .semibold))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .pink)
                    .shadow(color: .pink.opacity(0.35), radius: 20)

                VStack(spacing: 8) {
                    Text("Time's Up")
                        .font(.system(size: 42, weight: .bold, design: .rounded))

                    Text("Final Score")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.62))

                    Text("\(score)")
                        .font(.system(size: 86, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                        .accessibilityIdentifier("finalScoreLabel")
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 34)
            .padding(.horizontal, 24)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 34, style: .continuous))

            Button(action: retryGame) {
                Label("Retry", systemImage: "arrow.clockwise")
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .foregroundStyle(Color(red: 0.07, green: 0.09, blue: 0.17))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("retryButton")
            .accessibilityLabel("Retry")

            Spacer(minLength: 28)
        }
        .padding(.horizontal, 24)
    }

    private var formattedTimeRemaining: String {
        String(format: "%.1fs", max(0, timeRemaining))
    }

    private var timerProgress: CGFloat {
        guard selectedInterval > 0 else { return 0 }
        return min(max(timeRemaining / selectedInterval, 0), 1)
    }

    private var circleColor: Color {
        circlePalette[circleColorIndex]
    }

    private func intervalLabel(_ interval: TimeInterval) -> String {
        String(format: "%.1fs", interval)
    }

    private func startGame() {
        stopTimer()
        score = 0
        circleDiameter = startingCircleDiameter
        timeRemaining = selectedInterval
        roundStartDate = nil
        circleCenter = .zero

        withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
            phase = .playing
        }
    }

    private func retryGame() {
        stopTimer()
        timeRemaining = selectedInterval

        withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
            phase = .start
        }
    }

    private func preparePlayArea(_ size: CGSize) {
        playAreaSize = size

        guard phase == .playing else { return }

        if roundStartDate == nil || circleCenter == .zero {
            moveCircle(in: size, resetTimer: true)
            startTimer()
        } else {
            circleCenter = boundedCenter(circleCenter, in: size, diameter: circleDiameter)
        }
    }

    private func circleTapped() {
        guard phase == .playing else { return }

        score += 1
        circleDiameter = max(minimumCircleDiameter, circleDiameter - circleShrinkAmount)
        moveCircle(in: playAreaSize, resetTimer: true)
        startTimer()
    }

    private func moveCircle(in size: CGSize, resetTimer: Bool) {
        guard size.width > 0, size.height > 0 else { return }

        let nextCenter = randomCenter(in: size, diameter: circleDiameter)
        let nextColor = randomColor(excluding: circleColorIndex)

        if resetTimer {
            roundStartDate = Date()
            timeRemaining = selectedInterval
        }

        withAnimation(.spring(response: 0.34, dampingFraction: 0.72)) {
            circleCenter = nextCenter
            circleColorIndex = nextColor
        }
    }

    private func startTimer() {
        guard countdownTimer == nil else { return }

        let timer = Timer(timeInterval: timerTickInterval, repeats: true) { _ in
            updateCountdown()
        }
        countdownTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func stopTimer() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }

    private func updateCountdown() {
        guard phase == .playing, let roundStartDate else { return }

        let elapsed = Date().timeIntervalSince(roundStartDate)
        let remaining = selectedInterval - elapsed
        timeRemaining = max(0, remaining)

        if remaining <= 0 {
            gameFailed()
        }
    }

    private func gameFailed() {
        stopTimer()
        roundStartDate = nil

        withAnimation(.spring(response: 0.44, dampingFraction: 0.86)) {
            phase = .gameOver
        }
    }

    private func randomCenter(in size: CGSize, diameter: CGFloat) -> CGPoint {
        let horizontalInset: CGFloat = 18
        let bottomInset: CGFloat = 18
        let radius = diameter / 2
        let minX = horizontalInset + radius
        let maxX = max(minX, size.width - horizontalInset - radius)
        let minY = radius
        let maxY = max(minY, size.height - bottomInset - radius)

        return CGPoint(
            x: CGFloat.random(in: minX...maxX),
            y: CGFloat.random(in: minY...maxY)
        )
    }

    private func boundedCenter(_ center: CGPoint, in size: CGSize, diameter: CGFloat) -> CGPoint {
        let horizontalInset: CGFloat = 18
        let bottomInset: CGFloat = 18
        let radius = diameter / 2
        let minX = horizontalInset + radius
        let maxX = max(minX, size.width - horizontalInset - radius)
        let minY = radius
        let maxY = max(minY, size.height - bottomInset - radius)

        return CGPoint(
            x: min(max(center.x, minX), maxX),
            y: min(max(center.y, minY), maxY)
        )
    }

    private func randomColor(excluding currentIndex: Int) -> Int {
        let candidates = circlePalette.indices.filter { $0 != currentIndex }
        return candidates.randomElement() ?? 0
    }
}

#Preview {
    ContentView()
}
