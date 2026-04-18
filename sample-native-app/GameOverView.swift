import SwiftUI

struct GameOverView: View {
    var viewModel: GameViewModel

    @State private var animateIn = false

    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Sad circle icon
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.red.opacity(0.85), Color(red: 0.55, green: 0.05, blue: 0.15)],
                                center: .center,
                                startRadius: 0,
                                endRadius: 55
                            )
                        )
                        .frame(width: 110, height: 110)
                        .shadow(color: .red.opacity(0.5), radius: 22, y: 8)

                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .scaleEffect(animateIn ? 1.0 : 0.4)
                .opacity(animateIn ? 1 : 0)
                .padding(.bottom, 28)

                // Game Over title
                Text("Time's Up!")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 20)

                Text("Better luck next time")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.65))
                    .padding(.top, 6)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 12)

                Spacer().frame(height: 44)

                // Score card
                VStack(spacing: 6) {
                    Text("Your Score")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.55))
                        .textCase(.uppercase)
                        .kerning(1.2)

                    Text("\(viewModel.score)")
                        .font(.system(size: 72, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                        .shadow(color: .white.opacity(0.2), radius: 8, y: 0)

                    // Stars indicator (1-3 based on score)
                    HStack(spacing: 6) {
                        ForEach(0..<3) { i in
                            Image(systemName: i < starCount ? "star.fill" : "star")
                                .font(.system(size: 22))
                                .foregroundStyle(i < starCount ? .yellow : .white.opacity(0.25))
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(.vertical, 28)
                .padding(.horizontal, 40)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(.white.opacity(0.18), lineWidth: 1)
                )
                .padding(.horizontal, 32)
                .scaleEffect(animateIn ? 1.0 : 0.8)
                .opacity(animateIn ? 1 : 0)

                Spacer().frame(height: 40)

                // Retry button
                Button {
                    viewModel.retry()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 17, weight: .bold))
                        Text("Play Again")
                            .font(.system(size: 19, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [.red.opacity(0.9), Color(red: 0.55, green: 0.05, blue: 0.15)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: .red.opacity(0.4), radius: 12, y: 6)
                }
                .padding(.horizontal, 32)
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 16)
                .accessibilityIdentifier("retryButton")

                Spacer()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                animateIn = true
            }
        }
    }

    private var starCount: Int {
        switch viewModel.score {
        case 0..<5: return 1
        case 5..<10: return 2
        default: return 3
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.14, green: 0.03, blue: 0.08),
                Color(red: 0.06, green: 0.03, blue: 0.18)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

#Preview {
    GameOverView(viewModel: {
        let vm = GameViewModel()
        vm.gameState = .gameOver
        vm.score = 7
        return vm
    }())
}
