//
//  TD_04_MetalCanvasView.swift
//  MetalProjectsAdaptedFromOpenGLAdvancedCourseESGI
//
//  Created by Michaël ATTAL on 13/04/2025.
//

import MetalKit
import SwiftUI

// TD 04 OpenGL - Dragon - Version Metal
// https://www.notion.so/michael-attal/Cours-OpenGL-avanc-e-1ae116e2d32d80438fd1eba56ca78c56
// https://file.notion.so/f/f/f2320c07-9643-4088-a89e-2937678b3550/0073d3dd-ca8e-48d9-8f61-e5532aae0d72/OpenGL_moderne_-_TP_affichage_objet_3D_simple.pdf?table=block&id=1cb116e2-d32d-8017-ae15-f66957cfebda&spaceId=f2320c07-9643-4088-a89e-2937678b3550&expirationTimestamp=1744588800000&signature=S3pC1qxxyccQslZHLfX2jCVWsSFYuuidegYg-qsWKW0&downloadName=OpenGL+moderne+-+TP+affichage+objet+3D+simple.pdf

struct TD_04_MetalCanvasView: NSViewRepresentable {
    func makeNSView(context: Context) -> MTKView {
        // 1. Instantiates the Metal view
        let mtkView = MTKView(frame: .zero)
        
        // 2. Initializes default device
        mtkView.device = MTLCreateSystemDefaultDevice()
        
        // 3. Background color (black)
        mtkView.clearColor = MTLClearColorMake(0, 0, 0, 1)
        
        // 4. Create the renderer and assign it as a delegate
        let renderer = TD_04_DragonMetalRenderer(mtkView: mtkView)
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
        var renderer: TD_04_DragonMetalRenderer?
    }
}
