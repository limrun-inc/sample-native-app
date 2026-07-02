//
//  MeshFactory.swift
//  sample-native-app
//
//  Generates simple meshes (cube, ground quad) for the Metal renderer.
//

import Foundation
import Metal
import simd

struct MeshVertex {
    var position: SIMD3<Float>
    var normal: SIMD3<Float>
}

struct Mesh {
    let vertexBuffer: MTLBuffer
    let indexBuffer: MTLBuffer
    let indexCount: Int
}

enum MeshFactory {

    /// A unit cube centered at the origin (each side spans -0.5 ... +0.5),
    /// with per-face normals.
    static func makeUnitCube(device: MTLDevice) -> Mesh {
        // 6 faces × 4 vertices each = 24 vertices.
        let verts: [MeshVertex] = [
            // +X
            MeshVertex(position: SIMD3( 0.5, -0.5, -0.5), normal: SIMD3( 1, 0, 0)),
            MeshVertex(position: SIMD3( 0.5,  0.5, -0.5), normal: SIMD3( 1, 0, 0)),
            MeshVertex(position: SIMD3( 0.5,  0.5,  0.5), normal: SIMD3( 1, 0, 0)),
            MeshVertex(position: SIMD3( 0.5, -0.5,  0.5), normal: SIMD3( 1, 0, 0)),
            // -X
            MeshVertex(position: SIMD3(-0.5, -0.5,  0.5), normal: SIMD3(-1, 0, 0)),
            MeshVertex(position: SIMD3(-0.5,  0.5,  0.5), normal: SIMD3(-1, 0, 0)),
            MeshVertex(position: SIMD3(-0.5,  0.5, -0.5), normal: SIMD3(-1, 0, 0)),
            MeshVertex(position: SIMD3(-0.5, -0.5, -0.5), normal: SIMD3(-1, 0, 0)),
            // +Y
            MeshVertex(position: SIMD3(-0.5,  0.5, -0.5), normal: SIMD3(0,  1, 0)),
            MeshVertex(position: SIMD3(-0.5,  0.5,  0.5), normal: SIMD3(0,  1, 0)),
            MeshVertex(position: SIMD3( 0.5,  0.5,  0.5), normal: SIMD3(0,  1, 0)),
            MeshVertex(position: SIMD3( 0.5,  0.5, -0.5), normal: SIMD3(0,  1, 0)),
            // -Y
            MeshVertex(position: SIMD3(-0.5, -0.5,  0.5), normal: SIMD3(0, -1, 0)),
            MeshVertex(position: SIMD3(-0.5, -0.5, -0.5), normal: SIMD3(0, -1, 0)),
            MeshVertex(position: SIMD3( 0.5, -0.5, -0.5), normal: SIMD3(0, -1, 0)),
            MeshVertex(position: SIMD3( 0.5, -0.5,  0.5), normal: SIMD3(0, -1, 0)),
            // +Z
            MeshVertex(position: SIMD3( 0.5, -0.5,  0.5), normal: SIMD3(0, 0,  1)),
            MeshVertex(position: SIMD3( 0.5,  0.5,  0.5), normal: SIMD3(0, 0,  1)),
            MeshVertex(position: SIMD3(-0.5,  0.5,  0.5), normal: SIMD3(0, 0,  1)),
            MeshVertex(position: SIMD3(-0.5, -0.5,  0.5), normal: SIMD3(0, 0,  1)),
            // -Z
            MeshVertex(position: SIMD3(-0.5, -0.5, -0.5), normal: SIMD3(0, 0, -1)),
            MeshVertex(position: SIMD3(-0.5,  0.5, -0.5), normal: SIMD3(0, 0, -1)),
            MeshVertex(position: SIMD3( 0.5,  0.5, -0.5), normal: SIMD3(0, 0, -1)),
            MeshVertex(position: SIMD3( 0.5, -0.5, -0.5), normal: SIMD3(0, 0, -1)),
        ]

        var indices: [UInt16] = []
        indices.reserveCapacity(6 * 6)
        for face in 0..<6 {
            let base = UInt16(face * 4)
            indices += [base, base + 1, base + 2, base, base + 2, base + 3]
        }

        return makeMesh(device: device, vertices: verts, indices: indices)
    }

    /// A flat quad lying on the XZ plane, centered at the origin, of size 1×1,
    /// with normals pointing up (+Y).
    static func makeGroundQuad(device: MTLDevice) -> Mesh {
        let verts: [MeshVertex] = [
            MeshVertex(position: SIMD3(-0.5, 0,  0.5), normal: SIMD3(0, 1, 0)),
            MeshVertex(position: SIMD3( 0.5, 0,  0.5), normal: SIMD3(0, 1, 0)),
            MeshVertex(position: SIMD3( 0.5, 0, -0.5), normal: SIMD3(0, 1, 0)),
            MeshVertex(position: SIMD3(-0.5, 0, -0.5), normal: SIMD3(0, 1, 0)),
        ]
        let indices: [UInt16] = [0, 1, 2, 0, 2, 3]
        return makeMesh(device: device, vertices: verts, indices: indices)
    }

    private static func makeMesh(device: MTLDevice, vertices: [MeshVertex], indices: [UInt16]) -> Mesh {
        let vBuf = device.makeBuffer(bytes: vertices,
                                     length: MemoryLayout<MeshVertex>.stride * vertices.count,
                                     options: [])!
        let iBuf = device.makeBuffer(bytes: indices,
                                     length: MemoryLayout<UInt16>.stride * indices.count,
                                     options: [])!
        return Mesh(vertexBuffer: vBuf, indexBuffer: iBuf, indexCount: indices.count)
    }
}
