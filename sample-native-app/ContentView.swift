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

    private let intervalOptions: [TimeInterval] = [2, 3, 5]
    private let minimumCircleSize: CGFloat = 48
    private let initialCircleSize: CGFloat = 120
    private let circlePalette: [Color] = [
        .pink,
        .orange,
        .yellow,
        .green,
        .teal,
        .blue,
        .purple
    ]
    private let timer = Timer.publish(every: 0.02, on: .main, in: .common).autoconnect()

    @State private var phase: GamePhase = .start
    @State private var selectedInterval: TimeInterval = 3
    @State private var score = 0
    @State private var remainingTime: TimeInterval = 3
    @State private var deadline = Date()
    @State private var circleSize: CGFloat = 120
    @State private var circlePosition = CGPoint(x: 160, y: 220)
    @State private var circleColorIndex = 0
    @State private var canvasSize = CGSize.zero

    private var circleColor: Color {
        circlePalette[circleColorIndex]
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.08, blue: 0.17),
                    Color(red: 0.13, green: 0.16, blue: 0.32),
                    Color(red: 0.07, green: 0.28, blue: 0.31)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            switch phase {
            case .start:
                startScreen
                    .transition(.scale(scale: 0.96).combined(with: .opacity))
            case .playing:
                gameplayScreen
                    .transition(.opacity)
            case .gameOver:
                gameOverScreen
                    .transition(.scale(scale: 0.96).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: phase)
        .onReceive(timer) { now in
            updateTimer(now: now)
        }
    }

    private var startScreen: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 14) {
                Image(systemName: "circle.grid.cross.fill")
                    .font(.system(size: 64, weight: .semibold))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.pink, .cyan)
                    .shadow(color: .pink.opacity(0.35), radius: 24)
                    .accessibilityHidden(true)

                Text("Speedy Circles")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)

                Text("Tap each circle before the countdown hits zero. Every hit makes the next circle smaller and faster to chase.")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white.opacity(0.74))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            VStack(alignment: .leading, spacing: 14) {
                Text("Choose your timer")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.82))

                HStack(spacing: 10) {
                    ForEach(intervalOptions, id: \.self) { interval in
                        Button {
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                                selectedInterval = interval
                                remainingTime = interval
                            }
                        } label: {
                            Text(intervalLabel(interval))
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(selectedInterval == interval ? Color.white : Color.white.opacity(0.12))
                                )
                                .foregroundStyle(selectedInterval == interval ? Color(red: 0.06, green: 0.08, blue: 0.17) : .white)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("interval\(Int(interval))Button")
                    }
                }
            }
            .padding(20)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))

            Button(action: startGame) {
                Label("Start", systemImage: "play.fill")
                    .font(.title3.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [.pink, .orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 22, style: .continuous)
                    )
                    .shadow(color: .pink.opacity(0.35), radius: 18, y: 10)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("startButton")

            Spacer()
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 24)
    }

    private var gameplayScreen: some View {
        VStack(spacing: 16) {
            gameplayHeader

            GeometryReader { proxy in
                ZStack {
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 34, style: .continuous)
                                .stroke(Color.white.opacity(0.16), lineWidth: 1)
                        )

                    Circle()
                        .fill(circleColor.gradient)
                        .frame(width: circleSize, height: circleSize)
                        .shadow(color: circleColor.opacity(0.45), radius: 24, y: 12)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.42), lineWidth: 3)
                        )
                        .position(circlePosition)
                        .contentShape(Circle())
                        .onTapGesture(perform: hitCircle)
                        .accessibilityLabel("Target circle")
                        .accessibilityIdentifier("targetCircle")
                }
                .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
                .onAppear {
                    canvasSize = proxy.size
                    moveCircle(in: proxy.size)
                }
                .onChange(of: proxy.size) { _, newSize in
                    canvasSize = newSize
                    moveCircle(in: newSize)
                }
            }
        }
        .padding(20)
    }

    private var gameplayHeader: some View {
        HStack(spacing: 12) {
            metricCard(title: "Score", value: "\(score)", identifier: "scoreValue")

            metricCard(title: "Time", value: String(format: "%.1fs", max(0, remainingTime)), identifier: "timeValue")
        }
    }

    private func metricCard(title: String, value: String, identifier: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.56))

            Text(value)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .monospacedDigit()
                .accessibilityIdentifier(identifier)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .foregroundStyle(.white)
    }

    private var gameOverScreen: some View {
        VStack(spacing: 26) {
            Spacer()

            VStack(spacing: 12) {
                Text("Game Over")
                    .font(.system(size: 42, weight: .bold, design: .rounded))

                Text("Final score")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.68))

                Text("\(score)")
                    .font(.system(size: 84, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .accessibilityIdentifier("finalScoreValue")
            }
            .frame(maxWidth: .infinity)
            .padding(32)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 34, style: .continuous))

            Button(action: resetToStart) {
                Label("Retry", systemImage: "arrow.clockwise")
                    .font(.title3.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .foregroundStyle(Color(red: 0.06, green: 0.08, blue: 0.17))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("retryButton")

            Spacer()
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 24)
    }

    private func startGame() {
        score = 0
        circleSize = initialCircleSize
        circleColorIndex = Int.random(in: circlePalette.indices)
        resetCountdown()
        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
            phase = .playing
        }
    }

    private func hitCircle() {
        guard phase == .playing else { return }

        score += 1
        circleSize = max(minimumCircleSize, circleSize * 0.9)
        circleColorIndex = nextCircleColorIndex()
        resetCountdown()

        withAnimation(.spring(response: 0.34, dampingFraction: 0.68)) {
            moveCircle(in: canvasSize)
        }
    }

    private func updateTimer(now: Date) {
        guard phase == .playing else { return }

        let newRemainingTime = deadline.timeIntervalSince(now)
        remainingTime = max(0, newRemainingTime)

        if newRemainingTime <= 0 {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                phase = .gameOver
            }
        }
    }

    private func resetCountdown() {
        remainingTime = selectedInterval
        deadline = Date().addingTimeInterval(selectedInterval)
    }

    private func resetToStart() {
        remainingTime = selectedInterval
        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
            phase = .start
        }
    }

    private func moveCircle(in size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }

        let radius = circleSize / 2
        let x = randomCoordinate(length: size.width, inset: radius + 18)
        let y = randomCoordinate(length: size.height, inset: radius + 18)
        circlePosition = CGPoint(x: x, y: y)
    }

    private func randomCoordinate(length: CGFloat, inset: CGFloat) -> CGFloat {
        let lowerBound = min(inset, length / 2)
        let upperBound = max(length - inset, length / 2)

        guard lowerBound < upperBound else {
            return length / 2
        }

        return CGFloat.random(in: lowerBound...upperBound)
    }

    private func nextCircleColorIndex() -> Int {
        var nextIndex = Int.random(in: circlePalette.indices)
        if circlePalette.count > 1 {
            while nextIndex == circleColorIndex {
                nextIndex = Int.random(in: circlePalette.indices)
            }
        }
        return nextIndex
    }

    private func intervalLabel(_ interval: TimeInterval) -> String {
        String(format: "%.1fs", interval)
    }
}

#Preview {
    ContentView()
}
