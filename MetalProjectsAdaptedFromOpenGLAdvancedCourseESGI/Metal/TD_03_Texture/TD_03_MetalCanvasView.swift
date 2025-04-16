//
//  TD_03_MetalCanvasView.swift
//  MetalProjectsAdaptedFromOpenGLAdvancedCourseESGI
//
//  Created by Michaël ATTAL on 16/04/2035.
//

import MetalKit
import SwiftUI

// TD 03 OpenGL - Texture - Version Metal https://file.notion.so/f/f/f2320c07-9643-4088-a89e-2937678b3550/5b886afc-7e78-47ed-a3ef-cf649d1e1150/OpenGL_moderne_-_TP__Textures.pdf?table=block&id=1cb116e2-d32d-8026-85b8-d488f1679754&spaceId=f2320c07-9643-4088-a89e-2937678b3550&expirationTimestamp=1744848000000&signature=J0NR3LuNqWJtHRVFUZCOKZRLT7BT5pBOX31rOBcfuXQ&downloadName=OpenGL+moderne+-+TP++Textures.pdf

struct TD_03_MetalCanvasView: NSViewRepresentable {
    func makeNSView(context: Context) -> MTKView {
        // 1. Instantiates the Metal view
        let mtkView = MTKView(frame: .zero)
        
        // 2. Initializes default device
        mtkView.device = MTLCreateSystemDefaultDevice()
        
        // 3. Background color (black)
        mtkView.clearColor = MTLClearColorMake(0, 0, 0, 1)
        
        // 4. Create the renderer and assign it as a delegate
        let renderer = TD_03_CubeMetalRenderer(mtkView: mtkView)
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
        var renderer: TD_03_CubeMetalRenderer?
    }
}
