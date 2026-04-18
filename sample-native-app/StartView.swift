import SwiftUI

struct StartView: View {
    var viewModel: GameViewModel

    @State private var selectedInterval: Double = 3.0
    private let intervals: [Double] = [2.0, 3.0, 5.0]

    var body: some View {
        ZStack {
            backgroundGradient

            VStack(spacing: 0) {
                Spacer()

                // Hero icon
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.purple.opacity(0.9), .indigo],
                                center: .center,
                                startRadius: 0,
                                endRadius: 55
                            )
                        )
                        .frame(width: 110, height: 110)
                        .shadow(color: .purple.opacity(0.5), radius: 20, y: 8)

                    Image(systemName: "circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(.bottom, 28)

                // Title
                Text("Speedy Circles")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.25), radius: 4, y: 2)

                Text("Tap the circle before time runs out!")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                    .padding(.horizontal, 32)

                Spacer().frame(height: 52)

                // Interval picker
                VStack(spacing: 14) {
                    Text("Time per circle")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                        .textCase(.uppercase)
                        .kerning(1)

                    HStack(spacing: 12) {
                        ForEach(intervals, id: \.self) { interval in
                            IntervalButton(
                                label: String(format: "%.0fs", interval),
                                isSelected: selectedInterval == interval
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedInterval = interval
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 32)

                Spacer().frame(height: 40)

                // Start button
                Button {
                    viewModel.startGame(interval: selectedInterval)
                } label: {
                    Text("Start Game")
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [.purple, .indigo],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(color: .purple.opacity(0.45), radius: 12, y: 6)
                }
                .padding(.horizontal, 32)
                .accessibilityIdentifier("startButton")

                Spacer()
            }
        }
        .ignoresSafeArea()
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.06, green: 0.04, blue: 0.18),
                Color(red: 0.12, green: 0.06, blue: 0.28)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

struct IntervalButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(isSelected ? Color(red: 0.06, green: 0.04, blue: 0.18) : .white)
                .frame(width: 80, height: 52)
                .background(
                    Group {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(.white)
                        } else {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(.white.opacity(0.12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(.white.opacity(0.25), lineWidth: 1)
                                )
                        }
                    }
                )
                .shadow(color: isSelected ? .white.opacity(0.25) : .clear, radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    StartView(viewModel: GameViewModel())
}
