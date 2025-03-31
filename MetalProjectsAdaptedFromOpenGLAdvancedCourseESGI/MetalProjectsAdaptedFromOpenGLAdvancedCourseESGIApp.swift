//
//  MetalProjectsAdaptedFromOpenGLAdvancedCourseESGIApp.swift
//  MetalProjectsAdaptedFromOpenGLAdvancedCourseESGI
//
//  Created by Michaël ATTAL on 06/03/2025.
//

import SwiftData
import SwiftUI

@main
struct MetalProjectsAdaptedFromOpenGLAdvancedCourseESGIApp: App {
    @State var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
    }
}
