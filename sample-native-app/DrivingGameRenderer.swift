import Foundation
import Metal
import MetalKit
import QuartzCore
import simd

private struct Vertex {
    let position: SIMD3<Float>
    let color: SIMD4<Float>
}

private struct Uniforms {
    var viewProjection: simd_float4x4
}

private struct ModelConstants {
    var modelMatrix: simd_float4x4
}

private struct SceneObject {
    var transform: simd_float4x4
    var color: SIMD4<Float>
}

final class DrivingGameRenderer: NSObject, MTKViewDelegate {
    private let device: MTLDevice
    private let queue: MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState
    private let depthState: MTLDepthStencilState
    private let vertexBuffer: MTLBuffer
    private let indexBuffer: MTLBuffer
    private let indexCount: Int
    var input: GameInput
    private let updateHud: (Int, Int, Bool) -> Void

    private var projection = matrix_identity_float4x4
    private var elapsed: Float = 0
    private var lastTimestamp: CFTimeInterval = 0

    private var roadOffset: Float = 0
    private var playerX: Float = 0
    private var speed: Float = 0
    private var score: Int = 0
    private var crashed = false

    private var obstacles: [Float] = []
    private var obstacleLanes: [Float] = []

    init?(mtkView: MTKView, input: GameInput, updateHud: @escaping (Int, Int, Bool) -> Void) {
        guard let device = MTLCreateSystemDefaultDevice(),
              let queue = device.makeCommandQueue(),
              let library = try? device.makeLibrary(source: Self.shaderSource, options: nil),
              let vertexFunction = library.makeFunction(name: "vertex_main"),
              let fragmentFunction = library.makeFunction(name: "fragment_main") else {
            return nil
        }

        self.device = device
        self.queue = queue
        self.input = input
        self.updateHud = updateHud

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        descriptor.depthAttachmentPixelFormat = .depth32Float
        descriptor.vertexDescriptor = Self.makeVertexDescriptor()

        guard let state = try? device.makeRenderPipelineState(descriptor: descriptor) else {
            return nil
        }
        pipelineState = state

        let depthDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.depthCompareFunction = .less
        depthDescriptor.isDepthWriteEnabled = true
        guard let depth = device.makeDepthStencilState(descriptor: depthDescriptor) else {
            return nil
        }
        depthState = depth

        let (vertices, indices) = Self.makeCubeGeometry()
        guard let vb = device.makeBuffer(bytes: vertices, length: MemoryLayout<Vertex>.stride * vertices.count),
              let ib = device.makeBuffer(bytes: indices, length: MemoryLayout<UInt16>.stride * indices.count) else {
            return nil
        }
        vertexBuffer = vb
        indexBuffer = ib
        indexCount = indices.count

        super.init()

        mtkView.device = device
        mtkView.depthStencilPixelFormat = .depth32Float
        mtkView.clearColor = MTLClearColor(red: 0.06, green: 0.1, blue: 0.16, alpha: 1.0)
        mtkView.preferredFramesPerSecond = 60
        mtkView.delegate = self
        updateProjection(size: mtkView.drawableSize)
        resetObstacles()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        updateProjection(size: size)
    }

    func draw(in view: MTKView) {
        guard let renderPass = view.currentRenderPassDescriptor,
              let drawable = view.currentDrawable,
              let command = queue.makeCommandBuffer(),
              let encoder = command.makeRenderCommandEncoder(descriptor: renderPass) else {
            return
        }

        let now = CACurrentMediaTime()
        let dt = lastTimestamp == 0 ? 1.0 / 60.0 : min(0.05, now - lastTimestamp)
        lastTimestamp = now
        step(delta: Float(dt))

        encoder.setRenderPipelineState(pipelineState)
        encoder.setDepthStencilState(depthState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)

        let cameraPos = SIMD3<Float>(0, 2.5, 6.5)
        let viewMatrix = float4x4.lookAt(eye: cameraPos, target: SIMD3<Float>(0, 0.1, -5), up: SIMD3<Float>(0, 1, 0))
        var uniforms = Uniforms(viewProjection: projection * viewMatrix)
        encoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)

        for object in sceneObjects() {
            var model = ModelConstants(modelMatrix: object.transform)
            var color = object.color
            encoder.setVertexBytes(&model, length: MemoryLayout<ModelConstants>.stride, index: 2)
            encoder.setFragmentBytes(&color, length: MemoryLayout<SIMD4<Float>>.stride, index: 0)
            encoder.drawIndexedPrimitives(type: .triangle, indexCount: indexCount, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)
        }

        encoder.endEncoding()
        command.present(drawable)
        command.commit()
    }

    private func step(delta: Float) {
        elapsed += delta
        let targetSpeed = max(Float(4), Float(input.throttle) * Float(35))
        let speedBlend = min(Float(1), delta * Float(4))
        speed += (targetSpeed - speed) * speedBlend
        roadOffset += speed * delta

        playerX += Float(input.steering) * delta * 5.5
        playerX = max(-2.1, min(2.1, playerX))

        crashed = false
        for i in obstacles.indices {
            obstacles[i] += speed * delta
            if obstacles[i] > 4 {
                obstacles[i] = -55 - Float.random(in: 0...25)
                obstacleLanes[i] = laneX(for: Int.random(in: 0...2))
                score += 10
            }

            let dz = obstacles[i] + 2.4
            let dx = abs(obstacleLanes[i] - playerX)
            if dz > -0.8 && dz < 0.9 && dx < 0.7 {
                crashed = true
            }
        }

        if crashed {
            speed *= 0.9
            score = max(0, score - 1)
        } else {
            score += Int(speed * delta * 0.7)
        }

        updateHud(Int(speed * 3.2), score, crashed)
    }

    private func sceneObjects() -> [SceneObject] {
        var objects: [SceneObject] = []

        objects.append(SceneObject(
            transform: float4x4.translation(0, -0.35, -12) * float4x4.scale(5.8, 0.1, 30),
            color: SIMD4<Float>(0.17, 0.17, 0.18, 1)
        ))

        for lane in [-1.8 as Float, 0, 1.8] {
            for segment in 0..<7 {
                let z = -Float(segment) * 8 + fmod(roadOffset * 1.4, 8)
                objects.append(SceneObject(
                    transform: float4x4.translation(lane, -0.28, z - 6) * float4x4.scale(0.08, 0.02, 2),
                    color: SIMD4<Float>(0.95, 0.95, 0.4, 1)
                ))
            }
        }

        objects.append(SceneObject(
            transform: float4x4.translation(playerX, -0.03, -2.4) * float4x4.scale(0.8, 0.45, 1.2),
            color: crashed ? SIMD4<Float>(0.9, 0.25, 0.25, 1) : SIMD4<Float>(0.2, 0.75, 1, 1)
        ))

        for i in obstacles.indices {
            objects.append(SceneObject(
                transform: float4x4.translation(obstacleLanes[i], -0.03, obstacles[i] - 2.4) * float4x4.scale(0.8, 0.45, 1.2),
                color: SIMD4<Float>(1, 0.45, 0.2, 1)
            ))
        }

        return objects
    }

    private func laneX(for idx: Int) -> Float {
        switch idx {
        case 0: return -1.8
        case 1: return 0
        default: return 1.8
        }
    }

    private func resetObstacles() {
        obstacles = [-15, -28, -40]
        obstacleLanes = [laneX(for: 0), laneX(for: 2), laneX(for: 1)]
    }

    private func updateProjection(size: CGSize) {
        let aspect = max(0.1, Float(size.width / max(size.height, 1)))
        projection = float4x4.perspective(fovyRadians: 58 * .pi / 180, aspectRatio: aspect, nearZ: 0.1, farZ: 120)
    }

    private static func makeCubeGeometry() -> ([Vertex], [UInt16]) {
        let p: [SIMD3<Float>] = [
            SIMD3<Float>(-0.5, -0.5,  0.5), SIMD3<Float>( 0.5, -0.5,  0.5), SIMD3<Float>( 0.5,  0.5,  0.5), SIMD3<Float>(-0.5,  0.5,  0.5),
            SIMD3<Float>(-0.5, -0.5, -0.5), SIMD3<Float>( 0.5, -0.5, -0.5), SIMD3<Float>( 0.5,  0.5, -0.5), SIMD3<Float>(-0.5,  0.5, -0.5)
        ]
        let c = SIMD4<Float>(1, 1, 1, 1)
        let vertices = p.map { Vertex(position: $0, color: c) }
        let indices: [UInt16] = [
            0, 1, 2, 2, 3, 0,
            1, 5, 6, 6, 2, 1,
            5, 4, 7, 7, 6, 5,
            4, 0, 3, 3, 7, 4,
            3, 2, 6, 6, 7, 3,
            4, 5, 1, 1, 0, 4
        ]
        return (vertices, indices)
    }

    private static func makeVertexDescriptor() -> MTLVertexDescriptor {
        let descriptor = MTLVertexDescriptor()
        descriptor.attributes[0].format = .float3
        descriptor.attributes[0].offset = 0
        descriptor.attributes[0].bufferIndex = 0
        descriptor.attributes[1].format = .float4
        descriptor.attributes[1].offset = MemoryLayout<SIMD3<Float>>.stride
        descriptor.attributes[1].bufferIndex = 0
        descriptor.layouts[0].stride = MemoryLayout<Vertex>.stride
        descriptor.layouts[0].stepFunction = .perVertex
        return descriptor
    }

    private static let shaderSource = """
    #include <metal_stdlib>
    using namespace metal;

    struct VertexIn {
        float3 position [[attribute(0)]];
        float4 color [[attribute(1)]];
    };

    struct Uniforms {
        float4x4 viewProjection;
    };

    struct ModelConstants {
        float4x4 modelMatrix;
    };

    struct VertexOut {
        float4 position [[position]];
        float4 color;
    };

    vertex VertexOut vertex_main(
        VertexIn in [[stage_in]],
        constant Uniforms& uniforms [[buffer(1)]],
        constant ModelConstants& model [[buffer(2)]]
    ) {
        VertexOut out;
        out.position = uniforms.viewProjection * model.modelMatrix * float4(in.position, 1.0);
        out.color = in.color;
        return out;
    }

    fragment float4 fragment_main(
        VertexOut in [[stage_in]],
        constant float4& objectColor [[buffer(0)]]
    ) {
        return objectColor;
    }
    """
}

private extension float4x4 {
    static func perspective(fovyRadians: Float, aspectRatio: Float, nearZ: Float, farZ: Float) -> float4x4 {
        let ys = 1 / tan(fovyRadians * 0.5)
        let xs = ys / aspectRatio
        let zs = farZ / (nearZ - farZ)
        return float4x4(columns: (
            SIMD4<Float>(xs, 0, 0, 0),
            SIMD4<Float>(0, ys, 0, 0),
            SIMD4<Float>(0, 0, zs, -1),
            SIMD4<Float>(0, 0, zs * nearZ, 0)
        ))
    }

    static func translation(_ x: Float, _ y: Float, _ z: Float) -> float4x4 {
        float4x4(columns: (
            SIMD4<Float>(1, 0, 0, 0),
            SIMD4<Float>(0, 1, 0, 0),
            SIMD4<Float>(0, 0, 1, 0),
            SIMD4<Float>(x, y, z, 1)
        ))
    }

    static func scale(_ x: Float, _ y: Float, _ z: Float) -> float4x4 {
        float4x4(columns: (
            SIMD4<Float>(x, 0, 0, 0),
            SIMD4<Float>(0, y, 0, 0),
            SIMD4<Float>(0, 0, z, 0),
            SIMD4<Float>(0, 0, 0, 1)
        ))
    }

    static func lookAt(eye: SIMD3<Float>, target: SIMD3<Float>, up: SIMD3<Float>) -> float4x4 {
        let z = simd_normalize(eye - target)
        let x = simd_normalize(simd_cross(up, z))
        let y = simd_cross(z, x)
        return float4x4(columns: (
            SIMD4<Float>(x.x, y.x, z.x, 0),
            SIMD4<Float>(x.y, y.y, z.y, 0),
            SIMD4<Float>(x.z, y.z, z.z, 0),
            SIMD4<Float>(-simd_dot(x, eye), -simd_dot(y, eye), -simd_dot(z, eye), 1)
        ))
    }
}
