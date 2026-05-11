//
//  GameWorld.swift
//  sample-native-app
//
//  Game state for the three-lane endless runner.
//

import Foundation
import simd

/// Game-side coordinate convention used everywhere in the renderer:
///   +X = right
///   +Y = up
///   +Z = behind the camera (forward direction the hero runs is -Z)
///
/// The hero is always positioned at world Z = 0; obstacles spawn far in the
/// negative-Z distance and "approach" by increasing their Z toward the camera.
final class GameWorld {

    // MARK: - Tunables

    static let laneOffset: Float = 1.4         // world-X distance between lane centers
    static let groundHalfWidth: Float = 2.6    // visible ground extends ±this in X
    static let trackHalfLength: Float = 80     // visible track length in Z
    static let groundY: Float = 0              // top of ground plane (hero stands at this Y)
    static let heroHeight: Float = 1.4
    static let heroWidth: Float = 0.7
    static let policeHeight: Float = 1.5
    static let jumpVelocity: Float = 9.5
    static let gravity: Float = 26.0
    static let initialSpeed: Float = 11.0
    static let maxSpeed: Float = 26.0
    static let speedRamp: Float = 0.18         // units per second, per second

    // MARK: - Obstacle definition

    enum ObstacleKind {
        case lowBarrier   // can be jumped over
        case tallBlock    // must be avoided by switching lanes
    }

    struct Obstacle: Identifiable {
        let id = UUID()
        var kind: ObstacleKind
        var lane: Int            // -1, 0, +1
        var z: Float             // world Z (negative is far ahead)
        var size: SIMD3<Float>   // width, height, depth in world units

        var color: SIMD4<Float> {
            switch kind {
            case .lowBarrier: return SIMD4(0.95, 0.25, 0.20, 1)   // red barrier
            case .tallBlock:  return SIMD4(0.55, 0.35, 0.18, 1)   // brown crate
            }
        }
    }

    // MARK: - State

    /// Smooth lane index in [-1, +1].
    private(set) var heroLane: Float = 0
    /// Discrete lane the player wants to be in.
    private(set) var heroLaneTarget: Int = 0
    private(set) var heroY: Float = 0
    private(set) var heroVY: Float = 0
    private(set) var heroRun: Float = 0     // running animation phase
    private(set) var distance: Float = 0
    private(set) var speed: Float = GameWorld.initialSpeed
    private(set) var policeDistance: Float = 4.0   // how far the police is behind the hero (positive Z)
    private(set) var obstacles: [Obstacle] = []
    private(set) var score: Int = 0
    private(set) var isGameOver: Bool = false

    private var spawnCursorZ: Float = -25
    private var rng = SystemRandomNumberGenerator()

    init() {
        // Pre-populate a few obstacles so the world isn't empty at start.
        for _ in 0..<6 { spawnNextObstacle() }
    }

    // MARK: - Input

    func swipeLeft() {
        guard !isGameOver else { return }
        heroLaneTarget = max(-1, heroLaneTarget - 1)
    }

    func swipeRight() {
        guard !isGameOver else { return }
        heroLaneTarget = min(1, heroLaneTarget + 1)
    }

    func jump() {
        guard !isGameOver else { return }
        if heroY <= 0.01 {
            heroVY = GameWorld.jumpVelocity
        }
    }

    func restart() {
        heroLane = 0
        heroLaneTarget = 0
        heroY = 0
        heroVY = 0
        distance = 0
        speed = GameWorld.initialSpeed
        policeDistance = 4.0
        obstacles.removeAll()
        spawnCursorZ = -25
        isGameOver = false
        score = 0
        for _ in 0..<6 { spawnNextObstacle() }
    }

    // MARK: - Update

    func update(dt: Float) {
        if isGameOver {
            // After death, let the police catch up briefly and stop.
            policeDistance = max(0.6, policeDistance - dt * 1.5)
            return
        }

        // Speed ramp up over time.
        speed = min(GameWorld.maxSpeed, speed + GameWorld.speedRamp * dt)
        distance += speed * dt
        score = Int(distance)
        heroRun += dt * speed * 1.6

        // Smoothly move the hero toward the target lane.
        let target = Float(heroLaneTarget)
        let laneSpeed: Float = 12.0
        let alpha = 1 - exp(-laneSpeed * dt)
        heroLane += (target - heroLane) * alpha

        // Vertical jump physics.
        heroVY -= GameWorld.gravity * dt
        heroY  += heroVY * dt
        if heroY < 0 {
            heroY = 0
            heroVY = 0
        }

        // Move all obstacles toward the camera.
        for i in obstacles.indices {
            obstacles[i].z += speed * dt
        }

        // Recycle obstacles that have passed behind the camera.
        obstacles.removeAll { $0.z > 6 }

        // Spawn new obstacles to keep the track populated.
        while spawnCursorZ + speed * dt > -GameWorld.trackHalfLength + 20 {
            spawnNextObstacle()
        }
        // Move the spawn cursor along with the world so it stays "ahead".
        spawnCursorZ += speed * dt

        // Collision detection (only while the hero is still settled in / near
        // the chosen lane).
        let heroX = Float(heroLaneTarget) * GameWorld.laneOffset
        let heroMinY = heroY
        let heroMaxY = heroY + GameWorld.heroHeight
        let heroHalfW: Float = GameWorld.heroWidth * 0.5
        let heroHalfD: Float = 0.45

        for obs in obstacles {
            let obsX = Float(obs.lane) * GameWorld.laneOffset
            let dx = abs(heroX - obsX)
            let dz = abs(0 - obs.z)
            let obsHalfW = obs.size.x * 0.5
            let obsHalfD = obs.size.z * 0.5
            let obsMaxY = obs.size.y
            if dx < (heroHalfW + obsHalfW) * 0.85 &&
               dz < (heroHalfD + obsHalfD) * 0.85 &&
               heroMinY < obsMaxY - 0.05 &&
               heroMaxY > 0 {
                triggerGameOver()
                break
            }
        }
    }

    private func triggerGameOver() {
        isGameOver = true
        // Pull the police forward dramatically.
        policeDistance = 3.5
    }

    // MARK: - Obstacle generation

    private func spawnNextObstacle() {
        // Step the cursor forward by a random gap.
        let gap = Float.random(in: 6...11, using: &rng)
        spawnCursorZ -= gap

        // Decide a configuration. Sometimes spawn a "double" that blocks two
        // adjacent lanes, forcing the player to commit to a specific lane.
        let pattern = Int.random(in: 0...4, using: &rng)
        switch pattern {
        case 0:
            let lane = Int.random(in: -1...1, using: &rng)
            addObstacle(.lowBarrier, lane: lane, z: spawnCursorZ)
        case 1:
            let lane = Int.random(in: -1...1, using: &rng)
            addObstacle(.tallBlock, lane: lane, z: spawnCursorZ)
        case 2:
            // Two lanes blocked, one open.
            let openLane = Int.random(in: -1...1, using: &rng)
            for lane in -1...1 where lane != openLane {
                addObstacle(.tallBlock, lane: lane, z: spawnCursorZ)
            }
        case 3:
            // A row of low barriers across all three lanes — must jump.
            for lane in -1...1 {
                addObstacle(.lowBarrier, lane: lane, z: spawnCursorZ)
            }
        default:
            // Mixed: tall on one side, low on another.
            let side = Bool.random(using: &rng) ? -1 : 1
            addObstacle(.tallBlock, lane: side, z: spawnCursorZ)
            addObstacle(.lowBarrier, lane: 0, z: spawnCursorZ - 2.0)
        }
    }

    private func addObstacle(_ kind: ObstacleKind, lane: Int, z: Float) {
        let size: SIMD3<Float>
        switch kind {
        case .lowBarrier:
            size = SIMD3(1.05, 0.7, 0.45)
        case .tallBlock:
            size = SIMD3(1.10, 1.7, 1.05)
        }
        obstacles.append(Obstacle(kind: kind, lane: lane, z: z, size: size))
    }
}
