//
//  ProfileView.swift
//  sample-native-app
//
//  Created by Muvaffak on 1/16/26.
//

import SwiftUI

struct ProfileView: View {
    private let profile = MockProfile.sample

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 64, height: 64)
                            .foregroundStyle(.tint)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(profile.name)
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text(profile.handle)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Account") {
                    LabeledContent("Email", value: profile.email)
                    LabeledContent("Location", value: profile.location)
                    LabeledContent("Member since", value: profile.memberSince)
                }

                Section("Stats") {
                    LabeledContent("Posts", value: "\(profile.posts)")
                    LabeledContent("Followers", value: "\(profile.followers)")
                    LabeledContent("Following", value: "\(profile.following)")
                }
            }
            .navigationTitle("Profile")
        }
    }
}

struct MockProfile {
    let name: String
    let handle: String
    let email: String
    let location: String
    let memberSince: String
    let posts: Int
    let followers: Int
    let following: Int

    static let sample = MockProfile(
        name: "Ada Lovelace",
        handle: "@ada",
        email: "ada@example.com",
        location: "London, UK",
        memberSince: "Jan 2026",
        posts: 42,
        followers: 1280,
        following: 180
    )
}

#Preview {
    ProfileView()
}
