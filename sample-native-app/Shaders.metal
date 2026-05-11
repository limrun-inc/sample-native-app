//
//  Shaders.metal
//  sample-native-app
//
//  Subway Surfers-style game shaders.
//

#include <metal_stdlib>
using namespace metal;

struct Uniforms {
    float4x4 viewProjection;
    float3 lightDirection;
    float ambient;
};

struct InstanceData {
    float4x4 model;
    float4 color;
};

struct VertexIn {
    float3 position [[attribute(0)]];
    float3 normal   [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float3 worldNormal;
    float4 color;
    float3 worldPos;
};

vertex VertexOut vertex_main(VertexIn in [[stage_in]],
                             constant Uniforms &uniforms [[buffer(1)]],
                             constant InstanceData *instances [[buffer(2)]],
                             uint iid [[instance_id]]) {
    InstanceData inst = instances[iid];
    float4 worldPos = inst.model * float4(in.position, 1.0);
    VertexOut out;
    out.position = uniforms.viewProjection * worldPos;
    // Normal transformation assumes uniform scale; sufficient for our boxes.
    out.worldNormal = normalize((inst.model * float4(in.normal, 0.0)).xyz);
    out.color = inst.color;
    out.worldPos = worldPos.xyz;
    return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]],
                              constant Uniforms &uniforms [[buffer(1)]]) {
    float3 n = normalize(in.worldNormal);
    float3 l = normalize(-uniforms.lightDirection);
    float diff = max(dot(n, l), 0.0);
    float3 base = in.color.rgb;
    float3 lit = base * (uniforms.ambient + (1.0 - uniforms.ambient) * diff);
    // Simple distance fog so far-away objects fade into the sky.
    float dist = length(in.worldPos);
    float fog = clamp((dist - 18.0) / 28.0, 0.0, 1.0);
    float3 fogColor = float3(0.55, 0.78, 0.95);
    float3 final = mix(lit, fogColor, fog);
    return float4(final, in.color.a);
}
