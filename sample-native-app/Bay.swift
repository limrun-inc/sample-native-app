//
//  Bay.swift
//  sample-native-app
//

import Foundation

enum BayStatus {
    case onTrack
    case approachingLimit
    case overLimit

    var color: String {
        switch self {
        case .onTrack: return "green"
        case .approachingLimit: return "yellow"
        case .overLimit: return "red"
        }
    }
}

struct Bay: Identifiable {
    let id: Int
    let name: String
    let technician: String
    let elapsedMinutes: Int
    let limitMinutes: Int

    var status: BayStatus {
        let ratio = Double(elapsedMinutes) / Double(limitMinutes)
        if ratio < 0.8 { return .onTrack }
        if ratio < 1.0 { return .approachingLimit }
        return .overLimit
    }

    static let sample: [Bay] = [
        Bay(id: 1, name: "Bay 1", technician: "J. Alvarez", elapsedMinutes: 18, limitMinutes: 40),
        Bay(id: 2, name: "Bay 2", technician: "M. Chen", elapsedMinutes: 34, limitMinutes: 40),
        Bay(id: 3, name: "Bay 3", technician: "R. Patel", elapsedMinutes: 47, limitMinutes: 40),
        Bay(id: 4, name: "Bay 4", technician: "Empty", elapsedMinutes: 0, limitMinutes: 40),
    ]
}
