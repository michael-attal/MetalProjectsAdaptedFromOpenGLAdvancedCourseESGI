//
//  ContentView.swift
//  MetalProjectsAdaptedFromOpenGLAdvancedCourseESGI
//
//  Created by Michaël ATTAL on 06/03/2025.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            // MetalRendererSelector()
            // TD_01_MetalCanvasView().aspectRatio(contentMode: .fit)
            // TD_02_MetalCanvasView().aspectRatio(contentMode: .fit)
            // TD_03_MetalCanvasView().aspectRatio(contentMode: .fit)
            // TD_04_MetalCanvasView(modelType: .staticDragon).aspectRatio(contentMode: .fit)
            TD_04_MetalCanvasView(modelType: .loadedOBJ(Bundle.main.url(forResource: "bear", withExtension: "obj")!)).aspectRatio(contentMode: .fit)
        }
    }
}

#Preview {
    ContentView()
}
