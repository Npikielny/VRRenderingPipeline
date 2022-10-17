//
//  Rendering.metal
//  VRRenderingPipeline
//
//  Created by Noah Pikielny on 10/13/22.
//

#include <metal_stdlib>
using namespace metal;

constant float2 verts[] = {
    float2(-1, -1),
    float2(1, -1),
    float2(1, 1),
    
    float2(-1, -1),
    float2(1, 1),
    float2(-1, 1)
};

enum Eye {
    left,
    right,
    none
};

struct Vert {
    float4 position [[position]];
    float2 uv;
};

float2 flipUV(float2 in) {
    return float2(in.x, 1 - in.y);
}

[[vertex]]
Vert eyeVert(uint vid [[vertex_id]],
             constant int & eye) {
    Vert vert;
    float2 textureVert = verts[vid];
    
    vert.position = float4(textureVert.x * 0.5, textureVert.y, 0, 1);
    vert.uv = textureVert * 0.5 + 0.5;
    vert.uv = flipUV(vert.uv);
    return vert;
}

[[vertex]]
Vert imageVert(uint vid [[vertex_id]]) {
    Vert vert;
    float2 textureVert = verts[vid];
    vert.position = float4(textureVert, 0, 1);
    vert.uv = textureVert * 0.5 + 0.5;
    vert.uv = flipUV(vert.uv);
    return vert;
}

constexpr metal::sampler sam(metal::min_filter::nearest, metal::mag_filter::nearest, metal::mip_filter::none);

constant float2 conversion = float2(60.f / 360.f, 60.f / 180.f);
//constant float2 offset = float2(0.2, 0);
[[fragment]]
float4 renderImages(Vert vert [[stage_in]],
                    texture2d<float> image,
                    constant float * angles,
                    constant int & eye) {
    float angle = angles[0];
    
    
    float2 uv = float2x2(
                         cos(angle), -sin(angle),
                         sin(angle), cos(angle)
                         ) * (vert.uv - 0.5) * conversion + 0.5;
    float2 offset = float2(angles[1] + 0.5 * (float)eye, 0);
    uv += offset * conversion;
    float2 x = 1;
    uv = modf(uv, x);
    if (uv.x < 0) {
        uv.x += 1;
    }
    
    float4 color = image.sample(sam, uv);
//    return float4(1, 0, 0, 1);
    return float4(color.x, color.y, color.z, color.w);
}

[[fragment]]
float4 applyFisheye(Vert vert [[stage_in]],
                    texture2d<float>image) {
    const float PI = 3.141592;
    float aperture = 170.0;
    float apertureHalf = 0.5 * aperture * (PI / 180.0);
    float maxFactor = sin(apertureHalf);
    
    float2 uv;
    float2 xy = 2.0 * vert.uv - 1.0;
    
    float d = length(xy);
    
    if (d < 2.0-maxFactor) {
        d = length(xy * maxFactor);
        float z = sqrt(1.0 - d * d);
        float r = atan2(d, z) / PI;
        float phi = atan2(xy.y, xy.x);
        
        uv.x = r * cos(phi) + 0.5;
        uv.y = r * sin(phi) + 0.5;
    }
    else {
        uv = vert.uv.xy;
    }

    return image.sample(sam, uv);
}

[[fragment]]
float4 copyToDrawable(Vert vert [[stage_in]],
                      texture2d<float, access::sample>image) {
    return image.sample(sam, vert.uv);
}
