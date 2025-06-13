//
//  TD_05_Illumination.metal
//  MetalProjectsAdaptedFromOpenGLAdvancedCourseESGI
//
//  Created by Michaël ATTAL on 16/04/2045.
//

#include <metal_stdlib>
using namespace metal;

// Inverse exist only for matrix 4x4 in metal
// Copied from https://developer.apple.com/forums/thread/722849?answerId=826064022#826064022
static float3x3 TD_05_Illumination_inverse(float3x3 const m)
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
struct TD_05_Illumination_VertexIn {
    float3 position [[attribute(0)]];
    float3 normal [[attribute(1)]];
    float2 uv [[attribute(2)]];
};

// We could just use TD_05_Illumination_VertexIn because we use the same datas but again, let's keep it here just in case.
struct TD_05_Illumination_VertexOut {
    float4 position [[position]];
    float3 normal;
    float2 uv;
};

struct TD_05_Illumination_Light {
    float3 direction;
    float3 diffuseColor;
    float3 specularColor;
    float specularIntensity;
};

struct TD_05_Illumination_Material {
    float3 diffuseColor;
    float3 specularColor;
    float shininess;
};

vertex TD_05_Illumination_VertexOut vs_TD_05_Illumination(TD_05_Illumination_VertexIn inVertex [[stage_in]],
                                          uint vertexIndex [[vertex_id]],
                                          constant float3 *positions [[buffer(1)]],
                                          constant float3 *normals [[buffer(2)]],
                                          constant float2 *uv [[buffer(3)]],
                                          constant float4x4& translationModelMatrix [[buffer(4)]],
                                          constant float4x4& rotationModelMatrix [[buffer(5)]],
                                          constant float4x4& scaleModelMatrix [[buffer(6)]],
                                          constant float4x4& finalModelMatrix [[buffer(7)]])
{
    TD_05_Illumination_VertexOut out;

    out.position = finalModelMatrix * float4(positions[vertexIndex], 1.0);
    float4x4 matrixWithoutProjection = translationModelMatrix * rotationModelMatrix * scaleModelMatrix;
    float3x3 normalMatrix = transpose(TD_05_Illumination_inverse(float3x3(
        matrixWithoutProjection.columns[0].xyz,
        matrixWithoutProjection.columns[1].xyz,
        matrixWithoutProjection.columns[2].xyz
    )));
    out.normal = normalize(normalMatrix * normals[vertexIndex]);
    out.uv = uv[vertexIndex];
    
    return out;
}

fragment float4 fs_TD_05_Illumination(TD_05_Illumination_VertexOut outVertex [[stage_in]])
{
    return float4(0, 1, 0, 1);
}

float3 TD_05_Illumination_getDiffuse(float3 normal, float3 directionTowardsLight) {
    // float3 n = normalize(normal); // Avoid calculation on function
    // float3 l = normalize(directionTowardsLight);
    float3 n = normal;
    float3 l = directionTowardsLight;
    
    float NdotL = max(dot(n, l), 0.0);

    return float3(NdotL);
}

float3 TD_05_Illumination_getReflect(float3 incident, float3 normal) {
    // Reflect the incident vector around the normal
    return normalize(reflect(-incident, normal)); // Metal’s reflect assumes I = direction from light
}

float3 TD_05_Illumination_getSpecular(float3 incident, float3 normal, float3 viewDirection, float shininess) {
    float3 reflectDir = TD_05_Illumination_getReflect(incident, normal);
    float RdotV = max(dot(reflectDir, viewDirection), 0.0);
    return pow(RdotV, shininess);
}
fragment float4 fs_TD_05_Illumination_textured(
    TD_05_Illumination_VertexOut outVertex [[stage_in]],
    texture2d<float> fillTexture [[texture(0)]],
    texture2d<float> displacementTexture [[texture(1)]],
    texture2d<float> normalTexture [[texture(2)]],
    texture2d<float> roughnessTexture [[texture(3)]],
    texture2d<float> HDRPmaskMapTexture [[texture(4)]],
    constant bool& useAllTextures [[buffer(5)]],
    constant TD_05_Illumination_Light& u_light [[buffer(6)]],
    constant TD_05_Illumination_Material& u_material [[buffer(7)]])
{
    constexpr sampler s(address::clamp_to_edge, filter::linear);

    float4 fillTextureOrAlbedoTexture = fillTexture.sample(s, outVertex.uv);
    
    float3 lightDirection = normalize(u_light.direction);
    float3 directionTowardsLight = -lightDirection;
    float3 normal = normalize(outVertex.normal);
    float3 diffuse = TD_05_Illumination_getDiffuse(normal, directionTowardsLight);
    float3 lightDiffuseColor = u_light.diffuseColor;
    float3 finalDiffuse = diffuse * lightDiffuseColor;
    float3 specularColor = u_material.specularColor;
    float shininess = u_material.shininess;
    float3 incident = -directionTowardsLight;
    float3 viewDirection = normalize(-outVertex.position.xyz);
    float3 finalSpecular = TD_05_Illumination_getSpecular(incident, normal, viewDirection, shininess) * specularColor * u_light.specularIntensity;
    return float4(finalDiffuse * u_material.diffuseColor * fillTextureOrAlbedoTexture.rgb + finalSpecular, fillTextureOrAlbedoTexture.a);
}
