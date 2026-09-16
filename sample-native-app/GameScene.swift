//
//  GameScene.swift
//  sample-native-app
//

import SceneKit
import UIKit

final class GameController: NSObject, SCNSceneRendererDelegate {
    let scene = SCNScene()
    let state: GameState

    private let worldNode = SCNNode()
    private var playerNode: SCNNode!
    private var tiles: [SCNNode] = []
    private var buildings: [SCNNode] = []
    private var entities: [SCNNode] = []

    private let laneXs: [Float] = [-2, 0, 2]
    private var targetLane = 1
    private var isLaneMoving = false
    private var isJumping = false
    private var isRolling = false

    private var speed: Float = 12
    private var spawnZ: Float = -40
    private var distanceCounter: Double = 0
    private var lastTime: TimeInterval = 0

    private let skyColor = UIColor(red: 0.53, green: 0.81, blue: 0.98, alpha: 1)

    init(state: GameState) {
        self.state = state
        super.init()
        buildScene()
    }

    // MARK: - Scene construction

    private func buildScene() {
        scene.background.contents = skyColor
        scene.fogStartDistance = 40
        scene.fogEndDistance = 80
        scene.fogColor = skyColor

        scene.rootNode.addChildNode(worldNode)

        let camera = SCNCamera()
        camera.usesOrthographicProjection = false
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 4.5, 7)
        cameraNode.look(at: SCNVector3(0, 1, -6))
        worldNode.addChildNode(cameraNode)

        let directional = SCNNode()
        let directionalLight = SCNLight()
        directionalLight.type = .directional
        directionalLight.intensity = 900
        directional.light = directionalLight
        directional.eulerAngles = SCNVector3(-Float.pi / 3, Float.pi / 6, 0)
        scene.rootNode.addChildNode(directional)

        let ambient = SCNNode()
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.color = UIColor(white: 0.6, alpha: 1)
        ambient.light = ambientLight
        scene.rootNode.addChildNode(ambient)

        // Ground tiles with lane-divider stripes
        for i in 0..<12 {
            let tile = SCNNode(geometry: SCNBox(width: 8, height: 0.2, length: 10, chamferRadius: 0))
            tile.geometry?.firstMaterial?.diffuse.contents = UIColor(white: 0.35, alpha: 1)
            tile.position = SCNVector3(0, -0.1, Float(10 - i * 10))
            for stripeX: Float in [-1, 1] {
                let stripe = SCNNode(geometry: SCNBox(width: 0.1, height: 0.02, length: 9, chamferRadius: 0))
                stripe.geometry?.firstMaterial?.diffuse.contents = UIColor(white: 0.22, alpha: 1)
                stripe.position = SCNVector3(stripeX, 0.11, 0)
                tile.addChildNode(stripe)
            }
            scene.rootNode.addChildNode(tile)
            tiles.append(tile)
        }

        // Side buildings at x = ±5, recycled like tiles
        let buildingColors: [UIColor] = [
            UIColor(red: 0.4, green: 0.5, blue: 0.7, alpha: 1),
            UIColor(red: 0.6, green: 0.45, blue: 0.4, alpha: 1),
            UIColor(red: 0.45, green: 0.6, blue: 0.5, alpha: 1),
            UIColor(red: 0.55, green: 0.5, blue: 0.65, alpha: 1),
        ]
        for i in 0..<24 {
            let height = Float.random(in: 3...8)
            let side: Float = i % 2 == 0 ? -5 : 5
            let b = SCNNode(geometry: SCNBox(width: 2.5, height: CGFloat(height), length: 8, chamferRadius: 0))
            b.geometry?.firstMaterial?.diffuse.contents = buildingColors[i % buildingColors.count]
            b.position = SCNVector3(side, height / 2, Float(10 - (i / 2) * 10))
            scene.rootNode.addChildNode(b)
            buildings.append(b)
        }

        // Player capsule
        let capsule = SCNCapsule(capRadius: 0.35, height: 1.4)
        capsule.firstMaterial?.diffuse.contents = UIColor.orange
        playerNode = SCNNode(geometry: capsule)
        playerNode.position = SCNVector3(laneXs[targetLane], 0.9, 0)
        scene.rootNode.addChildNode(playerNode)
    }

    // MARK: - Public API

    func start() {
        for e in entities { e.removeFromParentNode() }
        entities.removeAll()
        targetLane = 1
        isLaneMoving = false
        isJumping = false
        isRolling = false
        speed = 12
        spawnZ = -40
        distanceCounter = 0
        lastTime = 0
        playerNode.removeAllActions()
        playerNode.position = SCNVector3(laneXs[1], 0.9, 0)
        playerNode.scale = SCNVector3(1, 1, 1)
        playerNode.geometry?.firstMaterial?.diffuse.contents = UIColor.orange
        DispatchQueue.main.async {
            self.state.score = 0
            self.state.coins = 0
            self.state.phase = .running
        }
    }

    func moveLeft() { changeLane(by: -1) }
    func moveRight() { changeLane(by: 1) }

    func jump() {
        guard state.phase == .running, !isJumping else { return }
        isJumping = true
        let up = SCNAction.moveBy(x: 0, y: 2.0, z: 0, duration: 0.35)
        up.timingMode = .easeOut
        let down = SCNAction.moveBy(x: 0, y: -2.0, z: 0, duration: 0.35)
        down.timingMode = .easeIn
        playerNode.runAction(.sequence([up, down, .run { [weak self] _ in
            self?.isJumping = false
        }]))
    }

    func roll() {
        guard state.phase == .running, !isRolling else { return }
        isRolling = true
        let shrink = SCNAction.customAction(duration: 0.1) { node, t in
            node.scale.y = Float(1.0 - 0.5 * min(t / 0.1, 1.0))
        }
        let hold = SCNAction.wait(duration: 0.4)
        let restore = SCNAction.customAction(duration: 0.1) { node, t in
            node.scale.y = Float(0.5 + 0.5 * min(t / 0.1, 1.0))
        }
        playerNode.runAction(.sequence([shrink, hold, restore, .run { [weak self] _ in
            self?.isRolling = false
        }]))
    }

    func gameOver() {
        guard state.phase == .running else { return }
        playerNode.removeAllActions()
        isJumping = false
        isRolling = false
        isLaneMoving = false
        playerNode.scale = SCNVector3(1, 1, 1)
        playerNode.geometry?.firstMaterial?.diffuse.contents = UIColor.gray
        DispatchQueue.main.async {
            self.state.phase = .gameOver
            self.state.updateBest()
        }
    }

    private func changeLane(by delta: Int) {
        guard state.phase == .running, !isLaneMoving else { return }
        let next = targetLane + delta
        guard (0...2).contains(next) else { return }
        targetLane = next
        isLaneMoving = true
        let dx = laneXs[next] - playerNode.position.x
        let move = SCNAction.moveBy(x: CGFloat(dx), y: 0, z: 0, duration: 0.15)
        playerNode.runAction(move) { [weak self] in
            self?.isLaneMoving = false
        }
    }

    // MARK: - Spawning

    private func spawnRow(at z: Float) {
        var blocked = Set<Int>()
        let blockedCount = Int.random(in: 1...2)
        while blocked.count < blockedCount {
            blocked.insert(Int.random(in: 0...2))
        }
        let colors: [UIColor] = [.systemRed, .systemBlue]
        for lane in blocked {
            let kind = ["train", "low", "high"].randomElement()!
            let node: SCNNode
            switch kind {
            case "train":
                node = SCNNode(geometry: SCNBox(width: 1.6, height: 2.6, length: 8, chamferRadius: 0.1))
                node.geometry?.firstMaterial?.diffuse.contents = colors.randomElement()!
                node.position = SCNVector3(laneXs[lane], 1.3, z)
            case "low":
                node = SCNNode(geometry: SCNBox(width: 1.6, height: 1.0, length: 0.4, chamferRadius: 0.05))
                node.geometry?.firstMaterial?.diffuse.contents = UIColor.systemYellow
                node.position = SCNVector3(laneXs[lane], 0.5, z)
            default:
                node = SCNNode(geometry: SCNBox(width: 1.6, height: 1.0, length: 0.4, chamferRadius: 0.05))
                node.geometry?.firstMaterial?.diffuse.contents = UIColor.systemYellow
                node.position = SCNVector3(laneXs[lane], 1.9, z)
            }
            node.name = kind
            scene.rootNode.addChildNode(node)
            entities.append(node)
        }

        let freeLanes = (0...2).filter { !blocked.contains($0) }
        if let coinLane = freeLanes.randomElement() {
            let count = Int.random(in: 3...5)
            for i in 0..<count {
                let coinGeo = SCNCylinder(radius: 0.3, height: 0.08)
                coinGeo.firstMaterial?.diffuse.contents = UIColor(red: 1, green: 0.84, blue: 0, alpha: 1)
                let disc = SCNNode(geometry: coinGeo)
                disc.eulerAngles = SCNVector3(Float.pi / 2, 0, 0)
                let pivot = SCNNode()
                pivot.name = "coin"
                pivot.position = SCNVector3(laneXs[coinLane], 1.0, z - Float(i) * 1.5)
                pivot.addChildNode(disc)
                let spin = SCNAction.repeatForever(.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 1.2))
                pivot.runAction(spin)
                scene.rootNode.addChildNode(pivot)
                entities.append(pivot)
            }
        }
    }

    // MARK: - Renderer delegate

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard state.phase == .running else {
            lastTime = time
            return
        }
        var dt = Float(time - lastTime)
        lastTime = time
        if dt <= 0 { return }
        if dt > 0.05 { dt = 0.05 }

        speed = min(speed + 0.25 * dt, 30)
        let dz = speed * dt

        // Distance-based score
        distanceCounter += Double(dz)
        if distanceCounter >= 1 {
            let gained = Int(distanceCounter)
            distanceCounter -= Double(gained)
            DispatchQueue.main.async { self.state.score += gained }
        }

        // Move world
        for tile in tiles {
            tile.position.z += dz
            if tile.position.z > 10 { tile.position.z -= 120 }
        }
        for b in buildings {
            b.position.z += dz
            if b.position.z > 10 {
                b.position.z -= 120
                let height = Float.random(in: 3...8)
                b.geometry = SCNBox(width: 2.5, height: CGFloat(height), length: 8, chamferRadius: 0)
                b.geometry?.firstMaterial?.diffuse.contents = UIColor(
                    red: CGFloat.random(in: 0.35...0.65),
                    green: CGFloat.random(in: 0.35...0.65),
                    blue: CGFloat.random(in: 0.45...0.75), alpha: 1)
                b.position.y = height / 2
            }
        }
        for e in entities { e.position.z += dz }
        entities.removeAll { e in
            if e.position.z > 12 {
                e.removeFromParentNode()
                return true
            }
            return false
        }

        // Spawn new rows
        spawnZ += dz
        while spawnZ > -120 {
            spawnRow(at: spawnZ)
            spawnZ -= Float.random(in: 10...16)
        }

        // Camera follows player x smoothly
        let px = playerNode.position.x
        worldNode.position.x += (px - worldNode.position.x) * 0.1

        // Collisions
        let playerY = playerNode.presentation.position.y
        let playerX = px
        for e in entities {
            guard e.parent != nil else { continue }
            let p = e.position
            let halfLength: Float
            switch e.name {
            case "train": halfLength = 4.0 + 0.5
            case "low", "high": halfLength = 0.2 + 0.5
            case "coin": halfLength = 0.6
            default: halfLength = 0.5
            }
            guard abs(p.z) < halfLength, abs(p.x - playerX) < 0.8 else { continue }
            switch e.name {
            case "coin":
                e.removeFromParentNode()
                DispatchQueue.main.async {
                    self.state.coins += 1
                    self.state.score += 10
                }
            case "train":
                gameOver()
                return
            case "low":
                if playerY <= 1.6 {
                    gameOver()
                    return
                }
            case "high":
                if !isRolling {
                    gameOver()
                    return
                }
            default:
                break
            }
        }
    }
}
