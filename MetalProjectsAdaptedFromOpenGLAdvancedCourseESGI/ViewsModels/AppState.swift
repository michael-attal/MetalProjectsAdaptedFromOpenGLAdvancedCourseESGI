//
//  AppState.swift
//  MetalProjectsAdaptedFromOpenGLAdvancedCourseESGI
//
//  Created by Michaël ATTAL on 06/03/2025.
//

import Foundation
import SwiftUI

@Observable
@MainActor final class AppState: Sendable {
    static let isDebugMode = false

    var mainCoordinator: MetalCanvasView.Coordinator?

    /// The color used for drawing polygons (or other shapes)
    var selectedColor: Color = .yellow

    /// The color used for the Metal canvas background (clearColor)
    var selectedBackgroundColor: Color = .black

    var selectedRenderers: Set<OptionRenderer> = [
        OptionRenderer(renderer: .triangleSimple),
        OptionRenderer(renderer: .triangleGradient)
    ]
}
