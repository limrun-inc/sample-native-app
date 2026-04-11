#include <metal_stdlib>

using namespace metal;

struct CarGameVertex {
    float2 position;
    float4 color;
};

struct CarRasterizerData {
    float4 position [[position]];
    float4 color;
};

vertex CarRasterizerData carVertex(const device CarGameVertex *vertices [[buffer(0)]], uint vertexID [[vertex_id]]) {
    CarRasterizerData out;
    out.position = float4(vertices[vertexID].position, 0.0, 1.0);
    out.color = vertices[vertexID].color;
    return out;
}

fragment float4 carFragment(CarRasterizerData in [[stage_in]]) {
    return in.color;
}
