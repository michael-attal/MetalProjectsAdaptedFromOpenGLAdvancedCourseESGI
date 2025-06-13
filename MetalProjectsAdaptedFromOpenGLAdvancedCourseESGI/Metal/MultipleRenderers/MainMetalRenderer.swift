//
//  MainMetalRenderer.swift
//  MetalProjectsAdaptedFromOpenGLAdvancedCourseESGI
//
//  Created by Michaël ATTAL on 06/03/2025.
//

import MetalKit
import simd
import SwiftUI

public final class MainMetalRenderer: NSObject, MTKViewDelegate {
    public let device: MTLDevice
    private var commandQueue: MTLCommandQueue?

    let triangleGradientRenderer: TriangleGradientRenderer?
    let triangleSimpleRenderer: TriangleSimpleRenderer?

    private var uniformBuffer: MTLBuffer?

    weak var appState: AppState?

    var globalColor: SIMD4<Float> = .init(1, 0, 1, 1)

    // MARK: - Init

    public init(mtkView: MTKView) {
        guard let dev = mtkView.device else {
            fatalError("No MTLDevice found for this MTKView.")
        }
        self.device = dev

        let library = device.makeDefaultLibrary()
        self.triangleGradientRenderer = TriangleGradientRenderer(device: dev, library: library)
        self.triangleSimpleRenderer = TriangleSimpleRenderer(device: dev, library: library)

        super.init()

        triangleGradientRenderer?.mainRenderer = self
        triangleSimpleRenderer?.mainRenderer = self

        self.commandQueue = dev.makeCommandQueue()
        buildResources()
    }

    private func buildResources() {
        uniformBuffer = device.makeBuffer(length: MemoryLayout<TransformUniforms>.size,
                                          options: [])
    }

    // MARK: - MTKViewDelegate

    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // not used
    }

    public func draw(in view: MTKView) {
        guard let rpd = view.currentRenderPassDescriptor,
              let drawable = view.currentDrawable,
              let cmdBuff = commandQueue?.makeCommandBuffer(),
              let appState = appState
        else { return }

        let encoder = cmdBuff.makeRenderCommandEncoder(descriptor: rpd)!

        if appState.selectedRenderers.first(where: { $0.renderer == .triangleGradient }) != nil {
            triangleGradientRenderer?.draw(encoder: encoder, uniformBuffer: uniformBuffer)
        }
        if appState.selectedRenderers.first(where: { $0.renderer == .triangleSimple }) != nil {
            triangleSimpleRenderer?.draw(encoder: encoder, uniformBuffer: uniformBuffer)
        }

        encoder.endEncoding()
        cmdBuff.present(drawable)
        cmdBuff.commit()
    }

    private func updateUniforms() {
        let s = zoom
        let scaleMatrix = float4x4(
            simd_float4(s, 0, 0, 0),
            simd_float4(0, s, 0, 0),
            simd_float4(0, 0, 1, 0),
            simd_float4(0, 0, 0, 1)
        )

        let tx = pan.x * 2.0
        let ty = -pan.y * 2.0
        let translationMatrix = float4x4(
            simd_float4(1, 0, 0, 0),
            simd_float4(0, 1, 0, 0),
            simd_float4(0, 0, 1, 0),
            simd_float4(tx, ty, 0, 1)
        )

        let finalTransform = translationMatrix * scaleMatrix

        uniforms.transform = finalTransform
        uniforms.color = globalColor
        uniforms.zoomFactor = s
        currentTransform = finalTransform

        if let ub = uniformBuffer {
            memcpy(ub.contents(), &uniforms, MemoryLayout<TransformUniforms>.size)
        }
    }

    private var uniforms = TransformUniforms(
        transform: matrix_identity_float4x4,
        color: SIMD4<Float>(1, 1, 1, 1)
    )

    // Zoom/pan
    private var zoom: Float = 1.0
    private var pan: SIMD2<Float> = .zero

    // Expose the final transform so we can invert it in the Coordinator
    public private(set) var currentTransform: float4x4 = matrix_identity_float4x4

    // This color is for preview or uniform
    var previewColor: SIMD4<Float> = .init(1, 1, 1, 1)

    public func setZoomAndPan(zoom: CGFloat, panOffset: CGSize) {
        self.zoom = Float(zoom)
        pan.x = Float(panOffset.width)
        pan.y = Float(panOffset.height)
    }
}

public extension MainMetalRenderer {
    func updateTriangleGradientColors(_ colors: [Color]) {
        // triangleGradientRenderer?.updateGriadientColors(colors)
    }
}

/// Common uniform struct for transforms in the vertex shader.
struct TransformUniforms {
    var transform: simd_float4x4
    var color: SIMD4<Float>
    var zoomFactor: Float = 1.0
}
