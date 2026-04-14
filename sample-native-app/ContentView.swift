//
//  ContentView.swift
//  sample-native-app
//
//  Created by Muvaffak on 1/16/26.
//

import SwiftUI

struct ContentView: View {
    private enum GamePhase {
        case menu
        case playing
        case gameOver
    }

    private let intervalOptions: [Double] = [2.0, 3.0, 5.0]
    private let targetPalette: [CircleTheme] = [
        .init(base: .pink, highlight: .red),
        .init(base: .orange, highlight: .yellow),
        .init(base: .mint, highlight: .cyan),
        .init(base: .blue, highlight: .indigo),
        .init(base: .purple, highlight: .pink),
        .init(base: .indigo, highlight: .blue),
        .init(base: .teal, highlight: .mint)
    ]
    private let maximumCircleDiameter: CGFloat = 156
    private let minimumCircleDiameter: CGFloat = 76
    private let shrinkStep: CGFloat = 12
    private let playfieldPadding: CGFloat = 28
    private let timerCadence: TimeInterval = 0.05

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var phase: GamePhase = .menu
    @State private var selectedInterval: Double = 3.0
    @State private var score: Int = 0
    @State private var finalScore: Int = 0
    @State private var remainingTime: Double = 3.0
    @State private var roundDeadline: Date = .now
    @State private var playfieldSize: CGSize = .zero
    @State private var circleDiameter: CGFloat = 156
    @State private var circleCenter: CGPoint = .zero
    @State private var circleTheme: CircleTheme = .init(base: .pink, highlight: .red)
    @State private var gameTimer: Timer?

    private var timeRemainingText: String {
        remainingTime.formatted(.number.precision(.fractionLength(1)))
    }

    private var progressValue: Double {
        guard selectedInterval > 0 else { return 0 }
        return min(max(remainingTime / selectedInterval, 0), 1)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.12, blue: 0.24),
                    Color(red: 0.20, green: 0.12, blue: 0.35),
                    Color(red: 0.47, green: 0.16, blue: 0.33)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                switch phase {
                case .menu:
                    startScreen
                        .transition(screenTransition)
                case .playing, .gameOver:
                    gameplayScreen
                        .transition(screenTransition)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .onDisappear {
            stopTimer()
        }
    }

    private var startScreen: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 12)

            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.12))
                        .frame(width: 88, height: 88)
                        .overlay(
                            Circle()
                                .stroke(.white.opacity(0.18), lineWidth: 1)
                        )

                    Image(systemName: "scope")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(spacing: 8) {
                    Text("Speedy Circles")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Pick a pace, chase the target, and keep the streak alive.")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.78))
                        .multilineTextAlignment(.center)
                }
            }

            VStack(alignment: .leading, spacing: 16) {
                Text("Round timer")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.92))

                HStack(spacing: 12) {
                    ForEach(intervalOptions, id: \.self) { option in
                        Button {
                            animateSelection {
                                selectedInterval = option
                            }
                        } label: {
                            Text("\(option.formatted(.number.precision(.fractionLength(1))))s")
                                .font(.headline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(selectedInterval == option ? .white : .white.opacity(0.10))
                                )
                                .foregroundStyle(selectedInterval == option ? Color(red: 0.17, green: 0.12, blue: 0.32) : .white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(.white.opacity(selectedInterval == option ? 0 : 0.22), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("interval_\(Int(option * 10))")
                    }
                }
            }
            .padding(24)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(.white.opacity(0.10), lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: 14) {
                FeatureRow(icon: "timer", text: "Countdown resets after every successful tap.")
                FeatureRow(icon: "circle.dashed.inset.filled", text: "Targets shrink over time, but never below the minimum size.")
                FeatureRow(icon: "sparkles", text: "Smooth movement and color changes keep each round lively.")
            }
            .padding(24)
            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 30, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            )

            Spacer()

            Button {
                beginGame()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "play.fill")
                    Text("Start")
                }
                .font(.title3.weight(.bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(.white)
                )
                .foregroundStyle(Color(red: 0.18, green: 0.14, blue: 0.34))
                .shadow(color: .black.opacity(0.18), radius: 18, y: 10)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("startButton")
        }
    }

    private var gameplayScreen: some View {
        VStack(spacing: 20) {
            header

            GeometryReader { geometry in
                ZStack {
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .fill(.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 34, style: .continuous)
                                .stroke(.white.opacity(0.10), lineWidth: 1)
                        )

                    Circle()
                        .stroke(.white.opacity(0.06), lineWidth: 1)
                        .frame(width: geometry.size.width * 0.72)

                    Circle()
                        .stroke(.white.opacity(0.04), lineWidth: 1)
                        .frame(width: geometry.size.width * 0.44)

                    if circleCenter != .zero {
                        Button {
                            handleTargetTap()
                        } label: {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            circleTheme.highlight.opacity(0.94),
                                            circleTheme.base.opacity(0.72)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    Circle()
                                        .stroke(.white.opacity(0.24), lineWidth: 2)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(.white.opacity(0.14), lineWidth: 6)
                                        .blur(radius: 4)
                                )
                                .shadow(color: circleTheme.base.opacity(0.45), radius: 24, y: 14)
                                .frame(width: circleDiameter, height: circleDiameter)
                        }
                        .buttonStyle(.plain)
                        .position(circleCenter)
                        .accessibilityIdentifier("targetCircle")
                        .accessibilityLabel("Target circle")
                        .animation(activeAnimation, value: circleCenter)
                        .animation(activeAnimation, value: circleDiameter)
                        .animation(activeAnimation, value: circleTheme.id)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
                .onAppear {
                    configurePlayfield(with: geometry.size)
                }
                .onChange(of: geometry.size) { newSize in
                    configurePlayfield(with: newSize, refreshRound: false)
                }
            }
            .overlay(alignment: .center) {
                if phase == .gameOver {
                    gameOverCard
                        .padding(24)
                        .transition(screenTransition)
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 16) {
            HStack(spacing: 14) {
                StatCard(title: "Score", value: "\(score)")
                    .accessibilityIdentifier("scoreCard")

                StatCard(title: "Time", value: "\(timeRemainingText)s")
                    .accessibilityIdentifier("timeCard")
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Remaining time")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.84))

                    Spacer()

                    Text("\(timeRemainingText)s")
                        .font(.subheadline.monospacedDigit().weight(.semibold))
                        .foregroundStyle(.white)
                        .accessibilityIdentifier("remainingTimeLabel")
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.white.opacity(0.12))

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.mint, .cyan, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progressValue)
                    }
                }
                .frame(height: 12)
                .animation(.linear(duration: timerCadence), value: progressValue)
            }
            .padding(20)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            )
        }
        .foregroundStyle(.white)
    }

    private var gameOverCard: some View {
        VStack(spacing: 18) {
            Image(systemName: "flag.checkered.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(.white)

            VStack(spacing: 8) {
                Text("Time’s up")
                    .font(.title.weight(.bold))
                    .foregroundStyle(.white)

                Text("Final score: \(finalScore)")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.88))
                    .accessibilityIdentifier("finalScoreLabel")
            }

            Text("Choose a new interval and jump right back in.")
                .font(.body)
                .foregroundStyle(.white.opacity(0.72))
                .multilineTextAlignment(.center)

            Button {
                returnToMenu()
            } label: {
                Text("Retry")
                    .font(.headline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(.white)
                    )
                    .foregroundStyle(Color(red: 0.18, green: 0.14, blue: 0.34))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("retryButton")
        }
        .padding(26)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(.white.opacity(0.14), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.24), radius: 26, y: 14)
    }

    private var screenTransition: AnyTransition {
        reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.98))
    }

    private var activeAnimation: Animation? {
        reduceMotion ? nil : .spring(response: 0.38, dampingFraction: 0.76)
    }

    private func beginGame() {
        stopTimer()
        score = 0
        finalScore = 0
        remainingTime = selectedInterval
        roundDeadline = Date().addingTimeInterval(selectedInterval)
        circleDiameter = maximumCircleDiameter
        circleTheme = randomTheme(excluding: nil)
        circleCenter = .zero

        animateSelection {
            phase = .playing
        }
    }

    private func configurePlayfield(with size: CGSize, refreshRound: Bool = true) {
        guard size.width > 0, size.height > 0 else { return }
        playfieldSize = size

        if circleCenter == .zero || refreshRound {
            resetRound(in: size, preserveSize: !refreshRound)
        } else {
            circleCenter = clampedCenter(for: circleCenter, in: size, diameter: circleDiameter)
        }

        if phase == .playing {
            startTimer()
        }
    }

    private func resetRound(in size: CGSize, preserveSize: Bool) {
        let nextDiameter = preserveSize ? circleDiameter : maximumCircleDiameter
        circleDiameter = max(minimumCircleDiameter, nextDiameter)
        circleTheme = randomTheme(excluding: circleTheme)
        circleCenter = randomCenter(in: size, diameter: circleDiameter)
        remainingTime = selectedInterval
        roundDeadline = Date().addingTimeInterval(selectedInterval)
    }

    private func handleTargetTap() {
        guard phase == .playing else { return }

        if roundDeadline.timeIntervalSinceNow <= 0 {
            endGame()
            return
        }

        score += 1
        let nextDiameter = max(minimumCircleDiameter, circleDiameter - shrinkStep)

        animateSelection {
            circleDiameter = nextDiameter
            circleTheme = randomTheme(excluding: circleTheme)
            circleCenter = randomCenter(in: playfieldSize, diameter: nextDiameter)
            remainingTime = selectedInterval
            roundDeadline = Date().addingTimeInterval(selectedInterval)
        }
    }

    private func startTimer() {
        guard gameTimer == nil else { return }

        gameTimer = Timer.scheduledTimer(withTimeInterval: timerCadence, repeats: true) { _ in
            let updatedTime = max(0, roundDeadline.timeIntervalSinceNow)
            remainingTime = updatedTime

            if updatedTime <= 0 {
                endGame()
            }
        }
    }

    private func stopTimer() {
        gameTimer?.invalidate()
        gameTimer = nil
    }

    private func endGame() {
        guard phase == .playing else { return }
        stopTimer()
        finalScore = score
        remainingTime = 0

        animateSelection {
            phase = .gameOver
        }
    }

    private func returnToMenu() {
        stopTimer()
        remainingTime = selectedInterval
        circleCenter = .zero
        circleDiameter = maximumCircleDiameter

        animateSelection {
            phase = .menu
        }
    }

    private func animateSelection(_ updates: @escaping () -> Void) {
        if reduceMotion {
            updates()
        } else {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.82), updates)
        }
    }

    private func randomCenter(in size: CGSize, diameter: CGFloat) -> CGPoint {
        let radius = diameter / 2
        let minimumX = radius + playfieldPadding
        let maximumX = max(minimumX, size.width - radius - playfieldPadding)
        let minimumY = radius + playfieldPadding
        let maximumY = max(minimumY, size.height - radius - playfieldPadding)

        if minimumX >= maximumX || minimumY >= maximumY {
            return CGPoint(x: size.width / 2, y: size.height / 2)
        }

        return CGPoint(
            x: CGFloat.random(in: minimumX...maximumX),
            y: CGFloat.random(in: minimumY...maximumY)
        )
    }

    private func clampedCenter(for center: CGPoint, in size: CGSize, diameter: CGFloat) -> CGPoint {
        let radius = diameter / 2
        let minimumX = radius + playfieldPadding
        let maximumX = max(minimumX, size.width - radius - playfieldPadding)
        let minimumY = radius + playfieldPadding
        let maximumY = max(minimumY, size.height - radius - playfieldPadding)

        return CGPoint(
            x: min(max(center.x, minimumX), maximumX),
            y: min(max(center.y, minimumY), maximumY)
        )
    }

    private func randomTheme(excluding currentTheme: CircleTheme?) -> CircleTheme {
        let filteredPalette = targetPalette.filter { candidate in
            guard let currentTheme else { return true }
            return candidate != currentTheme
        }

        return filteredPalette.randomElement() ?? targetPalette[0]
    }
}

private struct StatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.68))

            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.82))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct CircleTheme: Equatable {
    let id = UUID()
    let base: Color
    let highlight: Color
}

#Preview {
    ContentView()
}
