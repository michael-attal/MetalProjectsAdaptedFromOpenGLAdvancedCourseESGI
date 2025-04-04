//
//  TriangleGradientRenderer.swift
//  MetalProjectsAdaptedFromOpenGLAdvancedCourseESGI
//
//  Created by Michaël ATTAL on 06/03/2025.
//

import MetalKit

final class TriangleGradientRenderer {
    public var mainRenderer: MainMetalRenderer?

    private let device: MTLDevice
    private var pipelineState: MTLRenderPipelineState?
    private var vertexBuffer: MTLBuffer?

    init(device: MTLDevice, library: MTLLibrary?) {
        self.device = device
        buildPipeline(library: library)
    }

    private func buildPipeline(library: MTLLibrary?) {
        guard let library = library else {
            fatalError("Failed to build pipeline for TriangleGradientRenderer")
        }

        let vertexFunction = library.makeFunction(name: "vs_triangle_gradient")
        let fragmentFunction = library.makeFunction(name: "fs_triangle_gradient")

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.rasterSampleCount = 4

        // let vertexDescriptor = MTLVertexDescriptor()

        // vertexDescriptor.attributes[0].format = .float2
        // vertexDescriptor.attributes[0].offset = 0
        // vertexDescriptor.attributes[0].bufferIndex = 0

        // vertexDescriptor.layouts[0].stride = MemoryLayout<TriangleGradientVertex>.stride

        // pipelineDescriptor.vertexDescriptor = vertexDescriptor

        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("Could not create pipeline state: \(error)")
        }
    }

    func draw(encoder: MTLRenderCommandEncoder, uniformBuffer: MTLBuffer?) {
        guard
            let pipeline = pipelineState
        // let vb = vertexBuffer
        else {
            return
        }

        encoder.setRenderPipelineState(pipeline)

        // encoder.setVertexBuffer(vb, offset: 0, index: 0)

        if let ub = uniformBuffer {
            encoder.setVertexBuffer(ub, offset: 0, index: 1)
        }

        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
    }
}
