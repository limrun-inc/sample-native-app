//
//  LoginView.swift
//  sample-native-app
//

import SwiftUI

struct LoginView: View {
    @Binding var isLoggedIn: Bool

    @State private var username: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 8) {
                Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.tint)
                Text("Welcome Back")
                    .font(.largeTitle.bold())
                Text("Sign in to continue")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 12) {
                TextField("Username", text: $username)
                    .textContentType(.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier("usernameField")
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))

                SecureField("Password", text: $password)
                    .textContentType(.password)
                    .accessibilityIdentifier("passwordField")
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Button(action: logIn) {
                Text("Log In")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundStyle(.white)
                    .background(.tint, in: RoundedRectangle(cornerRadius: 10))
            }
            .accessibilityIdentifier("logInButton")

            Spacer()
            Spacer()
        }
        .padding()
    }

    private func logIn() {
        guard !username.isEmpty, !password.isEmpty else {
            errorMessage = "Enter a username and password."
            return
        }
        errorMessage = nil
        isLoggedIn = true
    }
}

#Preview {
    LoginView(isLoggedIn: .constant(false))
}
