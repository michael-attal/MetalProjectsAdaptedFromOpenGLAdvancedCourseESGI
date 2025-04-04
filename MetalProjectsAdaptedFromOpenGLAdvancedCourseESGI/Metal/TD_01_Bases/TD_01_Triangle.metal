//
//  TriangleBackup.metal
//  MetalProjectsAdaptedFromOpenGLAdvancedCourseESGI
//
//  Created by Michaël ATTAL on 06/03/2025.
//

#include <metal_stdlib>
using namespace metal;

struct TD_01_Triangle_VertexIn {
    float2 position [[attribute(0)]];
    float4 color [[attribute(1)]];
};

struct TD_01_Triangle_VertexOut {
    float4 position [[position]];
    float4 color;
};

// For exercises A1, A2 and B1
float4 vertexPosition2DTo3D(float2 position2D) {
    return float4(position2D.x, position2D.y, 0.0, 1.0);
}

// For exercice B2: Retrieves vertex position from an array passed via buffer
float4 vertexPositionFromPositionsBufferAndVertexIndex(constant float2 *positions, uint vertexIndex) {
    // We retrieve the position from the positions array using the vertex index.
    return float4(positions[vertexIndex], 0.0, 1.0);
}

vertex TD_01_Triangle_VertexOut vs_td_01_triangle(TD_01_Triangle_VertexIn inVertex [[stage_in]],
                                                  uint vertexIndex [[vertex_id]],
                                                  constant float2 *positions [[buffer(1)]])
{
    TD_01_Triangle_VertexOut out;

    // out.position = vertexPosition2DTo3D(inVertex.position); // A1, A2, B1
    out.position = vertexPositionFromPositionsBufferAndVertexIndex(positions, vertexIndex); // B2

    out.color = inVertex.color;
    return out;
}

fragment float4 fs_td_01_triangle(TD_01_Triangle_VertexOut outVertex [[stage_in]])
{
    return outVertex.color;
}

// Without custom vertex buffer example:

// struct TD_01_Triangle_VertexOut {
//     float4 position [[position]];
// };

// float4 vertexPosition2DTo3D(uint vertexID) {
//     const float2 positions2D[3] = {
//         float2(-0.5, -0.5),
//         float2(0.5, -0.5),
//         float2(0.0, 0.5)
//     };
//
//     return float4(positions2D[vertexID], 0.0, 1.0);
// }

// Now we use a custom vertex buffer to be as close as possible to the TD.
// vertex TD_01_Triangle_VertexOut vs_td_01_triangle(uint vertexID [[vertex_id]])
// { // We use custom vertexBuffer now
//     TD_01_Triangle_VertexOut out;
//
//     out.position = vertexPosition2DTo3D(vertexID);
//
//     return out;
// }
