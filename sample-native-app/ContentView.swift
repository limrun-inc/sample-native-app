//
//  ContentView.swift
//  sample-native-app
//
//  Created by Muvaffak on 1/16/26.
//

import SwiftUI
import Combine

struct ContentView: View {
    private enum GamePhase {
        case start
        case playing
        case gameOver
    }

    private static let intervals: [TimeInterval] = [2.0, 3.0, 5.0]
    private static let circleColors: [Color] = [
        .pink,
        .orange,
        .yellow,
        .green,
        .mint,
        .cyan,
        .blue,
        .purple
    ]

    private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    private let startingCircleDiameter: CGFloat = 124
    private let minimumCircleDiameter: CGFloat = 44
    private let circleShrinkFactor: CGFloat = 0.91
    private let playfieldInset: CGFloat = 18

    @State private var phase: GamePhase = .start
    @State private var selectedInterval: TimeInterval = 3.0
    @State private var score = 0
    @State private var remainingTime: TimeInterval = 3.0
    @State private var deadline = Date()
    @State private var circleDiameter: CGFloat = 124
    @State private var circleColor: Color = .pink
    @State private var circlePosition: CGPoint = .zero
    @State private var playfieldSize: CGSize = .zero

    var body: some View {
        ZStack {
            background

            switch phase {
            case .start:
                startScreen
                    .transition(.asymmetric(insertion: .scale(scale: 0.96).combined(with: .opacity), removal: .opacity))
            case .playing:
                gameScreen
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
            case .gameOver:
                gameOverScreen
                    .transition(.asymmetric(insertion: .scale(scale: 0.94).combined(with: .opacity), removal: .opacity))
            }
        }
        .onReceive(timer) { now in
            updateCountdown(at: now)
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color(red: 0.08, green: 0.09, blue: 0.16),
                Color(red: 0.12, green: 0.16, blue: 0.31),
                Color(red: 0.07, green: 0.18, blue: 0.24)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .overlay(
            Circle()
                .fill(.white.opacity(0.08))
                .frame(width: 360, height: 360)
                .blur(radius: 30)
                .offset(x: -170, y: -280)
        )
        .overlay(
            Circle()
                .fill(.cyan.opacity(0.12))
                .frame(width: 300, height: 300)
                .blur(radius: 34)
                .offset(x: 180, y: 300)
        )
    }

    private var startScreen: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 14) {
                Image(systemName: "bolt.circle.fill")
                    .font(.system(size: 66, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.yellow)
                    .shadow(color: .yellow.opacity(0.35), radius: 18)

                Text("Speedy Circles")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)

                Text("Tap the circle before the timer runs out. Each hit makes the target smaller, faster to miss, and worth another point.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.76))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 12)
            }

            VStack(spacing: 18) {
                Text("Choose your reaction window")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.86))

                Picker("Time interval", selection: $selectedInterval) {
                    ForEach(Self.intervals, id: \.self) { interval in
                        Text(intervalLabel(for: interval))
                            .tag(interval)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("intervalPicker")

                Button(action: startGame) {
                    Label("Start", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.cyan)
                .accessibilityIdentifier("startButton")
            }
            .padding(22)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(.white.opacity(0.16), lineWidth: 1)
            )

            Spacer()
        }
        .padding(24)
    }

    private var gameScreen: some View {
        VStack(spacing: 18) {
            gameHUD

            GeometryReader { geometry in
                ZStack {
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 34, style: .continuous)
                                .stroke(.white.opacity(0.14), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.22), radius: 28, y: 18)

                    Button(action: targetTapped) {
                        Circle()
                            .fill(circleColor.gradient)
                            .overlay(
                                Circle()
                                    .stroke(.white.opacity(0.62), lineWidth: 4)
                                    .padding(5)
                            )
                            .overlay(
                                Circle()
                                    .fill(.white.opacity(0.3))
                                    .frame(width: circleDiameter * 0.32, height: circleDiameter * 0.32)
                                    .offset(x: -circleDiameter * 0.16, y: -circleDiameter * 0.18)
                            )
                            .shadow(color: circleColor.opacity(0.58), radius: 20, y: 10)
                    }
                    .buttonStyle(.plain)
                    .frame(width: circleDiameter, height: circleDiameter)
                    .contentShape(Circle())
                    .position(visibleCirclePosition(in: geometry.size))
                    .accessibilityIdentifier("targetCircle")
                    .accessibilityLabel("Target circle")
                    .accessibilityHint("Tap before the timer reaches zero")
                }
                .onAppear {
                    updatePlayfieldSize(geometry.size, relocateTarget: true)
                }
                .onChange(of: geometry.size) { newSize in
                    updatePlayfieldSize(newSize, relocateTarget: true)
                }
            }
            .accessibilityIdentifier("playfield")
        }
        .padding(18)
    }

    private var gameHUD: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                metricCard(title: "Score", value: "\(score)", systemImage: "star.fill")
                    .accessibilityIdentifier("scoreLabel")

                metricCard(title: "Time", value: formattedTime(remainingTime), systemImage: "timer")
                    .accessibilityIdentifier("timeLabel")
            }

            ProgressView(value: max(0, min(1, remainingTime / selectedInterval)))
                .tint(progressTint)
                .accessibilityIdentifier("timeProgress")
        }
    }

    private var gameOverScreen: some View {
        VStack(spacing: 26) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "flag.checkered.circle.fill")
                    .font(.system(size: 68, weight: .bold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.cyan)

                Text("Time's Up")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)

                Text("Final Score")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.7))

                Text("\(score)")
                    .font(.system(size: 84, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .accessibilityIdentifier("finalScoreLabel")
            }

            Button(action: retry) {
                Label("Retry", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.cyan)
            .accessibilityIdentifier("retryButton")

            Spacer()
        }
        .padding(24)
    }

    private var progressTint: Color {
        if remainingTime <= selectedInterval * 0.25 {
            return .red
        }
        if remainingTime <= selectedInterval * 0.5 {
            return .orange
        }
        return .cyan
    }

    private func metricCard(title: String, value: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.cyan)
                .frame(width: 34, height: 34)
                .background(.white.opacity(0.1), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.64))
                Text(value)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                    .monospacedDigit()
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        )
    }

    private func startGame() {
        score = 0
        circleDiameter = startingCircleDiameter
        circleColor = Self.circleColors.randomElement() ?? .pink
        circlePosition = .zero
        remainingTime = selectedInterval
        deadline = Date().addingTimeInterval(selectedInterval)

        withAnimation(.spring(response: 0.48, dampingFraction: 0.86)) {
            phase = .playing
        }
    }

    private func targetTapped() {
        guard phase == .playing else {
            return
        }

        score += 1
        deadline = Date().addingTimeInterval(selectedInterval)
        remainingTime = selectedInterval

        withAnimation(.spring(response: 0.34, dampingFraction: 0.76)) {
            circleDiameter = max(minimumCircleDiameter, circleDiameter * circleShrinkFactor)
            circleColor = Self.circleColors.randomElement() ?? .cyan
            circlePosition = randomCirclePosition(in: playfieldSize, diameter: circleDiameter)
        }
    }

    private func updateCountdown(at now: Date) {
        guard phase == .playing else {
            return
        }

        let newRemainingTime = max(0, deadline.timeIntervalSince(now))
        remainingTime = newRemainingTime

        if newRemainingTime <= 0 {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                phase = .gameOver
            }
        }
    }

    private func retry() {
        withAnimation(.spring(response: 0.42, dampingFraction: 0.9)) {
            phase = .start
        }
        remainingTime = selectedInterval
    }

    private func updatePlayfieldSize(_ size: CGSize, relocateTarget: Bool) {
        playfieldSize = size

        if relocateTarget || circlePosition == .zero {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) {
                circlePosition = randomCirclePosition(in: size, diameter: circleDiameter)
            }
        }
    }

    private func randomCirclePosition(in size: CGSize, diameter: CGFloat) -> CGPoint {
        guard size.width > 0, size.height > 0 else {
            return .zero
        }

        let radius = diameter / 2
        let minX = radius + playfieldInset
        let maxX = max(minX, size.width - radius - playfieldInset)
        let minY = radius + playfieldInset
        let maxY = max(minY, size.height - radius - playfieldInset)

        return CGPoint(
            x: CGFloat.random(in: minX...maxX),
            y: CGFloat.random(in: minY...maxY)
        )
    }

    private func visibleCirclePosition(in size: CGSize) -> CGPoint {
        if circlePosition == .zero {
            return CGPoint(x: size.width / 2, y: size.height / 2)
        }

        return circlePosition
    }

    private func formattedTime(_ time: TimeInterval) -> String {
        String(format: "%.1fs", max(0, time))
    }

    private func intervalLabel(for interval: TimeInterval) -> String {
        String(format: "%.1fs", interval)
    }
}

#Preview {
    ContentView()
}
