//
//  ShaderTypes.h
//  MTLCanvas
//
//  Created by Fan on 2019/12/11.
//  Copyright © 2019 Yoko. All rights reserved.
//

#ifndef ShaderTypes_h
#define ShaderTypes_h

#ifdef __METAL_VERSION__
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
#define NSInteger metal::int32_t
#else
#import <Foundation/Foundation.h>
#endif

#include <simd/simd.h>


typedef NS_ENUM(NSInteger, RenderBufferIndex)
{
    RenderBufferIndexMeshVertexs = 0,
    RenderBufferIndexSpriteUniform = 1
};

typedef NS_ENUM(NSInteger, RenderTextureIndex)
{
    RenderTextureIndexColor = 0
};

typedef NS_ENUM(NSInteger, RenderVertexAttribute)
{
    RenderVertexAttributePosition  = 0,
    RenderVertexAttributeTexcoord  = 1
};


typedef struct
{
    float pointSize;
} SpriteUniforms;

#endif /* ShaderTypes_h */
