//
//  Rendering.metal
//  VRRenderPipeline
//
//  Created by Noah Pikielny on 8/29/22.
//

#include <metal_stdlib>
using namespace metal;

constant float2 corners[] = {
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

vertex Vert cornerVert(uint vid [[vertex_id]]) {
    Vert vert;
    vert.position = float4(corners[vid], 0, 1);
    vert.uv = vert.position.xy * 0.5 + 0.5;
    return vert;
}

fragment float4 cornerFrag(Vert vert [[stage_in]]) {
    return float4(vert.uv, 0, 1);
}
