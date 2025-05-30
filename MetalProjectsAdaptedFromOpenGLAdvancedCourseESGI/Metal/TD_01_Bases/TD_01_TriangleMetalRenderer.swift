//
//  TD_01_TriangleMetalRenderer.swift
//  MetalProjectsAdaptedFromOpenGLAdvancedCourseESGI
//
//  Created by Michaël ATTAL on 06/03/2025.
//

import MetalKit

struct TD_01_Triangle_VertexIn {
    let position: SIMD2<Float>
    let color: SIMD4<Float>
}

final class TD_01_TriangleMetalRenderer: NSObject, MTKViewDelegate {
    private let device: MTLDevice
    private var pipelineState: MTLRenderPipelineState?
    private var commandQueue: MTLCommandQueue?
    private var vertexBuffer: MTLBuffer?
    private var indexBuffer: MTLBuffer? // For exercise B2
    private var positionsBuffer: MTLBuffer? // For exercise B2

    var indices: [UInt16] = []

    init(mtkView: MTKView) {
        guard let device = mtkView.device else {
            fatalError("MTKView has no MTLDevice.")
        }
        self.device = device
        super.init()
        
        // Creates CommandQueue and pipeline
        buildResources(mtkView: mtkView)
    }
    
    private func buildResources(mtkView: MTKView) {
        // 1. Creation of a command queue
        commandQueue = device.makeCommandQueue()
        
        // 2. Retrieving the Metal library (which includes all metal files)
        guard let library = device.makeDefaultLibrary() else {
            fatalError("Failed to create Metal library.")
        }
        
        // 3. Functions (vertex & fragment) corresponding to shaders
        let vertexFunction = library.makeFunction(name: "vs_td_01_triangle")
        let fragmentFunction = library.makeFunction(name: "fs_td_01_triangle")
        
        // 4. Pipeline descriptor creation
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        
        // 4.b Vertex buffer descriptor creation
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[1].format = .float4
        vertexDescriptor.attributes[1].offset = 16 // MemoryLayout<SIMD2<Float>>.stride // I DONT KNOW WHY SWIFT IS ADDING PADDING TO SIMD2<Float> (so it's not 8 but 16 bytes)
        vertexDescriptor.attributes[1].bufferIndex = 0

        vertexDescriptor.layouts[0].stride = MemoryLayout<TD_01_Triangle_VertexIn>.stride

        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        
        // 5. Pipeline state creation
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("Could not create pipeline state: \(error)")
        }
        
        // 5.b Vertex & Index buffer creation
        
        let positions2D: [SIMD2<Float>] = [
            SIMD2<Float>(-0.5, -0.5), // bottom-left
            SIMD2<Float>(0.5, -0.5), // bottom-right
            SIMD2<Float>(0.0, 0.5), // top middle
            //SIMD2<Float>(0.0, -0.75) // (bottom adjusted middle) Uncomment for 2 triangles
        ]
        let redColor = SIMD4<Float>(1.0, 0.0, 0.0, 1.0)
        let blueColor = SIMD4<Float>(0.0, 0.0, 1.0, 1.0)
        let greenColor = SIMD4<Float>(0.0, 1.0, 0.0, 1.0)
        let colors = [redColor, blueColor, greenColor]
        var vertices: [TD_01_Triangle_VertexIn] = []
        vertices.reserveCapacity(positions2D.count)
        for (i, p) in positions2D.enumerated() {
            vertices.append(TD_01_Triangle_VertexIn(position: p, color: colors[i % 3]))
        }
            
        vertexBuffer = device.makeBuffer(
            bytes: vertices,
            length: vertices.count * MemoryLayout<TD_01_Triangle_VertexIn>.stride,
            options: []
        )
        
        // Define an array of indices for the triangle(s)
        indices = [0, 1, 2]
        // indices = [0, 1, 2, 0, 1, 3] // Uncomment for 2 triangles

        // Create the index buffer
        indexBuffer = device.makeBuffer(
            bytes: indices,
            length: indices.count * MemoryLayout<UInt16>.stride,
            options: []
        )
        
        // Constant positions buffer
        positionsBuffer = device.makeBuffer(
            bytes: positions2D,
            length: positions2D.count * MemoryLayout<SIMD2<Float>>.stride,
            options: []
        )
    }
    
    // MARK: - MTKViewDelegate
    
    /// Called if view size changes
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // TODO: Handle view resize here
    }
    
    /// Called every frame to draw
    func draw(in view: MTKView) {
        guard
            let pipelineState = pipelineState,
            let commandQueue = commandQueue,
            let passDescriptor = view.currentRenderPassDescriptor,
            let drawable = view.currentDrawable,
            let vertexBuffer = vertexBuffer,
            let indexBuffer = indexBuffer,
            let positionsBuffer = positionsBuffer,
            indices.count > 0
        else {
            return
        }
        
        // 1. Command buffer creation
        let commandBuffer = commandQueue.makeCommandBuffer()!
        
        // 2. Render command encoder creation
        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: passDescriptor)!
        encoder.setRenderPipelineState(pipelineState)
        
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)

        encoder.setVertexBuffer(positionsBuffer, offset: 0, index: 1)

        // 3. Draw a triangle (3 vertices)
        // encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3) // Exercise A1, A2, B1
        encoder.drawIndexedPrimitives(type: .triangle, indexCount: indices.count, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0) // Exercise B.2
        
        // 4. End & commit
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
