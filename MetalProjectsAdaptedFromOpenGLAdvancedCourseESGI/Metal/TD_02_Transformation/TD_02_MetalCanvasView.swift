//
//  TD_02_MetalCanvasView.swift
//  MetalProjectsAdaptedFromOpenGLAdvancedCourseESGI
//
//  Created by Michaël ATTAL on 04/04/2025.
//

import MetalKit
import SwiftUI

// TD 02 OpenGL - Transformation - Version Metal https://file.notion.so/f/f/f2320c07-9643-4088-a89e-2937678b3550/f45c989a-eda1-4ec7-9271-1c80bbc8df6c/OpenGL_moderne_-_TP_Transformations.pdf?table=block&id=1cb116e2-d32d-80b3-9778-cf8592602f9d&spaceId=f2320c07-9643-4088-a89e-2937678b3550&expirationTimestamp=1743811200000&signature=bQqEDBSceflYfoJMvhT_pPnZGNoSgFgGbxzUyqyOg4w&downloadName=OpenGL+moderne+-+TP+Transformations.pdf

struct TD_02_MetalCanvasView: NSViewRepresentable {
    func makeNSView(context: Context) -> MTKView {
        // 1. Instantiates the Metal view
        let mtkView = MTKView(frame: .zero)
        
        // 2. Initializes default device
        mtkView.device = MTLCreateSystemDefaultDevice()
        
        // 3. Background color (black)
        mtkView.clearColor = MTLClearColorMake(0, 0, 0, 1)
        
        // 4. Create the renderer and assign it as a delegate
        let renderer = TD_02_CubeMetalRenderer(mtkView: mtkView)
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
        var renderer: TD_02_CubeMetalRenderer?
    }
}
