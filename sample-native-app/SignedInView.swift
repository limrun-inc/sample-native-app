//
//  SignedInView.swift
//  sample-native-app
//

import SwiftUI

struct SignedInView: View {
    @EnvironmentObject private var auth: AuthState

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

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "person.crop.circle.fill.badge.checkmark")
                    .font(.system(size: 72, weight: .regular))
                    .foregroundStyle(.white)
                    .symbolRenderingMode(.hierarchical)
                    .accessibilityIdentifier("signedInIcon")

                Text("You're signed in")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .accessibilityIdentifier("signedInTitle")

                VStack(alignment: .leading, spacing: 12) {
                    InfoRow(label: "Name", value: auth.fullName ?? "—", id: "nameRow")
                    Divider().background(.white.opacity(0.15))
                    InfoRow(label: "Email", value: auth.email ?? "—", id: "emailRow")
                    Divider().background(.white.opacity(0.15))
                    InfoRow(label: "User ID", value: auth.userID ?? "—", id: "userIdRow")
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                )
                .padding(.horizontal, 24)

                Spacer()

                Button(role: .destructive) {
                    auth.signOut()
                } label: {
                    Text("Sign Out")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.red.opacity(0.85))
                        )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .accessibilityIdentifier("signOutButton")
            }
        }
    }
}

private struct InfoRow: View {
    let label: String
    let value: String
    let id: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 80, alignment: .leading)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.white)
                .lineLimit(2)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityIdentifier(id)
    }
}

#Preview {
    let state = AuthState()
    state.signIn(userID: "001234.abcdef.5678", fullName: "Jane Appleseed", email: "jane@example.com")
    return SignedInView().environmentObject(state)
}
