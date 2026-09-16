//
//  GameState.swift
//  sample-native-app
//

import Combine
import Foundation

final class GameState: ObservableObject {
    enum Phase {
        case ready, running, gameOver
    }

    @Published var phase: Phase = .ready
    @Published var score: Int = 0
    @Published var coins: Int = 0
    @Published var best: Int = UserDefaults.standard.integer(forKey: "bestScore")

    func updateBest() {
        if score > best {
            best = score
            UserDefaults.standard.set(best, forKey: "bestScore")
        }
    }
}
