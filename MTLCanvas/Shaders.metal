//
//  Shaders.metal
//  MTLCanvas
//
//  Created by Fan on 2019/12/11.
//  Copyright © 2019 Yoko. All rights reserved.
//

#include <metal_stdlib>
#include <simd/simd.h>
#import "ShaderTypes.h"

using namespace metal;


typedef struct
{
    float4 position [[attribute(RenderVertexAttributePosition)]];
    float2 texCoord [[attribute(RenderVertexAttributeTexcoord)]];
} RenderVertex;

typedef struct
{
    float4 position [[position]];
    float2 texCoord;
    float size [[point_size]];
} RenderVertexInOut;


vertex RenderVertexInOut renderVertexShader(RenderVertex in [[stage_in]],
                                            constant SpriteUniforms & spu [[ buffer(RenderBufferIndexSpriteUniform) ]])
{
    RenderVertexInOut out;
    
    out.position = in.position;
    out.texCoord = in.texCoord;
    out.size = spu.pointSize;
    
    return out;
}

fragment float4 renderFragmentShader(RenderVertexInOut in [[stage_in]],
                                             texture2d<float> colorMap [[ texture(RenderTextureIndexColor) ]],
                                            float2 pointCoord  [[ point_coord ]])
{
    constexpr sampler colorSampler(mag_filter::linear,
                                   min_filter::linear);
    
    float4 colorSample = colorMap.sample(colorSampler, pointCoord);
    
    return float4(0.3, 0.8, 0.2, colorSample.a);
    //return float4(colorSample.rgb, colorSample.a);
}


