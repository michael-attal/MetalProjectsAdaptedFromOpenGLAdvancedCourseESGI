//
//  TD_04_Dragon.metal
//  MetalProjectsAdaptedFromOpenGLAdvancedCourseESGI
//
//  Created by Michaël ATTAL on 16/04/2045.
//

#include <metal_stdlib>
using namespace metal;

// Not really necessary since we make a vertex buffer for each attribute instead, but let's keep it here just in case.
struct TD_04_Dragon_VertexIn {
    float3 position [[attribute(0)]];
    float3 normal [[attribute(1)]];
    float2 uv [[attribute(2)]];
};

// We could just use TD_04_Dragon_VertexIn because we use the same datas but again, let's keep it here just in case.
struct TD_04_Dragon_VertexOut {
    float4 position [[position]];
    float3 normal;
    float2 uv;
};

vertex TD_04_Dragon_VertexOut vs_td_04_dragon(TD_04_Dragon_VertexIn inVertex [[stage_in]],
                                          uint vertexIndex [[vertex_id]],
                                          constant float3 *positions [[buffer(1)]],
                                          constant float3 *normals [[buffer(2)]],
                                          constant float2 *uv [[buffer(3)]],
                                          constant float4x4& translationModelMatrix [[buffer(4)]],
                                          constant float4x4& rotationModelMatrix [[buffer(5)]],
                                          constant float4x4& scaleModelMatrix [[buffer(6)]],
                                          constant float4x4& finalModelMatrix [[buffer(7)]])
{
    TD_04_Dragon_VertexOut out;

    out.position = finalModelMatrix * float4(positions[vertexIndex], 1.0);
    out.normal = normals[vertexIndex];
    out.uv = uv[vertexIndex];
    
    return out;
}

fragment float4 fs_td_04_dragon(TD_04_Dragon_VertexOut outVertex [[stage_in]])
{
    return float4(0, 1, 0, 1);
}

fragment float4 fs_td_04_dragon_textured(
    TD_04_Dragon_VertexOut outVertex [[stage_in]],
    texture2d<float> fillTexture [[texture(0)]])
{
    constexpr sampler s(address::clamp_to_edge, filter::nearest);
    float4 textureColor = fillTexture.sample(s, outVertex.uv);
    return textureColor;
}
