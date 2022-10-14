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
    right
};

struct Vert {
    float4 position [[position]];
    float2 uv;
    float2 textureUV;
    int eye;
};

float2 flipUV(float2 in) {
    return float2(in.x, 1 - in.y);
}

[[vertex]]
Vert copyVert(uint vid [[vertex_id]]) {
    Vert vert;
    float2 textureVert = verts[vid % 6];

    if (vid < 6) {
        vert.eye = left;
    } else {
        vert.eye = right;
    }
    
    vert.position = float4(textureVert.x * 0.5 + ((float)vert.eye - 0.5), textureVert.y, 0, 1);
    vert.uv = textureVert * 0.5 + 0.5;
    vert.uv = flipUV(vert.uv);
    
    vert.textureUV = vert.uv * float2(0.5, 1);
    if (vert.eye == right) {
        vert.textureUV += float2(0.5, 0);
    }
    
    return vert;
}

constexpr metal::sampler sam(metal::min_filter::nearest, metal::mag_filter::nearest, metal::mip_filter::none);

constant float2 conversion = float2(60.f / 360.f, 60.f / 180.f);
constant float2 offset = float2(0.2, 0);
[[fragment]]
float4 renderImages(Vert vert [[stage_in]],
                    texture2d<float> image,
                    constant float * angles) {
    float angle = angles[0];
    
    
    float2 uv = float2x2(
                         cos(angle), -sin(angle),
                         sin(angle), cos(angle)
                         ) * (vert.uv - 0.5) * conversion + 0.5;
    float2 offset = float2(angles[1], 0);
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
    float4 color = image.sample(sam, vert.textureUV);
    
    return color;
}
