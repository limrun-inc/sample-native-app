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
    private let timer = Timer.publish(every: 0.02, on: .main, in: .common).autoconnect()
    private let minimumCircleDiameter: CGFloat = 48
    private let startingCircleDiameter: CGFloat = 108
    private let palette: [Color] = [
        .pink,
        .orange,
        .yellow,
        .green,
        .mint,
        .cyan,
        .blue,
        .purple
    ]

    @State private var phase: GamePhase = .start
    @State private var selectedInterval = 3.0
    @State private var score = 0
    @State private var remainingTime = 3.0
    @State private var circleDiameter: CGFloat = 108
    @State private var circleColorIndex = 0
    @State private var circlePosition = CGPoint(x: 200, y: 360)
    @State private var lastTickDate: Date?

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                background

                switch phase {
                case .start:
                    startScreen(in: proxy)
                        .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.96)), removal: .opacity))
                case .playing:
                    gameScreen(in: proxy)
                        .transition(.opacity)
                case .gameOver:
                    gameOverScreen(in: proxy)
                        .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.96)), removal: .opacity))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onReceive(timer) { tickDate in
                updateTimer(at: tickDate)
            }
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color(red: 0.08, green: 0.10, blue: 0.20),
                Color(red: 0.16, green: 0.13, blue: 0.34),
                Color(red: 0.05, green: 0.18, blue: 0.28)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .overlay {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.09))
                    .frame(width: 260, height: 260)
                    .blur(radius: 12)
                    .offset(x: -170, y: -290)
                Circle()
                    .fill(.cyan.opacity(0.12))
                    .frame(width: 320, height: 320)
                    .blur(radius: 22)
                    .offset(x: 160, y: 260)
            }
        }
    }

    private func startScreen(in proxy: GeometryProxy) -> some View {
        VStack(spacing: 30) {
            Spacer()

            VStack(spacing: 14) {
                Image(systemName: "circle.grid.cross")
                    .font(.system(size: 58, weight: .semibold))
                    .foregroundStyle(.white, .cyan)
                    .symbolEffect(.pulse)

                Text("Speedy Circles")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("Tap each circle before the timer runs out. Every hit makes the next target smaller and faster to find.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.76))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 8)
            }

            VStack(alignment: .leading, spacing: 14) {
                Text("Round timer")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.88))

                HStack(spacing: 10) {
                    ForEach(intervals, id: \.self) { interval in
                        intervalButton(interval)
                    }
                }
            }
            .padding(20)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(.white.opacity(0.16), lineWidth: 1)
            }
            .padding(.horizontal, 24)

            Button {
                startGame(in: proxy)
            } label: {
                Label("Start", systemImage: "play.fill")
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.cyan)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(.horizontal, 24)
            .accessibilityIdentifier("startButton")

            Spacer()
        }
        .padding(.vertical, 32)
    }

    private func intervalButton(_ interval: Double) -> some View {
        let isSelected = selectedInterval == interval

        return Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                selectedInterval = interval
            }
        } label: {
            Text(String(format: "%.1fs", interval))
                .font(.headline)
                .foregroundStyle(isSelected ? .black : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background {
                    Capsule(style: .continuous)
                        .fill(isSelected ? Color.white : Color.white.opacity(0.12))
                }
                .overlay {
                    Capsule(style: .continuous)
                        .stroke(.white.opacity(isSelected ? 0 : 0.18), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(String(format: "%.1f", interval)) seconds")
        .accessibilityIdentifier("interval\(Int(interval))Button")
    }

    private func gameScreen(in proxy: GeometryProxy) -> some View {
        ZStack {
            hud
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.top, proxy.safeAreaInsets.top + 14)
                .padding(.horizontal, 20)

            Button {
                hitCircle(in: proxy)
            } label: {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                .white.opacity(0.95),
                                circleColor,
                                circleColor.opacity(0.76)
                            ],
                            center: .topLeading,
                            startRadius: 4,
                            endRadius: circleDiameter
                        )
                    )
                    .overlay {
                        Circle()
                            .stroke(.white.opacity(0.85), lineWidth: 3)
                    }
                    .shadow(color: circleColor.opacity(0.45), radius: 26, x: 0, y: 16)
                    .frame(width: circleDiameter, height: circleDiameter)
            }
            .buttonStyle(.plain)
            .position(circlePosition)
            .accessibilityLabel("Tap circle")
            .accessibilityIdentifier("circleButton")
            .animation(.spring(response: 0.38, dampingFraction: 0.72), value: circlePosition)
            .animation(.spring(response: 0.38, dampingFraction: 0.78), value: circleDiameter)
            .animation(.easeInOut(duration: 0.22), value: circleColorIndex)
        }
    }

    private var hud: some View {
        HStack(spacing: 12) {
            metricCard(title: "Score", value: "\(score)", symbol: "target")
                .accessibilityIdentifier("scoreLabel")

            metricCard(title: "Time", value: String(format: "%.1fs", max(remainingTime, 0)), symbol: "timer")
                .accessibilityIdentifier("timeLabel")
        }
    }

    private func metricCard(title: String, value: String, symbol: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.headline)
                .foregroundStyle(.cyan)
                .frame(width: 32, height: 32)
                .background(.white.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.62))
                Text(value)
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(.white)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.14), lineWidth: 1)
        }
    }

    private func gameOverScreen(in proxy: GeometryProxy) -> some View {
        VStack(spacing: 22) {
            Spacer()

            VStack(spacing: 14) {
                Image(systemName: "flag.checkered")
                    .font(.system(size: 54, weight: .semibold))
                    .foregroundStyle(.white, .cyan)

                Text("Time's Up")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)

                Text("Final Score")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.66))

                Text("\(score)")
                    .font(.system(size: 76, weight: .black, design: .rounded).monospacedDigit())
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 36)
            .padding(.horizontal, 22)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 34, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .stroke(.white.opacity(0.16), lineWidth: 1)
            }
            .padding(.horizontal, 24)
            .accessibilityIdentifier("gameOverView")

            Button {
                retry()
            } label: {
                Label("Retry", systemImage: "arrow.clockwise")
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.cyan)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(.horizontal, 24)
            .accessibilityIdentifier("retryButton")

            Spacer()
        }
        .padding(.vertical, 32)
    }

    private func startGame(in proxy: GeometryProxy) {
        score = 0
        remainingTime = selectedInterval
        circleDiameter = startingCircleDiameter
        circleColorIndex = nextColorIndex(excluding: circleColorIndex)
        circlePosition = randomCirclePosition(in: proxy)
        lastTickDate = Date()

        withAnimation(.easeInOut(duration: 0.28)) {
            phase = .playing
        }
    }

    private func hitCircle(in proxy: GeometryProxy) {
        guard phase == .playing, remainingTime > 0 else { return }

        score += 1
        remainingTime = selectedInterval
        lastTickDate = Date()

        withAnimation(.spring(response: 0.38, dampingFraction: 0.74)) {
            circleDiameter = max(minimumCircleDiameter, circleDiameter * 0.9)
            circleColorIndex = nextColorIndex(excluding: circleColorIndex)
            circlePosition = randomCirclePosition(in: proxy)
        }
    }

    private func updateTimer(at date: Date) {
        guard phase == .playing else {
            lastTickDate = nil
            return
        }

        guard let lastTickDate else {
            self.lastTickDate = date
            return
        }

        remainingTime -= date.timeIntervalSince(lastTickDate)
        self.lastTickDate = date

        if remainingTime <= 0 {
            failGame()
        }
    }

    private func failGame() {
        remainingTime = 0
        lastTickDate = nil

        withAnimation(.easeInOut(duration: 0.28)) {
            phase = .gameOver
        }
    }

    private func retry() {
        withAnimation(.easeInOut(duration: 0.28)) {
            phase = .start
        }
        remainingTime = selectedInterval
        circleDiameter = startingCircleDiameter
        lastTickDate = nil
    }

    private func randomCirclePosition(in proxy: GeometryProxy) -> CGPoint {
        let size = proxy.size
        let radius = circleDiameter / 2
        let horizontalPadding = radius + 22
        let topPadding = proxy.safeAreaInsets.top + 126 + radius
        let bottomPadding = proxy.safeAreaInsets.bottom + 30 + radius

        let xRange = horizontalPadding...max(horizontalPadding, size.width - horizontalPadding)
        let yRange = topPadding...max(topPadding, size.height - bottomPadding)

        return CGPoint(
            x: CGFloat.random(in: xRange),
            y: CGFloat.random(in: yRange)
        )
    }

    private var circleColor: Color {
        palette[circleColorIndex]
    }

    private func nextColorIndex(excluding currentIndex: Int) -> Int {
        let candidates = palette.indices.filter { $0 != currentIndex }
        return candidates.randomElement() ?? 0
    }
}

#Preview {
    ContentView()
}
