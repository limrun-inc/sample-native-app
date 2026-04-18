import SwiftUI

struct GameView: View {
    var viewModel: GameViewModel

    var body: some View {
        GeometryReader { geo in
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()

                // The circle (only show once position is valid)
                if viewModel.gameState == .playing {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [viewModel.circleColor.opacity(0.95), viewModel.circleColor],
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: viewModel.circleSize
                            )
                        )
                        .overlay(
                            Circle()
                                .stroke(.white.opacity(0.35), lineWidth: 3)
                        )
                        .shadow(color: viewModel.circleColor.opacity(0.6), radius: 18, y: 6)
                        .frame(width: viewModel.circleSize, height: viewModel.circleSize)
                        .position(viewModel.circlePosition)
                        .onTapGesture {
                            viewModel.circleTapped()
                        }
                        .animation(.spring(response: 0.4, dampingFraction: 0.65), value: viewModel.circlePosition)
                        .animation(.easeInOut(duration: 0.25), value: viewModel.circleSize)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.circleColor)
                        .accessibilityIdentifier("gameCircle")
                }

                // HUD pinned to top safe area
                VStack(spacing: 0) {
                    HUDBar(score: viewModel.score,
                           timeRemaining: viewModel.timeRemaining,
                           totalTime: viewModel.selectedInterval)
                        .padding(.top, geo.safeAreaInsets.top + 8)
                        .padding(.horizontal, 20)
                    Spacer()
                }
            }
            .onAppear {
                viewModel.configure(screenSize: geo.size, topSafeArea: geo.safeAreaInsets.top)
                viewModel.beginGameplay()
            }
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.05, green: 0.03, blue: 0.16),
                Color(red: 0.10, green: 0.05, blue: 0.24)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

struct HUDBar: View {
    let score: Int
    let timeRemaining: Double
    let totalTime: Double

    private var timerFraction: Double {
        guard totalTime > 0 else { return 1 }
        return min(max(timeRemaining / totalTime, 0), 1)
    }

    private var timerColor: Color {
        if timerFraction > 0.5 { return .green }
        if timerFraction > 0.25 { return .orange }
        return .red
    }

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Score pill
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.yellow)
                Text("\(score)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3), value: score)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.white.opacity(0.1), in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.2), lineWidth: 1))

            Spacer()

            // Timer pill
            HStack(spacing: 8) {
                // Circular countdown ring (depletes as time runs out)
                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.2), lineWidth: 3)
                        .frame(width: 28, height: 28)
                    Circle()
                        .trim(from: 0, to: timerFraction)
                        .stroke(timerColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 28, height: 28)
                        .rotationEffect(.degrees(90))
                        .scaleEffect(x: -1, y: 1)
                        .animation(.linear(duration: 0.05), value: timerFraction)
                }

                Text(String(format: "%.1f", max(timeRemaining, 0)))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(timerColor)
                    .monospacedDigit()
                    .animation(.linear(duration: 0.05), value: timeRemaining)
                    .accessibilityIdentifier("timerLabel")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.white.opacity(0.1), in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.2), lineWidth: 1))
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    GameView(viewModel: {
        let vm = GameViewModel()
        vm.startGame(interval: 3.0)
        return vm
    }())
}
