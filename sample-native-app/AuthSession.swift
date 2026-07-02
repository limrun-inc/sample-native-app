//
//  AuthSession.swift
//  sample-native-app
//

import Foundation

enum AuthProvider: String {
    case apple
    case google

    var displayName: String {
        switch self {
        case .apple: return "Apple"
        case .google: return "Google"
        }
    }
}

struct SignedInUser: Equatable {
    var displayName: String
    var email: String?
    var provider: AuthProvider
}

struct AuthSession: Equatable {
    var user: SignedInUser?

    var isSignedIn: Bool { user != nil }

    mutating func signIn(provider: AuthProvider, displayName: String, email: String?) {
        user = SignedInUser(displayName: displayName, email: email, provider: provider)
    }

    mutating func signOut() {
        user = nil
    }
}
