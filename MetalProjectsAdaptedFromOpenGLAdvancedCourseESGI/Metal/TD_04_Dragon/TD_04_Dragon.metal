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
    texture2d<float> fillTexture [[texture(0)]],
    texture2d<float> displacementTexture [[texture(1)]],
    texture2d<float> normalTexture [[texture(2)]],
    texture2d<float> roughnessTexture [[texture(3)]],
    texture2d<float> HDRPmaskMapTexture [[texture(4)]],
    constant bool& useAllTextures [[buffer(5)]])
{
    constexpr sampler s(address::clamp_to_edge, filter::linear);

    float4 fillTextureOrAlbedoTexture = fillTexture.sample(s, outVertex.uv);
    if (useAllTextures == false) {
        return fillTextureOrAlbedoTexture;
    }

    // Defaults
    float3 normal = float3(0.0, 0.0, 1.0);
    float roughness = 1.0;
    float metallic = 0.0;
    float ao = 1.0;

    // Sample and check normal texture
    float3 sampledNormal = normalTexture.sample(s, outVertex.uv).xyz;
    if (any(sampledNormal > float3(0.01))) {
        normal = normalize(sampledNormal * 2.0 - 1.0);
    }

    // Sample and check roughness texture
    float sampledRoughness = roughnessTexture.sample(s, outVertex.uv).g;
    if (sampledRoughness > 0.01) {
        roughness = sampledRoughness;
    }

    // Sample and check HDRP mask
    float4 hdrpSample = HDRPmaskMapTexture.sample(s, outVertex.uv);
    if (any(hdrpSample.rgb > float3(0.01))) {
        metallic = hdrpSample.r;
        ao = hdrpSample.g;
    }

    // Fake light direction (waiting for the course with light from the professor)
    float3 lightDir = normalize(float3(0.5, 0.5, 1.0));
    float3 viewDir = normalize(-outVertex.position.xyz);

    float NdotL = max(dot(normal, lightDir), 0.0);
    float3 diffuse = fillTextureOrAlbedoTexture.rgb * NdotL;

    float specularStrength = 1.0 - roughness;
    float3 halfwayDir = normalize(lightDir + viewDir);
    float NdotH = max(dot(normal, halfwayDir), 0.0);
    float3 specular = pow(NdotH, 32.0 * specularStrength) * specularStrength;

    float3 color = (diffuse + specular) * ao;

    return float4(color, fillTextureOrAlbedoTexture.a);
}
