//
//  CanvasRender.swift
//  MTLCanvas
//
//  Created by Fan on 2019/12/11.
//  Copyright © 2019 Yoko. All rights reserved.
//

import Foundation
import MetalKit
import Metal
import Accelerate





class CanvasRender: NSObject, MTKViewDelegate {
    
    class var colorPixelFormat: MTLPixelFormat {
        return MTLPixelFormat.bgra8Unorm_srgb
    }
    
    class var sampleCount: Int {
        return 1
    }
    
    public let device: MTLDevice
    let commandQueue: MTLCommandQueue
    var vertextDataBuffer: MTLBuffer
    var vertextIndicesBuffer: MTLBuffer
    let brushTexture: MTLTexture
    let pipeline: MTLRenderPipelineState
    let pointSizeBuffer: MTLBuffer
    var pointSizeUniform: UnsafeMutablePointer<SpriteUniforms>
    
    
    init?(aDevice: MTLDevice) {
        device = aDevice
        
        guard let queue = device.makeCommandQueue() else {
            return nil
        }
        commandQueue = queue
        
        let cut: Int = 12800
        
        let xPlotsData: [Float] = [-0.3, 0.2]
        let xPlotsIndics: [Float] = [0, Float(cut)]
        var xresult: [Float] = [Float](repeating: 0, count: cut)
        vDSP_vgenp(xPlotsData, vDSP_Stride(1), xPlotsIndics, vDSP_Stride(1), &xresult, vDSP_Stride(1), vDSP_Length(cut), vDSP_Length(xPlotsData.count))
        
        let yPlotsData: [Float] = [-0.3, 0.2]
        let yPlotsIndics: [Float] = [0, Float(cut)]
        var yresult: [Float] = [Float](repeating: 0, count: cut)
        vDSP_vgenp(yPlotsData, vDSP_Stride(1), yPlotsIndics, vDSP_Stride(1), &yresult, vDSP_Stride(1), vDSP_Length(cut), vDSP_Length(yPlotsData.count))
        
        var vertexData: [Float] = [Float](repeating: 0, count: cut*6)
        for i in 0 ..< cut {
            vertexData[i*6 + 0] = xresult[i]
            vertexData[i*6 + 1] = yresult[i]
            vertexData[i*6 + 2] = 0
            vertexData[i*6 + 3] = 1
            vertexData[i*6 + 4] = 0
            vertexData[i*6 + 5] = 0
        }
        guard let vertexBuffer = CanvasRender.createBuffer(metalDevice: device, data: vertexData) else {
            return nil
        }
        
        vertextDataBuffer = vertexBuffer
        
        
        var vertexIndex: [UInt16] = [UInt16](repeating: 0, count: cut)
        for i in 0 ..< cut {
            vertexIndex[i] = UInt16(i)
        }
        guard let indicesBuffer = CanvasRender.createBuffer(metalDevice: device, data: vertexIndex) else {
            return nil
        }
        
        vertextIndicesBuffer = indicesBuffer
        
        guard let sampleColor = CanvasRender.loadTexture(metalDevice: device, textureName: "brush") else {
            return nil
        }
        brushTexture = sampleColor
        
        
        guard let uniformbuffer = device.makeBuffer(length: MemoryLayout<SpriteUniforms>.size, options: [MTLResourceOptions.storageModeShared]) else {
            return nil
        }
        
        pointSizeBuffer = uniformbuffer
        pointSizeUniform = UnsafeMutableRawPointer(pointSizeBuffer.contents()).bindMemory(to: SpriteUniforms.self, capacity: 1)
        pointSizeUniform[0].pointSize = 4
        
        
        guard let defaultLibrary = device.makeDefaultLibrary() else {
            return nil
        }
        
        let vertexProgram = defaultLibrary.makeFunction(name: "renderVertexShader")
        let fragmentProgram = defaultLibrary.makeFunction(name: "renderFragmentShader")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "RenderPipeline"
        pipelineDescriptor.vertexFunction = vertexProgram
        pipelineDescriptor.fragmentFunction = fragmentProgram
        
        let mtlVertexDescriptor = MTLVertexDescriptor()
        mtlVertexDescriptor.attributes[RenderVertexAttribute.position.rawValue].format = MTLVertexFormat.float4
        mtlVertexDescriptor.attributes[RenderVertexAttribute.position.rawValue].offset = 0
        mtlVertexDescriptor.attributes[RenderVertexAttribute.position.rawValue].bufferIndex = RenderBufferIndex.meshVertexs.rawValue
        
        mtlVertexDescriptor.attributes[RenderVertexAttribute.texcoord.rawValue].format = MTLVertexFormat.float2
        mtlVertexDescriptor.attributes[RenderVertexAttribute.texcoord.rawValue].offset = 16
        mtlVertexDescriptor.attributes[RenderVertexAttribute.texcoord.rawValue].bufferIndex = RenderBufferIndex.meshVertexs.rawValue
        
        mtlVertexDescriptor.layouts[RenderBufferIndex.meshVertexs.rawValue].stride = 24
        mtlVertexDescriptor.layouts[RenderBufferIndex.meshVertexs.rawValue].stepRate = 1
        mtlVertexDescriptor.layouts[RenderBufferIndex.meshVertexs.rawValue].stepFunction = MTLVertexStepFunction.perVertex
        
        pipelineDescriptor.vertexDescriptor = mtlVertexDescriptor
        
        pipelineDescriptor.sampleCount = CanvasRender.sampleCount
        pipelineDescriptor.colorAttachments[0].pixelFormat = CanvasRender.colorPixelFormat
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation           = MTLBlendOperation.add;
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation         = MTLBlendOperation.add;
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor        = MTLBlendFactor.sourceAlpha;
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor      = MTLBlendFactor.sourceAlpha;
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor   = MTLBlendFactor.oneMinusSourceAlpha;
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactor.oneMinusSourceAlpha;
        

        
        do {
            pipeline = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            print("makeRenderPipelineState \(error)")
            return nil
        }
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            return
        }
        
        if let passDescriptor = view.currentRenderPassDescriptor {
            passDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 1.0, green: 1, blue: 1, alpha: 1)
            passDescriptor.colorAttachments[0].loadAction = .clear
            passDescriptor.colorAttachments[0].storeAction = .store
            
            if let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: passDescriptor) {
                
                renderEncoder.label = "Primary Render Encoder"
                renderEncoder.pushDebugGroup("Draw Box")
                renderEncoder.setCullMode(.back)
                renderEncoder.setFrontFacing(.counterClockwise)
                renderEncoder.setRenderPipelineState(pipeline)
                
                renderEncoder.setVertexBuffer(vertextDataBuffer, offset: 0, index: RenderBufferIndex.meshVertexs.rawValue)
                renderEncoder.setVertexBuffer(pointSizeBuffer, offset: 0, index: RenderBufferIndex.spriteUniform.rawValue)
                renderEncoder.setFragmentTexture(brushTexture, index: RenderTextureIndex.color.rawValue)
                
                renderEncoder.drawIndexedPrimitives(type: MTLPrimitiveType.point, indexCount: vertextIndicesBuffer.length/MemoryLayout<UInt16>.size, indexType: MTLIndexType.uint16, indexBuffer: vertextIndicesBuffer, indexBufferOffset: 0)
                
                renderEncoder.popDebugGroup()
                renderEncoder.endEncoding()
            }
        }
        
        if let drawable = view.currentDrawable {
            commandBuffer.present(drawable)
        }
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
    
    func setPointSize(size: Float) {
        pointSizeUniform[0].pointSize = size
    }
    
    func setSpriteCounts(count: Int) {
        let cut: Int = count
        
        let xPlotsData: [Float] = [-0.3, 0.4]
        let xPlotsIndics: [Float] = [0, Float(cut)]
        var xresult: [Float] = [Float](repeating: 0, count: cut)
        vDSP_vgenp(xPlotsData, vDSP_Stride(1), xPlotsIndics, vDSP_Stride(1), &xresult, vDSP_Stride(1), vDSP_Length(cut), vDSP_Length(xPlotsData.count))
        
        let yPlotsData: [Float] = [-0.3, 0.4]
        let yPlotsIndics: [Float] = [0, Float(cut)]
        var yresult: [Float] = [Float](repeating: 0, count: cut)
        vDSP_vgenp(yPlotsData, vDSP_Stride(1), yPlotsIndics, vDSP_Stride(1), &yresult, vDSP_Stride(1), vDSP_Length(cut), vDSP_Length(yPlotsData.count))
        
        var vertexData: [Float] = [Float](repeating: 0, count: cut*6)
        for i in 0 ..< cut {
            vertexData[i*6 + 0] = xresult[i]
            vertexData[i*6 + 1] = yresult[i]
            vertexData[i*6 + 2] = 0
            vertexData[i*6 + 3] = 1
            vertexData[i*6 + 4] = 0
            vertexData[i*6 + 5] = 0
        }
        guard let vertexBuffer = CanvasRender.createBuffer(metalDevice: device, data: vertexData) else {
            return
        }
        
        vertextDataBuffer = vertexBuffer
        
        
        var vertexIndex: [UInt16] = [UInt16](repeating: 0, count: cut)
        for i in 0 ..< cut {
            vertexIndex[i] = UInt16(i)
        }
        guard let indicesBuffer = CanvasRender.createBuffer(metalDevice: device, data: vertexIndex) else {
            return
        }
        
        vertextIndicesBuffer = indicesBuffer
    }
    
    static func createBuffer<T>(metalDevice: MTLDevice, data: [T]) -> MTLBuffer? {
        let dataSize = data.count * MemoryLayout.size(ofValue: data[0])
        
        return metalDevice.makeBuffer(bytes: data, length: dataSize, options: MTLResourceOptions.storageModeManaged)
    }
    
    static func loadTexture(metalDevice: MTLDevice, textureName: String) -> MTLTexture? {
        let loader = MTKTextureLoader(device: metalDevice)
        
        let textureLoaderOptions = [
            MTKTextureLoader.Option.textureUsage: MTLTextureUsage.shaderRead.rawValue,
            MTKTextureLoader.Option.textureStorageMode: MTLStorageMode.managed.rawValue
        ]
        
        return try? loader.newTexture(name: textureName, scaleFactor: 1.0, bundle: nil, options: textureLoaderOptions)
    }
}
