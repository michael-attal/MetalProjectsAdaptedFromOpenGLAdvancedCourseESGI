//
//  TD_05_MetalCanvasView.swift
//  MetalProjectsAdaptedFromOpenGLAdvancedCourseESGI
//
//  Created by Michaël ATTAL on 13/04/2025.
//

import MetalKit
import SwiftUI

// TD 05 Illumination - Version Metal

struct TD_05_MetalCanvasView: NSViewRepresentable {
    enum ModelType {
        case staticDragon
        case loadedOBJ(URL)
    }
    
    let modelType: ModelType

    func makeNSView(context: Context) -> MTKView {
        // 1. Instantiates the Metal view
        let mtkView = MTKView(frame: .zero)
        
        // 2. Initializes default device
        mtkView.device = MTLCreateSystemDefaultDevice()
        
        // 3. Background color (black)
        mtkView.clearColor = MTLClearColorMake(0, 0, 0, 1)
        
        // 4. Create the renderer and assign it as a delegate
        let renderer: TD_05_IlluminationMetalRenderer
        switch modelType {
        case .staticDragon:
            renderer = TD_05_IlluminationMetalRenderer(mtkView: mtkView)
        case .loadedOBJ(let url):
            renderer = TD_05_IlluminationMetalRenderer(mtkView: mtkView, objURL: url)
        }
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
        var renderer: TD_05_IlluminationMetalRenderer?
    }
}
