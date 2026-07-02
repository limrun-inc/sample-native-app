//
//  Shaders.metal
//  sample-native-app
//
//  Metal shaders for the Subway-Surf-style runner game.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float3 position;
    float3 normal;
};

struct VertexOut {
    float4 position [[position]];
    float3 worldNormal;
    float3 worldPosition;
    float4 color;
    float fogFactor;
};

struct CameraUniforms {
    float4x4 viewProjection;
    float3   cameraPos;
    float    fogStart;
    float    fogEnd;
};

struct InstanceUniforms {
    float4x4 model;
    float4   color;
};

vertex VertexOut vertex_main(uint vid [[vertex_id]],
                             const device VertexIn* vertices [[buffer(0)]],
                             constant CameraUniforms& camera [[buffer(1)]],
                             constant InstanceUniforms& instance [[buffer(2)]]) {
    VertexIn v = vertices[vid];
    float4 worldPos = instance.model * float4(v.position, 1.0);

    VertexOut out;
    out.position = camera.viewProjection * worldPos;
    out.worldPosition = worldPos.xyz;
    // Treat the upper-left 3x3 of the model matrix as orthonormal for normals
    // (we only use translation/scale-1/rotation here, so this is fine).
    out.worldNormal = (instance.model * float4(v.normal, 0.0)).xyz;
    out.color = instance.color;

    float dist = length(worldPos.xyz - camera.cameraPos);
    float t = saturate((dist - camera.fogStart) / max(0.001, camera.fogEnd - camera.fogStart));
    out.fogFactor = t;

    return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]]) {
    float3 N = normalize(in.worldNormal);
    float3 L = normalize(float3(0.4, 1.0, 0.2));
    float diff = max(dot(N, L), 0.0);
    float3 ambient = 0.45 * in.color.rgb;
    float3 lit = ambient + 0.65 * diff * in.color.rgb;

    // Simple sky-colored fog blend so distant geometry fades into the sky.
    float3 fogColor = float3(0.55, 0.78, 0.97);
    float3 col = mix(lit, fogColor, in.fogFactor);
    return float4(col, in.color.a);
}
