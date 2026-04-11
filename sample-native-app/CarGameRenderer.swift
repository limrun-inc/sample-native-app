import Foundation
import MetalKit
import simd

struct CarGameSnapshot: Equatable {
    let score: Int
    let bestScore: Int
    let isGameOver: Bool
}

private struct CarGameVertex {
    let position: SIMD2<Float>
    let color: SIMD4<Float>
}

private struct TrafficCar {
    var lane: Int
    var y: Float
    var speed: Float
    var color: SIMD4<Float>
}

final class CarGameRenderer: NSObject, MTKViewDelegate {
    var onStateChange: (CarGameSnapshot) -> Void = { _ in }

    private let laneCenters: [Float] = [-0.52, 0, 0.52]
    private let playerY: Float = -0.78
    private let carBodySize = SIMD2<Float>(0.25, 0.3)
    private let laneDashSize = SIMD2<Float>(0.032, 0.18)
    private let roadSize = SIMD2<Float>(1.52, 2.2)
    private let shoulderSize = SIMD2<Float>(0.16, 2.2)
    private let laneDividerX: [Float] = [-0.26, 0.26]
    private let spawnInterval: Float = 0.9

    private var device: MTLDevice?
    private var commandQueue: MTLCommandQueue?
    private var pipelineState: MTLRenderPipelineState?

    private var lastTimestamp: CFTimeInterval?
    private var lastSnapshot = CarGameSnapshot(score: 0, bestScore: 0, isGameOver: false)
    private var traffic: [TrafficCar] = []
    private var playerLane = 1
    private var score = 0
    private var bestScore = 0
    private var distance: Float = 0
    private var spawnTimer: Float = 0
    private var dashOffset: Float = 0
    private var isGameOver = false

    func configure(view: MTKView) {
        let activeDevice = view.device ?? MTLCreateSystemDefaultDevice()
        view.device = activeDevice
        device = activeDevice
        commandQueue = activeDevice?.makeCommandQueue()

        guard
            let activeDevice,
            let library = try? activeDevice.makeDefaultLibrary(bundle: .main)
        else {
            return
        }

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = library.makeFunction(name: "carVertex")
        pipelineDescriptor.fragmentFunction = library.makeFunction(name: "carFragment")
        pipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat

        pipelineState = try? activeDevice.makeRenderPipelineState(descriptor: pipelineDescriptor)
        publishState(force: true)
    }

    func movePlayer(by step: Int) {
        guard !isGameOver else { return }
        playerLane = min(max(playerLane + step, 0), laneCenters.count - 1)
    }

    func restartGame() {
        traffic.removeAll()
        playerLane = 1
        score = 0
        distance = 0
        spawnTimer = 0
        dashOffset = 0
        isGameOver = false
        lastTimestamp = nil
        publishState(force: true)
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard
            let pipelineState,
            let commandQueue,
            let currentDrawable = view.currentDrawable,
            let renderPassDescriptor = view.currentRenderPassDescriptor
        else {
            return
        }

        let now = CACurrentMediaTime()
        let deltaTime: Float
        if let lastTimestamp {
            deltaTime = min(Float(now - lastTimestamp), 1 / 20)
        } else {
            deltaTime = 1 / 60
        }
        self.lastTimestamp = now

        updateGame(deltaTime: deltaTime)

        let vertices = buildSceneVertices()
        guard
            let activeDevice = device,
            let vertexBuffer = activeDevice.makeBuffer(
                bytes: vertices,
                length: MemoryLayout<CarGameVertex>.stride * vertices.count
            )
        else {
            return
        }

        let commandBuffer = commandQueue.makeCommandBuffer()
        let encoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        encoder?.setRenderPipelineState(pipelineState)
        encoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
        encoder?.endEncoding()

        commandBuffer?.present(currentDrawable)
        commandBuffer?.commit()
    }

    private func updateGame(deltaTime: Float) {
        guard !isGameOver else {
            publishState(force: false)
            return
        }

        distance += deltaTime * 20
        score = Int(distance.rounded(.down))
        bestScore = max(bestScore, score)

        dashOffset += deltaTime * 1.4
        spawnTimer += deltaTime

        if spawnTimer >= spawnInterval {
            spawnTraffic()
            spawnTimer = 0
        }

        for index in traffic.indices {
            traffic[index].y -= traffic[index].speed * deltaTime
        }
        traffic.removeAll { $0.y < -1.4 }

        if traffic.contains(where: { $0.lane == playerLane && abs($0.y - playerY) < 0.23 }) {
            isGameOver = true
        }

        publishState(force: false)
    }

    private func spawnTraffic() {
        let lane = Int.random(in: 0..<laneCenters.count)
        let speed = Float.random(in: 1.1...1.55)
        let colors: [SIMD4<Float>] = [
            SIMD4<Float>(0.94, 0.28, 0.22, 1),
            SIMD4<Float>(0.16, 0.76, 0.56, 1),
            SIMD4<Float>(0.95, 0.72, 0.22, 1),
            SIMD4<Float>(0.43, 0.52, 0.95, 1)
        ]

        traffic.append(
            TrafficCar(
                lane: lane,
                y: 1.28,
                speed: speed,
                color: colors.randomElement() ?? SIMD4<Float>(1, 1, 1, 1)
            )
        )
    }

    private func publishState(force: Bool) {
        let snapshot = CarGameSnapshot(score: score, bestScore: bestScore, isGameOver: isGameOver)
        guard force || snapshot != lastSnapshot else { return }
        lastSnapshot = snapshot
        onStateChange(snapshot)
    }

    private func buildSceneVertices() -> [CarGameVertex] {
        var vertices: [CarGameVertex] = []

        appendRectangle(
            center: SIMD2<Float>(0, 0),
            size: roadSize,
            color: SIMD4<Float>(0.14, 0.15, 0.18, 1),
            vertices: &vertices
        )

        appendRectangle(
            center: SIMD2<Float>(-0.84, 0),
            size: shoulderSize,
            color: SIMD4<Float>(0.05, 0.32, 0.19, 1),
            vertices: &vertices
        )
        appendRectangle(
            center: SIMD2<Float>(0.84, 0),
            size: shoulderSize,
            color: SIMD4<Float>(0.05, 0.32, 0.19, 1),
            vertices: &vertices
        )

        for dividerX in laneDividerX {
            var y = -1.15 + dashOffset.truncatingRemainder(dividingBy: 0.32)
            while y < 1.2 {
                appendRectangle(
                    center: SIMD2<Float>(dividerX, y),
                    size: laneDashSize,
                    color: SIMD4<Float>(0.96, 0.96, 0.98, 0.95),
                    vertices: &vertices
                )
                y += 0.32
            }
        }

        for car in traffic {
            appendCar(
                center: SIMD2<Float>(laneCenters[car.lane], car.y),
                bodyColor: car.color,
                windshieldColor: SIMD4<Float>(0.88, 0.96, 1, 0.95),
                vertices: &vertices
            )
        }

        appendCar(
            center: SIMD2<Float>(laneCenters[playerLane], playerY),
            bodyColor: SIMD4<Float>(0.2, 0.72, 1, 1),
            windshieldColor: SIMD4<Float>(0.92, 0.97, 1, 1),
            vertices: &vertices
        )

        appendRectangle(
            center: SIMD2<Float>(laneCenters[playerLane], playerY - 0.18),
            size: SIMD2<Float>(0.19, 0.03),
            color: SIMD4<Float>(1, 0.25, 0.18, 1),
            vertices: &vertices
        )

        return vertices
    }

    private func appendCar(
        center: SIMD2<Float>,
        bodyColor: SIMD4<Float>,
        windshieldColor: SIMD4<Float>,
        vertices: inout [CarGameVertex]
    ) {
        appendRectangle(center: center, size: carBodySize, color: bodyColor, vertices: &vertices)
        appendRectangle(
            center: SIMD2<Float>(center.x, center.y + 0.04),
            size: SIMD2<Float>(0.16, 0.09),
            color: windshieldColor,
            vertices: &vertices
        )
        appendRectangle(
            center: SIMD2<Float>(center.x, center.y - 0.14),
            size: SIMD2<Float>(0.18, 0.025),
            color: SIMD4<Float>(0.1, 0.1, 0.16, 1),
            vertices: &vertices
        )
    }

    private func appendRectangle(
        center: SIMD2<Float>,
        size: SIMD2<Float>,
        color: SIMD4<Float>,
        vertices: inout [CarGameVertex]
    ) {
        let halfWidth = size.x / 2
        let halfHeight = size.y / 2

        let topLeft = SIMD2<Float>(center.x - halfWidth, center.y + halfHeight)
        let topRight = SIMD2<Float>(center.x + halfWidth, center.y + halfHeight)
        let bottomLeft = SIMD2<Float>(center.x - halfWidth, center.y - halfHeight)
        let bottomRight = SIMD2<Float>(center.x + halfWidth, center.y - halfHeight)

        vertices.append(contentsOf: [
            CarGameVertex(position: topLeft, color: color),
            CarGameVertex(position: bottomLeft, color: color),
            CarGameVertex(position: topRight, color: color),
            CarGameVertex(position: topRight, color: color),
            CarGameVertex(position: bottomLeft, color: color),
            CarGameVertex(position: bottomRight, color: color)
        ])
    }
}
