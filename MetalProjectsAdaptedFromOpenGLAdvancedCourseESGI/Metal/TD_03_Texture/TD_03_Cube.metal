//
//  TD_03_Cube.metal
//  MetalProjectsAdaptedFromOpenGLAdvancedCourseESGI
//
//  Created by Michaël ATTAL on 16/04/2035.
//

#include <metal_stdlib>
using namespace metal;

struct TD_03_Cube_VertexIn {
    float3 position [[attribute(0)]];
    float4 color [[attribute(1)]];
};

struct TD_03_Cube_VertexOut {
    float4 position [[position]];
    float2 uv;
};

vertex TD_03_Cube_VertexOut vs_td_03_cube(TD_03_Cube_VertexIn inVertex [[stage_in]],
                                          uint vertexIndex [[vertex_id]],
                                          constant float3 *positions [[buffer(1)]],
                                          constant float2 *uv [[buffer(2)]],
                                          constant float4x4& translationModelMatrix [[buffer(3)]],
                                          constant float4x4& rotationModelMatrix [[buffer(4)]],
                                          constant float4x4& scaleModelMatrix [[buffer(5)]],
                                          constant float4x4& finalModelMatrix [[buffer(6)]])
{
    TD_03_Cube_VertexOut out;

    out.position = finalModelMatrix * float4(inVertex.position, 1.0);
    out.uv = uv[vertexIndex];
    
    return out;
}

fragment float4 fs_td_03_cube_textured(
    TD_03_Cube_VertexOut outVertex [[stage_in]],
    texture2d<float> fillTexture [[texture(0)]])
{
    //return float4(outVertex.uv, 0.0, 1.0); // cool effect
    constexpr sampler s(address::clamp_to_edge, filter::nearest);  // or address::repeat, filter::linear ...
    float4 textureColor = fillTexture.sample(s, outVertex.uv);
    return textureColor;
}
