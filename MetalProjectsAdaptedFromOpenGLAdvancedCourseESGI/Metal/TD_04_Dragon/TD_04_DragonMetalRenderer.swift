//
//  TD_04_TriangleMetalRenderer.swift
//  MetalProjectsAdaptedFromOpenGLAdvancedCourseESGI
//
//  Created by Michaël ATTAL on 16/04/2045.
//

import MetalKit

struct TD_04_Dragon_VertexIn {
    let position: SIMD3<Float>
    let normal: SIMD3<Float>
    let uv: SIMD2<Float>
}

enum TD_04_Dragon_Direction {
    case top_right
    case bottom_left
}

enum TD_04_Dragon_ScaleEffect {
    case grow
    case shrink
}

final class TD_04_DragonMetalRenderer: NSObject, MTKViewDelegate {
    private let device: MTLDevice
    private var pipelineState: MTLRenderPipelineState?
    private var commandQueue: MTLCommandQueue?
    private var vertexBuffer: MTLBuffer?
    private var indexBuffer: MTLBuffer?
    private var positionsBuffer: MTLBuffer?
    private var normalsBuffer: MTLBuffer?
    private var direction: TD_04_Dragon_Direction = .top_right
    private var scaleEffect: TD_04_Dragon_ScaleEffect = .grow
    private var projectionMatrix: matrix_float4x4 = .init()
    private var translationMatrix: matrix_float4x4 = .init()
    private var rotationMatrix: matrix_float4x4 = .init()
    private var scaleMatrix: matrix_float4x4 = .init()
    private var finalMatrix: matrix_float4x4 = .init()
    
    private var fillTexture: MTLTexture?
    private var textureData: [UInt8] = []
    private var uvBuffer: MTLBuffer?
    private var uvTexture: [SIMD2<Float>] = []
    private var textureWidth: Int = 1
    private var textureHeight: Int = 1

    private var depthStencilState: MTLDepthStencilState?
    
    private var indices: [UInt16] = []
    
    private let nbIndicesDragon = DragonIndices.count
    private let nbVerticesDragon = DragonVertices.count / 8 // because each vertex contains X,Y,Z, NX, NY, NZ, U, V = 8 floats per vertex
    
    private var isObj = false
    private var objMtlVertexDescriptor: MTLVertexDescriptor?
    private var objURL: URL?
    private var objMesh: MTKMesh?
    private var objSubmesh: MTKSubmesh?
    
    init(mtkView: MTKView, objURL: URL? = nil) {
        guard let device = mtkView.device else {
            fatalError("MTKView has no MTLDevice.")
        }
        self.device = device
        super.init()
        
        self.objURL = objURL
        
        // Creates CommandQueue and pipeline
        buildResources(mtkView: mtkView)
    }
    
    private func buildResources(mtkView: MTKView) {
        if let objURL = objURL {
            // MARK: - ModelIO Setup

            // 1. Prepare ModelIO vertex descriptor for position, normal, uv
            let mdlVertexDescriptor = MDLVertexDescriptor()
            mdlVertexDescriptor.attributes[0] = MDLVertexAttribute(name: MDLVertexAttributePosition,
                                                                   format: .float3,
                                                                   offset: 0,
                                                                   bufferIndex: 0)
            mdlVertexDescriptor.attributes[1] = MDLVertexAttribute(name: MDLVertexAttributeNormal,
                                                                   format: .float3,
                                                                   offset: MemoryLayout<SIMD3<Float>>.stride,
                                                                   bufferIndex: 0)
            mdlVertexDescriptor.attributes[2] = MDLVertexAttribute(name: MDLVertexAttributeTextureCoordinate,
                                                                   format: .float2,
                                                                   offset: MemoryLayout<SIMD3<Float>>.stride * 2,
                                                                   bufferIndex: 0)
            mdlVertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: MemoryLayout<TD_04_Dragon_VertexIn>.stride)

            // 2. Load the OBJ using ModelIO with custom descriptor
            let allocator = MTKMeshBufferAllocator(device: device)
            let asset = MDLAsset(url: objURL,
                                 vertexDescriptor: mdlVertexDescriptor,
                                 bufferAllocator: allocator)
            guard let mdlMesh = asset.childObjects(of: MDLMesh.self).first as? MDLMesh else {
                fatalError("Failed to load MDLMesh from URL: \(objURL)")
            }
            mdlMesh.addNormals(withAttributeNamed: MDLVertexAttributeNormal,
                               creaseThreshold: 0.0)

            // 3. Create an MTKMesh from the ModelIO mesh
            do {
                objMesh = try MTKMesh(mesh: mdlMesh, device: device)
            } catch {
                fatalError("Failed to create MTKMesh: \(error)")
            }
            guard let objMesh = objMesh, let firstSubmesh = objMesh.submeshes.first else {
                fatalError("No submeshes found in the OBJ model.")
            }
            objSubmesh = firstSubmesh

            // Convert MDL to MTL vertex descriptor for pipeline
            guard let mtlVertexDescriptor = MTKMetalVertexDescriptorFromModelIO(mdlVertexDescriptor) else {
                fatalError("Failed to convert MDLVertexDescriptor to MTLVertexDescriptor.")
            }
            
            objMtlVertexDescriptor = mtlVertexDescriptor
        }
        
        // 1. Creation of a command queue
        commandQueue = device.makeCommandQueue()
        
        // 2. Retrieving the Metal library (which includes all metal files)
        guard let library = device.makeDefaultLibrary() else {
            fatalError("Failed to create Metal library.")
        }
        
        // 3. Functions (vertex & fragment) corresponding to shaders
        let vertexFunction = library.makeFunction(name: "vs_td_04_dragon")
        let fragmentFunction = library.makeFunction(name: "fs_td_04_dragon_textured")
        
        // 4. Pipeline descriptor creation
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        
        // 4.b Vertex buffer descriptor creation
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].bufferIndex = 0 // Not used for the moment, we pass all these 3 attributes via vertex buffers
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[1].bufferIndex = 0
        vertexDescriptor.attributes[1].format = .float3
        vertexDescriptor.attributes[1].offset = 16 // MemoryLayout<SIMD3<Float>>.stride // All SIMD count as 16 bytes for optimization (it adds padding)
        vertexDescriptor.attributes[2].bufferIndex = 0
        vertexDescriptor.attributes[2].format = .float2
        vertexDescriptor.attributes[2].offset = 16

        vertexDescriptor.layouts[0].stride = MemoryLayout<TD_04_Dragon_VertexIn>.stride

        pipelineDescriptor.vertexDescriptor = isObj ? objMtlVertexDescriptor : vertexDescriptor
        
        let depthDescriptor = MTLDepthStencilDescriptor() // Configure Z-buffer
        depthDescriptor.isDepthWriteEnabled = true
        depthDescriptor.depthCompareFunction = .less
        depthStencilState = device.makeDepthStencilState(descriptor: depthDescriptor)
        
        mtkView.depthStencilPixelFormat = .depth32Float
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        
        // 5. Pipeline state creation
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("Could not create pipeline state: \(error)")
        }
        
        // 5.b Vertex & Index buffer creation
        
        // Added more positions (and indices) to allow custom textures per face (not just a uniform one).
        var positions3D: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var uv: [SIMD2<Float>] = []
        for i in 0 ..< DragonVertices.count {
            if i % 8 != 0 { continue }
            // if i == DragonVertices.count - 5 { break }
            positions3D.append([DragonVertices[i], DragonVertices[i + 1], DragonVertices[i + 2]])
            normals.append([DragonVertices[i + 3], DragonVertices[i + 4], DragonVertices[i + 5]])
            uv.append([DragonVertices[i + 6], DragonVertices[i + 7]])
        }
        
        var vertices: [TD_04_Dragon_VertexIn] = []
        vertices.reserveCapacity(positions3D.count)
        for (i, p) in positions3D.enumerated() {
            vertices.append(TD_04_Dragon_VertexIn(position: p, normal: .init(), uv: .init()))
        }
            
        vertexBuffer = device.makeBuffer(
            bytes: vertices,
            length: vertices.count * MemoryLayout<TD_04_Dragon_VertexIn>.stride,
            options: []
        )
        
        // Define an array of indices for the dragon
        indices = DragonIndices
        
        // Create the index buffer
        indexBuffer = device.makeBuffer(
            bytes: indices,
            length: indices.count * MemoryLayout<UInt16>.stride,
            options: []
        )
        
        if let objMesh = objMesh, let vb = objMesh.vertexBuffers.first, let objMtlVertexDescriptor = objMtlVertexDescriptor {
            let desc = objMtlVertexDescriptor
            let stride = desc.layouts[0].stride
            let posOffset = desc.attributes[0].offset
            let normalOffset = desc.attributes[1].offset
            let uvOffset = desc.attributes[2].offset
            let vertexCount = objMesh.vertexCount
            let rawPtr = vb.buffer.contents()

            var positions = [SIMD3<Float>]()
            var normals = [SIMD3<Float>]()
            var uvs = [SIMD2<Float>]()
            positions.reserveCapacity(vertexCount)
            normals.reserveCapacity(vertexCount)
            uvs.reserveCapacity(vertexCount)

            for i in 0 ..< vertexCount {
                let basePtr = rawPtr.advanced(by: i * stride)
                // Positions
                let pPtr = basePtr.advanced(by: posOffset).assumingMemoryBound(to: Float.self)
                let p = SIMD3<Float>(pPtr[0], pPtr[1], pPtr[2])
                positions.append(p)
                // Normals
                let nPtr = basePtr.advanced(by: normalOffset).assumingMemoryBound(to: Float.self)
                let n = SIMD3<Float>(nPtr[0], nPtr[1], nPtr[2])
                normals.append(n)
                // UVs
                let uPtr = basePtr.advanced(by: uvOffset).assumingMemoryBound(to: Float.self)
                let u = SIMD2<Float>(uPtr[0], uPtr[1])
                uvs.append(u)
            }

            positionsBuffer = device.makeBuffer(
                bytes: positions,
                length: positions.count * MemoryLayout<SIMD3<Float>>.stride,
                options: []
            )
            normalsBuffer = device.makeBuffer(
                bytes: normals,
                length: normals.count * MemoryLayout<SIMD3<Float>>.stride,
                options: []
            )
            uvBuffer = device.makeBuffer(
                bytes: uvs,
                length: uvs.count * MemoryLayout<SIMD2<Float>>.stride,
                options: []
            )

            if let sub = objSubmesh {
                indexBuffer = sub.indexBuffer.buffer
                indices = Array(UnsafeBufferPointer(start: sub.indexBuffer.buffer.contents().assumingMemoryBound(to: UInt16.self),
                                                    count: Int(sub.indexCount)))
            }
            
            vertexBuffer = objMesh.vertexBuffers[0].buffer
            // uv = uvs // Uncomment to use the obj uvs
            isObj = true
        } else {
            // Constant positions buffer for dragon
            positionsBuffer = device.makeBuffer(
                bytes: positions3D,
                length: positions3D.count * MemoryLayout<SIMD3<Float>>.stride,
                options: []
            )
            
            normalsBuffer = device.makeBuffer(
                bytes: normals,
                length: normals.count * MemoryLayout<SIMD3<Float>>.stride,
                options: []
            )
        }
        
        projectionMatrix = getProjectionMatrix()

        translationMatrix = getNewTranslationMatrix(isInitialState: true)
        
        rotationMatrix = getNewRotationMatrix(isInitialState: true, for: 0.0)
        
        scaleMatrix = getNewScaleMatrix(isInitialState: true)
        
        finalMatrix = projectionMatrix * translationMatrix * rotationMatrix * scaleMatrix
        
        let desc = MTLTextureDescriptor()
        textureWidth = 4
        textureHeight = 4
        desc.pixelFormat = .rgba8Unorm
        desc.width = textureWidth
        desc.height = textureHeight
        desc.usage = [.shaderRead, .renderTarget]
        desc.storageMode = .managed
        fillTexture = device.makeTexture(descriptor: desc)
        
        // textureData = updateTextureData(useUniformColor: true, rgbaColor: [0, 255, 0, 255], textureWidth: textureWidth, textureHeight: textureHeight) // Uncomment to use a uniform color (green dragon)
        
        // textureData = updateTextureData(useUniformColor: false, textureWidth: textureWidth, textureHeight: textureHeight) // Uncomment to use multiple color
        // textureData = updateTextureData(useCustomTexture: true, customTextureName: "dragon") // Not working correctly, I use the prebuilt metal texture loader instead.
        
        // fillTexture = updateFillTexture(textureData, textureWidth: textureWidth, textureHeight: textureHeight) // Uncomment to use the textureData created before in the fill texture.
        
        // prebuilt metal texture loader - Uncomment to use
        let textureLoader = MTKTextureLoader(device: device)
        let textureName: String
        if isObj {
            textureName = "bear-multiples-colors" // TODO: pass it as parameter also later
        } else {
            textureName = "dragon"
        }
        if let url = Bundle.main.url(forResource: textureName, withExtension: "png") {
            do {
                fillTexture = try textureLoader.newTexture(URL: url, options: [
                    MTKTextureLoader.Option.origin: MTKTextureLoader.Origin.bottomLeft,
                    MTKTextureLoader.Option.SRGB: false,
                ])
            } catch {
                print("Failed to load custom texture: \(error)")
            }
        } else {
            print("Texture my-texture.png not found in bundle.")
        }
        
        uvTexture = uv
        
        // Constant uv buffer ftm
        uvBuffer = device.makeBuffer(
            bytes: uvTexture,
            length: uvTexture.count * MemoryLayout<SIMD2<Float>>.stride,
            options: []
        )
    }
    
    private func updateTextureData(
        useUniformColor: Bool = false,
        rgbaColor: SIMD4<UInt8> = [0, 255, 0, 255],
        useCustomTexture: Bool = false,
        customTextureName: String = "my-texture",
        textureWidth: Int = 1,
        textureHeight: Int = 1
    ) -> [UInt8] {
        if useCustomTexture {
            guard
                let url = Bundle.main.url(forResource: customTextureName, withExtension: "png"),
                let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
                let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
            else {
                print("Failed to load or decode PNG image: \(customTextureName).png")
                return []
            }

            let width = min(cgImage.width, textureWidth)
            let height = min(cgImage.height, textureHeight)

            let bytesPerPixel = 4
            let bytesPerRow = width * bytesPerPixel
            let bitsPerComponent = 8

            textureData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

            guard
                let context = CGContext(
                    data: &textureData,
                    width: width,
                    height: height,
                    bitsPerComponent: bitsPerComponent,
                    bytesPerRow: bytesPerRow,
                    space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                )
            else {
                print("Failed to create CGContext for texture image.")
                return []
            }

            let rect = CGRect(x: 0, y: 0, width: width, height: height)
            context.clear(rect)
            context.draw(cgImage, in: rect)

            return textureData
        } else {
            textureData = [UInt8](repeating: 0, count: textureWidth * textureHeight * 4)
            
            // Uniform color (used for the moment only if texture is 1 by height or width)
            if textureWidth == 1 || textureHeight == 1 || useUniformColor {
                for i in 0 ..< (textureWidth * textureHeight) {
                    let idx = i * 4
                    textureData[idx + 0] = rgbaColor.x
                    textureData[idx + 1] = rgbaColor.y
                    textureData[idx + 2] = rgbaColor.z
                    textureData[idx + 3] = rgbaColor.w
                }
            } else {
                for i in 0 ..< (textureWidth * textureHeight) {
                    let idx = i * 4
                    textureData[idx + 0] = UInt8.random(in: 0 ..< 255)
                    textureData[idx + 1] = UInt8.random(in: 0 ..< 255)
                    textureData[idx + 2] = UInt8.random(in: 0 ..< 255)
                    textureData[idx + 3] = 255
                }
            }
            
            return textureData
        }
    }
    
    private func updateFillTexture(_ textureBuffer: [UInt8], textureWidth: Int = 1, textureHeight: Int = 1) -> MTLTexture? {
        guard let texture = fillTexture else { return nil }
        texture.replace(
            region: MTLRegionMake2D(0, 0, textureWidth, textureHeight),
            mipmapLevel: 0,
            withBytes: textureBuffer,
            bytesPerRow: textureWidth * 4
        )
        
        return texture
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
                    [0.0, 1.0, 0.0, -3.0], // Down the dragon a little bit
                    [0.0, 0.0, 1.0, isObj ? -70.0 : -30.0], // Since the implementation of the projection matrix, move the dragon a little bit.
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
            let tz: Float = isObj ? -70.0 : -30.0
            let translationMatrix = matrix_float4x4.init(
                rows: [
                    // C0  C1   C2   C3
                    [1.0, 0.0, 0.0, tx],
                    [0.0, 1.0, 0.0, ty - 3.0],
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
                // rows: [
                //     // C0  C1   C2   C3
                //     [1.0, 0.0, 0.0, 0.0],
                //     [0.0, cA, -sA, 0.0],
                //     [0.0, sA, cA, 0.0],
                //     [0.0, 0.0, 0.0, 1.0],
                // ]
                // y
                rows: [
                    // C0  C1   C2   C3
                    [cA, 0.0, -sA, 0.0],
                    [0.0, 1.0, 0.0, 0.0],
                    [sA, 0.0, cA, 0.0],
                    [0.0, 0.0, 0.0, 1.0],
                ]
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
            let uvBuffer = uvBuffer,
            let depthStencilState = depthStencilState,
            let normalsBuffer = normalsBuffer,
            indices.count > 0
        else {
            return
        }
        
        // 1. Command buffer creation
        let commandBuffer = commandQueue.makeCommandBuffer()!
        
        // 2. Render command encoder creation
        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: passDescriptor)!
        
        encoder.setRenderPipelineState(pipelineState)
        
        encoder.setDepthStencilState(depthStencilState)
        
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)

        encoder.setVertexBuffer(positionsBuffer, offset: 0, index: 1)

        encoder.setVertexBuffer(normalsBuffer, offset: 0, index: 2)

        encoder.setVertexBuffer(uvBuffer, offset: 0, index: 3)
        
        // encoder.setCullMode(.front) // We can uncomment it we do no rotation of the dragon and want to optimize a little bit by not drawing hidden faces

        projectionMatrix = getProjectionMatrix()
        
        translationMatrix = getNewTranslationMatrix(isInitialState: true) // Set isInitialState to false to see ping pong effect
        // Send the translation transformation matrix directly to the GPU without creating a persistent buffer (efficient for small, frequently updated data) with setVertexBytes
        encoder.setVertexBytes(&translationMatrix, length: MemoryLayout<matrix_float4x4>.stride, index: 4)
        
        rotationMatrix = getNewRotationMatrix(isInitialState: false, for: CACurrentMediaTime())
        encoder.setVertexBytes(&rotationMatrix, length: MemoryLayout<matrix_float4x4>.stride, index: 5) // Set isInitialState to false to see rotation effect

        scaleMatrix = getNewScaleMatrix(isInitialState: true) // Set isInitialState to false to see grow/shrink effect
        encoder.setVertexBytes(&scaleMatrix, length: MemoryLayout<matrix_float4x4>.stride, index: 6)

        finalMatrix = projectionMatrix * translationMatrix * rotationMatrix * scaleMatrix // TRS
        encoder.setVertexBytes(&finalMatrix, length: MemoryLayout<matrix_float4x4>.stride, index: 7)

        if let texture = fillTexture {
            encoder.setFragmentTexture(texture, index: 0)
        }
        
        encoder.drawIndexedPrimitives(type: .triangle, indexCount: indices.count, indexType: isObj ? objSubmesh!.indexType : .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)
        
        // 4. End & commit
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
