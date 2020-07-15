//
//  Bitmap.swift
//  generator
//
//  Created by Vlad Z. on 7/14/20.
//

import AppKit
import CoreGraphics

public class Bitmap {
    private static let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
    private static let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
    private static let componentSize = MemoryLayout<Pixel.Component>.size
    private static let pixelSize = MemoryLayout<Pixel>.size

    /// the bitmap's underlying data
    public private(set) var pixels: [Pixel]
    public private(set) var width, height: Int

    private var context: CGContext

    /**
    Initializes a bitmap of the specified width and height

    This constructor fails iff `width * height != pixels.count`

    - Parameter pixels: initial pixels of the bitmap
    */
    public init?(width: Int, height: Int, pixels: [Pixel]) {
        guard pixels.count == width * height else { return nil }
        self.width = width
        self.height = height
        self.pixels = pixels

        context = (CGContext(
            data: &self.pixels,
            width: width,
            height: height,
            bitsPerComponent: 8 * Bitmap.componentSize,
            bytesPerRow: width * Bitmap.pixelSize,
            space: Bitmap.rgbColorSpace,
            bitmapInfo: Bitmap.bitmapInfo
        ))!
    }

    /// Initializes a bitmap of the specified width and height, filled with a single color.
    ///
    /// - Parameter base: the color to initially fill the bitmap with; defaults to `Pixel.clear`
    public convenience init(width: Int, height: Int, filledWith base: Pixel = .clear) {
        self.init(width: width, height: height, pixels: Array(repeating: base, count: width * height))!
    }

    // TODO this is apparently slow af
    /// Initializes a bitmap of the specified width and height, consulting your custom closure for each pixel.
    ///
    /// - Parameter generator: This closure is queried for every position in the bitmap and its result is used in the specified slot
    public convenience init(width: Int, height: Int, using generator: (_ x: Int, _ y: Int) throws -> Pixel) rethrows {
        let pixels = try (0..<height).flatMap { y in
            try (0..<width).map { x in
                try generator(x, y)
            }
        }
        self.init(width: width, height: height, pixels: pixels)!
    }

    /// Access the pixel at the specified x and y coordinates
    public subscript(x: Int, y: Int) -> Pixel {
        get { pixels[x + y * width] }
        set { pixels[x + y * width] = newValue }
    }

    /// Size of the bitmap, as a `CGSize` for your convenience
    public var size: CGSize {
        CGSize(width: width, height: height)
    }

    /// Creates an image from the bitmap, using its underlying data.
    public func cgImage() -> CGImage {
        context.makeImage()!
    }

    /// Creates a new bitmap from the given image.
    public convenience init(from cgImage: CGImage) {
        self.init(width: cgImage.width, height: cgImage.height)

        context.draw(cgImage, in: CGRect(origin: .zero, size: size))
    }

    /**
    Maps `transform` over all pixels, returning a row-major matrix of the mapped pixels (pixels on the same line are congiuous in memory)

    - Parameter transform: The transformation to apply to every pixel
    */
    public func map<T>(_ transform: (Pixel) -> T) -> [[T]] {
        stride(from: 0, to: pixels.count, by: width).map { offset -> [T] in
            pixels[offset ..< offset + width].map(transform)
        }
    }
}

extension CGContext {
    public func draw(_ bitmap: Bitmap, at point: CGPoint = .zero) {
        self.draw(bitmap.cgImage(), in: CGRect(origin: point, size: bitmap.size))
    }
}

public struct Pixel {
    public typealias Component = UInt8

    /// fully transparent
    public static let clear = Pixel(red: 0, green: 0, blue: 0, alpha: 0)

    public static let black = Pixel(red: 0, green: 0, blue: 0)
    public static let white = Pixel(red: .max, green: .max, blue: .max)

    public static let red = Pixel(red: .max, green: 0, blue: 0)
    public static let yellow = Pixel(red: .max, green: .max, blue: 0)
    public static let green = Pixel(red: 0, green: .max, blue: 0)
    public static let cyan = Pixel(red: 0, green: .max, blue: .max)
    public static let blue = Pixel(red: 0, green: 0, blue: .max)
    public static let magenta = Pixel(red: .max, green: 0, blue: .max)

    /// the red component, out of 255
    public var red: Component

    /// the green component, out of 255
    public var green: Component

    /// the blue component, out of 255
    public var blue: Component

    /// the alpha component, out of 255 (255 means fully opaque)
    ///
    /// N.B.: RGB components should be premultiplied with the alpha, i.e. the alpha is always the maximum component.
    public var alpha: Component

    /**
    Creates a pixel with the specified **premultiplied** components, ranging from 0 to 255.

    - Parameter red: the red component, out of 255
    - Parameter green: the green component, out of 255
    - Parameter blue: the blue component, out of 255
    - Parameter alpha: the alpha component, out of 255 — defaults to 255 (opaque)
    */
    public init(red: Component, green: Component, blue: Component, alpha: Component = .max) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    /**
    Creates a pixel with the specified (**not** premultiplied) components, ranging from 0 to 255.

    - Parameter red: the red component, out of 255
    - Parameter green: the green component, out of 255
    - Parameter blue: the blue component, out of 255
    - Parameter alpha: the alpha component, out of 255 — defaults to 255 (opaque)
    */
    public init(red: Component, green: Component, blue: Component, premultiplyingWithAlpha alpha: Component) {
        self.red = red * alpha / Component.max
        self.green = green * alpha / Component.max
        self.blue = blue * alpha / Component.max
        self.alpha = alpha
    }
}

extension Pixel: Equatable {
    public static func ==(lhs: Pixel, rhs: Pixel) -> Bool {
        true
            && lhs.red == rhs.red
            && lhs.green == rhs.green
            && lhs.blue == rhs.blue
            && lhs.alpha == rhs.alpha
    }
}
