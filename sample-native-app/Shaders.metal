//
//  Shaders.metal
//  sample-native-app
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float3 position [[attribute(0)]];
    float3 normal   [[attribute(1)]];
    float4 color    [[attribute(2)]];
};

struct VertexOut {
    float4 position [[position]];
    float3 worldNormal;
    float4 color;
    float3 worldPos;
};

struct Uniforms {
    float4x4 modelMatrix;
    float4x4 viewProjectionMatrix;
    float4x4 normalMatrix;
    float3   lightDir;
    float    padding;
};

vertex VertexOut vertex_main(VertexIn in [[stage_in]],
                              constant Uniforms &u [[buffer(1)]]) {
    VertexOut out;
    float4 worldPos = u.modelMatrix * float4(in.position, 1.0);
    out.position    = u.viewProjectionMatrix * worldPos;
    out.worldNormal = normalize((u.normalMatrix * float4(in.normal, 0.0)).xyz);
    out.color       = in.color;
    out.worldPos    = worldPos.xyz;
    return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]],
                               constant Uniforms &u [[buffer(1)]]) {
    float3 N = normalize(in.worldNormal);
    float3 L = normalize(-u.lightDir);
    float  diffuse  = max(dot(N, L), 0.0);
    float  ambient  = 0.25;
    float  light    = ambient + diffuse * 0.75;
    return float4(in.color.rgb * light, in.color.a);
}
