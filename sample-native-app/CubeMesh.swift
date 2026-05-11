//
//  CubeMesh.swift
//  sample-native-app
//
//  Generates a unit cube mesh (positions + per-face normals) for the renderer.
//

import Metal
import simd

struct MeshVertex {
    var position: SIMD3<Float>
    var normal: SIMD3<Float>
}

enum CubeMesh {
    /// Builds a unit cube centered at the origin with extents [-0.5, 0.5] on each axis.
    static func makeBuffers(device: MTLDevice) -> (vertexBuffer: MTLBuffer, indexBuffer: MTLBuffer, indexCount: Int) {
        struct Face {
            var normal: SIMD3<Float>
            var corners: [SIMD3<Float>]
        }

        let faces: [Face] = [
            // +X
            Face(normal: SIMD3<Float>( 1, 0, 0), corners: [
                SIMD3<Float>( 0.5, -0.5, -0.5), SIMD3<Float>( 0.5, -0.5,  0.5),
                SIMD3<Float>( 0.5,  0.5,  0.5), SIMD3<Float>( 0.5,  0.5, -0.5)
            ]),
            // -X
            Face(normal: SIMD3<Float>(-1, 0, 0), corners: [
                SIMD3<Float>(-0.5, -0.5,  0.5), SIMD3<Float>(-0.5, -0.5, -0.5),
                SIMD3<Float>(-0.5,  0.5, -0.5), SIMD3<Float>(-0.5,  0.5,  0.5)
            ]),
            // +Y
            Face(normal: SIMD3<Float>(0,  1, 0), corners: [
                SIMD3<Float>(-0.5,  0.5, -0.5), SIMD3<Float>( 0.5,  0.5, -0.5),
                SIMD3<Float>( 0.5,  0.5,  0.5), SIMD3<Float>(-0.5,  0.5,  0.5)
            ]),
            // -Y
            Face(normal: SIMD3<Float>(0, -1, 0), corners: [
                SIMD3<Float>(-0.5, -0.5,  0.5), SIMD3<Float>( 0.5, -0.5,  0.5),
                SIMD3<Float>( 0.5, -0.5, -0.5), SIMD3<Float>(-0.5, -0.5, -0.5)
            ]),
            // +Z
            Face(normal: SIMD3<Float>(0, 0,  1), corners: [
                SIMD3<Float>( 0.5, -0.5,  0.5), SIMD3<Float>(-0.5, -0.5,  0.5),
                SIMD3<Float>(-0.5,  0.5,  0.5), SIMD3<Float>( 0.5,  0.5,  0.5)
            ]),
            // -Z
            Face(normal: SIMD3<Float>(0, 0, -1), corners: [
                SIMD3<Float>(-0.5, -0.5, -0.5), SIMD3<Float>( 0.5, -0.5, -0.5),
                SIMD3<Float>( 0.5,  0.5, -0.5), SIMD3<Float>(-0.5,  0.5, -0.5)
            ])
        ]

        var vertices: [MeshVertex] = []
        var indices: [UInt16] = []
        for face in faces {
            let baseIndex = UInt16(vertices.count)
            for c in face.corners {
                vertices.append(MeshVertex(position: c, normal: face.normal))
            }
            indices.append(baseIndex)
            indices.append(baseIndex + 1)
            indices.append(baseIndex + 2)
            indices.append(baseIndex)
            indices.append(baseIndex + 2)
            indices.append(baseIndex + 3)
        }

        let vbLength = vertices.count * MemoryLayout<MeshVertex>.stride
        let ibLength = indices.count * MemoryLayout<UInt16>.stride
        guard let vb = device.makeBuffer(bytes: vertices, length: vbLength, options: []),
              let ib = device.makeBuffer(bytes: indices, length: ibLength, options: []) else {
            fatalError("Failed to create cube mesh buffers")
        }
        vb.label = "CubeVertices"
        ib.label = "CubeIndices"
        return (vb, ib, indices.count)
    }
}
