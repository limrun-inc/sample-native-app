//
//  AuthState.swift
//  sample-native-app
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class AuthState: ObservableObject {
    @Published var userID: String?
    @Published var fullName: String?
    @Published var email: String?
    @Published var errorMessage: String?

    private let userIDKey = "auth.userID"
    private let fullNameKey = "auth.fullName"
    private let emailKey = "auth.email"

    var isSignedIn: Bool { userID != nil }

    init() {
        let defaults = UserDefaults.standard
        self.userID = defaults.string(forKey: userIDKey)
        self.fullName = defaults.string(forKey: fullNameKey)
        self.email = defaults.string(forKey: emailKey)
    }

    func signIn(userID: String, fullName: String?, email: String?) {
        let defaults = UserDefaults.standard
        self.userID = userID
        defaults.set(userID, forKey: userIDKey)

        // Apple only returns fullName/email on the very first authorization for a
        // given Apple ID. Persist whatever we have, but don't overwrite an existing
        // value with nil on subsequent sign-ins.
        if let fullName, !fullName.isEmpty {
            self.fullName = fullName
            defaults.set(fullName, forKey: fullNameKey)
        }
        if let email, !email.isEmpty {
            self.email = email
            defaults.set(email, forKey: emailKey)
        }
        self.errorMessage = nil
    }

    func signOut() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: userIDKey)
        defaults.removeObject(forKey: fullNameKey)
        defaults.removeObject(forKey: emailKey)
        self.userID = nil
        self.fullName = nil
        self.email = nil
        self.errorMessage = nil
    }

    func setError(_ message: String) {
        self.errorMessage = message
    }
}
