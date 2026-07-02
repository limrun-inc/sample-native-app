//
//  LoginView.swift
//  sample-native-app
//

import SwiftUI

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isPasswordVisible: Bool = false
    @State private var rememberMe: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var isLoggedIn: Bool = false

    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case email
        case password
    }

    private var isFormValid: Bool {
        isValidEmail(email) && password.count >= 6
    }

    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    header
                        .padding(.top, 40)

                    formCard

                    socialSection

                    signUpFooter
                        .padding(.bottom, 24)
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationDestination(isPresented: $isLoggedIn) {
            HomeView(email: email)
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.36, green: 0.30, blue: 0.95),
                Color(red: 0.55, green: 0.35, blue: 0.92),
                Color(red: 0.86, green: 0.45, blue: 0.78)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var header: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.18))
                    .frame(width: 96, height: 96)
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
            .accessibilityHidden(true)

            Text("Welcome Back")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .accessibilityIdentifier("welcomeTitle")

            Text("Sign in to continue to your account")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
        }
    }

    private var formCard: some View {
        VStack(spacing: 18) {
            emailField
            passwordField

            HStack {
                Toggle(isOn: $rememberMe) {
                    Text("Remember me")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .toggleStyle(CheckboxToggleStyle())
                .accessibilityIdentifier("rememberMeToggle")

                Spacer()

                Button {
                    // Forgot password placeholder
                } label: {
                    Text("Forgot password?")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color(red: 0.36, green: 0.30, blue: 0.95))
                }
                .accessibilityIdentifier("forgotPasswordButton")
            }

            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("errorMessage")
            }

            signInButton
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(0.18), radius: 18, x: 0, y: 10)
        )
    }

    private var emailField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Email")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                Image(systemName: "envelope.fill")
                    .foregroundStyle(.secondary)
                    .frame(width: 18)
                TextField("you@example.com", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .focused($focusedField, equals: .email)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .password }
                    .accessibilityIdentifier("emailField")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.secondary.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(focusedField == .email ? Color.accentColor : Color.clear, lineWidth: 1.5)
            )
        }
    }

    private var passwordField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Password")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                Image(systemName: "lock.fill")
                    .foregroundStyle(.secondary)
                    .frame(width: 18)

                Group {
                    if isPasswordVisible {
                        TextField("Enter your password", text: $password)
                            .textContentType(.password)
                            .autocorrectionDisabled(true)
                            .textInputAutocapitalization(.never)
                    } else {
                        SecureField("Enter your password", text: $password)
                            .textContentType(.password)
                    }
                }
                .focused($focusedField, equals: .password)
                .submitLabel(.go)
                .onSubmit(performSignIn)
                .accessibilityIdentifier("passwordField")

                Button {
                    isPasswordVisible.toggle()
                } label: {
                    Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("togglePasswordVisibility")
                .accessibilityLabel(isPasswordVisible ? "Hide password" : "Show password")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.secondary.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(focusedField == .password ? Color.accentColor : Color.clear, lineWidth: 1.5)
            )
        }
    }

    private var signInButton: some View {
        Button(action: performSignIn) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                } else {
                    Text("Sign In")
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.36, green: 0.30, blue: 0.95),
                        Color(red: 0.86, green: 0.45, blue: 0.78)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .opacity(isFormValid ? 1.0 : 0.5)
        }
        .disabled(!isFormValid || isLoading)
        .accessibilityIdentifier("signInButton")
    }

    private var socialSection: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                Rectangle()
                    .fill(.white.opacity(0.4))
                    .frame(height: 1)
                Text("OR CONTINUE WITH")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))
                Rectangle()
                    .fill(.white.opacity(0.4))
                    .frame(height: 1)
            }

            HStack(spacing: 12) {
                socialButton(label: "Apple", systemImage: "apple.logo", id: "appleSignInButton")
                socialButton(label: "Google", systemImage: "g.circle.fill", id: "googleSignInButton")
            }
        }
    }

    private func socialButton(label: String, systemImage: String, id: String) -> some View {
        Button {
            // Social sign-in placeholder
        } label: {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                Text(label)
                    .font(.subheadline.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.white.opacity(0.95))
            )
            .foregroundStyle(.black)
        }
        .accessibilityIdentifier(id)
    }

    private var signUpFooter: some View {
        HStack(spacing: 4) {
            Text("Don't have an account?")
                .foregroundStyle(.white.opacity(0.85))
            Button {
                // Sign up placeholder
            } label: {
                Text("Sign Up")
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }
            .accessibilityIdentifier("signUpButton")
        }
        .font(.subheadline)
    }

    private func performSignIn() {
        focusedField = nil
        errorMessage = nil

        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email address."
            return
        }
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters."
            return
        }

        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isLoading = false
            isLoggedIn = true
        }
    }

    private func isValidEmail(_ value: String) -> Bool {
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return value.range(of: pattern, options: .regularExpression) != nil
    }
}

private struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .foregroundStyle(configuration.isOn ? Color.accentColor : .secondary)
                configuration.label
            }
        }
        .buttonStyle(.plain)
    }
}

struct HomeView: View {
    let email: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
            Text("Signed in")
                .font(.title.weight(.bold))
                .accessibilityIdentifier("signedInTitle")
            Text(email)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle("Home")
    }
}

#Preview {
    NavigationStack {
        LoginView()
    }
}
