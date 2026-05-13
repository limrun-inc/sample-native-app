//
//  UserProfile.swift
//  sample-native-app
//

import Foundation

struct UserProfile: Identifiable, Equatable {
    let id: UUID
    let name: String
    let username: String
    let bio: String
    let location: String
    let website: String
    let email: String
    let joinedDate: Date
    let avatarSystemName: String
    let stats: ProfileStats
    let interests: [String]
}

struct ProfileStats: Equatable {
    let posts: Int
    let followers: Int
    let following: Int
}

extension UserProfile {
    static let mock = UserProfile(
        id: UUID(),
        name: "Ada Lovelace",
        username: "@ada",
        bio: "Mathematician, writer, and the world's first programmer. Building the future, one algorithm at a time.",
        location: "London, UK",
        website: "ada.example.com",
        email: "ada@example.com",
        joinedDate: Calendar.current.date(from: DateComponents(year: 2024, month: 3, day: 12)) ?? Date(),
        avatarSystemName: "person.crop.circle.fill",
        stats: ProfileStats(posts: 128, followers: 12_400, following: 312),
        interests: ["Algorithms", "Mathematics", "Poetry", "Engines", "Music"]
    )
}
