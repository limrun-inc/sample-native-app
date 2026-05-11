//
//  MathUtils.swift
//  sample-native-app
//
//  4x4 matrix helpers for the Metal renderer.
//

import simd

enum MathUtils {
    static func translation(_ x: Float, _ y: Float, _ z: Float) -> simd_float4x4 {
        var m = matrix_identity_float4x4
        m.columns.3 = SIMD4<Float>(x, y, z, 1)
        return m
    }

    static func scale(_ x: Float, _ y: Float, _ z: Float) -> simd_float4x4 {
        return simd_float4x4(diagonal: SIMD4<Float>(x, y, z, 1))
    }

    static func rotationY(_ angle: Float) -> simd_float4x4 {
        let c = cosf(angle)
        let s = sinf(angle)
        return simd_float4x4(
            SIMD4<Float>( c, 0, -s, 0),
            SIMD4<Float>( 0, 1,  0, 0),
            SIMD4<Float>( s, 0,  c, 0),
            SIMD4<Float>( 0, 0,  0, 1)
        )
    }

    /// Right-handed perspective projection matrix that maps depth into [0, 1]
    /// (the convention Metal expects).
    static func perspective(fovyRadians: Float, aspect: Float, nearZ: Float, farZ: Float) -> simd_float4x4 {
        let ys = 1 / tanf(fovyRadians * 0.5)
        let xs = ys / aspect
        let zs = farZ / (nearZ - farZ)
        return simd_float4x4(
            SIMD4<Float>(xs,  0,   0,  0),
            SIMD4<Float>( 0, ys,   0,  0),
            SIMD4<Float>( 0,  0,  zs, -1),
            SIMD4<Float>( 0,  0, zs * nearZ, 0)
        )
    }

    /// Right-handed look-at view matrix.
    static func lookAt(eye: SIMD3<Float>, center: SIMD3<Float>, up: SIMD3<Float>) -> simd_float4x4 {
        let f = simd_normalize(center - eye)
        let s = simd_normalize(simd_cross(f, up))
        let u = simd_cross(s, f)
        return simd_float4x4(
            SIMD4<Float>( s.x,  u.x, -f.x, 0),
            SIMD4<Float>( s.y,  u.y, -f.y, 0),
            SIMD4<Float>( s.z,  u.z, -f.z, 0),
            SIMD4<Float>(-simd_dot(s, eye), -simd_dot(u, eye), simd_dot(f, eye), 1)
        )
    }
}
