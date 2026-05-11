//
//  LoginView.swift
//  sample-native-app
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject private var auth: AuthState
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.10),
                    Color(red: 0.10, green: 0.10, blue: 0.18),
                    Color(red: 0.18, green: 0.10, blue: 0.28)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 40)

                VStack(spacing: 16) {
                    Image(systemName: "applelogo")
                        .font(.system(size: 64, weight: .regular))
                        .foregroundStyle(.white)
                        .accessibilityIdentifier("appleLogo")

                    Text("Welcome")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.white)
                        .accessibilityIdentifier("welcomeTitle")

                    Text("Sign in to continue to Sample Native App")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .accessibilityIdentifier("welcomeSubtitle")
                }

                Spacer()

                VStack(spacing: 16) {
                    if let errorMessage = auth.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color.red.opacity(0.85))
                            )
                            .transition(.opacity.combined(with: .move(edge: .top)))
                            .accessibilityIdentifier("errorBanner")
                    }

                    SignInWithAppleButton(
                        .signIn,
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: handleCompletion
                    )
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .accessibilityIdentifier("signInWithAppleButton")

                    Text("By continuing, you agree to our Terms of Service and Privacy Policy.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.55))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                        .accessibilityIdentifier("termsFooter")
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .animation(.easeInOut(duration: 0.25), value: auth.errorMessage)
        }
    }

    private func handleCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                auth.setError("Unexpected credential type returned by Apple.")
                return
            }
            let formatter = PersonNameComponentsFormatter()
            let fullName: String? = credential.fullName.map { formatter.string(from: $0) }
                .flatMap { $0.isEmpty ? nil : $0 }
            auth.signIn(
                userID: credential.user,
                fullName: fullName,
                email: credential.email
            )

        case .failure(let error):
            // The simulator typically returns ASAuthorizationError.unknown when the
            // sheet is dismissed. Filter out user-cancellation cases so we don't
            // show a confusing red banner.
            if let authError = error as? ASAuthorizationError {
                switch authError.code {
                case .canceled, .unknown:
                    return
                default:
                    break
                }
            }
            auth.setError("Sign in failed: \(error.localizedDescription)")
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthState())
}
