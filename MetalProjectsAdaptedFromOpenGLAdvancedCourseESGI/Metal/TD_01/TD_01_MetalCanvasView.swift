//
//  MetalCanvasViewBackup.swift
//  MetalProjectsAdaptedFromOpenGLAdvancedCourseESGI
//
//  Created by Michaël ATTAL on 06/03/2025.
//

import MetalKit
import SwiftUI

// TODO: TD OPENGL MODERNE - LES BASES- Version Metal https://file.notion.so/f/f/f2320c07-9643-4088-a89e-2937678b3550/d586967a-2a66-4f5c-8954-b429b14aa2fb/OpenGL_-_TD_OpenGL_01_-_bases.pdf?table=block&id=1ae116e2-d32d-80cd-b375-f19d5f391d4a&spaceId=f2320c07-9643-4088-a89e-2937678b3550&expirationTimestamp=1741305600000&signature=1J9XbzXR5KYhopOmN48zBVUuFoIuNx1ArlaNd-Te6eE&downloadName=OpenGL+-+TD+OpenGL+01+-+bases.pdf
struct TD_01_MetalCanvasView: NSViewRepresentable {
    func makeNSView(context: Context) -> MTKView {
        // 1. Instantiates the Metal view
        let mtkView = MTKView(frame: .zero)
        
        // 2. Initializes default device
        mtkView.device = MTLCreateSystemDefaultDevice()
        
        // 3. Background color (black)
        mtkView.clearColor = MTLClearColorMake(0, 0, 0, 1)
        
        // 4. Create the renderer and assign it as a delegate
        let renderer = TD_01_TriangleMetalRenderer(mtkView: mtkView)
        mtkView.delegate = renderer
        
        // 5. Stores the renderer in the Coordinator
        context.coordinator.renderer = renderer
        
        return mtkView
    }
    
    func updateNSView(_ nsView: MTKView, context: Context) {
        // Handle update later here
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        // We keep a strong reference here, otherwise the renderer will be freed.
        var renderer: TD_01_TriangleMetalRenderer?
    }
}
