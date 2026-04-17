import SwiftUI
import Combine

// MARK: - Game State

enum GameState {
    case start
    case playing
    case gameOver
}

// MARK: - Game View Model

@MainActor
final class GameViewModel: ObservableObject {

    // Configuration
    static let minCircleSize: CGFloat = 60
    static let maxCircleSize: CGFloat = 120
    static let shrinkAmount: CGFloat = 12

    // Published state
    @Published var gameState: GameState = .start
    @Published var selectedInterval: Double = 3.0
    @Published var score: Int = 0
    @Published var timeRemaining: Double = 3.0
    @Published var circlePosition: CGPoint = .zero
    @Published var circleSize: CGFloat = maxCircleSize
    @Published var circleColor: Color = .blue

    private var timer: Timer?
    private var screenSize: CGSize = .zero
    private let availableColors: [Color] = [
        .red, .orange, .yellow, .green, .mint, .teal,
        .cyan, .blue, .indigo, .purple, .pink
    ]

    func setScreenSize(_ size: CGSize) {
        screenSize = size
    }

    func startGame() {
        score = 0
        circleSize = Self.maxCircleSize
        circleColor = randomColor(excluding: nil)
        circlePosition = randomPosition(for: circleSize)
        timeRemaining = selectedInterval
        gameState = .playing
        startTimer()
    }

    func circleTapped() {
        guard gameState == .playing else { return }
        score += 1

        // Shrink circle, enforce minimum
        circleSize = max(Self.minCircleSize, circleSize - Self.shrinkAmount)

        // Change color and move to new position
        circleColor = randomColor(excluding: circleColor)
        circlePosition = randomPosition(for: circleSize)

        // Reset timer
        timeRemaining = selectedInterval
    }

    func retry() {
        stopTimer()
        gameState = .start
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.timeRemaining -= 0.05
                if self.timeRemaining <= 0 {
                    self.timeRemaining = 0
                    self.stopTimer()
                    self.gameState = .gameOver
                }
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func randomColor(excluding current: Color?) -> Color {
        var candidates = availableColors
        if let current, candidates.count > 1 {
            candidates = candidates.filter { "\($0)" != "\(current)" }
        }
        return candidates.randomElement() ?? .blue
    }

    private func randomPosition(for size: CGFloat) -> CGPoint {
        let safeInset: CGFloat = 20
        let radius = size / 2
        let minX = radius + safeInset
        let maxX = screenSize.width - radius - safeInset
        let minY = radius + 120 // leave room for score bar at top
        let maxY = screenSize.height - radius - safeInset

        guard maxX > minX, maxY > minY else {
            return CGPoint(x: screenSize.width / 2, y: screenSize.height / 2)
        }

        let x = CGFloat.random(in: minX...maxX)
        let y = CGFloat.random(in: minY...maxY)
        return CGPoint(x: x, y: y)
    }
}

// MARK: - Root Content View

struct ContentView: View {
    @StateObject private var vm = GameViewModel()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                switch vm.gameState {
                case .start:
                    StartView(vm: vm)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.95)),
                            removal: .opacity.combined(with: .scale(scale: 1.05))
                        ))
                case .playing:
                    GamePlayView(vm: vm)
                        .transition(.opacity)
                case .gameOver:
                    GameOverView(vm: vm)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.95)),
                            removal: .opacity
                        ))
                }
            }
            .animation(.easeInOut(duration: 0.35), value: vm.gameState)
            .onAppear {
                vm.setScreenSize(geo.size)
            }
            .onChange(of: geo.size) { _, newSize in
                vm.setScreenSize(newSize)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Start Screen

struct StartView: View {
    @ObservedObject var vm: GameViewModel

    private let intervals: [Double] = [2.0, 3.0, 5.0]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.05, blue: 0.15),
                         Color(red: 0.1, green: 0.05, blue: 0.25)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Title
                VStack(spacing: 8) {
                    Text("⚡")
                        .font(.system(size: 64))
                    Text("Speedy Circles")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Tap the circle before time runs out!")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Spacer().frame(height: 56)

                // Interval selector
                VStack(spacing: 14) {
                    Text("Select Time Interval")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                        .textCase(.uppercase)
                        .tracking(1.2)

                    HStack(spacing: 12) {
                        ForEach(intervals, id: \.self) { interval in
                            IntervalButton(
                                label: "\(Int(interval) == Int(interval) ? String(format: "%.0f", interval) : String(interval))s",
                                isSelected: vm.selectedInterval == interval
                            ) {
                                vm.selectedInterval = interval
                            }
                        }
                    }
                }
                .padding(.horizontal, 32)

                Spacer().frame(height: 44)

                // Start button
                Button {
                    vm.startGame()
                } label: {
                    Text("Start Game")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [Color.purple, Color.indigo],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: .purple.opacity(0.5), radius: 12, y: 6)
                }
                .accessibilityIdentifier("startButton")
                .padding(.horizontal, 32)
                .buttonStyle(BouncyButtonStyle())

                Spacer()
            }
        }
    }
}

struct IntervalButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(isSelected ? .white : .white.opacity(0.5))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(isSelected
                              ? LinearGradient(colors: [.purple, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
                              : LinearGradient(colors: [Color.white.opacity(0.08), Color.white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(isSelected ? Color.purple.opacity(0.6) : Color.white.opacity(0.12), lineWidth: 1.5)
                )
        }
        .buttonStyle(BouncyButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Gameplay Screen

struct GamePlayView: View {
    @ObservedObject var vm: GameViewModel

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.12)
                .ignoresSafeArea()

            // Score / Timer HUD
            VStack {
                HUDBar(score: vm.score, timeRemaining: vm.timeRemaining, interval: vm.selectedInterval)
                    .padding(.top, 56)
                    .padding(.horizontal, 20)
                Spacer()
            }

            // Circle
            CircleTarget(color: vm.circleColor, size: vm.circleSize) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
                    vm.circleTapped()
                }
            }
            .position(vm.circlePosition)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: vm.circlePosition)
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: vm.circleSize)
            .animation(.easeInOut(duration: 0.3), value: vm.circleColor.description)
        }
    }
}

struct HUDBar: View {
    let score: Int
    let timeRemaining: Double
    let interval: Double

    private var progress: Double {
        guard interval > 0 else { return 0 }
        return max(0, min(1, timeRemaining / interval))
    }

    private var timerColor: Color {
        if progress > 0.5 { return .green }
        if progress > 0.25 { return .orange }
        return .red
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Label("\(score)", systemImage: "star.fill")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .accessibilityIdentifier("scoreLabel")

                Spacer()

                Text(String(format: "%.1fs", max(0, timeRemaining)))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(timerColor)
                    .contentTransition(.numericText())
                    .accessibilityIdentifier("timerLabel")
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [timerColor.opacity(0.9), timerColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progress, height: 8)
                        .animation(.linear(duration: 0.05), value: timeRemaining)
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
    }
}

struct CircleTarget: View {
    let color: Color
    let size: CGFloat
    let onTap: () -> Void

    @State private var isPressed = false
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Pulse ring
            Circle()
                .strokeBorder(color.opacity(0.35), lineWidth: 3)
                .frame(width: size + 24, height: size + 24)
                .scaleEffect(pulseScale)
                .opacity(2 - pulseScale)

            // Main circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [color.opacity(0.85), color],
                        center: .init(x: 0.35, y: 0.3),
                        startRadius: 0,
                        endRadius: size * 0.7
                    )
                )
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.25), lineWidth: 2)
                )
                .shadow(color: color.opacity(0.6), radius: 18, y: 6)
                .scaleEffect(isPressed ? 0.88 : 1.0)
        }
        .onTapGesture {
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
            }
            onTap()
        }
        .accessibilityIdentifier("circleTarget")
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("Tap the circle")
        .onAppear { startPulse() }
        .onChange(of: color) { _, _ in startPulse() }
        .animation(.spring(response: 0.2, dampingFraction: 0.5), value: isPressed)
    }

    private func startPulse() {
        pulseScale = 1.0
        withAnimation(
            .easeOut(duration: 1.2)
            .repeatForever(autoreverses: false)
        ) {
            pulseScale = 2.0
        }
    }
}

// MARK: - Game Over Screen

struct GameOverView: View {
    @ObservedObject var vm: GameViewModel
    @State private var appear = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.04, blue: 0.18),
                         Color(red: 0.15, green: 0.04, blue: 0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 28) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.15))
                            .frame(width: 120, height: 120)
                        Text("💥")
                            .font(.system(size: 56))
                    }

                    VStack(spacing: 8) {
                        Text("Time's Up!")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Final Score")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.55))
                            .textCase(.uppercase)
                            .tracking(1.5)
                    }

                    // Score badge
                    ZStack {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                            )
                            .frame(width: 160, height: 100)

                        VStack(spacing: 4) {
                            Text("\(vm.score)")
                                .font(.system(size: 52, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .accessibilityIdentifier("finalScoreLabel")
                            Text(vm.score == 1 ? "circle tapped" : "circles tapped")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                    .scaleEffect(appear ? 1.0 : 0.7)
                    .opacity(appear ? 1.0 : 0.0)
                }

                Spacer().frame(height: 56)

                // Retry button
                Button {
                    vm.retry()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 18, weight: .bold))
                        Text("Play Again")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [Color.purple, Color.indigo],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .purple.opacity(0.5), radius: 12, y: 6)
                }
                .accessibilityIdentifier("retryButton")
                .padding(.horizontal, 32)
                .buttonStyle(BouncyButtonStyle())

                Spacer()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.7).delay(0.15)) {
                appear = true
            }
        }
    }
}

// MARK: - Bouncy Button Style

struct BouncyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview {
    ContentView()
}
