//
//  LoginView.swift
//  sample-native-app
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @Binding var session: AuthSession

    @State private var statusMessage: String?
    @State private var isWorking: Bool = false

    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 24)

                header

                Spacer(minLength: 32)

                signInCard

                Spacer(minLength: 24)

                footer
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.18))
                    .frame(width: 96, height: 96)
                Image(systemName: "sparkles")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .shadow(color: .black.opacity(0.15), radius: 24, x: 0, y: 12)
            .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text("Welcome to Acme")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .accessibilityIdentifier("loginTitle")

                Text("Sign in to continue")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(.white.opacity(0.85))
                    .accessibilityIdentifier("loginSubtitle")
            }
            .multilineTextAlignment(.center)
        }
    }

    private var signInCard: some View {
        VStack(spacing: 16) {
            SignInWithAppleButton(
                .signIn,
                onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                },
                onCompletion: handleAppleCompletion
            )
            .signInWithAppleButtonStyle(.black)
            .frame(height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .accessibilityIdentifier("signInWithAppleButton")

            GoogleSignInButton(action: handleGoogleTap)
                .frame(height: 52)
                .accessibilityIdentifier("signInWithGoogleButton")

            dividerWithText("or")

            EmailSignInButton(action: handleEmailTap)
                .frame(height: 52)
                .accessibilityIdentifier("signInWithEmailButton")

            if let statusMessage {
                Text(statusMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
                    .accessibilityIdentifier("loginStatusMessage")
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(0.15), radius: 30, x: 0, y: 16)
        )
        .overlay {
            if isWorking {
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.background.opacity(0.6))
                    ProgressView()
                        .controlSize(.large)
                }
                .accessibilityIdentifier("loginProgressOverlay")
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 8) {
            Text("By continuing you agree to our Terms and Privacy Policy.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)

            HStack(spacing: 4) {
                Text("New here?")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.85))
                Button("Create an account") {
                    statusMessage = "Account creation is not configured in this sample."
                }
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white)
                .accessibilityIdentifier("createAccountButton")
            }
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.27, green: 0.36, blue: 0.96),
                Color(red: 0.55, green: 0.32, blue: 0.86),
                Color(red: 0.86, green: 0.34, blue: 0.55)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func dividerWithText(_ text: String) -> some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(height: 1)
            Text(text)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(height: 1)
        }
    }

    // MARK: - Actions

    private func handleAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                statusMessage = "Apple sign-in returned an unexpected credential."
                return
            }
            let displayName = [credential.fullName?.givenName, credential.fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            let resolvedName = displayName.isEmpty ? "Apple User" : displayName
            session.signIn(provider: .apple, displayName: resolvedName, email: credential.email)
            statusMessage = nil

        case .failure(let error):
            if (error as? ASAuthorizationError)?.code == .canceled {
                statusMessage = "Apple sign-in was canceled."
            } else {
                statusMessage = "Apple sign-in failed: \(error.localizedDescription)"
            }
        }
    }

    private func handleGoogleTap() {
        guard !isWorking else { return }
        isWorking = true
        statusMessage = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isWorking = false
            session.signIn(provider: .google, displayName: "Google User", email: "user@example.com")
        }
    }

    private func handleEmailTap() {
        statusMessage = "Email sign-in is not configured in this sample."
    }
}

// MARK: - Google Button

private struct GoogleSignInButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                GoogleLogo()
                    .frame(width: 20, height: 20)
                Text("Sign in with Google")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color(red: 0.13, green: 0.13, blue: 0.13))
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.black.opacity(0.12), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct GoogleLogo: View {
    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0.0, to: 0.25)
                .stroke(Color(red: 0.92, green: 0.26, blue: 0.21), lineWidth: 3)
                .rotationEffect(.degrees(-90))
            Circle()
                .trim(from: 0.25, to: 0.5)
                .stroke(Color(red: 0.98, green: 0.74, blue: 0.02), lineWidth: 3)
                .rotationEffect(.degrees(-90))
            Circle()
                .trim(from: 0.5, to: 0.75)
                .stroke(Color(red: 0.20, green: 0.66, blue: 0.32), lineWidth: 3)
                .rotationEffect(.degrees(-90))
            Circle()
                .trim(from: 0.75, to: 1.0)
                .stroke(Color(red: 0.26, green: 0.52, blue: 0.96), lineWidth: 3)
                .rotationEffect(.degrees(-90))
            Text("G")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.26, green: 0.52, blue: 0.96))
        }
    }
}

// MARK: - Email Button

private struct EmailSignInButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "envelope.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                Text("Continue with Email")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.27, green: 0.36, blue: 0.96),
                                Color(red: 0.55, green: 0.32, blue: 0.86)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    StatefulPreviewWrapper(AuthSession()) { session in
        LoginView(session: session)
    }
}

private struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State private var value: Value
    let content: (Binding<Value>) -> Content

    init(_ initial: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
        _value = State(initialValue: initial)
        self.content = content
    }

    var body: some View {
        content($value)
    }
}
