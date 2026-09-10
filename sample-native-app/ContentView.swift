//
//  ContentView.swift
//  sample-native-app
//
//  Created by Muvaffak on 1/16/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                avatarBadge

                VStack(spacing: 10) {
                    Text("Hello, Grok Bot!")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(titleGradient)
                        .multilineTextAlignment(.center)

                    Text("So glad you made it. Pull up a chair —\nthis home screen was built just for you.")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)

                welcomeCard

                Spacer()

                Label("Crafted with SwiftUI", systemImage: "swift")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.tertiary)
                    .padding(.bottom, 8)
            }
            .padding()
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(.systemBackground),
                Color.indigo.opacity(0.15),
                Color.purple.opacity(0.22),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var titleGradient: LinearGradient {
        LinearGradient(
            colors: [.indigo, .purple],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var avatarBadge: some View {
        ZStack {
            Circle()
                .fill(titleGradient)
                .frame(width: 112, height: 112)
                .shadow(color: .purple.opacity(0.35), radius: 18, y: 8)

            Image(systemName: "sparkles")
                .font(.system(size: 48, weight: .semibold))
                .foregroundStyle(.white)
                .accessibilityHidden(true)
        }
        .accessibilityLabel("Grok Bot avatar")
    }

    private var welcomeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            welcomeRow(
                icon: "hand.wave.fill",
                tint: .orange,
                title: "Warm welcome",
                detail: "Grok Bot, it's wonderful to see you here."
            )

            Divider()

            welcomeRow(
                icon: "bolt.fill",
                tint: .indigo,
                title: "Ready when you are",
                detail: "Everything on this screen is set up for your visit."
            )
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.25), lineWidth: 1)
        )
        .padding(.horizontal, 24)
    }

    private func welcomeRow(icon: String, tint: Color, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 36, height: 36)
                .background(tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                Text(detail)
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    ContentView()
}

#Preview("Dark") {
    ContentView()
        .preferredColorScheme(.dark)
}
