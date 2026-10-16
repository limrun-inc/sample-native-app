#include <metal_stdlib>
using namespace metal;

struct Vertex {
    float3 position;
    float4 color;
};

struct RasterizedVertex {
    float4 position [[position]];
    float4 color;
};

vertex RasterizedVertex runnerVertex(const device Vertex *vertices [[buffer(0)]],
                                     constant float4x4 &viewProjection [[buffer(1)]],
                                     uint vertexID [[vertex_id]]) {
    RasterizedVertex result;
    result.position = viewProjection * float4(vertices[vertexID].position, 1.0);
    result.color = vertices[vertexID].color;
    return result;
}

fragment float4 runnerFragment(RasterizedVertex input [[stage_in]]) {
    return input.color;
}
