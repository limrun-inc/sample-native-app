import Combine
import Foundation

enum RunPhase {
    case ready, running, paused, over
}

enum HazardKind {
    case barrier, train, overhead, coin
}

struct TrackObject: Identifiable {
    let id = UUID()
    let lane: Int
    var z: Float
    let kind: HazardKind
    var checked = false
}

final class RunnerGame: ObservableObject {
    @Published private(set) var phase: RunPhase = .ready
    @Published private(set) var lane = 1
    @Published private(set) var score = 0
    @Published private(set) var coins = 0
    @Published private(set) var best = UserDefaults.standard.integer(forKey: "nightRunnerBest")

    private(set) var objects: [TrackObject] = []
    private(set) var distance: Float = 0
    private(set) var jumpTime: Float = 0
    private(set) var slideTime: Float = 0
    private var spawnTime: Float = 0
    private var wave = 0

    var jumpHeight: Float {
        jumpTime > 0 ? sin(.pi * (1 - jumpTime / 0.9)) * 1.8 : 0
    }

    func start() {
        objects = []
        distance = 0
        score = 0
        coins = 0
        lane = 1
        jumpTime = 0
        slideTime = 0
        spawnTime = 0
        wave = 0
        phase = .running
    }

    func pauseOrResume() {
        switch phase {
        case .running: phase = .paused
        case .paused: phase = .running
        default: break
        }
    }

    func move(_ direction: Int) {
        guard phase == .running else { return }
        lane = min(2, max(0, lane + direction))
    }

    func jump() {
        guard phase == .running, jumpTime == 0 else { return }
        slideTime = 0
        jumpTime = 0.9
    }

    func slide() {
        guard phase == .running, jumpTime == 0 else { return }
        slideTime = 0.85
    }

    func update(_ delta: Float) {
        guard phase == .running else { return }
        let step = min(delta, 0.05)
        distance += step * min(28, 17 + distance / 100)
        let newScore = Int(distance)
        if newScore != score { score = newScore }
        jumpTime = max(0, jumpTime - step)
        slideTime = max(0, slideTime - step)

        spawnTime -= step
        if spawnTime <= 0 {
            spawnTime = max(0.85, 1.45 - distance / 650)
            let hazardLane = (wave * 7 + 1) % 3
            let kinds: [HazardKind] = [.barrier, .train, .overhead]
            objects.append(TrackObject(lane: hazardLane, z: -72, kind: kinds[wave % kinds.count]))
            let coinLane = (hazardLane + 1 + wave % 2) % 3
            for index in 0..<3 {
                objects.append(TrackObject(lane: coinLane, z: -77 - Float(index) * 3.2, kind: .coin))
            }
            wave += 1
        }

        for index in objects.indices {
            objects[index].z += step * min(28, 17 + distance / 100)
            guard !objects[index].checked, objects[index].z >= 1.6 else { continue }
            objects[index].checked = true
            guard objects[index].lane == lane else { continue }
            switch objects[index].kind {
            case .coin:
                coins += 1
            case .barrier where jumpHeight > 0.85, .overhead where slideTime > 0:
                break
            default:
                phase = .over
                if score > best {
                    best = score
                    UserDefaults.standard.set(best, forKey: "nightRunnerBest")
                }
            }
            if phase == .over { break }
        }
        objects.removeAll { $0.z > 13 }
    }
}
