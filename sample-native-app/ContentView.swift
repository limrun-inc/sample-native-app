//
//  ContentView.swift
//  sample-native-app
//
//  Created by Muvaffak on 1/16/26.
//

import SwiftUI

struct ContentView: View {
    @State private var signedInUser: AppleIDCredential?
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if let user = signedInUser {
                SignedInView(user: user) {
                    signedInUser = nil
                }
            } else {
                LoginView(
                    onSignIn: { credential in
                        errorMessage = nil
                        signedInUser = credential
                    },
                    onFailure: { error in
                        errorMessage = error.localizedDescription
                    }
                )
                .overlay(alignment: .top) {
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.red.opacity(0.85), in: Capsule())
                            .padding(.top, 24)
                            .accessibilityIdentifier("loginErrorBanner")
                    }
                }
            }
        }
        .animation(.easeInOut, value: signedInUser)
    }
}

struct SignedInView: View {
    let user: AppleIDCredential
    var onSignOut: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.seal.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .foregroundStyle(.green)

            Text("Signed in")
                .font(.title.weight(.semibold))

            VStack(spacing: 8) {
                Text(user.displayName)
                    .font(.headline)
                if let email = user.email, !email.isEmpty {
                    Text(email)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Text("User ID: \(user.userIdentifier)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .padding(.horizontal, 24)
            }

            Button("Sign out", action: onSignOut)
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("signOutButton")
        }
        .padding()
    }
}

#Preview("Login") {
    ContentView()
}

#Preview("Signed in") {
    SignedInView(
        user: AppleIDCredential(
            userIdentifier: "001234.abcdef.5678",
            email: "jane@example.com",
            fullName: {
                var components = PersonNameComponents()
                components.givenName = "Jane"
                components.familyName = "Appleseed"
                return components
            }()
        ),
        onSignOut: {}
    )
}
