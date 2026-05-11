//
//  Renderer.swift
//  sample-native-app
//
//  Metal renderer for the three-lane runner game.
//

import Foundation
import Metal
import MetalKit
import simd

private struct CameraUniforms {
    var viewProjection: simd_float4x4
    var cameraPos: SIMD3<Float>
    var fogStart: Float
    var fogEnd: Float
}

private struct InstanceUniforms {
    var model: simd_float4x4
    var color: SIMD4<Float>
}

final class Renderer: NSObject, MTKViewDelegate {

    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private var pipelineState: MTLRenderPipelineState!
    private var depthState: MTLDepthStencilState!

    private var cubeMesh: Mesh!
    private var quadMesh: Mesh!

    private let world: GameWorld
    private var aspect: Float = 1
    private var lastTime: CFTimeInterval = CACurrentMediaTime()

    init?(view: MTKView, world: GameWorld) {
        guard let device = MTLCreateSystemDefaultDevice(),
              let queue = device.makeCommandQueue() else {
            return nil
        }
        self.device = device
        self.commandQueue = queue
        self.world = world

        super.init()

        view.device = device
        view.colorPixelFormat = .bgra8Unorm
        view.depthStencilPixelFormat = .depth32Float
        view.clearColor = MTLClearColor(red: 0.55, green: 0.78, blue: 0.97, alpha: 1)
        view.sampleCount = 1
        view.preferredFramesPerSecond = 60

        guard buildPipeline(view: view) else {
            return nil
        }
        buildMeshes()
    }

    private func buildPipeline(view: MTKView) -> Bool {
        let library: MTLLibrary
        do {
            library = try device.makeDefaultLibrary(bundle: .main)
        } catch {
            print("Renderer: failed to load default Metal library: \(error)")
            return false
        }

        guard let vfn = library.makeFunction(name: "vertex_main"),
              let ffn = library.makeFunction(name: "fragment_main") else {
            print("Renderer: shader functions not found in library")
            return false
        }

        let desc = MTLRenderPipelineDescriptor()
        desc.vertexFunction = vfn
        desc.fragmentFunction = ffn
        desc.colorAttachments[0].pixelFormat = view.colorPixelFormat
        desc.depthAttachmentPixelFormat = view.depthStencilPixelFormat

        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: desc)
        } catch {
            print("Renderer: failed to create render pipeline state: \(error)")
            return false
        }

        let depthDesc = MTLDepthStencilDescriptor()
        depthDesc.depthCompareFunction = .less
        depthDesc.isDepthWriteEnabled = true
        depthState = device.makeDepthStencilState(descriptor: depthDesc)
        return true
    }

    private func buildMeshes() {
        cubeMesh = MeshFactory.makeUnitCube(device: device)
        quadMesh = MeshFactory.makeGroundQuad(device: device)
    }

    // MARK: - MTKViewDelegate

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        aspect = Float(max(1, size.width)) / Float(max(1, size.height))
    }

    func draw(in view: MTKView) {
        let now = CACurrentMediaTime()
        let dt = Float(min(1.0 / 30.0, max(0.0, now - lastTime)))
        lastTime = now
        world.update(dt: dt)

        guard let drawable = view.currentDrawable,
              let rpd = view.currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: rpd) else {
            return
        }

        encoder.setRenderPipelineState(pipelineState)
        encoder.setDepthStencilState(depthState)
        encoder.setCullMode(.back)
        encoder.setFrontFacing(.counterClockwise)

        // Camera follows just behind and above the hero, looking forward (-Z).
        let heroX = world.heroLane * GameWorld.laneOffset
        let cameraPos = SIMD3<Float>(heroX * 0.35, 3.4, 6.2)
        let lookTarget = SIMD3<Float>(heroX * 0.55, 1.2, -6.0)
        let view4x4 = MathUtils.lookAt(eye: cameraPos, center: lookTarget, up: SIMD3(0, 1, 0))
        let proj = MathUtils.perspective(fovyRadians: .pi / 3,
                                         aspect: aspect,
                                         nearZ: 0.1,
                                         farZ: 200)
        var camera = CameraUniforms(viewProjection: proj * view4x4,
                                    cameraPos: cameraPos,
                                    fogStart: 25,
                                    fogEnd: 75)
        encoder.setVertexBytes(&camera, length: MemoryLayout<CameraUniforms>.stride, index: 1)

        // 1) Ground.
        drawGround(encoder: encoder)

        // 2) Lane stripes (visual rails).
        drawLaneStripes(encoder: encoder)

        // 3) Side walls / scenery blocks.
        drawScenery(encoder: encoder)

        // 4) Obstacles.
        for obs in world.obstacles {
            drawObstacle(obs, encoder: encoder)
        }

        // 5) Hero (front of the chase).
        drawHero(encoder: encoder)

        // 6) Police (chasing behind).
        drawPolice(encoder: encoder)

        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    // MARK: - Drawing helpers

    private func drawCube(model: simd_float4x4, color: SIMD4<Float>, encoder: MTLRenderCommandEncoder) {
        var inst = InstanceUniforms(model: model, color: color)
        encoder.setVertexBuffer(cubeMesh.vertexBuffer, offset: 0, index: 0)
        encoder.setVertexBytes(&inst, length: MemoryLayout<InstanceUniforms>.stride, index: 2)
        encoder.drawIndexedPrimitives(type: .triangle,
                                      indexCount: cubeMesh.indexCount,
                                      indexType: .uint16,
                                      indexBuffer: cubeMesh.indexBuffer,
                                      indexBufferOffset: 0)
    }

    private func drawQuad(model: simd_float4x4, color: SIMD4<Float>, encoder: MTLRenderCommandEncoder) {
        var inst = InstanceUniforms(model: model, color: color)
        encoder.setVertexBuffer(quadMesh.vertexBuffer, offset: 0, index: 0)
        encoder.setVertexBytes(&inst, length: MemoryLayout<InstanceUniforms>.stride, index: 2)
        encoder.drawIndexedPrimitives(type: .triangle,
                                      indexCount: quadMesh.indexCount,
                                      indexType: .uint16,
                                      indexBuffer: quadMesh.indexBuffer,
                                      indexBufferOffset: 0)
    }

    private func drawGround(encoder: MTLRenderCommandEncoder) {
        let length: Float = GameWorld.trackHalfLength * 2
        let width: Float = GameWorld.groundHalfWidth * 2.4
        let model = MathUtils.translation(0, 0, -GameWorld.trackHalfLength + 6) *
                    MathUtils.scale(width, 1, length)
        drawQuad(model: model, color: SIMD4(0.27, 0.27, 0.30, 1), encoder: encoder)

        // Side-walks (lighter strips) on each side of the track.
        let walkWidth: Float = 1.6
        let walkX = GameWorld.groundHalfWidth + walkWidth * 0.5
        let walkColor = SIMD4<Float>(0.42, 0.41, 0.38, 1)
        let walkLeft = MathUtils.translation(-walkX, 0.001, -GameWorld.trackHalfLength + 6) *
                       MathUtils.scale(walkWidth, 1, length)
        let walkRight = MathUtils.translation( walkX, 0.001, -GameWorld.trackHalfLength + 6) *
                        MathUtils.scale(walkWidth, 1, length)
        drawQuad(model: walkLeft, color: walkColor, encoder: encoder)
        drawQuad(model: walkRight, color: walkColor, encoder: encoder)
    }

    private func drawLaneStripes(encoder: MTLRenderCommandEncoder) {
        // Yellow dashed stripes scrolling toward the player.
        let stripeColor = SIMD4<Float>(0.95, 0.85, 0.20, 1)
        let dashLength: Float = 1.5
        let dashGap: Float = 2.5
        let cycle = dashLength + dashGap
        let scroll = -fmodf(world.distance, cycle)

        for laneEdge in [-0.5, 0.5] as [Float] {
            let x = laneEdge * GameWorld.laneOffset
            var z: Float = 5
            while z > -GameWorld.trackHalfLength {
                let zCenter = z + scroll
                let model = MathUtils.translation(x, 0.005, zCenter) *
                            MathUtils.scale(0.12, 1, dashLength)
                drawQuad(model: model, color: stripeColor, encoder: encoder)
                z -= cycle
            }
        }
    }

    private func drawScenery(encoder: MTLRenderCommandEncoder) {
        // Periodic side buildings/walls scrolling with the world.
        let cycle: Float = 9.0
        let scroll = fmodf(world.distance, cycle)
        var z: Float = 5
        var alt = 0
        while z > -GameWorld.trackHalfLength {
            let zCenter = z - scroll
            let height: Float = (alt % 2 == 0) ? 3.4 : 2.6
            let color: SIMD4<Float> = (alt % 2 == 0)
                ? SIMD4(0.78, 0.45, 0.32, 1)   // brick red
                : SIMD4(0.55, 0.62, 0.70, 1)   // cool gray
            let widthX: Float = 1.6
            let xLeft  = -(GameWorld.groundHalfWidth + 1.6 + widthX * 0.5)
            let xRight =  (GameWorld.groundHalfWidth + 1.6 + widthX * 0.5)
            let mLeft  = MathUtils.translation(xLeft,  height * 0.5, zCenter) *
                         MathUtils.scale(widthX, height, 4.0)
            let mRight = MathUtils.translation(xRight, height * 0.5, zCenter) *
                         MathUtils.scale(widthX, height, 4.0)
            drawCube(model: mLeft,  color: color, encoder: encoder)
            drawCube(model: mRight, color: color, encoder: encoder)
            z -= cycle
            alt += 1
        }
    }

    private func drawObstacle(_ obs: GameWorld.Obstacle, encoder: MTLRenderCommandEncoder) {
        let x = Float(obs.lane) * GameWorld.laneOffset
        let model = MathUtils.translation(x, obs.size.y * 0.5, obs.z) *
                    MathUtils.scale(obs.size.x, obs.size.y, obs.size.z)
        drawCube(model: model, color: obs.color, encoder: encoder)
    }

    private func drawHero(encoder: MTLRenderCommandEncoder) {
        let x = world.heroLane * GameWorld.laneOffset
        let y = world.heroY
        let runBob = sinf(world.heroRun) * 0.06

        // Torso (orange jacket).
        let torsoH: Float = 0.7
        let torso = MathUtils.translation(x, y + 0.55 + runBob, 0) *
                    MathUtils.scale(GameWorld.heroWidth, torsoH, 0.45)
        drawCube(model: torso, color: SIMD4(0.95, 0.55, 0.10, 1), encoder: encoder)

        // Head (skin tone).
        let head = MathUtils.translation(x, y + 1.10 + runBob, 0) *
                   MathUtils.scale(0.45, 0.45, 0.45)
        drawCube(model: head, color: SIMD4(0.98, 0.84, 0.65, 1), encoder: encoder)

        // Beanie hat (yellow cap).
        let hat = MathUtils.translation(x, y + 1.36 + runBob, 0) *
                  MathUtils.scale(0.50, 0.18, 0.50)
        drawCube(model: hat, color: SIMD4(0.95, 0.85, 0.20, 1), encoder: encoder)

        // Legs (blue jeans) — alternate forward/back to suggest running.
        let legSwing = sinf(world.heroRun) * 0.18
        let legL = MathUtils.translation(x - 0.18, y + 0.20 - runBob, legSwing) *
                   MathUtils.scale(0.25, 0.45, 0.30)
        let legR = MathUtils.translation(x + 0.18, y + 0.20 - runBob, -legSwing) *
                   MathUtils.scale(0.25, 0.45, 0.30)
        let jeans = SIMD4<Float>(0.18, 0.30, 0.65, 1)
        drawCube(model: legL, color: jeans, encoder: encoder)
        drawCube(model: legR, color: jeans, encoder: encoder)

        // Arms swinging opposite to legs.
        let armL = MathUtils.translation(x - 0.50, y + 0.65 + runBob * 0.5, -legSwing * 0.6) *
                   MathUtils.scale(0.18, 0.55, 0.22)
        let armR = MathUtils.translation(x + 0.50, y + 0.65 + runBob * 0.5,  legSwing * 0.6) *
                   MathUtils.scale(0.18, 0.55, 0.22)
        let armColor = SIMD4<Float>(0.85, 0.45, 0.05, 1)
        drawCube(model: armL, color: armColor, encoder: encoder)
        drawCube(model: armR, color: armColor, encoder: encoder)

        // Backpack (small green block on the back).
        let pack = MathUtils.translation(x, y + 0.65 + runBob, 0.27) *
                   MathUtils.scale(0.55, 0.55, 0.20)
        drawCube(model: pack, color: SIMD4(0.20, 0.55, 0.30, 1), encoder: encoder)
    }

    private func drawPolice(encoder: MTLRenderCommandEncoder) {
        // Police runs in the same lane as the hero, just behind them.
        let x = world.heroLane * GameWorld.laneOffset
        let z = world.policeDistance
        let bob = sinf(world.heroRun * 0.9 + 1.0) * 0.05

        // Dark blue torso (uniform).
        let torso = MathUtils.translation(x, 0.55 + bob, z) *
                    MathUtils.scale(0.78, 0.75, 0.45)
        drawCube(model: torso, color: SIMD4(0.10, 0.18, 0.45, 1), encoder: encoder)

        // Head.
        let head = MathUtils.translation(x, 1.10 + bob, z) *
                   MathUtils.scale(0.45, 0.45, 0.45)
        drawCube(model: head, color: SIMD4(0.95, 0.78, 0.60, 1), encoder: encoder)

        // Police hat (blue with badge).
        let hat = MathUtils.translation(x, 1.40 + bob, z) *
                  MathUtils.scale(0.55, 0.20, 0.55)
        drawCube(model: hat, color: SIMD4(0.05, 0.10, 0.30, 1), encoder: encoder)
        let badge = MathUtils.translation(x, 1.42 + bob, z - 0.25) *
                    MathUtils.scale(0.18, 0.14, 0.05)
        drawCube(model: badge, color: SIMD4(0.95, 0.85, 0.20, 1), encoder: encoder)

        // Legs.
        let legSwing = sinf(world.heroRun * 0.9 + 1.0) * 0.18
        let legL = MathUtils.translation(x - 0.20, 0.20 - bob, z + legSwing) *
                   MathUtils.scale(0.25, 0.45, 0.30)
        let legR = MathUtils.translation(x + 0.20, 0.20 - bob, z - legSwing) *
                   MathUtils.scale(0.25, 0.45, 0.30)
        let pants = SIMD4<Float>(0.06, 0.10, 0.30, 1)
        drawCube(model: legL, color: pants, encoder: encoder)
        drawCube(model: legR, color: pants, encoder: encoder)

        // Arms.
        let armL = MathUtils.translation(x - 0.55, 0.65 + bob * 0.5, z - legSwing * 0.6) *
                   MathUtils.scale(0.18, 0.55, 0.22)
        let armR = MathUtils.translation(x + 0.55, 0.65 + bob * 0.5, z + legSwing * 0.6) *
                   MathUtils.scale(0.18, 0.55, 0.22)
        drawCube(model: armL, color: SIMD4(0.10, 0.18, 0.45, 1), encoder: encoder)
        drawCube(model: armR, color: SIMD4(0.10, 0.18, 0.45, 1), encoder: encoder)
    }
}
