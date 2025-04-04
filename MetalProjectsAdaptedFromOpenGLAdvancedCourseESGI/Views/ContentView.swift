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
            TD_02_MetalCanvasView().aspectRatio(contentMode: .fit)
        }
    }
}

#Preview {
    ContentView()
}
