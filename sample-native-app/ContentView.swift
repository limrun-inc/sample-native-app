//
//  ContentView.swift
//  sample-native-app
//
//  Created by Muvaffak on 1/16/26.
//

import SwiftUI

struct ContentView: View {
    private enum GamePhase {
        case start
        case playing
        case gameOver
    }

    private let intervalOptions: [Double] = [0.5, 1.0, 2.0, 3.0, 5.0]
    private let colorPalette: [Color] = [
        .pink,
        .blue,
        .orange,
        .green,
        .purple,
        .red,
        .teal,
        .indigo
    ]
    private let gameTimer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()
    private let initialCircleDiameter: CGFloat = 156
    private let minimumCircleDiameter: CGFloat = 72
    private let circleShrinkStep: CGFloat = 12

    @State private var phase: GamePhase = .start
    @State private var selectedInterval: Double = 1.0
    @State private var score = 0
    @State private var finalScore = 0
    @State private var timeRemaining: Double = 1.0
    @State private var circleDiameter: CGFloat = 156
    @State private var circleCenter: CGPoint = .zero
    @State private var circleColorIndex = 0
    @State private var roundDeadline: Date?
    @State private var needsRoundSetup = false

    private var circleColor: Color {
        colorPalette[circleColorIndex]
    }

    private var formattedTimeRemaining: String {
        String(format: "%.2f s", max(timeRemaining, 0))
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.10, blue: 0.24),
                    Color(red: 0.15, green: 0.24, blue: 0.45),
                    Color(red: 0.37, green: 0.16, blue: 0.54)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 240, height: 240)
                .blur(radius: 4)
                .offset(x: 140, y: -240)

            Circle()
                .fill(Color.cyan.opacity(0.12))
                .frame(width: 300, height: 300)
                .blur(radius: 12)
                .offset(x: -150, y: 320)

            switch phase {
            case .start:
                startScreen
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            case .playing:
                gameplayScreen
                    .transition(.opacity.combined(with: .scale(scale: 1.02)))
            case .gameOver:
                gameOverScreen
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.35), value: phase)
        .onReceive(gameTimer) { now in
            updateCountdown(currentDate: now)
        }
    }

    private var startScreen: some View {
        VStack(spacing: 26) {
            VStack(spacing: 12) {
                Image(systemName: "circle.circle.fill")
                    .font(.system(size: 56, weight: .bold))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .cyan)

                Text("Speedy Circles")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Pick a countdown, then tap the target before time runs out.")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.80))
                    .frame(maxWidth: 340)
            }

            VStack(alignment: .leading, spacing: 14) {
                Text("Round Timer")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.72))

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 12)], spacing: 12) {
                    ForEach(intervalOptions, id: \.self) { option in
                        intervalButton(for: option)
                    }
                }
            }

            Button(action: startGame) {
                Label("Start", systemImage: "play.fill")
                    .font(.headline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.cyan, Color.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: .blue.opacity(0.35), radius: 18, y: 10)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("startButton")
        }
        .padding(28)
        .frame(maxWidth: 420)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .strokeBorder(.white.opacity(0.14), lineWidth: 1)
        )
        .padding(24)
        .accessibilityIdentifier("startScreen")
    }

    private var gameplayScreen: some View {
        VStack(spacing: 20) {
            HStack(spacing: 12) {
                statCard(title: "Score", value: "\(score)", icon: "bolt.fill")
                    .accessibilityIdentifier("scoreValue")

                statCard(title: "Time", value: formattedTimeRemaining, icon: "timer")
                    .accessibilityIdentifier("timerValue")
            }

            GeometryReader { proxy in
                ZStack {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(Color.white.opacity(0.08))

                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [circleColor.opacity(0.95), circleColor.opacity(0.65)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Circle()
                                .strokeBorder(.white.opacity(0.35), lineWidth: 2)
                        )
                        .shadow(color: circleColor.opacity(0.55), radius: 24, y: 14)
                        .frame(width: circleDiameter, height: circleDiameter)
                        .position(circleCenter)
                        .opacity(roundDeadline == nil ? 0 : 1)
                        .allowsHitTesting(roundDeadline != nil)
                        .contentShape(Circle())
                        .onTapGesture {
                            handleCircleTap(in: proxy.size)
                        }
                        .accessibilityIdentifier("targetCircle")
                        .accessibilityLabel("Target circle")
                }
                .onAppear {
                    if needsRoundSetup {
                        beginRound(in: proxy.size)
                    } else {
                        clampCircle(to: proxy.size)
                    }
                }
                .onChange(of: proxy.size) { _, newSize in
                    if needsRoundSetup {
                        beginRound(in: newSize)
                    } else {
                        clampCircle(to: newSize)
                    }
                }
            }
            .padding(8)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .accessibilityIdentifier("gameplayScreen")
    }

    private var gameOverScreen: some View {
        VStack(spacing: 22) {
            Image(systemName: "flag.checkered.2.crossed")
                .font(.system(size: 52, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))

            VStack(spacing: 8) {
                Text("Time's Up")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Final Score")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.72))

                Text("\(finalScore)")
                    .font(.system(size: 60, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .accessibilityIdentifier("finalScoreValue")
            }

            Button(action: resetToStart) {
                Label("Retry", systemImage: "arrow.clockwise")
                    .font(.headline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .foregroundStyle(Color(red: 0.14, green: 0.20, blue: 0.42))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("retryButton")
        }
        .padding(28)
        .frame(maxWidth: 400)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .strokeBorder(.white.opacity(0.14), lineWidth: 1)
        )
        .padding(24)
        .accessibilityIdentifier("gameOverScreen")
    }

    private func intervalButton(for option: Double) -> some View {
        let isSelected = option == selectedInterval

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedInterval = option
                timeRemaining = option
            }
        } label: {
            Text(String(format: "%.1f s", option))
                .font(.headline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(isSelected ? Color.white.opacity(0.20) : Color.white.opacity(0.07))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(isSelected ? Color.cyan : Color.white.opacity(0.12), lineWidth: 1.5)
                )
                .foregroundStyle(.white)
                .scaleEffect(isSelected ? 1.03 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("interval-\(String(format: "%.1f", option))")
    }

    private func statCard(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.cyan)
                .frame(width: 34, height: 34)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.62))

                Text(value)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(0.10), lineWidth: 1)
        )
    }

    private func startGame() {
        score = 0
        finalScore = 0
        timeRemaining = selectedInterval
        circleDiameter = initialCircleDiameter
        circleColorIndex = Int.random(in: 0..<colorPalette.count)
        circleCenter = .zero
        roundDeadline = nil
        needsRoundSetup = true

        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            phase = .playing
        }
    }

    private func resetToStart() {
        roundDeadline = nil
        needsRoundSetup = false
        timeRemaining = selectedInterval

        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            phase = .start
        }
    }

    private func beginRound(in size: CGSize) {
        guard phase == .playing, size.width > 0, size.height > 0 else {
            return
        }

        timeRemaining = selectedInterval
        roundDeadline = Date().addingTimeInterval(selectedInterval)
        circleCenter = randomPoint(in: size, diameter: circleDiameter)
        needsRoundSetup = false
    }

    private func handleCircleTap(in size: CGSize) {
        guard phase == .playing else {
            return
        }

        score += 1

        let nextDiameter = max(minimumCircleDiameter, circleDiameter - circleShrinkStep)
        let nextColorIndex = randomColorIndex(excluding: circleColorIndex)

        withAnimation(.spring(response: 0.35, dampingFraction: 0.74)) {
            circleDiameter = nextDiameter
            circleColorIndex = nextColorIndex
            circleCenter = randomPoint(in: size, diameter: nextDiameter)
        }

        roundDeadline = Date().addingTimeInterval(selectedInterval)
        timeRemaining = selectedInterval
    }

    private func updateCountdown(currentDate: Date) {
        guard phase == .playing, let deadline = roundDeadline else {
            return
        }

        let remaining = deadline.timeIntervalSince(currentDate)
        if remaining <= 0 {
            endGame()
        } else {
            timeRemaining = remaining
        }
    }

    private func endGame() {
        finalScore = score
        roundDeadline = nil
        needsRoundSetup = false

        withAnimation(.spring(response: 0.42, dampingFraction: 0.85)) {
            phase = .gameOver
        }
    }

    private func randomColorIndex(excluding currentIndex: Int) -> Int {
        let availableIndices = colorPalette.indices.filter { $0 != currentIndex }
        return availableIndices.randomElement() ?? currentIndex
    }

    private func randomPoint(in size: CGSize, diameter: CGFloat) -> CGPoint {
        let horizontalTravel = max(size.width - diameter, 0)
        let verticalTravel = max(size.height - diameter, 0)
        let radius = diameter / 2

        return CGPoint(
            x: radius + CGFloat.random(in: 0...horizontalTravel),
            y: radius + CGFloat.random(in: 0...verticalTravel)
        )
    }

    private func clampCircle(to size: CGSize) {
        guard phase == .playing, circleCenter != .zero else {
            return
        }

        let horizontalTravel = max(size.width - circleDiameter, 0)
        let verticalTravel = max(size.height - circleDiameter, 0)
        let radius = circleDiameter / 2

        circleCenter = CGPoint(
            x: min(max(circleCenter.x, radius), radius + horizontalTravel),
            y: min(max(circleCenter.y, radius), radius + verticalTravel)
        )
    }
}

#Preview {
    ContentView()
}
