//
//  GameScene.swift
//  sample-native-app
//
//  Game state and update logic for the Subway Surfers-style runner.
//
//  Coordinate system:
//  - X: lane axis (left negative, right positive)
//  - Y: vertical (up positive)
//  - Z: forward direction is -Z. The player moves through the world by
//    decreasing its z over time. Obstacles are placed at increasingly
//    negative z and the player chases them.
//

import simd
import Foundation

struct InstanceUniform {
    var model: matrix_float4x4
    var color: SIMD4<Float>
}

struct SceneUniforms {
    var viewProjection: matrix_float4x4
    var lightDirection: SIMD3<Float>
    var ambient: Float
}

enum Lane: Int, CaseIterable {
    case left = -1
    case center = 0
    case right = 1

    var x: Float {
        switch self {
        case .left:   return -1.6
        case .center: return 0.0
        case .right:  return 1.6
        }
    }
}

struct Obstacle {
    var lane: Lane
    var z: Float            // world-space z (negative means ahead of the player)
    var height: Float       // tall (jump-blocking) or short (duckable but we just avoid)
    var color: SIMD4<Float>
    var passed: Bool = false
}

final class GameScene {
    // Tunables
    private let laneSwitchDuration: Float = 0.14
    private let baseSpeed: Float = 9.0
    private let maxSpeed: Float = 22.0
    private let speedRampPerSecond: Float = 0.35
    private let gravity: Float = -34.0
    private let jumpVelocity: Float = 11.0
    private let obstacleSpawnDistance: Float = 70.0
    private let despawnBehindDistance: Float = 8.0
    private let initialSpawnGap: Float = 12.0
    private let minSpawnGap: Float = 7.0
    private let trackHalfWidth: Float = 3.2
    private let groundSegmentLength: Float = 12.0
    private let groundSegmentCount: Int = 14
    private let policeFollowDistance: Float = 7.5

    // Player state
    private(set) var playerLane: Lane = .center
    private var playerX: Float = Lane.center.x
    private var laneSwitchT: Float = 1.0
    private var laneSwitchFromX: Float = Lane.center.x
    private var laneSwitchToX: Float = Lane.center.x
    private(set) var playerY: Float = 0.5
    private var playerVY: Float = 0.0
    private(set) var playerZ: Float = 0.0

    // Obstacles
    private(set) var obstacles: [Obstacle] = []
    private var nextSpawnZ: Float = -25.0
    private var rng = SystemRandomNumberGenerator()

    // Game state
    private(set) var speed: Float = 9.0
    private(set) var score: Int = 0
    private(set) var elapsed: Float = 0.0
    private(set) var isGameOver: Bool = false

    // Camera
    var aspect: Float = 1.0
    private let cameraOffset = SIMD3<Float>(0.0, 4.2, 7.5)
    private let cameraLookAheadZ: Float = -6.0

    init() {
        reset()
    }

    func reset() {
        playerLane = .center
        playerX = Lane.center.x
        laneSwitchT = 1.0
        laneSwitchFromX = playerX
        laneSwitchToX = playerX
        playerY = 0.5
        playerVY = 0.0
        playerZ = 0.0
        obstacles.removeAll(keepingCapacity: true)
        nextSpawnZ = -25.0
        speed = baseSpeed
        score = 0
        elapsed = 0
        isGameOver = false
        // Pre-populate the track ahead so the player doesn't see an empty world on start.
        var z: Float = -25.0
        while z > -obstacleSpawnDistance {
            spawnObstacle(at: z)
            z -= randomGap()
        }
        nextSpawnZ = z
    }

    // MARK: - Input

    func swipeLeft() {
        guard !isGameOver else { return }
        if let newLane = Lane(rawValue: playerLane.rawValue - 1) {
            startLaneSwitch(to: newLane)
        }
    }

    func swipeRight() {
        guard !isGameOver else { return }
        if let newLane = Lane(rawValue: playerLane.rawValue + 1) {
            startLaneSwitch(to: newLane)
        }
    }

    func jump() {
        guard !isGameOver else { return }
        // Only allow jump when grounded.
        if abs(playerY - 0.5) < 0.001 && playerVY == 0 {
            playerVY = jumpVelocity
        }
    }

    private func startLaneSwitch(to lane: Lane) {
        laneSwitchFromX = playerX
        laneSwitchToX = lane.x
        laneSwitchT = 0
        playerLane = lane
    }

    // MARK: - Update

    func update(deltaTime dt: Float) {
        guard !isGameOver else { return }
        elapsed += dt

        // Speed ramps up over time.
        speed = min(maxSpeed, baseSpeed + speedRampPerSecond * elapsed)

        // Move forward.
        playerZ -= speed * dt
        score = max(score, Int(-playerZ))

        // Lane switch interpolation (smoothstep).
        if laneSwitchT < 1.0 {
            laneSwitchT = min(1.0, laneSwitchT + dt / laneSwitchDuration)
            let s = laneSwitchT
            let smooth = s * s * (3 - 2 * s)
            playerX = laneSwitchFromX + (laneSwitchToX - laneSwitchFromX) * smooth
        } else {
            playerX = laneSwitchToX
        }

        // Vertical motion (jump + gravity).
        playerY += playerVY * dt
        playerVY += gravity * dt
        if playerY <= 0.5 {
            playerY = 0.5
            playerVY = 0.0
        }

        // Spawn new obstacles ahead.
        while nextSpawnZ > playerZ - obstacleSpawnDistance {
            spawnObstacle(at: nextSpawnZ)
            nextSpawnZ -= randomGap()
        }

        // Cull obstacles behind the player.
        let cullBehindZ = playerZ + despawnBehindDistance
        obstacles.removeAll { $0.z > cullBehindZ }

        // Collision detection.
        let playerHalfX: Float = 0.4
        let playerHalfZ: Float = 0.5
        let playerBottom = playerY - 0.5
        let playerTop = playerY + 0.5
        for obstacle in obstacles {
            let dx = abs(playerX - obstacle.lane.x)
            let dz = abs(playerZ - obstacle.z)
            if dx < (playerHalfX + 0.7) && dz < (playerHalfZ + 0.7) {
                // Vertical overlap with the obstacle's bounding box.
                let obstacleTop = obstacle.height
                if playerBottom < obstacleTop && playerTop > 0 {
                    isGameOver = true
                    break
                }
            }
        }
    }

    private func randomGap() -> Float {
        let progress = min(1.0, elapsed / 45.0)
        let maxGap = max(minSpawnGap + 1.0, initialSpawnGap - progress * 4.0)
        let minGap = max(minSpawnGap, maxGap - 4.0)
        return Float.random(in: minGap...maxGap, using: &rng)
    }

    private func spawnObstacle(at z: Float) {
        // Pick 1 or 2 lanes to leave open so the player always has an out.
        var lanes: [Lane] = Lane.allCases
        let blockedCount = Int.random(in: 1...2, using: &rng)
        lanes.shuffle(using: &rng)
        let blockedLanes = Array(lanes.prefix(blockedCount))
        for lane in blockedLanes {
            let isTall = Bool.random(using: &rng)
            let h: Float = isTall ? 1.4 : 0.9
            let color: SIMD4<Float> = isTall
                ? SIMD4<Float>(0.85, 0.20, 0.20, 1) // red barrier
                : SIMD4<Float>(0.95, 0.65, 0.10, 1) // orange crate
            obstacles.append(Obstacle(lane: lane, z: z, height: h, color: color))
        }
    }

    // MARK: - Rendering data

    /// Build the per-frame instance buffer contents.
    /// Returns instances in an order independent of frame count, so the renderer
    /// can simply upload + draw.
    func buildInstances() -> (instances: [InstanceUniform], uniforms: SceneUniforms) {
        var instances: [InstanceUniform] = []
        instances.reserveCapacity(obstacles.count + 32)

        // Ground segments (scrolling tiles).
        let baseSeg = floor(playerZ / groundSegmentLength)
        for i in -2..<(groundSegmentCount - 2) {
            let segIndex = Int(baseSeg) - i
            let segCenterZ = Float(segIndex) * groundSegmentLength - groundSegmentLength * 0.5
            let isDark = (segIndex & 1) == 0
            let color: SIMD4<Float> = isDark
                ? SIMD4<Float>(0.18, 0.18, 0.22, 1)
                : SIMD4<Float>(0.22, 0.22, 0.28, 1)
            let model = Mat4.translation(SIMD3<Float>(0, -0.25, segCenterZ))
                * Mat4.scale(SIMD3<Float>(trackHalfWidth * 2, 0.5, groundSegmentLength))
            instances.append(InstanceUniform(model: model, color: color))
        }

        // Lane stripes between adjacent lanes.
        for offset in [Float(-0.8), Float(0.8)] {
            let stripeBase = floor(playerZ / 4.0)
            for i in -1..<16 {
                let segZ = (Float(Int(stripeBase) - i)) * 4.0 - 1.0
                let model = Mat4.translation(SIMD3<Float>(offset, 0.001, segZ))
                    * Mat4.scale(SIMD3<Float>(0.08, 0.02, 1.5))
                instances.append(InstanceUniform(
                    model: model,
                    color: SIMD4<Float>(1.0, 0.95, 0.4, 1)
                ))
            }
        }

        // Side rails.
        for side in [Float(-1.0), Float(1.0)] {
            let model = Mat4.translation(SIMD3<Float>(side * trackHalfWidth, 0.4, playerZ - 30.0))
                * Mat4.scale(SIMD3<Float>(0.25, 0.8, 80.0))
            instances.append(InstanceUniform(
                model: model,
                color: SIMD4<Float>(0.45, 0.45, 0.55, 1)
            ))
        }

        // Obstacles.
        for obstacle in obstacles {
            let width: Float = 1.4
            let depth: Float = 1.4
            let model = Mat4.translation(SIMD3<Float>(obstacle.lane.x, obstacle.height * 0.5, obstacle.z))
                * Mat4.scale(SIMD3<Float>(width, obstacle.height, depth))
            instances.append(InstanceUniform(model: model, color: obstacle.color))
        }

        // Player (hero) - body + head for a little more character than a single cube.
        let runBob = sinf(elapsed * 14.0) * 0.05
        let bodyModel = Mat4.translation(SIMD3<Float>(playerX, playerY + runBob, playerZ))
            * Mat4.scale(SIMD3<Float>(0.7, 1.0, 0.55))
        instances.append(InstanceUniform(
            model: bodyModel,
            color: SIMD4<Float>(0.20, 0.55, 0.95, 1)
        ))
        let headModel = Mat4.translation(SIMD3<Float>(playerX, playerY + 0.75 + runBob, playerZ))
            * Mat4.scale(SIMD3<Float>(0.45, 0.45, 0.45))
        instances.append(InstanceUniform(
            model: headModel,
            color: SIMD4<Float>(0.96, 0.80, 0.60, 1)
        ))

        // Police chaser behind the player.
        let policeZ = playerZ + policeFollowDistance + sinf(elapsed * 6.0) * 0.15
        let policeBody = Mat4.translation(SIMD3<Float>(playerX, 0.5, policeZ))
            * Mat4.scale(SIMD3<Float>(0.8, 1.1, 0.6))
        instances.append(InstanceUniform(
            model: policeBody,
            color: SIMD4<Float>(0.10, 0.18, 0.45, 1)
        ))
        let policeHead = Mat4.translation(SIMD3<Float>(playerX, 1.25, policeZ))
            * Mat4.scale(SIMD3<Float>(0.45, 0.45, 0.45))
        instances.append(InstanceUniform(
            model: policeHead,
            color: SIMD4<Float>(0.15, 0.15, 0.20, 1)
        ))
        // Police flashing light on top.
        let lightFlash = (Int(elapsed * 4) & 1) == 0
        let policeLight = Mat4.translation(SIMD3<Float>(playerX, 1.7, policeZ))
            * Mat4.scale(SIMD3<Float>(0.3, 0.15, 0.3))
        instances.append(InstanceUniform(
            model: policeLight,
            color: lightFlash
                ? SIMD4<Float>(1.0, 0.15, 0.15, 1)
                : SIMD4<Float>(0.15, 0.35, 1.0, 1)
        ))

        // Camera.
        let target = SIMD3<Float>(0, 0.8, playerZ + cameraLookAheadZ)
        let eye = SIMD3<Float>(0, cameraOffset.y, playerZ + cameraOffset.z)
        let view = Mat4.lookAt(eye: eye, center: target, up: SIMD3<Float>(0, 1, 0))
        let proj = Mat4.perspective(
            fovYRadians: radians(60),
            aspect: aspect,
            near: 0.1,
            far: 200.0
        )
        let vp = proj * view
        let uniforms = SceneUniforms(
            viewProjection: vp,
            lightDirection: simd_normalize(SIMD3<Float>(-0.5, -1.0, -0.3)),
            ambient: 0.45
        )

        return (instances, uniforms)
    }
}
