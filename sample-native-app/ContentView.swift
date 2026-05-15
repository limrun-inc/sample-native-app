//
//  ContentView.swift
//  sample-native-app
//
//  Created by Muvaffak on 1/16/26.
//

import Combine
import Foundation
import SwiftUI

struct ContentView: View {
    private enum GamePhase {
        case start
        case playing
        case gameOver
    }

    private struct IntervalOption: Identifiable {
        let seconds: Double

        var id: Double { seconds }
        var title: String { String(format: "%.1fs", seconds) }
    }

    private let intervalOptions = [
        IntervalOption(seconds: 2.0),
        IntervalOption(seconds: 3.0),
        IntervalOption(seconds: 5.0)
    ]
    private let startingCircleDiameter: CGFloat = 118
    private let minimumCircleDiameter: CGFloat = 48
    private let shrinkStep: CGFloat = 8
    private let circleColors: [Color] = [
        .pink,
        .orange,
        .yellow,
        .green,
        .mint,
        .cyan,
        .blue,
        .purple
    ]
    private let tick = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()

    @State private var phase: GamePhase = .start
    @State private var selectedInterval = 3.0
    @State private var score = 0
    @State private var timeRemaining = 0.0
    @State private var roundEndDate = Date()
    @State private var circleDiameter: CGFloat = 118
    @State private var circlePosition = CGPoint(x: 160, y: 360)
    @State private var circleColorIndex = 1

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                background

                switch phase {
                case .start:
                    startScreen(in: geometry)
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                case .playing:
                    gameScreen(in: geometry)
                        .transition(.opacity.combined(with: .scale(scale: 1.02)))
                case .gameOver:
                    gameOverScreen
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                }
            }
            .onReceive(tick) { now in
                updateCountdown(now: now)
            }
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color(red: 0.07, green: 0.09, blue: 0.16),
                Color(red: 0.14, green: 0.18, blue: 0.34),
                Color(red: 0.05, green: 0.32, blue: 0.43)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .overlay {
            Circle()
                .fill(.white.opacity(0.08))
                .frame(width: 360, height: 360)
                .blur(radius: 24)
                .offset(x: 140, y: -260)
        }
    }

    private func startScreen(in geometry: GeometryProxy) -> some View {
        VStack(spacing: 28) {
            Spacer(minLength: 32)

            VStack(spacing: 14) {
                Text("Speedy Circles")
                    .font(.system(size: 46, weight: .black, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)

                Text("Tap each circle before the timer expires. Every hit makes the next one smaller, faster to find, and more satisfying.")
                    .font(.system(.headline, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.78))
                    .lineSpacing(4)
                    .padding(.horizontal, 18)
            }

            VStack(spacing: 14) {
                Text("Round timer")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(.white.opacity(0.7))
                    .textCase(.uppercase)
                    .tracking(1.4)

                HStack(spacing: 10) {
                    ForEach(intervalOptions) { option in
                        intervalButton(for: option)
                    }
                }
            }
            .padding(18)
            .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(.white.opacity(0.14), lineWidth: 1)
            }

            Button {
                startGame(in: geometry)
            } label: {
                Label("Start", systemImage: "play.fill")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color(red: 0.06, green: 0.12, blue: 0.22))
            .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.22), radius: 18, x: 0, y: 12)
            .accessibilityIdentifier("startButton")

            Spacer(minLength: 40)
        }
        .padding(.horizontal, 24)
        .frame(width: geometry.size.width, height: geometry.size.height)
    }

    private func intervalButton(for option: IntervalOption) -> some View {
        let isSelected = selectedInterval == option.seconds

        return Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.76)) {
                selectedInterval = option.seconds
            }
        } label: {
            Text(option.title)
                .font(.system(.headline, design: .rounded).weight(.bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(isSelected ? Color(red: 0.06, green: 0.12, blue: 0.22) : .white)
                .background(
                    isSelected ? .white : .white.opacity(0.12),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("interval\(Int(option.seconds))Button")
    }

    private func gameScreen(in geometry: GeometryProxy) -> some View {
        ZStack(alignment: .top) {
            Circle()
                .fill(circleColors[circleColorIndex])
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.86), lineWidth: 4)
                }
                .shadow(color: circleColors[circleColorIndex].opacity(0.5), radius: 24, x: 0, y: 12)
                .frame(width: circleDiameter, height: circleDiameter)
                .position(circlePosition)
                .onTapGesture {
                    hitCircle(in: geometry)
                }
                .accessibilityLabel("Circle target")
                .accessibilityIdentifier("circleTarget")

            VStack(spacing: 14) {
                HStack(spacing: 12) {
                    metricCard(title: "Score", value: "\(score)", identifier: "scoreLabel")
                    metricCard(title: "Time", value: String(format: "%.1fs", timeRemaining), identifier: "timerLabel")
                }

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.white.opacity(0.16))
                        Capsule()
                            .fill(.white)
                            .frame(width: max(0, proxy.size.width * countdownProgress))
                            .animation(.linear(duration: 0.1), value: countdownProgress)
                    }
                }
                .frame(height: 10)
                .accessibilityIdentifier("countdownProgress")
            }
            .padding(18)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(.white.opacity(0.18), lineWidth: 1)
            }
            .padding(.horizontal, 20)
            .padding(.top, geometry.safeAreaInsets.top + 14)
        }
        .frame(width: geometry.size.width, height: geometry.size.height)
    }

    private func metricCard(title: String, value: String, identifier: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundStyle(.white.opacity(0.65))
                .textCase(.uppercase)
                .tracking(1.2)

            Text(value)
                .font(.system(.title2, design: .rounded).weight(.black))
                .monospacedDigit()
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityIdentifier(identifier)
    }

    private var gameOverScreen: some View {
        VStack(spacing: 22) {
            Image(systemName: "timer")
                .font(.system(size: 54, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(24)
                .background(.white.opacity(0.12), in: Circle())

            VStack(spacing: 10) {
                Text("Time's up")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text("Final score: \(score)")
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(.white.opacity(0.8))
                    .accessibilityIdentifier("finalScoreLabel")
            }

            Button {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                    phase = .start
                    timeRemaining = selectedInterval
                }
            } label: {
                Label("Retry", systemImage: "arrow.clockwise")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color(red: 0.06, green: 0.12, blue: 0.22))
            .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.22), radius: 18, x: 0, y: 12)
            .accessibilityIdentifier("retryButton")
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: 520)
    }

    private var countdownProgress: CGFloat {
        guard selectedInterval > 0 else { return 0 }
        return CGFloat(max(0, min(1, timeRemaining / selectedInterval)))
    }

    private func startGame(in geometry: GeometryProxy) {
        let colorIndex = Int.random(in: circleColors.indices)

        score = 0
        circleDiameter = startingCircleDiameter
        circleColorIndex = colorIndex
        circlePosition = randomCirclePosition(in: geometry, diameter: startingCircleDiameter)
        resetRoundTimer()

        withAnimation(.spring(response: 0.42, dampingFraction: 0.84)) {
            phase = .playing
        }
    }

    private func hitCircle(in geometry: GeometryProxy) {
        guard phase == .playing else { return }

        let nextDiameter = max(minimumCircleDiameter, circleDiameter - shrinkStep)
        let nextColorIndex = randomColorIndex(excluding: circleColorIndex)
        let nextPosition = randomCirclePosition(in: geometry, diameter: nextDiameter)

        resetRoundTimer()

        withAnimation(.spring(response: 0.36, dampingFraction: 0.64)) {
            score += 1
            circleDiameter = nextDiameter
            circleColorIndex = nextColorIndex
            circlePosition = nextPosition
        }
    }

    private func updateCountdown(now: Date) {
        guard phase == .playing else { return }

        let remaining = roundEndDate.timeIntervalSince(now)
        timeRemaining = max(0, remaining)

        guard remaining <= 0 else { return }

        withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
            phase = .gameOver
        }
    }

    private func resetRoundTimer() {
        timeRemaining = selectedInterval
        roundEndDate = Date().addingTimeInterval(selectedInterval)
    }

    private func randomColorIndex(excluding currentIndex: Int) -> Int {
        guard circleColors.count > 1 else { return currentIndex }

        var nextIndex = currentIndex
        while nextIndex == currentIndex {
            nextIndex = Int.random(in: circleColors.indices)
        }
        return nextIndex
    }

    private func randomCirclePosition(in geometry: GeometryProxy, diameter: CGFloat) -> CGPoint {
        let radius = diameter / 2
        let sidePadding: CGFloat = 22
        let topReserved = geometry.safeAreaInsets.top + 146
        let bottomReserved = geometry.safeAreaInsets.bottom + 96

        let minX = radius + sidePadding
        let maxX = max(minX, geometry.size.width - radius - sidePadding)
        let minY = max(radius + 24, topReserved + radius)
        let maxY = max(minY, geometry.size.height - bottomReserved - radius)

        return CGPoint(
            x: CGFloat.random(in: minX...maxX),
            y: CGFloat.random(in: minY...maxY)
        )
    }
}

#Preview {
    ContentView()
}
