//
//  ContentView.swift
//  sample-native-app
//
//  Hosts the Metal-powered Subway Surfers-style runner with a HUD overlay.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var state = GameViewState()
    @State private var resetToken: Int = 0

    var body: some View {
        ZStack {
            GameView(state: state, resetToken: resetToken)
                .ignoresSafeArea()

            VStack {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SCORE")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.85))
                        Text("\(state.score)")
                            .font(.system(size: 36, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(radius: 3)
                            .accessibilityIdentifier("scoreLabel")
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 14))

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("SPEED")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.85))
                        Text(String(format: "%.0f", state.speed * 3.0))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(radius: 3)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)

                Spacer()

                if !state.isGameOver {
                    Text("Swipe ⬅ ➡ to switch lanes  •  Tap or swipe ⬆ to jump")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.black.opacity(0.30), in: Capsule())
                        .padding(.bottom, 24)
                        .accessibilityIdentifier("hintLabel")
                }
            }

            if state.isGameOver {
                VStack(spacing: 18) {
                    Text("BUSTED!")
                        .font(.system(size: 56, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(radius: 4)
                        .accessibilityIdentifier("gameOverLabel")
                    Text("Final score: \(state.score)")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                    Button {
                        resetToken &+= 1
                    } label: {
                        Text("Play Again")
                            .font(.headline)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 14)
                            .background(Color.white, in: Capsule())
                            .foregroundStyle(.black)
                    }
                    .accessibilityIdentifier("playAgainButton")
                }
                .padding(32)
                .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 24))
            }
        }
        .statusBarHidden()
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
