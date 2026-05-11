//
//  MathUtils.swift
//  sample-native-app
//
//  Lightweight matrix/vector helpers used by the Metal renderer.
//

import simd

@inline(__always)
func radians(_ degrees: Float) -> Float {
    return degrees * .pi / 180.0
}

enum Mat4 {
    static func identity() -> matrix_float4x4 {
        return matrix_identity_float4x4
    }

    static func translation(_ t: SIMD3<Float>) -> matrix_float4x4 {
        var m = matrix_identity_float4x4
        m.columns.3 = SIMD4<Float>(t.x, t.y, t.z, 1.0)
        return m
    }

    static func scale(_ s: SIMD3<Float>) -> matrix_float4x4 {
        var m = matrix_identity_float4x4
        m.columns.0.x = s.x
        m.columns.1.y = s.y
        m.columns.2.z = s.z
        return m
    }

    static func rotationY(_ angle: Float) -> matrix_float4x4 {
        let c = cosf(angle), s = sinf(angle)
        return matrix_float4x4(columns: (
            SIMD4<Float>(c, 0, -s, 0),
            SIMD4<Float>(0, 1, 0, 0),
            SIMD4<Float>(s, 0, c, 0),
            SIMD4<Float>(0, 0, 0, 1)
        ))
    }

    static func rotationX(_ angle: Float) -> matrix_float4x4 {
        let c = cosf(angle), s = sinf(angle)
        return matrix_float4x4(columns: (
            SIMD4<Float>(1, 0, 0, 0),
            SIMD4<Float>(0, c, s, 0),
            SIMD4<Float>(0, -s, c, 0),
            SIMD4<Float>(0, 0, 0, 1)
        ))
    }

    /// Right-handed perspective projection matrix (Metal NDC: z in [0, 1]).
    static func perspective(fovYRadians fovY: Float, aspect: Float, near: Float, far: Float) -> matrix_float4x4 {
        let ys = 1.0 / tanf(fovY * 0.5)
        let xs = ys / aspect
        let zs = far / (near - far)
        return matrix_float4x4(columns: (
            SIMD4<Float>(xs, 0, 0, 0),
            SIMD4<Float>(0, ys, 0, 0),
            SIMD4<Float>(0, 0, zs, -1),
            SIMD4<Float>(0, 0, zs * near, 0)
        ))
    }

    /// Right-handed look-at matrix.
    static func lookAt(eye: SIMD3<Float>, center: SIMD3<Float>, up: SIMD3<Float>) -> matrix_float4x4 {
        let f = simd_normalize(center - eye)
        let s = simd_normalize(simd_cross(f, up))
        let u = simd_cross(s, f)
        return matrix_float4x4(columns: (
            SIMD4<Float>(s.x, u.x, -f.x, 0),
            SIMD4<Float>(s.y, u.y, -f.y, 0),
            SIMD4<Float>(s.z, u.z, -f.z, 0),
            SIMD4<Float>(-simd_dot(s, eye), -simd_dot(u, eye), simd_dot(f, eye), 1)
        ))
    }
}
