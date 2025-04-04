//
//  TriangleRenderer.metal
//  MetalProjectsAdaptedFromOpenGLAdvancedCourseESGI
//
//  Created by Michaël ATTAL on 06/03/2025.
//

#include <metal_stdlib>
using namespace metal;

struct TriangleSimpleVertexOut {
    float4 position [[position]];
    float4 color;
};

vertex TriangleSimpleVertexOut vs_triangle_simple(uint vertexID [[vertex_id]]) {
    TriangleSimpleVertexOut out;
    
    // Array of the positions of our 3 vertices (a triangle).
    float2 positions[3] = {
        float2( 0.0,  0.5),
        float2(-0.5, -0.5),
        float2( 0.5, -0.5)
    };
    
    out.position = float4(positions[vertexID], 0.0, 1.0);
    // We draw the triangle in blue
    out.color = float4(0.0, 0.0, 1.0, 1.0);
    return out;
}

fragment float4 fs_triangle_simple(TriangleSimpleVertexOut in [[stage_in]]) {
    return in.color;
}
