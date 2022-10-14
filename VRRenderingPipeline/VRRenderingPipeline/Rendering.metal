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

struct Vert {
    float4 position [[position]];
    float2 uv;
};

[[vertex]]
Vert copyVert(uint vid [[vertex_id]]) {
    Vert vert;
    float2 textureVert = verts[vid];
    
    vert.position = float4(textureVert, 0, 1);
    vert.uv = textureVert * 0.5 + 0.5;
    vert.uv = float2(vert.uv.x, 1 - vert.uv.y);
    return vert;
}

constexpr metal::sampler sam(metal::min_filter::nearest, metal::mag_filter::nearest, metal::mip_filter::none);

constant float2 conversion = float2(60.f / 360.f, 60.f / 180.f);

[[fragment]]
float4 editImage(Vert vert [[stage_in]],
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
    return float4(color.x, color.y, color.z, color.w);
}