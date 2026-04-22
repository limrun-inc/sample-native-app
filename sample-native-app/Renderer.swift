//
//  Renderer.swift
//  sample-native-app
//

import Metal
import MetalKit
import simd

// MARK: – Vertex layout

struct Vertex {
    var position: SIMD3<Float>
    var normal:   SIMD3<Float>
    var color:    SIMD4<Float>
}

struct Uniforms {
    var modelMatrix:          simd_float4x4
    var viewProjectionMatrix: simd_float4x4
    var normalMatrix:         simd_float4x4
    var lightDir:             SIMD3<Float>
    var padding:              Float = 0
}

// MARK: – Mesh helper

struct Mesh {
    let vertexBuffer: MTLBuffer
    let indexBuffer:  MTLBuffer
    let indexCount:   Int
    let indexType:    MTLIndexType

    func draw(encoder: MTLRenderCommandEncoder) {
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.drawIndexedPrimitives(type:              .triangle,
                                      indexCount:        indexCount,
                                      indexType:         indexType,
                                      indexBuffer:       indexBuffer,
                                      indexBufferOffset: 0)
    }
}

// MARK: – Geometry factories

private func makeBox(device: MTLDevice,
                     size: SIMD3<Float>,
                     color: SIMD4<Float>) -> Mesh {
    let hw = size.x * 0.5, hh = size.y * 0.5, hd = size.z * 0.5
    // 24 unique vertices (4 per face) for correct normals
    let faces: [(normal: SIMD3<Float>, verts: [SIMD3<Float>])] = [
        // +Y top
        (SIMD3( 0, 1, 0), [SIMD3(-hw,hh,-hd),SIMD3(hw,hh,-hd),SIMD3(hw,hh,hd),SIMD3(-hw,hh,hd)]),
        // -Y bottom
        (SIMD3( 0,-1, 0), [SIMD3(-hw,-hh,hd),SIMD3(hw,-hh,hd),SIMD3(hw,-hh,-hd),SIMD3(-hw,-hh,-hd)]),
        // +Z front
        (SIMD3( 0, 0, 1), [SIMD3(-hw,-hh,hd),SIMD3(hw,-hh,hd),SIMD3(hw,hh,hd),SIMD3(-hw,hh,hd)]),
        // -Z back
        (SIMD3( 0, 0,-1), [SIMD3(hw,-hh,-hd),SIMD3(-hw,-hh,-hd),SIMD3(-hw,hh,-hd),SIMD3(hw,hh,-hd)]),
        // +X right
        (SIMD3( 1, 0, 0), [SIMD3(hw,-hh,hd),SIMD3(hw,-hh,-hd),SIMD3(hw,hh,-hd),SIMD3(hw,hh,hd)]),
        // -X left
        (SIMD3(-1, 0, 0), [SIMD3(-hw,-hh,-hd),SIMD3(-hw,-hh,hd),SIMD3(-hw,hh,hd),SIMD3(-hw,hh,-hd)])
    ]
    var verts: [Vertex] = []
    var indices: [UInt16] = []
    for face in faces {
        let base = UInt16(verts.count)
        for p in face.verts {
            verts.append(Vertex(position: p, normal: face.normal, color: color))
        }
        indices += [base, base+1, base+2, base, base+2, base+3]
    }
    let vBuf = device.makeBuffer(bytes: verts,
                                 length: verts.count * MemoryLayout<Vertex>.stride,
                                 options: .storageModeShared)!
    let iBuf = device.makeBuffer(bytes: indices,
                                 length: indices.count * MemoryLayout<UInt16>.stride,
                                 options: .storageModeShared)!
    return Mesh(vertexBuffer: vBuf, indexBuffer: iBuf,
                indexCount: indices.count, indexType: .uint16)
}

private func makeWheel(device: MTLDevice,
                       radius: Float, width: Float,
                       color: SIMD4<Float>,
                       segments: Int = 16) -> Mesh {
    var verts: [Vertex] = []
    var indices: [UInt16] = []

    // Cylinder along X axis
    let hw = width * 0.5
    for i in 0..<segments {
        let a0 = Float(i)   / Float(segments) * 2 * .pi
        let a1 = Float(i+1) / Float(segments) * 2 * .pi
        let y0 = cos(a0) * radius, z0 = sin(a0) * radius
        let y1 = cos(a1) * radius, z1 = sin(a1) * radius
        let n0 = SIMD3<Float>(0, cos(a0), sin(a0))
        let n1 = SIMD3<Float>(0, cos(a1), sin(a1))
        let b = UInt16(verts.count)
        // side quad
        verts += [
            Vertex(position: SIMD3(-hw, y0, z0), normal: n0, color: color),
            Vertex(position: SIMD3( hw, y0, z0), normal: n0, color: color),
            Vertex(position: SIMD3( hw, y1, z1), normal: n1, color: color),
            Vertex(position: SIMD3(-hw, y1, z1), normal: n1, color: color)
        ]
        indices += [b, b+1, b+2, b, b+2, b+3]
        // cap triangles (centre verts shared inline)
        let cl = UInt16(verts.count)
        verts.append(Vertex(position: SIMD3(-hw,0,0), normal: SIMD3(-1,0,0), color: color))
        verts.append(Vertex(position: SIMD3(-hw,y0,z0), normal: SIMD3(-1,0,0), color: color))
        verts.append(Vertex(position: SIMD3(-hw,y1,z1), normal: SIMD3(-1,0,0), color: color))
        indices += [cl, cl+1, cl+2]
        let cr = UInt16(verts.count)
        verts.append(Vertex(position: SIMD3( hw,0,0),  normal: SIMD3(1,0,0), color: color))
        verts.append(Vertex(position: SIMD3( hw,y0,z0),normal: SIMD3(1,0,0), color: color))
        verts.append(Vertex(position: SIMD3( hw,y1,z1),normal: SIMD3(1,0,0), color: color))
        indices += [cr, cr+2, cr+1]
    }
    let vBuf = device.makeBuffer(bytes: verts,
                                 length: verts.count * MemoryLayout<Vertex>.stride,
                                 options: .storageModeShared)!
    let iBuf = device.makeBuffer(bytes: indices,
                                 length: indices.count * MemoryLayout<UInt16>.stride,
                                 options: .storageModeShared)!
    return Mesh(vertexBuffer: vBuf, indexBuffer: iBuf,
                indexCount: indices.count, indexType: .uint16)
}

private func makeGroundPlane(device: MTLDevice,
                              size: Float,
                              tiles: Int) -> Mesh {
    var verts: [Vertex] = []
    var indices: [UInt16] = []
    let step = size / Float(tiles)
    let half = size * 0.5
    for row in 0..<tiles {
        for col in 0..<tiles {
            let x0 = Float(col) * step - half
            let z0 = Float(row) * step - half
            let x1 = x0 + step, z1 = z0 + step
            let checker = (row + col) % 2 == 0
            let c = checker ? SIMD4<Float>(0.3,0.55,0.25,1) : SIMD4<Float>(0.25,0.48,0.20,1)
            let n = SIMD3<Float>(0,1,0)
            let b = UInt16(verts.count)
            verts += [
                Vertex(position: SIMD3(x0,0,z0), normal: n, color: c),
                Vertex(position: SIMD3(x1,0,z0), normal: n, color: c),
                Vertex(position: SIMD3(x1,0,z1), normal: n, color: c),
                Vertex(position: SIMD3(x0,0,z1), normal: n, color: c)
            ]
            indices += [b,b+1,b+2, b,b+2,b+3]
        }
    }
    let vBuf = device.makeBuffer(bytes: verts,
                                 length: verts.count * MemoryLayout<Vertex>.stride,
                                 options: .storageModeShared)!
    let iBuf = device.makeBuffer(bytes: indices,
                                 length: indices.count * MemoryLayout<UInt16>.stride,
                                 options: .storageModeShared)!
    return Mesh(vertexBuffer: vBuf, indexBuffer: iBuf,
                indexCount: indices.count, indexType: .uint16)
}

private func makeTrackMarkers(device: MTLDevice) -> [Mesh] {
    // Simple oval track markers (cones as thin boxes)
    var meshes: [Mesh] = []
    let coneColor = SIMD4<Float>(1.0, 0.6, 0.0, 1)
    let trackRadius: Float = 25.0
    let markerCount = 24
    for i in 0..<markerCount {
        let angle = Float(i) / Float(markerCount) * 2 * .pi
        // Oval: scale X vs Z
        let x = cos(angle) * trackRadius * 1.6
        let z = sin(angle) * trackRadius
        let _ = makeBox(device: device, size: SIMD3(0.4, 1.2, 0.4), color: coneColor)
        // We return translation info alongside – store as a box
        let _ = x; let _ = z
        meshes.append(makeBox(device: device, size: SIMD3(0.4, 1.2, 0.4), color: coneColor))
    }
    return meshes
}

// MARK: – Renderer

class Renderer: NSObject, MTKViewDelegate {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    var pipelineState: MTLRenderPipelineState!
    var depthState: MTLDepthStencilState!

    // Meshes
    var groundMesh: Mesh!
    var carBodyMesh: Mesh!
    var carCabinMesh: Mesh!
    var wheelMesh: Mesh!
    var trackMarkers: [Mesh] = []

    var trackMarkerPositions: [SIMD3<Float>] = []

    weak var gameState: GameState?

    init?(mtkView: MTKView, gameState: GameState) {
        guard let device = mtkView.device,
              let queue  = device.makeCommandQueue() else { return nil }
        self.device       = device
        self.commandQueue = queue
        self.gameState    = gameState

        super.init()

        buildPipeline(mtkView: mtkView)
        buildMeshes()
        buildTrackMarkers()
    }

    private func buildPipeline(mtkView: MTKView) {
        let library   = device.makeDefaultLibrary()!
        let vertFn    = library.makeFunction(name: "vertex_main")!
        let fragFn    = library.makeFunction(name: "fragment_main")!

        let vDesc = MTLVertexDescriptor()
        // position
        vDesc.attributes[0].format = .float3
        vDesc.attributes[0].offset = 0
        vDesc.attributes[0].bufferIndex = 0
        // normal
        vDesc.attributes[1].format = .float3
        vDesc.attributes[1].offset = MemoryLayout<SIMD3<Float>>.stride
        vDesc.attributes[1].bufferIndex = 0
        // color
        vDesc.attributes[2].format = .float4
        vDesc.attributes[2].offset = MemoryLayout<SIMD3<Float>>.stride * 2
        vDesc.attributes[2].bufferIndex = 0
        vDesc.layouts[0].stride = MemoryLayout<Vertex>.stride

        let desc = MTLRenderPipelineDescriptor()
        desc.vertexFunction   = vertFn
        desc.fragmentFunction = fragFn
        desc.vertexDescriptor = vDesc
        desc.colorAttachments[0].pixelFormat   = mtkView.colorPixelFormat
        desc.depthAttachmentPixelFormat        = mtkView.depthStencilPixelFormat

        pipelineState = try! device.makeRenderPipelineState(descriptor: desc)

        let dDesc = MTLDepthStencilDescriptor()
        dDesc.depthCompareFunction = .less
        dDesc.isDepthWriteEnabled  = true
        depthState = device.makeDepthStencilState(descriptor: dDesc)!
    }

    private func buildMeshes() {
        groundMesh  = makeGroundPlane(device: device, size: 160, tiles: 40)
        carBodyMesh = makeBox(device: device,
                              size: SIMD3(1.8, 0.55, 3.8),
                              color: SIMD4<Float>(0.9, 0.1, 0.1, 1))
        carCabinMesh = makeBox(device: device,
                               size: SIMD3(1.4, 0.5, 2.0),
                               color: SIMD4<Float>(0.6, 0.8, 1.0, 1))
        wheelMesh   = makeWheel(device: device,
                                radius: 0.38, width: 0.28,
                                color: SIMD4<Float>(0.15, 0.15, 0.15, 1))
    }

    private func buildTrackMarkers() {
        let coneColor = SIMD4<Float>(1.0, 0.6, 0.0, 1)
        let trackRadius: Float = 25.0
        let markerCount = 28
        for i in 0..<markerCount {
            let angle = Float(i) / Float(markerCount) * 2 * .pi
            let x = cos(angle) * trackRadius * 1.6
            let z = sin(angle) * trackRadius
            trackMarkerPositions.append(SIMD3(x, 0, z))
            trackMarkers.append(makeBox(device: device,
                                        size: SIMD3(0.4, 1.2, 0.4),
                                        color: coneColor))
        }
    }

    // MARK: – Draw helpers

    private func drawMesh(_ mesh: Mesh,
                          encoder: MTLRenderCommandEncoder,
                          model: simd_float4x4,
                          vp: simd_float4x4,
                          lightDir: SIMD3<Float>) {
        var u = Uniforms(modelMatrix: model,
                         viewProjectionMatrix: vp,
                         normalMatrix: model.normalMatrix,
                         lightDir: lightDir)
        encoder.setVertexBytes(&u, length: MemoryLayout<Uniforms>.stride, index: 1)
        encoder.setFragmentBytes(&u, length: MemoryLayout<Uniforms>.stride, index: 1)
        mesh.draw(encoder: encoder)
    }

    // MARK: – MTKViewDelegate

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard let gs = gameState,
              let rpd = view.currentRenderPassDescriptor,
              let cb  = commandQueue.makeCommandBuffer(),
              let enc = cb.makeRenderCommandEncoder(descriptor: rpd) else { return }

        enc.setRenderPipelineState(pipelineState)
        enc.setDepthStencilState(depthState)
        enc.setFrontFacing(.counterClockwise)
        enc.setCullMode(.back)

        // Camera: follow car from behind + above
        let car = gs.car
        let camOffset = SIMD3<Float>(sin(car.heading) * (-8),
                                     4.5,
                                     cos(car.heading) * (-8))
        let eye    = car.position + camOffset
        let center = car.position + SIMD3<Float>(sin(car.heading), -0.3, cos(car.heading)) * 3
        let view4  = simd_float4x4.lookAt(eye: eye, center: center, up: SIMD3(0,1,0))

        let aspect: Float = Float(view.drawableSize.width / view.drawableSize.height)
        let proj   = simd_float4x4.perspective(fovY: .pi / 3.5, aspect: aspect,
                                               near: 0.1, far: 300)
        let vp     = proj * view4
        let lightDir = SIMD3<Float>(normalize(SIMD3(0.4, -1.0, 0.6)))

        // Ground
        drawMesh(groundMesh, encoder: enc,
                 model: .identity(), vp: vp, lightDir: lightDir)

        // Track cones
        for (i, pos) in trackMarkerPositions.enumerated() {
            let m = simd_float4x4.translation(pos + SIMD3(0, 0.6, 0))
            drawMesh(trackMarkers[i], encoder: enc, model: m, vp: vp, lightDir: lightDir)
        }

        // Car body
        let carBase = simd_float4x4.translation(car.position + SIMD3(0, 0.55, 0)) *
                      simd_float4x4.rotationY(-car.heading)
        drawMesh(carBodyMesh, encoder: enc, model: carBase, vp: vp, lightDir: lightDir)

        // Cabin (offset up and back)
        let cabinModel = carBase *
            simd_float4x4.translation(SIMD3(0, 0.55, -0.2))
        drawMesh(carCabinMesh, encoder: enc, model: cabinModel, vp: vp, lightDir: lightDir)

        // Wheels (4 corners)
        let wheelPositions: [(SIMD3<Float>, Bool)] = [
            (SIMD3( 1.0, -0.1,  1.4), true),   // front-right (steerable)
            (SIMD3(-1.0, -0.1,  1.4), true),   // front-left
            (SIMD3( 1.0, -0.1, -1.4), false),  // rear-right
            (SIMD3(-1.0, -0.1, -1.4), false)   // rear-left
        ]
        for (offset, steerable) in wheelPositions {
            let steerRot = steerable ? simd_float4x4.rotationY(-car.steerAngle) : .identity()
            let wModel   = carBase *
                simd_float4x4.translation(offset) *
                steerRot
            drawMesh(wheelMesh, encoder: enc, model: wModel, vp: vp, lightDir: lightDir)
        }

        enc.endEncoding()
        if let drawable = view.currentDrawable {
            cb.present(drawable)
        }
        cb.commit()
    }
}
