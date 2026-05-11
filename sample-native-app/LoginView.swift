//
//  LoginView.swift
//  sample-native-app
//

import AuthenticationServices
import SwiftUI

struct LoginView: View {
    @Environment(\.colorScheme) private var colorScheme

    var onSignIn: (AppleIDCredential) -> Void
    var onFailure: (Error) -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.07, blue: 0.12),
                    Color(red: 0.12, green: 0.13, blue: 0.22),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 16) {
                    Image(systemName: "applelogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64, height: 64)
                        .foregroundStyle(.white)
                        .accessibilityHidden(true)

                    Text("Welcome")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.white)

                    Text("Sign in to continue to Sample App")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.75))
                        .padding(.horizontal, 32)
                }

                Spacer()

                VStack(spacing: 16) {
                    SignInWithAppleButton(
                        .signIn,
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            switch result {
                            case .success(let authorization):
                                if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
                                    onSignIn(AppleIDCredential(credential: credential))
                                }
                            case .failure(let error):
                                onFailure(error)
                            }
                        }
                    )
                    .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                    .frame(height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .accessibilityIdentifier("signInWithAppleButton")

                    Text("By continuing you agree to our Terms and Privacy Policy.")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.horizontal, 24)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }
}

struct AppleIDCredential: Equatable {
    let userIdentifier: String
    let email: String?
    let fullName: PersonNameComponents?

    init(credential: ASAuthorizationAppleIDCredential) {
        self.userIdentifier = credential.user
        self.email = credential.email
        self.fullName = credential.fullName
    }

    init(userIdentifier: String, email: String?, fullName: PersonNameComponents?) {
        self.userIdentifier = userIdentifier
        self.email = email
        self.fullName = fullName
    }

    var displayName: String {
        if let fullName, let formatted = PersonNameComponentsFormatter().string(for: fullName), !formatted.isEmpty {
            return formatted
        }
        if let email, !email.isEmpty {
            return email
        }
        return "Apple User"
    }
}

#Preview {
    LoginView(onSignIn: { _ in }, onFailure: { _ in })
}
