//
//  MetalRendererSelector.swift
//  MetalProjectsAdaptedFromOpenGLAdvancedCourseESGI
//
//  Created by Michaël ATTAL on 06/03/2025.
//

import SwiftUI

public struct OptionRenderer: Hashable, CustomStringConvertible, Equatable, Sendable {
    public let renderer: AvailableRenderer

    public var value: String {
        return renderer.rawValue
    }

    public init(renderer: AvailableRenderer) {
        self.renderer = renderer
    }

    public var description: String {
        return value
    }

    public static func == (lhs: OptionRenderer, rhs: OptionRenderer) -> Bool {
        return lhs.renderer == rhs.renderer
    }
}

public enum AvailableRenderer: String, CaseIterable, Sendable {
    case triangleSimple = "Triangle Simple"
    case triangleGradient = "Triangle Gradient"
}

struct MetalRendererSelector: View {
    @Environment(AppState.self) private var appState

    @State private var zoom: CGFloat = 1.0
    @State private var panOffset: CGSize = .zero

    var body: some View {
        VStack {
            MultiSelectionDropdownView(labelText: "Select your renderer(s)", options: [
                OptionRenderer(renderer: .triangleSimple),
                OptionRenderer(renderer: .triangleGradient)
            ], selectedOptions: Binding<Set<OptionRenderer>>(
                get: { appState.selectedRenderers },
                set: { appState.selectedRenderers = $0 }
            )).padding()
            MetalCanvasView(
                zoom: $zoom,
                panOffset: $panOffset
            ).aspectRatio(contentMode: .fit)
        }
    }
}

#Preview {
    MetalRendererSelector()
}
