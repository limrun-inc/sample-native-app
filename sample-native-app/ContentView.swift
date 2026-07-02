//
//  ContentView.swift
//  sample-native-app
//
//  Created by Muvaffak on 1/16/26.
//

import SwiftUI

struct ContentView: View {
    @State private var session = AuthSession()

    var body: some View {
        Group {
            if let user = session.user {
                SignedInView(user: user) {
                    withAnimation(.easeInOut) {
                        session.signOut()
                    }
                }
                .transition(.opacity)
            } else {
                LoginView(session: $session)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: session.isSignedIn)
    }
}

private struct SignedInView: View {
    let user: SignedInUser
    let onSignOut: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(.tint.opacity(0.15))
                    .frame(width: 96, height: 96)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(.tint)
            }
            .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text("Welcome, \(user.displayName)!")
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("welcomeTitle")

                Text("Signed in with \(user.provider.displayName)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("welcomeProvider")

                if let email = user.email, !email.isEmpty {
                    Text(email)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button(role: .destructive, action: onSignOut) {
                Text("Sign Out")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .accessibilityIdentifier("signOutButton")
        }
        .padding()
    }
}

#Preview("Login") {
    ContentView()
}

#Preview("Signed In") {
    SignedInView(
        user: SignedInUser(displayName: "Ada Lovelace", email: "ada@example.com", provider: .apple),
        onSignOut: {}
    )
}
