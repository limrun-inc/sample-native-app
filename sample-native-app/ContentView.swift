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

    private let intervalOptions = [2.0, 3.0, 5.0]
    private let startingCircleDiameter: CGFloat = 112
    private let minimumCircleDiameter: CGFloat = 44
    private let circleColors: [Color] = [
        .pink,
        .orange,
        .yellow,
        .green,
        .mint,
        .cyan,
        .indigo,
        .purple
    ]
    private let timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    @State private var phase: GamePhase = .start
    @State private var selectedInterval = 3.0
    @State private var score = 0
    @State private var remainingTime = 3.0
    @State private var circleDiameter: CGFloat = 112
    @State private var circlePosition = CGPoint(x: 160, y: 240)
    @State private var circleColorIndex = 0
    @State private var hasPlacedCircle = false
    @State private var lastTick = Date()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.09, blue: 0.18), Color(red: 0.16, green: 0.18, blue: 0.35)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            switch phase {
            case .start:
                startScreen
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            case .playing:
                playingScreen
                    .transition(.opacity)
            case .gameOver:
                gameOverScreen
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: phase)
        .onReceive(timer, perform: updateTimer)
    }

    private var startScreen: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 12) {
                Text("Speedy Circles")
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("Pick a countdown, then tap each circle before time runs out.")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }

            VStack(spacing: 14) {
                Text("Round timer")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.7))

                HStack(spacing: 12) {
                    ForEach(intervalOptions, id: \.self) { interval in
                        Button {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                                selectedInterval = interval
                            }
                        } label: {
                            Text(String(format: "%.1fs", interval))
                                .font(.headline)
                                .frame(width: 78, height: 52)
                                .background(selectedInterval == interval ? Color.white : Color.white.opacity(0.14))
                                .foregroundStyle(selectedInterval == interval ? Color(red: 0.13, green: 0.15, blue: 0.3) : .white)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(.white.opacity(0.22), lineWidth: 1)
                                )
                        }
                        .accessibilityIdentifier("interval-\(String(format: "%.0f", interval))")
                    }
                }
            }

            Button(action: startGame) {
                Text("Start")
                    .font(.title3.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.white)
                    .foregroundStyle(Color(red: 0.13, green: 0.15, blue: 0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 10)
            }
            .accessibilityIdentifier("startButton")
            .padding(.horizontal, 36)

            Spacer()
        }
    }

    private var playingScreen: some View {
        VStack(spacing: 0) {
            HStack {
                statCard(title: "Score", value: "\(score)", identifier: "scoreLabel")

                Spacer(minLength: 16)

                statCard(title: "Time", value: String(format: "%.1fs", remainingTime), identifier: "timeLabel")
            }
            .padding(.horizontal, 22)
            .padding(.top, 18)
            .padding(.bottom, 14)

            ProgressView(value: remainingTime, total: selectedInterval)
                .tint(circleColors[circleColorIndex])
                .padding(.horizontal, 22)
                .padding(.bottom, 10)
                .animation(.linear(duration: 0.08), value: remainingTime)

            GeometryReader { geometry in
                ZStack {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 32, style: .continuous)
                                .stroke(.white.opacity(0.12), lineWidth: 1)
                        )
                        .padding(12)

                    Circle()
                        .fill(circleColors[circleColorIndex])
                        .frame(width: circleDiameter, height: circleDiameter)
                        .shadow(color: circleColors[circleColorIndex].opacity(0.45), radius: 24, x: 0, y: 12)
                        .position(circlePosition)
                        .accessibilityLabel("Target circle")
                        .accessibilityIdentifier("targetCircle")
                        .accessibilityAddTraits(.isButton)
                        .accessibilityAction {
                            hitCircle(in: geometry.size)
                        }
                        .onTapGesture {
                            hitCircle(in: geometry.size)
                        }
                        .animation(.spring(response: 0.28, dampingFraction: 0.72), value: circlePosition)
                        .animation(.spring(response: 0.28, dampingFraction: 0.78), value: circleDiameter)
                        .animation(.easeInOut(duration: 0.18), value: circleColorIndex)
                }
                .contentShape(Rectangle())
                .onAppear {
                    placeInitialCircle(in: geometry.size)
                }
                .onChange(of: geometry.size) { _, newSize in
                    keepCircleWithinBounds(newSize)
                }
            }
        }
    }

    private var gameOverScreen: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 10) {
                Text("Time's up!")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text("Final score: \(score)")
                    .font(.title.weight(.bold))
                    .foregroundStyle(circleColors[circleColorIndex])
                    .accessibilityIdentifier("finalScoreLabel")
            }
            .padding(32)
            .frame(maxWidth: .infinity)
            .background(.white.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(.white.opacity(0.14), lineWidth: 1)
            )
            .padding(.horizontal, 28)

            Button(action: retry) {
                Text("Retry")
                    .font(.title3.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.white)
                    .foregroundStyle(Color(red: 0.13, green: 0.15, blue: 0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
            .accessibilityIdentifier("retryButton")
            .padding(.horizontal, 36)

            Spacer()
        }
    }

    private func statCard(title: String, value: String, identifier: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.6))

            Text(value)
                .font(.title2.monospacedDigit().weight(.heavy))
                .foregroundStyle(.white)
                .accessibilityIdentifier(identifier)
        }
        .frame(width: 132, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func startGame() {
        score = 0
        remainingTime = selectedInterval
        circleDiameter = startingCircleDiameter
        circleColorIndex = Int.random(in: circleColors.indices)
        hasPlacedCircle = false
        lastTick = Date()

        withAnimation(.easeInOut(duration: 0.25)) {
            phase = .playing
        }
    }

    private func retry() {
        withAnimation(.easeInOut(duration: 0.25)) {
            phase = .start
        }
    }

    private func hitCircle(in size: CGSize) {
        guard phase == .playing else { return }

        score += 1
        remainingTime = selectedInterval
        lastTick = Date()

        withAnimation(.spring(response: 0.28, dampingFraction: 0.76)) {
            circleDiameter = max(minimumCircleDiameter, circleDiameter * 0.9)
            circleColorIndex = nextColorIndex()
            circlePosition = randomPosition(in: size, diameter: circleDiameter)
        }
    }

    private func placeInitialCircle(in size: CGSize) {
        guard phase == .playing, !hasPlacedCircle else { return }

        hasPlacedCircle = true
        circlePosition = randomPosition(in: size, diameter: circleDiameter)
    }

    private func keepCircleWithinBounds(_ size: CGSize) {
        guard phase == .playing else { return }

        let radius = circleDiameter / 2
        circlePosition = CGPoint(
            x: clamp(circlePosition.x, min: radius, max: max(radius, size.width - radius)),
            y: clamp(circlePosition.y, min: radius, max: max(radius, size.height - radius))
        )
    }

    private func updateTimer(_ now: Date) {
        guard phase == .playing else {
            lastTick = now
            return
        }

        let elapsed = now.timeIntervalSince(lastTick)
        lastTick = now
        remainingTime = max(0, remainingTime - elapsed)

        if remainingTime == 0 {
            withAnimation(.easeInOut(duration: 0.25)) {
                phase = .gameOver
            }
        }
    }

    private func randomPosition(in size: CGSize, diameter: CGFloat) -> CGPoint {
        let radius = diameter / 2
        let minX = min(radius, size.width / 2)
        let maxX = max(size.width - radius, size.width / 2)
        let minY = min(radius, size.height / 2)
        let maxY = max(size.height - radius, size.height / 2)

        return CGPoint(
            x: CGFloat.random(in: minX...maxX),
            y: CGFloat.random(in: minY...maxY)
        )
    }

    private func nextColorIndex() -> Int {
        let offset = Int.random(in: 1..<circleColors.count)
        return (circleColorIndex + offset) % circleColors.count
    }

    private func clamp(_ value: CGFloat, min minimumValue: CGFloat, max maximumValue: CGFloat) -> CGFloat {
        min(max(value, minimumValue), maximumValue)
    }
}

#Preview {
    ContentView()
}
