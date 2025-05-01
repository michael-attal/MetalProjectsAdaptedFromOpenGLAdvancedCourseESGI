//
//  TD_04_Dragon.metal
//  MetalProjectsAdaptedFromOpenGLAdvancedCourseESGI
//
//  Created by Michaël ATTAL on 16/04/2045.
//

#include <metal_stdlib>
using namespace metal;

// Inverse exist only for matrix 4x4 in metal
// Copied from https://developer.apple.com/forums/thread/722849?answerId=826064022#826064022
static float3x3 inverse(float3x3 const m)
{
    float const A =   m[1][1] * m[2][2] - m[2][1] * m[1][2];
    float const B = -(m[0][1] * m[2][2] - m[2][1] * m[0][2]);
    float const C =   m[0][1] * m[1][2] - m[1][1] * m[0][2];
    float const D = -(m[1][0] * m[2][2] - m[2][0] * m[1][2]);
    float const E =   m[0][0] * m[2][2] - m[2][0] * m[0][2];
    float const F = -(m[0][0] * m[1][2] - m[1][0] * m[0][2]);
    float const G =   m[1][0] * m[2][1] - m[2][0] * m[1][1];
    float const H = -(m[0][0] * m[2][1] - m[2][0] * m[0][1]);
    float const I =   m[0][0] * m[1][1] - m[1][0] * m[0][1];
        
    float const det = m[0][0] * A + m[1][0] * B + m[2][0] * C;
    float const inv_det = 1.f / det;
    return inv_det * float3x3{
        float3{A, B, C},
        float3{D, E, F},
        float3{G, H, I}
    };
}

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
    float4x4 matrixWithoutProjection = translationModelMatrix * rotationModelMatrix * scaleModelMatrix;
    float3x3 normalMatrix = transpose(inverse(float3x3(
        matrixWithoutProjection.columns[0].xyz,
        matrixWithoutProjection.columns[1].xyz,
        matrixWithoutProjection.columns[2].xyz
    )));
    out.normal = normalize(normalMatrix * normals[vertexIndex]);
    out.uv = uv[vertexIndex];
    
    return out;
}

fragment float4 fs_td_04_dragon(TD_04_Dragon_VertexOut outVertex [[stage_in]])
{
    return float4(0, 1, 0, 1);
}

float3 getDiffuse(float3 normal, float3 directionTowardsLight) {
    // float3 n = normalize(normal); // Avoid calculation on function
    // float3 l = normalize(directionTowardsLight);
    float3 n = normal;
    float3 l = directionTowardsLight;
    
    float NdotL = max(dot(n, l), 0.0);

    return float3(NdotL);
}

float3 getReflect(float3 incident, float3 normal) {
    // Reflect the incident vector around the normal
    return normalize(reflect(-incident, normal)); // Metal’s reflect assumes I = direction from light
}

float3 getSpecular(float3 incident, float3 normal, float3 viewDirection, float shininess) {
    float3 reflectDir = getReflect(incident, normal);
    float RdotV = max(dot(reflectDir, viewDirection), 0.0);
    return pow(RdotV, shininess);
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
        // It's the dragon, we got normals
        // Calculate diffuse now for the TD 05 Illumination
        float3 lightDirection = normalize(float3(0.0, 0.0, -1.0));
        float3 directionTowardsLight = -lightDirection;
        float3 normal = normalize(outVertex.normal);
        float3 diffuse = getDiffuse(normal, directionTowardsLight);
        float3 lightDiffuseColor = float3(1.0, 1.0, 1.0); // For exercice 2, Part 3, Eq2. Diffuse = N.L * Id * Kd - Full white lighting ftm
        float3 finalDiffuse = diffuse * lightDiffuseColor;
        float3 specularColor = float3(1.0, 1.0, 1.0);
        float specularIntensity = 1.0;
        float shininess = 64.0;
        float3 incident = -directionTowardsLight;
        float3 viewDirection = normalize(-outVertex.position.xyz);
        float3 finalSpecular = getSpecular(incident, normal, viewDirection, shininess) * specularColor * specularIntensity; // Exercise 3 done.
        return float4(finalDiffuse * fillTextureOrAlbedoTexture.rgb + finalSpecular, fillTextureOrAlbedoTexture.a);
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
