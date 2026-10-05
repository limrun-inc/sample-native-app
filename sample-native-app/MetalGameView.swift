import MetalKit
import SwiftUI
import simd

struct MetalGameView: UIViewRepresentable {
    let game: RunnerGame

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView()
        guard let device = MTLCreateSystemDefaultDevice() else { return view }
        view.device = device
        view.colorPixelFormat = .bgra8Unorm
        view.depthStencilPixelFormat = .depth32Float
        view.clearColor = MTLClearColor(red: 0.055, green: 0.055, blue: 0.14, alpha: 1)
        view.preferredFramesPerSecond = 60
        view.isPaused = false
        view.enableSetNeedsDisplay = false
        context.coordinator.renderer = RunnerRenderer(device: device, game: game)
        view.delegate = context.coordinator.renderer
        return view
    }

    func updateUIView(_ view: MTKView, context: Context) {}

    final class Coordinator {
        var renderer: RunnerRenderer?
    }
}

private struct SceneVertex {
    var position: SIMD3<Float>
    var color: SIMD4<Float>
}

private typealias SceneColor = SIMD4<Float>

private enum Palette {
    static let midnight = SceneColor(0.055, 0.055, 0.14, 1)
    static let street = SceneColor(0.13, 0.12, 0.25, 1)
    static let asphalt = SceneColor(0.19, 0.19, 0.33, 1)
    static let rail = SceneColor(0.55, 0.77, 0.82, 1)
    static let coral = SceneColor(1, 0.34, 0.32, 1)
    static let orange = SceneColor(1, 0.68, 0.35, 1)
    static let gold = SceneColor(1, 0.78, 0.31, 1)
    static let cyan = SceneColor(0.30, 0.91, 0.89, 1)
    static let violet = SceneColor(0.34, 0.28, 0.59, 1)
    static let wall = SceneColor(0.20, 0.18, 0.37, 1)
    static let cream = SceneColor(1, 0.94, 0.79, 1)
}

private struct SceneMesh {
    var vertices: [SceneVertex] = []

    mutating func box(_ x: Float, _ y: Float, _ z: Float,
                      _ width: Float, _ height: Float, _ depth: Float,
                      _ color: SceneColor) {
        let left = x - width / 2, right = x + width / 2
        let bottom = y - height / 2, top = y + height / 2
        let back = z - depth / 2, front = z + depth / 2
        quad(SIMD3(left, bottom, front), SIMD3(right, bottom, front),
             SIMD3(right, top, front), SIMD3(left, top, front), color)
        quad(SIMD3(right, bottom, back), SIMD3(left, bottom, back),
             SIMD3(left, top, back), SIMD3(right, top, back), color * 0.72)
        quad(SIMD3(left, bottom, back), SIMD3(left, bottom, front),
             SIMD3(left, top, front), SIMD3(left, top, back), color * 0.77)
        quad(SIMD3(right, bottom, front), SIMD3(right, bottom, back),
             SIMD3(right, top, back), SIMD3(right, top, front), color * 0.85)
        quad(SIMD3(left, top, front), SIMD3(right, top, front),
             SIMD3(right, top, back), SIMD3(left, top, back), color * 1.14)
        quad(SIMD3(left, bottom, back), SIMD3(right, bottom, back),
             SIMD3(right, bottom, front), SIMD3(left, bottom, front), color * 0.56)
    }

    mutating func quad(_ first: SIMD3<Float>, _ second: SIMD3<Float>,
                       _ third: SIMD3<Float>, _ fourth: SIMD3<Float>, _ color: SceneColor) {
        for point in [first, second, third, first, third, fourth] {
            vertices.append(SceneVertex(position: point, color: color))
        }
    }

    mutating func coin(_ x: Float, _ y: Float, _ z: Float, _ rotation: Float) {
        let segments = 12
        let center = SIMD3<Float>(x, y, z)
        let facing = SceneColor(1, 0.82, 0.37, 1)
        for segment in 0..<segments {
            let first = Float(segment) * 2 * .pi / Float(segments)
            let second = Float(segment + 1) * 2 * .pi / Float(segments)
            let pointA = SIMD3<Float>(x + cos(first) * 0.52 * cos(rotation), y + sin(first) * 0.52,
                                      z + cos(first) * 0.52 * sin(rotation))
            let pointB = SIMD3<Float>(x + cos(second) * 0.52 * cos(rotation), y + sin(second) * 0.52,
                                      z + cos(second) * 0.52 * sin(rotation))
            for point in [center, pointA, pointB] {
                vertices.append(SceneVertex(position: point, color: facing))
            }
        }
        box(x, y, z, 0.16, 0.16, 0.07, Palette.cream)
    }
}

final class RunnerRenderer: NSObject, MTKViewDelegate {
    private let device: MTLDevice
    private let queue: MTLCommandQueue
    private let pipeline: MTLRenderPipelineState
    private let depthState: MTLDepthStencilState
    private let game: RunnerGame
    private var previousTime = CACurrentMediaTime()
    private var elapsed: Float = 0
    private var runnerX: Float = 0

    init?(device: MTLDevice, game: RunnerGame) {
        guard let queue = device.makeCommandQueue(),
              let library = device.makeDefaultLibrary(),
              let vertex = library.makeFunction(name: "runnerVertex"),
              let fragment = library.makeFunction(name: "runnerFragment") else { return nil }
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertex
        descriptor.fragmentFunction = fragment
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        descriptor.depthAttachmentPixelFormat = .depth32Float
        guard let pipeline = try? device.makeRenderPipelineState(descriptor: descriptor) else { return nil }
        let depthDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.depthCompareFunction = .less
        depthDescriptor.isDepthWriteEnabled = true
        guard let depthState = device.makeDepthStencilState(descriptor: depthDescriptor) else { return nil }
        self.device = device
        self.queue = queue
        self.pipeline = pipeline
        self.depthState = depthState
        self.game = game
        super.init()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        let now = CACurrentMediaTime()
        let delta = Float(min(now - previousTime, 0.05))
        previousTime = now
        if game.phase != .paused { elapsed += delta }
        game.update(delta)
        runnerX += (Float(game.lane - 1) * 2.8 - runnerX) * min(1, delta * 13)

        guard let pass = view.currentRenderPassDescriptor,
              let drawable = view.currentDrawable,
              let commandBuffer = queue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: pass) else { return }

        var mesh = SceneMesh()
        buildWorld(into: &mesh)
        let length = mesh.vertices.count * MemoryLayout<SceneVertex>.stride
        guard length > 0,
              let buffer = device.makeBuffer(bytes: mesh.vertices, length: length) else {
            encoder.endEncoding()
            return
        }

        let aspect = Float(view.drawableSize.width / max(view.drawableSize.height, 1))
        let projection = perspective(fov: .pi * 0.39, aspect: aspect, near: 0.1, far: 150)
        let camera = lookAt(eye: SIMD3<Float>(0, 5.8, 14), target: SIMD3<Float>(0, 1.1, -16))
        var transform = projection * camera
        encoder.setRenderPipelineState(pipeline)
        encoder.setDepthStencilState(depthState)
        encoder.setVertexBuffer(buffer, offset: 0, index: 0)
        encoder.setVertexBytes(&transform, length: MemoryLayout<simd_float4x4>.stride, index: 1)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: mesh.vertices.count)
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    private func buildWorld(into mesh: inout SceneMesh) {
        mesh.box(0, -0.55, -38, 12, 0.7, 110, Palette.street)
        mesh.box(0, -0.17, -38, 8.6, 0.08, 110, Palette.asphalt)
        mesh.box(-7.5, -0.2, -38, 3, 0.35, 110, Palette.violet)
        mesh.box(7.5, -0.2, -38, 3, 0.35, 110, Palette.violet)

        for lane in -1...1 {
            let x = Float(lane) * 2.8
            for side in [-1.0 as Float, 1.0] {
                mesh.box(x + side * 0.94, 0.02, -38, 0.13, 0.11, 110, Palette.rail)
                mesh.box(x + side * 0.94, 0.09, -38, 0.045, 0.035, 110, Palette.cyan)
            }
        }

        let offset = game.phase == .ready ? elapsed * 3 : game.distance
        for index in 0..<19 {
            let z = 11 - Float(index) * 5 + offset.truncatingRemainder(dividingBy: 5)
            if z > 13 { continue }
            mesh.box(0, -0.08, z, 8.6, 0.08, 0.31, Palette.wall)
            for lane in -1...1 {
                let x = Float(lane) * 2.8
                mesh.box(x, -0.015, z, 1.9, 0.04, 0.24, Palette.orange * 0.55)
            }
        }

        for index in 0..<13 {
            let z = 9 - Float(index) * 8 + offset.truncatingRemainder(dividingBy: 8)
            if z > 13 { continue }
            for side in [-1.0 as Float, 1.0] {
                let height = Float(7 + (index * 7 + (side > 0 ? 3 : 0)) % 8)
                let x = side * 10.1
                mesh.box(x, height / 2 - 0.1, z - 1, 4.0, height, 6.0,
                         index % 3 == 0 ? Palette.violet : Palette.wall)
                mesh.box(side * 7.97, 3.0, z - 1, 0.05, 4.4, 0.12, Palette.coral * 0.8)
                for floor in 0..<3 {
                    for column in 0..<2 {
                        mesh.box(side * 7.96, Float(floor) * 1.55 + 1.5, z - 2.6 + Float(column) * 2,
                                 0.07, 0.57, 0.9, (index + column) % 3 == 0 ? Palette.coral : Palette.gold * 0.75)
                    }
                }
                mesh.box(side * 5.7, 0.1, z, 0.15, 0.65, 0.15, Palette.cyan)
            }
            if index % 3 == 0 {
                mesh.box(0, 6.2, z - 3, 12, 0.22, 0.22, Palette.violet)
                mesh.box(-5.9, 3.1, z - 3, 0.24, 6.2, 0.24, Palette.violet)
                mesh.box(5.9, 3.1, z - 3, 0.24, 6.2, 0.24, Palette.violet)
                mesh.box(0, 6.0, z - 3, 3.4, 0.18, 0.26, Palette.coral)
            }
        }

        for object in game.objects where !object.checked || object.kind != .coin {
            let x = Float(object.lane - 1) * 2.8
            switch object.kind {
            case .barrier:
                mesh.box(x, 0.54, object.z, 1.85, 1.05, 0.55, Palette.orange)
                mesh.box(x, 0.72, object.z + 0.29, 1.8, 0.17, 0.06, Palette.cream)
                mesh.box(x, 0.3, object.z + 0.29, 1.8, 0.15, 0.06, Palette.coral)
            case .train:
                mesh.box(x, 1.45, object.z - 2.0, 2.15, 2.9, 5.0, Palette.coral)
                mesh.box(x, 1.92, object.z + 0.54, 1.75, 0.95, 0.09, Palette.midnight)
                mesh.box(x, 0.55, object.z + 0.54, 1.75, 0.2, 0.1, Palette.cream)
                for side in [-1.0 as Float, 1.0] {
                    mesh.box(x + side * 0.72, 0.93, object.z + 0.55, 0.26, 0.22, 0.1, Palette.gold)
                }
            case .overhead:
                for side in [-1.0 as Float, 1.0] {
                    mesh.box(x + side * 0.8, 1.25, object.z, 0.18, 2.5, 0.32, Palette.cyan)
                }
                mesh.box(x, 2.15, object.z, 1.8, 0.7, 0.38, Palette.cyan)
                mesh.box(x, 2.15, object.z + 0.2, 1.5, 0.13, 0.05, Palette.midnight)
            case .coin:
                mesh.coin(x, 1.35 + sin(elapsed * 4 + object.z) * 0.13, object.z, elapsed * 2)
            }
        }

        let jumping = game.jumpHeight
        let sliding = game.slideTime > 0
        let bob = game.phase == .running && !sliding && jumping == 0 ? sin(elapsed * 18) * 0.06 : 0
        let base = jumping + bob
        let x = runnerX
        mesh.box(x, 0.12 + base, 2, 1.0, 0.08, 1.35, Palette.midnight)
        if sliding {
            mesh.box(x, 0.52 + base, 2, 0.86, 0.68, 0.6, Palette.coral)
            mesh.box(x, 0.65 + base, 2.35, 0.47, 0.46, 0.44, Palette.cream)
            mesh.box(x, 0.25 + base, 1.48, 0.7, 0.32, 1.0, Palette.cyan)
        } else {
            let stride = game.phase == .running ? sin(elapsed * 18) * 0.19 : 0
            for side in [-1.0 as Float, 1.0] {
                mesh.box(x + side * 0.27, 0.48 + base + side * stride, 2, 0.3, 0.82, 0.38, Palette.midnight)
                mesh.box(x + side * 0.53, 1.42 + base - side * stride, 2, 0.22, 0.75, 0.35, Palette.cream)
                mesh.box(x + side * 0.27, 0.11 + base + side * stride, 2.19, 0.37, 0.18, 0.69, Palette.cyan)
            }
            mesh.box(x, 1.43 + base, 2, 0.83, 0.95, 0.5, Palette.coral)
            mesh.box(x, 1.52 + base, 2.28, 0.4, 0.44, 0.08, Palette.orange)
            mesh.box(x, 2.25 + base, 2, 0.58, 0.6, 0.57, Palette.cream)
            mesh.box(x, 2.58 + base, 2, 0.71, 0.19, 0.68, Palette.midnight)
            mesh.box(x, 2.28 + base, 2.31, 0.44, 0.13, 0.08, Palette.midnight)
        }
    }

    private func perspective(fov: Float, aspect: Float, near: Float, far: Float) -> simd_float4x4 {
        let scale = 1 / tan(fov / 2)
        return simd_float4x4(columns: (
            SIMD4<Float>(scale / aspect, 0, 0, 0),
            SIMD4<Float>(0, scale, 0, 0),
            SIMD4<Float>(0, 0, far / (near - far), -1),
            SIMD4<Float>(0, 0, far * near / (near - far), 0)
        ))
    }

    private func lookAt(eye: SIMD3<Float>, target: SIMD3<Float>) -> simd_float4x4 {
        let forward = simd_normalize(target - eye)
        let right = simd_normalize(simd_cross(forward, SIMD3<Float>(0, 1, 0)))
        let up = simd_cross(right, forward)
        return simd_float4x4(columns: (
            SIMD4<Float>(right.x, up.x, -forward.x, 0),
            SIMD4<Float>(right.y, up.y, -forward.y, 0),
            SIMD4<Float>(right.z, up.z, -forward.z, 0),
            SIMD4<Float>(-simd_dot(right, eye), -simd_dot(up, eye), simd_dot(forward, eye), 1)
        ))
    }
}
