//
//  Extensions.swift
//  MetalProjectsAdaptedFromOpenGLAdvancedCourseESGI
//
//  Created by Michaël ATTAL on 06/03/2025.
//

import AppKit
import Foundation
import RealityKit
import SwiftUI

import AppKit
import MetalKit

// MARK: - Export PNG for macOS

extension MTKView {
    /// Export the current view content to a PNG file at `saveURL`.
    /// We must ensure `self.framebufferOnly = false` before calling `draw()`, and it's bad for performance.
    func exportToPNG(saveURL: URL) {
        // Force creation of currentDrawable if needed
        // This ensures currentDrawable is up to date
        self.draw()

        guard let currentDrawable = self.currentDrawable else {
            print("No currentDrawable available.")
            return
        }

        // Retrieve the drawable texture (must not be framebufferOnly)
        let texture = currentDrawable.texture
        let width = texture.width
        let height = texture.height

        // If the texture is still framebufferOnly => error
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        var imageBytes = [UInt8](repeating: 0, count: height * bytesPerRow)

        let region = MTLRegionMake2D(0, 0, width, height)

        // Read back the BGRA bytes
        texture.getBytes(&imageBytes,
                         bytesPerRow: bytesPerRow,
                         from: region,
                         mipmapLevel: 0)

        // Convert BGRA -> RGBA if needed
        for row in 0..<height {
            for col in 0..<width {
                let index = row * bytesPerRow + col * bytesPerPixel
                let b = imageBytes[index + 0]
                let g = imageBytes[index + 1]
                let r = imageBytes[index + 2]
                let a = imageBytes[index + 3]
                // rearrange to RGBA
                imageBytes[index + 0] = r
                imageBytes[index + 1] = g
                imageBytes[index + 2] = b
                imageBytes[index + 3] = a
            }
        }

        // Create CGImage
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: &imageBytes,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: 8,
                                      bytesPerRow: bytesPerRow,
                                      space: colorSpace,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
            let cgImage = context.makeImage()
        else {
            print("Failed to create CGContext or CGImage.")
            return
        }

        // Convert CGImage -> NSImage
        let image = NSImage(cgImage: cgImage,
                            size: NSSize(width: width, height: height))

        // Save as PNG
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapImage.representation(using: .png, properties: [:])
        else {
            print("Failed to convert image to PNG data.")
            return
        }

        do {
            try pngData.write(to: saveURL)
            print("Exported to PNG:", saveURL.path)
        } catch {
            print("Error writing PNG:", error)
        }
    }
}

extension Double {
    var degreesToRadians: Double { return self * .pi / 180 }
}

/// Helper extension to create float4x4 easily
extension float4x4 {
    init(rotationX angle: Float) {
        self = float4x4(
            [1, 0, 0, 0],
            [0, cos(angle), sin(angle), 0],
            [0, -sin(angle), cos(angle), 0],
            [0, 0, 0, 1]
        )
    }

    init(rotationY angle: Float) {
        self = float4x4(
            [cos(angle), 0, -sin(angle), 0],
            [0, 1, 0, 0],
            [sin(angle), 0, cos(angle), 0],
            [0, 0, 0, 1]
        )
    }

    init(rotationZ angle: Float) {
        self = float4x4(
            [cos(angle), sin(angle), 0, 0],
            [-sin(angle), cos(angle), 0, 0],
            [0, 0, 1, 0],
            [0, 0, 0, 1]
        )
    }

    init(_ c0: simd_float4,
         _ c1: simd_float4,
         _ c2: simd_float4,
         _ c3: simd_float4)
    {
        self.init(columns: (c0, c1, c2, c3))
    }
}

public extension Sequence {
    /// Groups up elements of `self` into a new Dictionary,
    /// whose values are Arrays of grouped elements,
    /// each keyed by the group key returned by the given closure.
    /// - Parameters:
    ///   - keyForValue: A closure that returns a key for each element in
    ///     `self`.
    /// - Returns: A dictionary containing grouped elements of self, keyed by
    ///     the keys derived by the `keyForValue` closure.
    @inlinable
    func grouped<GroupKey>(by keyForValue: (Element) throws -> GroupKey) rethrows -> [GroupKey: [Element]] {
        try Dictionary(grouping: self, by: keyForValue)
    }
}

extension Color {
    /// Convert the SwiftUI color to a SIMD4<Float> in RGBA order
    func toSIMD4() -> SIMD4<Float> {
        let nsColor = NSColor(self)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        if let converted = nsColor.usingColorSpace(.deviceRGB) {
            converted.getRed(&r, green: &g, blue: &b, alpha: &a)
        }

        return SIMD4<Float>(Float(r), Float(g), Float(b), Float(a))
    }
}

extension Color {
    /// Converts a SwiftUI Color to an MTLClearColor
    func toMTLClearColor() -> MTLClearColor {
        let nsColor = NSColor(self)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        if let converted = nsColor.usingColorSpace(.deviceRGB) {
            converted.getRed(&r, green: &g, blue: &b, alpha: &a)
        }

        return MTLClearColorMake(Double(r), Double(g), Double(b), Double(a))
    }
}

extension simd_int4 {
    func contains(_ value: Int32) -> Bool {
        return x == value || y == value || z == value || w == value
    }
}
