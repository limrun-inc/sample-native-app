//
//  MetalRenderer.swift
//  sample-native-app
//
//  Metal renderer that draws the GameScene each frame. Uses instanced
//  drawing of a single unit-cube mesh so we can render the entire world
//  (ground, lane markings, rails, obstacles, player, police) with one
//  draw call per frame.
//

import Metal
import MetalKit
import simd

@MainActor
final class MetalRenderer: NSObject, MTKViewDelegate {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState
    private let depthState: MTLDepthStencilState

    private let vertexBuffer: MTLBuffer
    private let indexBuffer: MTLBuffer
    private let indexCount: Int

    // Triple-buffered instance buffers to avoid CPU/GPU contention.
    private static let maxInstances = 1024
    private static let inFlightFrames = 3
    private var instanceBuffers: [MTLBuffer] = []
    private var uniformBuffers: [MTLBuffer] = []
    private var frameIndex: Int = 0
    private let inFlightSemaphore = DispatchSemaphore(value: MetalRenderer.inFlightFrames)

    private var lastFrameTime: CFTimeInterval = CACurrentMediaTime()

    let scene = GameScene()

    /// Called from the rendering thread (main) every frame after update.
    var onFrame: (@MainActor (GameScene) -> Void)?

    init?(mtkView: MTKView) {
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("Metal is not supported on this device")
            return nil
        }
        self.device = device

        mtkView.device = device
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.depthStencilPixelFormat = .depth32Float
        mtkView.clearColor = MTLClearColor(red: 0.55, green: 0.78, blue: 0.95, alpha: 1.0)
        mtkView.preferredFramesPerSecond = 60
        mtkView.sampleCount = 1

        guard let queue = device.makeCommandQueue() else {
            print("Failed to create command queue")
            return nil
        }
        self.commandQueue = queue

        guard let library = device.makeDefaultLibrary() else {
            print("Failed to create default Metal library")
            return nil
        }
        guard let vertexFn = library.makeFunction(name: "vertex_main"),
              let fragmentFn = library.makeFunction(name: "fragment_main") else {
            print("Failed to load shader functions")
            return nil
        }

        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[1].format = .float3
        vertexDescriptor.attributes[1].offset = MemoryLayout<SIMD3<Float>>.stride
        vertexDescriptor.attributes[1].bufferIndex = 0
        vertexDescriptor.layouts[0].stride = MemoryLayout<MeshVertex>.stride

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFn
        pipelineDescriptor.fragmentFunction = fragmentFn
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = mtkView.depthStencilPixelFormat

        do {
            self.pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            print("Failed to create pipeline state: \(error)")
            return nil
        }

        let depthDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.depthCompareFunction = .less
        depthDescriptor.isDepthWriteEnabled = true
        guard let ds = device.makeDepthStencilState(descriptor: depthDescriptor) else {
            print("Failed to create depth-stencil state")
            return nil
        }
        self.depthState = ds

        let mesh = CubeMesh.makeBuffers(device: device)
        self.vertexBuffer = mesh.vertexBuffer
        self.indexBuffer = mesh.indexBuffer
        self.indexCount = mesh.indexCount

        let instanceLength = MemoryLayout<InstanceUniform>.stride * MetalRenderer.maxInstances
        let uniformLength = MemoryLayout<SceneUniforms>.stride
        for i in 0..<MetalRenderer.inFlightFrames {
            guard let ib = device.makeBuffer(length: instanceLength, options: .storageModeShared),
                  let ub = device.makeBuffer(length: uniformLength, options: .storageModeShared) else {
                print("Failed to create dynamic buffers")
                return nil
            }
            ib.label = "Instances\(i)"
            ub.label = "Uniforms\(i)"
            instanceBuffers.append(ib)
            uniformBuffers.append(ub)
        }

        super.init()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        if size.width > 0 && size.height > 0 {
            scene.aspect = Float(size.width / size.height)
        }
    }

    func draw(in view: MTKView) {
        // Per-frame timing.
        let now = CACurrentMediaTime()
        var dt = Float(now - lastFrameTime)
        lastFrameTime = now
        if dt > 0.05 { dt = 0.05 } // clamp to avoid huge steps after pauses

        // Update simulation.
        let size = view.drawableSize
        if size.width > 0 && size.height > 0 {
            scene.aspect = Float(size.width / size.height)
        }
        scene.update(deltaTime: dt)
        onFrame?(scene)

        // Triple-buffered: wait for an available slot before writing into the buffer
        // GPU might still be reading from.
        _ = inFlightSemaphore.wait(timeout: .distantFuture)

        let bufferIndex = frameIndex % MetalRenderer.inFlightFrames
        frameIndex &+= 1

        let frameData = scene.buildInstances()
        let count = min(frameData.instances.count, MetalRenderer.maxInstances)
        if count > 0 {
            let dst = instanceBuffers[bufferIndex].contents()
            frameData.instances.withUnsafeBufferPointer { src in
                memcpy(dst, src.baseAddress, count * MemoryLayout<InstanceUniform>.stride)
            }
        }
        var uniforms = frameData.uniforms
        memcpy(uniformBuffers[bufferIndex].contents(), &uniforms, MemoryLayout<SceneUniforms>.stride)

        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let drawable = view.currentDrawable else {
            inFlightSemaphore.signal()
            return
        }

        let semaphore = inFlightSemaphore
        commandBuffer.addCompletedHandler { _ in
            semaphore.signal()
        }

        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            commandBuffer.commit()
            return
        }

        encoder.setRenderPipelineState(pipelineState)
        encoder.setDepthStencilState(depthState)
        encoder.setCullMode(.back)
        encoder.setFrontFacingWinding(.counterClockwise)

        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.setVertexBuffer(uniformBuffers[bufferIndex], offset: 0, index: 1)
        encoder.setVertexBuffer(instanceBuffers[bufferIndex], offset: 0, index: 2)
        encoder.setFragmentBuffer(uniformBuffers[bufferIndex], offset: 0, index: 1)

        if count > 0 {
            encoder.drawIndexedPrimitives(
                type: .triangle,
                indexCount: indexCount,
                indexType: .uint16,
                indexBuffer: indexBuffer,
                indexBufferOffset: 0,
                instanceCount: count
            )
        }

        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
