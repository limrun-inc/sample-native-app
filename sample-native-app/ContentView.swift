import SwiftUI

struct ContentView: View {
    @State private var viewModel = GameViewModel()

    private var darkBackground: Color {
        Color(red: 0.06, green: 0.04, blue: 0.18)
    }

    var body: some View {
        ZStack {
            // Persistent dark background to prevent white flash during transitions
            darkBackground
                .ignoresSafeArea()

            if viewModel.gameState == .start {
                StartView(viewModel: viewModel)
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            } else if viewModel.gameState == .playing {
                GameView(viewModel: viewModel)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            } else {
                GameOverView(viewModel: viewModel)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.88).combined(with: .opacity),
                        removal: .scale(scale: 0.88).combined(with: .opacity)
                    ))
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: viewModel.gameState)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
