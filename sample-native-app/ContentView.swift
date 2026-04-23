//
//  ContentView.swift
//  sample-native-app
//
//  Created by Muvaffak on 1/16/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var input = GameInput()
    @State private var speedKph = 0
    @State private var score = 0
    @State private var isCrashed = false

    var body: some View {
        ZStack {
            MetalDrivingGameView(
                input: input,
                speedKph: $speedKph,
                score: $score,
                isCrashed: $isCrashed
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 10) {
                Text("Metal Car Drive")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                    .accessibilityIdentifier("titleLabel")

                HStack(spacing: 16) {
                    Text("Speed \(speedKph) km/h")
                        .accessibilityIdentifier("speedLabel")
                    Text("Score \(score)")
                        .accessibilityIdentifier("scoreLabel")
                }
                .font(.headline.monospacedDigit())
                .foregroundStyle(.white)

                if isCrashed {
                    Text("Collision! Slow down and steer clear.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.yellow)
                        .accessibilityIdentifier("collisionLabel")
                }

                Spacer()

                VStack(alignment: .leading, spacing: 10) {
                    Text("Steering")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.9))
                    Slider(value: $input.steering, in: -1...1, step: 0.01)
                        .tint(.cyan)
                        .accessibilityIdentifier("steeringSlider")

                    Text("Throttle")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.9))
                    Slider(value: $input.throttle, in: 0...1, step: 0.01)
                        .tint(.green)
                        .accessibilityIdentifier("throttleSlider")

                    Text("Slide steering to change lanes and throttle to control speed.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(14)
                .background(.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 14))
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
