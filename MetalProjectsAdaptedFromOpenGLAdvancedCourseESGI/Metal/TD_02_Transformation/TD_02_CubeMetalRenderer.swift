//
//  TD_02_TriangleMetalRenderer.swift
//  MetalProjectsAdaptedFromOpenGLAdvancedCourseESGI
//
//  Created by Michaël ATTAL on 06/03/2025.
//

import MetalKit

struct TD_02_Cube_VertexIn {
    let position: SIMD3<Float>
    let color: SIMD4<Float>
}

enum TD_02_Cube_Direction {
    case top_right
    case bottom_left
}

enum TD_02_Cube_ScaleEffect {
    case grow
    case shrink
}

final class TD_02_CubeMetalRenderer: NSObject, MTKViewDelegate {
    private let device: MTLDevice
    private var pipelineState: MTLRenderPipelineState?
    private var commandQueue: MTLCommandQueue?
    private var vertexBuffer: MTLBuffer?
    private var indexBuffer: MTLBuffer?
    private var positionsBuffer: MTLBuffer?
    private var direction: TD_02_Cube_Direction = .top_right
    private var scaleEffect: TD_02_Cube_ScaleEffect = .grow
    private var projectionMatrix: matrix_float4x4 = .init()
    private var translationMatrix: matrix_float4x4 = .init()
    private var rotationMatrix: matrix_float4x4 = .init()
    private var scaleMatrix: matrix_float4x4 = .init()
    private var finalMatrix: matrix_float4x4 = .init()

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
        let vertexFunction = library.makeFunction(name: "vs_td_02_cube")
        let fragmentFunction = library.makeFunction(name: "fs_td_02_cube")
        
        // 4. Pipeline descriptor creation
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        
        // 4.b Vertex buffer descriptor creation
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[1].format = .float4
        vertexDescriptor.attributes[1].offset = 16 // MemoryLayout<SIMD3<Float>>.stride // All SIMD count as 16 bytes for optimization (it adds padding)
        vertexDescriptor.attributes[1].bufferIndex = 0

        vertexDescriptor.layouts[0].stride = MemoryLayout<TD_02_Cube_VertexIn>.stride

        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        
        // 5. Pipeline state creation
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("Could not create pipeline state: \(error)")
        }
        
        // 5.b Vertex & Index buffer creation
        
        let positions3D: [SIMD3<Float>] = [
            SIMD3<Float>(-0.5, -0.5, -0.5), // front bottom-left // z is -0.5 (behind the near plane). z is pointing into the screen (left hand), see 1.7 Metal Coordinate Systems: https://developer.apple.com/metal/Metal-Shading-Language-Specification.pdf
            SIMD3<Float>(0.5, -0.5, -0.5), // front bottom-right
            SIMD3<Float>(0.5, 0.5, -0.5), // front top-right
            SIMD3<Float>(-0.5, 0.5, -0.5), // front top-left
            
            SIMD3<Float>(-0.5, -0.5, 0.5), // back bottom-left
            SIMD3<Float>(0.5, -0.5, 0.5), // back bottom-right
            SIMD3<Float>(0.5, 0.5, 0.5), // back top-right
            SIMD3<Float>(-0.5, 0.5, 0.5), // back top-left
        ]
        let redColor = SIMD4<Float>(1.0, 0.0, 0.0, 1.0)
        let blueColor = SIMD4<Float>(0.0, 0.0, 1.0, 1.0)
        let greenColor = SIMD4<Float>(0.0, 1.0, 0.0, 1.0)
        let colors = [redColor, blueColor, greenColor]
        var vertices: [TD_02_Cube_VertexIn] = []
        vertices.reserveCapacity(positions3D.count)
        for (i, p) in positions3D.enumerated() {
            vertices.append(TD_02_Cube_VertexIn(position: p, color: colors[1]))
        }
            
        vertexBuffer = device.makeBuffer(
            bytes: vertices,
            length: vertices.count * MemoryLayout<TD_02_Cube_VertexIn>.stride,
            options: []
        )
        
        // Define an array of indices for the cube(s)
        indices = [
            0, 1, 2, 2, 3, 0, // front face
            4, 5, 6, 6, 7, 4, // back face
            4, 0, 3, 3, 7, 4, // left face
            1, 5, 6, 6, 2, 1, // right face
            3, 2, 6, 6, 7, 3, // top face
            4, 5, 1, 1, 0, 4, // bottom face
        ]

        // Create the index buffer
        indexBuffer = device.makeBuffer(
            bytes: indices,
            length: indices.count * MemoryLayout<UInt16>.stride,
            options: []
        )
        
        // Constant positions buffer
        positionsBuffer = device.makeBuffer(
            bytes: positions3D,
            length: positions3D.count * MemoryLayout<SIMD3<Float>>.stride,
            options: []
        )
        
        projectionMatrix = getProjectionMatrix()

        translationMatrix = getNewTranslationMatrix(isInitialState: true)
        
        rotationMatrix = getNewRotationMatrix(isInitialState: true, for: 0.0)
        
        scaleMatrix = getNewScaleMatrix(isInitialState: true)
        
        finalMatrix = projectionMatrix * translationMatrix * rotationMatrix * scaleMatrix
    }
    
    // MARK: - MTKViewDelegate
    
    /// Called if view size changes
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // TODO: Handle view resize here
    }
    
    func getNewTranslationMatrix(isInitialState: Bool = false) -> float4x4 {
        if isInitialState {
            let translationMatrix = matrix_float4x4.init(
                rows: [
                    // C0  C1   C2   C3
                    [1.0, 0.0, 0.0, 0],
                    [0.0, 1.0, 0.0, 0],
                    [0.0, 0.0, 1.0, -5.0], // Since the implementation of the projection matrix, move the cube a little bit.
                    [0.0, 0.0, 0.0, 1.0],
                ]
            )
            return translationMatrix
        } else {
            let prevTx = translationMatrix.columns.3.x
            let prevTy = translationMatrix.columns.3.y
            if prevTx >= 0.5 /* 1.0 */ {
                direction = .bottom_left
            } else if prevTy <= -0.5 /* -1.0 */ {
                direction = .top_right
            }
            // For fun: Switch back to initial state to do a ping pong effect :D
            let tx: Float = direction == .top_right ? prevTx + 0.01 : prevTx - 0.01
            let ty: Float = direction == .top_right ? prevTy + 0.01 : prevTy - 0.01
            let tz: Float = -5.0
            let translationMatrix = matrix_float4x4.init(
                rows: [
                    // C0  C1   C2   C3
                    [1.0, 0.0, 0.0, tx],
                    [0.0, 1.0, 0.0, ty],
                    [0.0, 0.0, 1.0, tz],
                    [0.0, 0.0, 0.0, 1.0],
                ]
            )
            return translationMatrix
        }
    }
    
    func getNewRotationMatrix(isInitialState: Bool = false, for time: TimeInterval) -> float4x4 {
        if isInitialState {
            let rotationMatrix = matrix_float4x4.init(
                rows: [
                    // C0  C1   C2   C3
                    [1.0, 0.0, 0.0, 0],
                    [0.0, 1.0, 0.0, 0],
                    [0.0, 0.0, 1.0, 0],
                    [0.0, 0.0, 0.0, 1.0],
                ]
            )
            return rotationMatrix
        } else {
            let angle = Float(time)
            let cA = cos(angle) // cosAngle
            let sA = sin(angle) // sinAngle

            // Rotate on X
            let rotationMatrix = matrix_float4x4.init(
                // x
                rows: [
                    // C0  C1   C2   C3
                    [1.0, 0.0, 0.0, 0.0],
                    [0.0, cA, -sA, 0.0],
                    [0.0, sA, cA, 0.0],
                    [0.0, 0.0, 0.0, 1.0],
                ]
                // y
                // rows: [
                //     // C0  C1   C2   C3
                //     [cA, 0.0, -sA, 0.0],
                //     [0.0, 1.0, 0.0, 0.0],
                //     [sA, 0.0, cA, 0.0],
                //     [0.0, 0.0, 0.0, 1.0],
                // ]
                // z
                // rows: [
                //     // C0  C1   C2   C3
                //     [cA, -sA, 0.0, 0.0],
                //     [sA, cA, 0.0, 0.0],
                //     [0.0, 0.0, 1.0, 0.0],
                //     [0.0, 0.0, 0.0, 1.0],
                // ]
            )
            
            return rotationMatrix
        }
    }

    func getNewScaleMatrix(isInitialState: Bool = false) -> float4x4 {
        if isInitialState {
            let scaleMatrix = matrix_float4x4.init(
                rows: [
                    // C0  C1   C2   C3
                    [1.0, 0.0, 0.0, 0],
                    [0.0, 1.0, 0.0, 0],
                    [0.0, 0.0, 1.0, 0],
                    [0.0, 0.0, 0.0, 1.0],
                ]
            )
            return scaleMatrix
        } else {
            let prevSx = scaleMatrix.columns.0.x
            let prevSy = scaleMatrix.columns.1.y
            let prevSz = scaleMatrix.columns.2.z
            if prevSx >= 2.0 {
                scaleEffect = .shrink
            } else if prevSx <= 0.5 {
                scaleEffect = .grow
            }
            // For fun: grow/shrink effect
            let sx: Float = scaleEffect == .grow ? prevSx + 0.01 : prevSx - 0.01
            let sy: Float = scaleEffect == .grow ? prevSy + 0.01 : prevSy - 0.01
            let sz: Float = scaleEffect == .grow ? prevSz + 0.01 : prevSz - 0.01
            let scaleMatrix = matrix_float4x4.init(
                rows: [
                    // C0  C1   C2   C3
                    [sx, 0.0, 0.0, 0.0],
                    [0.0, sy, 0.0, 0.0],
                    [0.0, 0.0, sz, 0.0],
                    [0.0, 0.0, 0.0, 1.0],
                ]
            )
            return scaleMatrix
        }
    }
    
    func getProjectionMatrix(near: Float = 0.1, far: Float = 100.0, aspect: Float = 1.0) -> float4x4 {
        let fovyRadians: Float = .pi / 4.0 // 45 degrees
        let cotangent = 1.0 / tan(fovyRadians / 2)
        let projectionMatrix = matrix_float4x4.init(
            rows: [
                // C0  C1   C2   C3
                [cotangent / aspect, 0.0, 0.0, 0.0],
                [0.0, cotangent, 0.0, 0.0],
                [0.0, 0.0, (far + near) / (near - far), 2 * near * far / (near - far)],
                [0.0, 0.0, -1.0, 0.0],
            ]
        )
        return projectionMatrix
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

        projectionMatrix = getProjectionMatrix()
        
        translationMatrix = getNewTranslationMatrix(isInitialState: true) // Set isInitialState to false to see ping pong effect
        // Send the translation transformation matrix directly to the GPU without creating a persistent buffer (efficient for small, frequently updated data) with setVertexBytes
        encoder.setVertexBytes(&translationMatrix, length: MemoryLayout<matrix_float4x4>.stride, index: 2)
        
        rotationMatrix = getNewRotationMatrix(isInitialState: false, for: CACurrentMediaTime())
        encoder.setVertexBytes(&rotationMatrix, length: MemoryLayout<matrix_float4x4>.stride, index: 3) // Set isInitialState to false to see rotation effect

        scaleMatrix = getNewScaleMatrix(isInitialState: true) // Set isInitialState to false to see grow/shrink effect
        encoder.setVertexBytes(&scaleMatrix, length: MemoryLayout<matrix_float4x4>.stride, index: 4)

        finalMatrix = projectionMatrix * translationMatrix * rotationMatrix * scaleMatrix // TRS
        encoder.setVertexBytes(&finalMatrix, length: MemoryLayout<matrix_float4x4>.stride, index: 5)

        encoder.drawIndexedPrimitives(type: .triangle, indexCount: indices.count, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)
        
        // 4. End & commit
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
