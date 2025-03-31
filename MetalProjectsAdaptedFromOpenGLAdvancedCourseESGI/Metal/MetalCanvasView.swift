//
//  MetalCanvasView.swift
//  MetalProjectsAdaptedFromOpenGLAdvancedCourseESGI
//
//  Created by Michaël ATTAL on 06/03/2025.
//

import MetalKit
import SwiftUI

/// A SwiftUI NSViewRepresentable that hosts an MTKView and uses a Coordinator
/// to handle zoom, pan, and user interactions.
struct MetalCanvasView: NSViewRepresentable {
    @Binding var zoom: CGFloat
    @Binding var panOffset: CGSize

    @Environment(AppState.self) private var appState

    func makeCoordinator() -> Coordinator {
        Coordinator(
            zoom: $zoom,
            panOffset: $panOffset,
            appState: appState
        )
    }

    func makeNSView(context: Context) -> MTKView {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal not supported.")
        }

        let mtkView = ZoomableMTKView(frame: .zero, device: device)
        mtkView.framebufferOnly = false
        mtkView.sampleCount = 4

        // Create the main renderer
        let mr = MainMetalRenderer(
            mtkView: mtkView
        )
        mr.appState = appState
        mtkView.delegate = mr

        // Store references
        context.coordinator.metalView = mtkView
        context.coordinator.mainRenderer = mr
        mtkView.coordinator = context.coordinator

        DispatchQueue.main.async {
            self.appState.mainCoordinator = context.coordinator
        }

        mtkView.clearColor = appState.selectedBackgroundColor.toMTLClearColor()
        mtkView.enableSetNeedsDisplay = true
        mtkView.isPaused = false

        // Gestures: pinch => zoom, pan => translation
        let pinchGesture = NSMagnificationGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleMagnification(_:))
        )
        mtkView.addGestureRecognizer(pinchGesture)

        let panGesture = NSPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePan(_:))
        )
        mtkView.addGestureRecognizer(panGesture)
        context.coordinator.panGesture = panGesture

        // Make this view first responder so it can receive key events
        mtkView.window?.makeFirstResponder(mtkView)

        return mtkView
    }

    func updateNSView(_ nsView: MTKView, context: Context) {
        // Update transform, color, etc.
        context.coordinator.mainRenderer?.previewColor = appState.selectedColor.toSIMD4()
        context.coordinator.mainRenderer?.setZoomAndPan(zoom: zoom, panOffset: panOffset)

        nsView.clearColor = appState.selectedBackgroundColor.toMTLClearColor()
    }

    // MARK: - Coordinator

    @MainActor
    class Coordinator: NSObject {
        @Binding var zoom: CGFloat
        @Binding var panOffset: CGSize

        let appState: AppState
        var mainRenderer: MainMetalRenderer?
        weak var metalView: MTKView?

        var panGesture: NSPanGestureRecognizer?

        init(
            zoom: Binding<CGFloat>,
            panOffset: Binding<CGSize>,
            appState: AppState
        ) {
            self._zoom = zoom
            self._panOffset = panOffset
            self.appState = appState
        }

        // MARK: - Pinch Zoom

        @objc
        func handleMagnification(_ sender: NSMagnificationGestureRecognizer) {
            if sender.state == .changed {
                // factor = 1 + pinchDelta
                let factor = 1 + sender.magnification
                sender.magnification = 0

                // Multiply current zoom
                var newZoom = zoom*factor
                
                zoom = newZoom

                mainRenderer?.setZoomAndPan(zoom: zoom, panOffset: panOffset)
            }
        }

        // MARK: - Pan gesture

        @objc
        func handlePan(_ sender: NSPanGestureRecognizer) {
            let translation = sender.translation(in: sender.view)
            let size = sender.view?.bounds.size ?? .zero

            // We invert Y => dragging up => panOffset.height > 0
            panOffset.width += translation.x / size.width
            panOffset.height -= translation.y / size.height

            sender.setTranslation(.zero, in: sender.view)
            mainRenderer?.setZoomAndPan(zoom: zoom, panOffset: panOffset)
        }

        // MARK: - Scroll Wheel => Zoom

        func handleScrollWheel(_ event: NSEvent) {
            let oldZoom = zoom
            let zoomFactor: CGFloat = 1.1

            if event.deltaY > 0 {
                // scroll up => zoom in
                zoom = oldZoom*zoomFactor
            } else if event.deltaY < 0 {
                // scroll down => zoom out
                zoom = oldZoom / zoomFactor
            }

            mainRenderer?.setZoomAndPan(zoom: zoom, panOffset: panOffset)
        }
    }

    // MARK: - ZoomableMTKView

    class ZoomableMTKView: MTKView {
        weak var coordinator: Coordinator?

        override func scrollWheel(with event: NSEvent) {
            coordinator?.handleScrollWheel(event)
        }

        override func mouseDown(with event: NSEvent) {
            super.mouseDown(with: event)
            let loc = convert(event.locationInWindow, from: nil)
            // coordinator?.mouseClicked(at: loc, in: self)
        }

        override func mouseDragged(with event: NSEvent) {
            super.mouseDragged(with: event)
            let loc = convert(event.locationInWindow, from: nil)
            // coordinator?.mouseDragged(at: loc, in: self)
        }

        override func mouseUp(with event: NSEvent) {
            super.mouseUp(with: event)
            let loc = convert(event.locationInWindow, from: nil)
            // coordinator?.mouseUp(at: loc, in: self)
        }

        override var acceptsFirstResponder: Bool { true }

        override func keyDown(with event: NSEvent) {
            // Enter => keyCode = 36
            if event.keyCode == 36 {
                // coordinator?.keyPressedEnter()
            } else {
                super.keyDown(with: event)
            }
        }
    }
}
