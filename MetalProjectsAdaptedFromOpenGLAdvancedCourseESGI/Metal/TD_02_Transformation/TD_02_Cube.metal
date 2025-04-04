//
//  TD_02_Cube.metal
//  MetalProjectsAdaptedFromOpenGLAdvancedCourseESGI
//
//  Created by Michaël ATTAL on 04/04/2025.
//

#include <metal_stdlib>
using namespace metal;

struct TD_02_Cube_VertexIn {
    float3 position [[attribute(0)]];
    float4 color [[attribute(1)]];
};

struct TD_02_Cube_VertexOut {
    float4 position [[position]];
    float4 color;
};

float4 setPosition(constant float3 *positions, uint vertexIndex) {
    return float4(positions[vertexIndex], 1.0);
}

vertex TD_02_Cube_VertexOut vs_td_02_cube(TD_02_Cube_VertexIn inVertex [[stage_in]],
                                          uint vertexIndex [[vertex_id]],
                                          constant float3 *positions [[buffer(1)]],
                                          constant float4x4& translationModelMatrix [[buffer(2)]],
                                          constant float4x4& rotationModelMatrix [[buffer(3)]],
                                          constant float4x4& scaleModelMatrix [[buffer(4)]],
                                          constant float4x4& finalModelMatrix [[buffer(5)]])
{
    TD_02_Cube_VertexOut out;

    // out.position = setPosition(positions, vertexIndex);
    // out.position = translationModelMatrix * rotationModelMatrix * scaleModelMatrix * float4(inVertex.position, 1.0);
    out.position = finalModelMatrix * float4(inVertex.position, 1.0);
    
    out.color = inVertex.color;
    return out;
}

fragment float4 fs_td_02_cube(TD_02_Cube_VertexOut outVertex [[stage_in]])
{
    return outVertex.color;
}
