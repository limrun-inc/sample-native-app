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

    private let intervals = [2.0, 3.0, 5.0]
    private let maximumCircleSize: CGFloat = 108
    private let minimumCircleSize: CGFloat = 44
    private let ticker = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    private let circleColors: [Color] = [
        .pink,
        .orange,
        .mint,
        .blue,
        .purple,
        .yellow
    ]

    @State private var selectedInterval = 3.0
    @State private var phase: GamePhase = .start
    @State private var score = 0
    @State private var finalScore = 0
    @State private var circleSize: CGFloat = 108
    @State private var circlePosition = CGPoint(x: 200, y: 360)
    @State private var circleColorIndex = 0
    @State private var roundEndsAt = Date()
    @State private var remainingTime = 3.0

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.10, blue: 0.20),
                        Color(red: 0.16, green: 0.19, blue: 0.34),
                        Color(red: 0.05, green: 0.09, blue: 0.18)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                switch phase {
                case .start:
                    startView(in: proxy)
                        .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
                case .playing:
                    playingView(in: proxy)
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                case .gameOver:
                    gameOverView()
                        .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
                }
            }
            .animation(.spring(response: 0.45, dampingFraction: 0.82), value: phase)
            .onReceive(ticker) { now in
                guard phase == .playing else { return }
                updateCountdown(now: now)
            }
        }
    }

    private func startView(in proxy: GeometryProxy) -> some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 14) {
                Image(systemName: "circle.grid.cross.fill")
                    .font(.system(size: 68, weight: .semibold))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.pink, .mint)
                    .accessibilityHidden(true)

                Text("Speedy Circles")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)

                Text("Tap each circle before the timer expires. Every hit makes the next target smaller.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.72))
                    .padding(.horizontal, 24)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Round timer")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.86))

                HStack(spacing: 10) {
                    ForEach(intervals, id: \.self) { interval in
                        intervalButton(interval)
                    }
                }
            }
            .padding(18)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            .padding(.horizontal, 22)

            Button {
                startGame(in: proxy.size, safeAreaInsets: proxy.safeAreaInsets)
            } label: {
                Text("Start")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle(radius: 18))
            .controlSize(.large)
            .tint(.pink)
            .padding(.horizontal, 34)
            .accessibilityIdentifier("startButton")

            Spacer()
        }
    }

    private func intervalButton(_ interval: Double) -> some View {
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                selectedInterval = interval
                remainingTime = interval
            }
        } label: {
            Text(intervalLabel(interval))
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(selectedInterval == interval ? .black : .white)
                .background {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(selectedInterval == interval ? Color.white : Color.white.opacity(0.14))
                }
        }
        .accessibilityIdentifier("interval\(Int(interval))Button")
    }

    private func playingView(in proxy: GeometryProxy) -> some View {
        ZStack {
            VStack(spacing: 0) {
                hudView
                    .padding(.top, proxy.safeAreaInsets.top + 8)
                    .padding(.horizontal, 18)

                Spacer()
            }

            Circle()
                .fill(circleColors[circleColorIndex])
                .frame(width: circleSize, height: circleSize)
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.62), lineWidth: 3)
                }
                .shadow(color: circleColors[circleColorIndex].opacity(0.48), radius: 22, y: 10)
                .position(circlePosition)
                .contentShape(Circle())
                .onTapGesture {
                    handleCircleTap(in: proxy.size, safeAreaInsets: proxy.safeAreaInsets)
                }
                .accessibilityLabel("Circle")
                .accessibilityValue("Score \(score)")
                .accessibilityIdentifier("gameCircle")
        }
    }

    private var hudView: some View {
        HStack(spacing: 12) {
            metricCard(title: "Score", value: "\(score)")
                .accessibilityIdentifier("scoreLabel")

            metricCard(title: "Time", value: formattedTime(remainingTime))
                .accessibilityIdentifier("timeLabel")
        }
    }

    private func metricCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.62))
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func gameOverView() -> some View {
        VStack(spacing: 22) {
            Spacer()

            VStack(spacing: 12) {
                Text("Time's Up")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)

                Text("Final score: \(finalScore)")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.82))
                    .accessibilityIdentifier("finalScoreLabel")
            }
            .padding(28)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
            .padding(.horizontal, 26)

            Button {
                withAnimation {
                    phase = .start
                    score = 0
                    finalScore = 0
                    circleSize = maximumCircleSize
                    remainingTime = selectedInterval
                }
            } label: {
                Text("Retry")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle(radius: 18))
            .controlSize(.large)
            .tint(.mint)
            .padding(.horizontal, 34)
            .accessibilityIdentifier("retryButton")

            Spacer()
        }
    }

    private func startGame(in size: CGSize, safeAreaInsets: EdgeInsets) {
        score = 0
        finalScore = 0
        circleSize = maximumCircleSize
        remainingTime = selectedInterval
        circleColorIndex = Int.random(in: 0..<circleColors.count)
        circlePosition = randomCirclePosition(in: size, safeAreaInsets: safeAreaInsets, diameter: circleSize)
        roundEndsAt = Date().addingTimeInterval(selectedInterval)

        withAnimation {
            phase = .playing
        }
    }

    private func handleCircleTap(in size: CGSize, safeAreaInsets: EdgeInsets) {
        guard phase == .playing else { return }

        score += 1
        circleSize = max(minimumCircleSize, maximumCircleSize - CGFloat(score) * 7)
        circleColorIndex = nextColorIndex()
        remainingTime = selectedInterval
        roundEndsAt = Date().addingTimeInterval(selectedInterval)

        withAnimation(.spring(response: 0.32, dampingFraction: 0.72)) {
            circlePosition = randomCirclePosition(in: size, safeAreaInsets: safeAreaInsets, diameter: circleSize)
        }
    }

    private func updateCountdown(now: Date) {
        let secondsLeft = roundEndsAt.timeIntervalSince(now)
        remainingTime = max(0, secondsLeft)

        if secondsLeft <= 0 {
            finalScore = score
            withAnimation {
                phase = .gameOver
            }
        }
    }

    private func randomCirclePosition(in size: CGSize, safeAreaInsets: EdgeInsets, diameter: CGFloat) -> CGPoint {
        let radius = diameter / 2
        let horizontalPadding: CGFloat = 18
        let topPadding = safeAreaInsets.top + 132
        let bottomPadding = safeAreaInsets.bottom + 28

        let minX = safeAreaInsets.leading + horizontalPadding + radius
        let maxX = max(minX, size.width - safeAreaInsets.trailing - horizontalPadding - radius)
        let minY = topPadding + radius
        let maxY = max(minY, size.height - bottomPadding - radius)

        return CGPoint(
            x: CGFloat.random(in: minX...maxX),
            y: CGFloat.random(in: minY...maxY)
        )
    }

    private func nextColorIndex() -> Int {
        guard circleColors.count > 1 else { return 0 }

        var newIndex = circleColorIndex
        while newIndex == circleColorIndex {
            newIndex = Int.random(in: 0..<circleColors.count)
        }

        return newIndex
    }

    private func intervalLabel(_ interval: Double) -> String {
        String(format: "%.1fs", interval)
    }

    private func formattedTime(_ time: Double) -> String {
        String(format: "%.1f", time)
    }
}

#Preview {
    ContentView()
}
