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
        case finished
    }

    private enum Constants {
        static let intervals: [TimeInterval] = [2.0, 3.0, 5.0]
        static let startCircleSize: CGFloat = 112
        static let minimumCircleSize: CGFloat = 44
        static let circleShrinkStep: CGFloat = 7
        static let circleColors: [Color] = [
            .pink,
            .orange,
            .yellow,
            .green,
            .mint,
            .cyan,
            .blue,
            .purple
        ]
    }

    @State private var phase: GamePhase = .start
    @State private var selectedInterval: TimeInterval = 3.0
    @State private var score = 0
    @State private var finalScore = 0
    @State private var remainingTime: TimeInterval = 3.0
    @State private var deadline = Date()
    @State private var circlePosition = CGPoint(x: 180, y: 360)
    @State private var circleSize = Constants.startCircleSize
    @State private var circleColor = Color.pink

    private let timer = Timer.publish(every: 0.02, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                background

                switch phase {
                case .start:
                    startScreen(in: proxy.size)
                        .transition(.scale(scale: 0.96).combined(with: .opacity))
                case .playing:
                    gameScreen(in: proxy.size)
                        .transition(.opacity)
                case .finished:
                    gameOverScreen
                        .transition(.scale(scale: 0.96).combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onReceive(timer) { now in
                guard phase == .playing else { return }

                let updatedTime = max(0, deadline.timeIntervalSince(now))
                remainingTime = updatedTime

                if updatedTime == 0 {
                    finishGame()
                }
            }
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color(red: 0.08, green: 0.11, blue: 0.22),
                Color(red: 0.13, green: 0.18, blue: 0.36),
                Color(red: 0.32, green: 0.18, blue: 0.47)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private func startScreen(in size: CGSize) -> some View {
        VStack(spacing: 28) {
            VStack(spacing: 12) {
                Image(systemName: "circle.circle.fill")
                    .font(.system(size: 72, weight: .semibold))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.pink, .white.opacity(0.35))
                    .shadow(color: .pink.opacity(0.45), radius: 28)

                Text("Speedy Circles")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)

                Text("Tap each circle before the countdown ends. Every hit makes the target smaller and faster to track.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.72))
                    .lineSpacing(3)
            }

            VStack(alignment: .leading, spacing: 14) {
                Text("Round timer")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.86))

                HStack(spacing: 10) {
                    ForEach(Constants.intervals, id: \.self) { interval in
                        intervalButton(interval)
                    }
                }
            }
            .padding(18)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))

            Button {
                startGame(in: size)
            } label: {
                Text("Start")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(
                        LinearGradient(colors: [.pink, .purple], startPoint: .leading, endPoint: .trailing),
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
                    .shadow(color: .pink.opacity(0.34), radius: 18, y: 8)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("startButton")
        }
        .padding(28)
        .frame(maxWidth: 430)
    }

    private func intervalButton(_ interval: TimeInterval) -> some View {
        let isSelected = selectedInterval == interval

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedInterval = interval
                remainingTime = interval
            }
        } label: {
            Text(String(format: "%.0fs", interval))
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundStyle(isSelected ? .white : .white.opacity(0.72))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(isSelected ? Color.white.opacity(0.22) : Color.white.opacity(0.08))
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(isSelected ? Color.white.opacity(0.42) : Color.white.opacity(0.12), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(Int(interval)) seconds")
    }

    private func gameScreen(in size: CGSize) -> some View {
        ZStack {
            VStack {
                gameHeader
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(0.9), circleColor, circleColor.opacity(0.74)],
                        center: .topLeading,
                        startRadius: 4,
                        endRadius: circleSize
                    )
                )
                .frame(width: circleSize, height: circleSize)
                .shadow(color: circleColor.opacity(0.46), radius: 26, y: 12)
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.48), lineWidth: 2)
                }
                .position(circlePosition)
                .onTapGesture {
                    hitCircle(in: size)
                }
                .accessibilityLabel("Target circle")
                .accessibilityIdentifier("targetCircle")
        }
    }

    private var gameHeader: some View {
        HStack(spacing: 12) {
            statCard(title: "Score", value: "\(score)", icon: "star.fill")

            statCard(
                title: "Time",
                value: String(format: "%.1fs", remainingTime),
                icon: "timer"
            )
            .overlay(alignment: .bottomLeading) {
                GeometryReader { proxy in
                    Capsule()
                        .fill(.white.opacity(0.18))
                        .overlay(alignment: .leading) {
                            Capsule()
                                .fill(timeProgressColor)
                                .frame(width: proxy.size.width * max(0, min(1, remainingTime / selectedInterval)))
                        }
                }
                .frame(height: 4)
                .padding(.horizontal, 14)
                .padding(.bottom, 10)
            }
        }
    }

    private func statCard(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(.white.opacity(0.82))
                .frame(width: 28, height: 28)
                .background(.white.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.54))

                Text(value)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var gameOverScreen: some View {
        VStack(spacing: 24) {
            VStack(spacing: 10) {
                Image(systemName: "flag.checkered.circle.fill")
                    .font(.system(size: 68, weight: .bold))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .pink)

                Text("Time's Up")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)

                Text("Final Score")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.66))

                Text("\(finalScore)")
                    .font(.system(size: 74, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
            }

            Button {
                retry()
            } label: {
                Text("Retry")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(
                        LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing),
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
                    .shadow(color: .blue.opacity(0.36), radius: 18, y: 8)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("retryButton")
        }
        .padding(28)
        .frame(maxWidth: 410)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 34, style: .continuous))
        .padding(24)
    }

    private var timeProgressColor: Color {
        switch remainingTime / selectedInterval {
        case 0.5...:
            .green
        case 0.25..<0.5:
            .yellow
        default:
            .red
        }
    }

    private func startGame(in size: CGSize) {
        score = 0
        finalScore = 0
        circleSize = Constants.startCircleSize
        circleColor = randomCircleColor()
        circlePosition = randomCirclePosition(in: size, diameter: circleSize)
        resetTimer()

        withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
            phase = .playing
        }
    }

    private func hitCircle(in size: CGSize) {
        guard phase == .playing else { return }

        score += 1
        resetTimer()

        withAnimation(.spring(response: 0.32, dampingFraction: 0.72)) {
            circleSize = max(Constants.minimumCircleSize, circleSize - Constants.circleShrinkStep)
            circleColor = randomCircleColor(excluding: circleColor)
            circlePosition = randomCirclePosition(in: size, diameter: circleSize)
        }
    }

    private func finishGame() {
        guard phase == .playing else { return }

        finalScore = score

        withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
            phase = .finished
        }
    }

    private func retry() {
        remainingTime = selectedInterval

        withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
            phase = .start
        }
    }

    private func resetTimer() {
        remainingTime = selectedInterval
        deadline = Date().addingTimeInterval(selectedInterval)
    }

    private func randomCirclePosition(in size: CGSize, diameter: CGFloat) -> CGPoint {
        let radius = diameter / 2
        let xRange = (radius + 24)...max(radius + 24, size.width - radius - 24)
        let yRange = (radius + 132)...max(radius + 132, size.height - radius - 48)

        return CGPoint(
            x: CGFloat.random(in: xRange),
            y: CGFloat.random(in: yRange)
        )
    }

    private func randomCircleColor(excluding color: Color? = nil) -> Color {
        var colors = Constants.circleColors

        if let color {
            colors.removeAll { $0 == color }
        }

        return colors.randomElement() ?? .pink
    }
}

#Preview {
    ContentView()
}
