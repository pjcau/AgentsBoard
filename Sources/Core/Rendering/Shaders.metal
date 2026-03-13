// MARK: - Metal Shaders (Step 2.2)
// Vertex + Fragment shaders for terminal cell rendering.

#include <metal_stdlib>
using namespace metal;

struct Vertex {
    float2 position;
    float2 texCoord;
    float4 foregroundColor;
    float4 backgroundColor;
};

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
    float4 foregroundColor;
    float4 backgroundColor;
};

vertex VertexOut vertexShader(
    const device Vertex* vertices [[buffer(0)]],
    uint vertexId [[vertex_id]]
) {
    VertexOut out;
    Vertex v = vertices[vertexId];
    out.position = float4(v.position, 0.0, 1.0);
    out.texCoord = v.texCoord;
    out.foregroundColor = v.foregroundColor;
    out.backgroundColor = v.backgroundColor;
    return out;
}

fragment float4 fragmentShader(
    VertexOut in [[stage_in]],
    texture2d<float> glyphAtlas [[texture(0)]]
) {
    constexpr sampler texSampler(mag_filter::linear, min_filter::linear);
    float4 glyphSample = glyphAtlas.sample(texSampler, in.texCoord);

    // Mix: background where glyph alpha is 0, foreground where glyph alpha is 1
    float4 color = mix(in.backgroundColor, in.foregroundColor, glyphSample.a);
    return color;
}
