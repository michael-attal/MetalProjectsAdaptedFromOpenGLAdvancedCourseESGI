//
//  TriangleBackup.metal
//  MetalProjectsAdaptedFromOpenGLAdvancedCourseESGI
//
//  Created by Michaël ATTAL on 06/03/2025.
//

#include <metal_stdlib>
using namespace metal;

struct Backup_VertexOut {
    float4 position [[position]];
    float2 uv; // Fragment coordinates
};

vertex Backup_VertexOut vs_backup_triangle_gradient(uint vertexID [[vertex_id]])
{
    Backup_VertexOut out;

    float2 positions[3] = {
        float2( 0.0,  0.5),
        float2(-0.5, -0.5),
        float2( 0.5, -0.5)
    };

    float2 uvs[3] = {
        float2(0.5, 1.0), // Top
        float2(0.0, 0.0),
        float2(1.0, 0.0)
    };

    //  Place top vertex
    out.position = float4(positions[vertexID], 0.0, 1.0);

    // We store the UV coordinate for the fragment
    out.uv = uvs[vertexID];

    return out;
}

fragment float4 fs_backup_triangle_gradient(Backup_VertexOut in [[stage_in]])
{
    // in.uv.y will be close to 0 at the bottom of the triangle, and close to 1 at the top.
    // For the test, we  interpolate between two different colors (e.g. black -> blue).
    
    // Base color
    float4 colorBottom = float4(0.0, 0.0, 0.0, 1.0); // Black
    float4 colorTop    = float4(0.0, 0.0, 1.0, 1.0); // Blue

    // Interpolation: the higher we are (uv.y close to 1), the bluer it is
    float4 color = mix(colorBottom, colorTop, in.uv.y);
    
    return color;
}
