//
//  MathUtils.swift
//  sample-native-app
//

import simd

typealias float4x4 = simd_float4x4
typealias float3x3 = simd_float3x3

extension simd_float4x4 {
    static func identity() -> simd_float4x4 {
        return matrix_identity_float4x4
    }

    static func translation(_ t: SIMD3<Float>) -> simd_float4x4 {
        var m = matrix_identity_float4x4
        m.columns.3 = SIMD4<Float>(t.x, t.y, t.z, 1)
        return m
    }

    static func scale(_ s: SIMD3<Float>) -> simd_float4x4 {
        var m = matrix_identity_float4x4
        m.columns.0.x = s.x
        m.columns.1.y = s.y
        m.columns.2.z = s.z
        return m
    }

    static func rotationY(_ angle: Float) -> simd_float4x4 {
        let c = cos(angle), s = sin(angle)
        return simd_float4x4(
            SIMD4<Float>( c, 0, s, 0),
            SIMD4<Float>( 0, 1, 0, 0),
            SIMD4<Float>(-s, 0, c, 0),
            SIMD4<Float>( 0, 0, 0, 1)
        )
    }

    static func rotationX(_ angle: Float) -> simd_float4x4 {
        let c = cos(angle), s = sin(angle)
        return simd_float4x4(
            SIMD4<Float>(1,  0,  0, 0),
            SIMD4<Float>(0,  c, -s, 0),
            SIMD4<Float>(0,  s,  c, 0),
            SIMD4<Float>(0,  0,  0, 1)
        )
    }

    static func perspective(fovY: Float, aspect: Float, near: Float, far: Float) -> simd_float4x4 {
        let yScale = 1 / tan(fovY * 0.5)
        let xScale = yScale / aspect
        let zRange = far - near
        let zScale = -(far + near) / zRange
        let wzScale = -2 * far * near / zRange
        return simd_float4x4(
            SIMD4<Float>(xScale,      0,       0,  0),
            SIMD4<Float>(     0, yScale,       0,  0),
            SIMD4<Float>(     0,      0,  zScale, -1),
            SIMD4<Float>(     0,      0, wzScale,  0)
        )
    }

    static func lookAt(eye: SIMD3<Float>, center: SIMD3<Float>, up: SIMD3<Float>) -> simd_float4x4 {
        let f = normalize(center - eye)
        let s = normalize(cross(f, up))
        let u = cross(s, f)
        return simd_float4x4(
            SIMD4<Float>(s.x,  u.x, -f.x, 0),
            SIMD4<Float>(s.y,  u.y, -f.y, 0),
            SIMD4<Float>(s.z,  u.z, -f.z, 0),
            SIMD4<Float>(-dot(s, eye), -dot(u, eye), dot(f, eye), 1)
        )
    }

    var normalMatrix: simd_float4x4 {
        return simd_transpose(self.inverse)
    }
}
