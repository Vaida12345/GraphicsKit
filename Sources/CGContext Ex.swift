//
//  CoreGraphicsContext Extensions.swift
//
//
//  Created by Vaida on 9/19/22.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//

import CoreGraphics


public extension CGContext {
    
    /// Creates a valid default context by its parameters.
    ///
    /// - Parameters:
    ///   - size: The size, in pixels, of the required bitmap.
    ///   - bitsPerComponent: The number of bits to use for each component of a pixel in memory.
    ///   - space: The color space to use for the bitmap context.
    ///   - withAlpha: Indicating whether the image has alpha channel.
    ///
    /// - Returns: The best match for the given parameters. If a match for the colorSpace cannot be found, `rgb` would be used instead.
    static func createContext(size: CGSize, bitsPerComponent: Int, space: CGColorSpace, withAlpha: Bool) -> CGContext {
        let preset = ParameterPreset.allCases
            .filter { $0.hasAlpha == withAlpha && $0.colorSpace == space.model }
            .nearestElement { instance in
                instance.bitsPerComponent - bitsPerComponent
            } ?? ParameterPreset.allCases
            .filter { $0.hasAlpha == withAlpha && $0.colorSpace == .rgb }
            .nearestElement { instance in
                instance.bitsPerComponent - bitsPerComponent
            }
        
        let optimal = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: preset!.bitsPerComponent,
            bytesPerRow: 0,
            space: space,
            bitmapInfo: preset!.bitmapInfo
        )
        
        let fallbackColorSpace = preset!.bitsPerComponent == 8 ? CGColorSpace.sRGB : CGColorSpace.extendedSRGB
        
        let fallback = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: preset!.bitsPerComponent,
            bytesPerRow: 0,
            space: CGColorSpace(name: fallbackColorSpace)!,
            bitmapInfo: preset!.bitmapInfo
        )!
        
        return optimal ?? fallback
    }
    
    
    /// Creates a context by referencing the properties of the `image`.
    ///
    /// - Note: If the context of `image` is not available, the most similar one will be used instead.
    ///
    /// - Parameters:
    ///   - image: The referenced image.
    ///   - size: The size for the `CGContext`. Pass `nil` if the size of the referenced image is used.
    @inlinable
    static func createContext(referencing image: CGImage, size: CGSize? = nil) -> CGContext {
        let targetSize = size ?? image.size
        if let context = CGContext(data: nil,
                                   width: Int(targetSize.width),
                                   height: Int(targetSize.height),
                                   bitsPerComponent: image.bitsPerComponent,
                                   bytesPerRow: 0,
                                   space: image.colorSpace!,
                                   bitmapInfo: image.bitmapInfo.rawValue) {
            // A exact matching can be found
            return context
        } else {
            return createContext(size: targetSize,
                                 bitsPerComponent: image.bitsPerComponent,
                                 space: image.colorSpace!,
                                 withAlpha: ![CGImageAlphaInfo.none, .noneSkipLast, .noneSkipFirst].contains(image.alphaInfo))
        }
    }
    
    /// The preset available in quartz 2D.
    ///
    /// - SeeAlso: [Developer Documentation](https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/dq_context/dq_context.html#//apple_ref/doc/uid/TP30001066-CH203-TPXREF101)
    private struct ParameterPreset: CaseIterable {
        
        fileprivate let bitsPerPixel: Int
        
        fileprivate let bitsPerComponent: Int
        
        fileprivate let hasAlpha: Bool
        
        fileprivate let colorSpace: CGColorSpaceModel
        
        fileprivate let bitmapInfo: UInt32
        
        
        fileprivate static let allCases: [ParameterPreset] = [
            ParameterPreset(bitsPerPixel: 16,  bitsPerComponent: 5,  hasAlpha: false, colorSpace: .rgb, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue),
            ParameterPreset(bitsPerPixel: 32,  bitsPerComponent: 8,  hasAlpha: false, colorSpace: .rgb, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue),
            ParameterPreset(bitsPerPixel: 32,  bitsPerComponent: 8,  hasAlpha: false, colorSpace: .rgb, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue),
            ParameterPreset(bitsPerPixel: 32,  bitsPerComponent: 8,  hasAlpha: true,  colorSpace: .rgb, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue),
            ParameterPreset(bitsPerPixel: 32,  bitsPerComponent: 8,  hasAlpha: true,  colorSpace: .rgb, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
            
            ParameterPreset(bitsPerPixel: 32,  bitsPerComponent: 10, hasAlpha: false, colorSpace: .rgb, bitmapInfo: CGImageAlphaInfo.none.rawValue | CGImagePixelFormatInfo.RGBCIF10.rawValue | CGImageByteOrderInfo.order32Little.rawValue),
            
            ParameterPreset(bitsPerPixel: 64,  bitsPerComponent: 16, hasAlpha: true,  colorSpace: .rgb, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
            ParameterPreset(bitsPerPixel: 64,  bitsPerComponent: 16, hasAlpha: false, colorSpace: .rgb, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue),
            
            ParameterPreset(bitsPerPixel: 64,  bitsPerComponent: 16, hasAlpha: true,  colorSpace: .rgb, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.floatComponents.rawValue | CGImageByteOrderInfo.order16Little.rawValue),
            ParameterPreset(bitsPerPixel: 64,  bitsPerComponent: 16, hasAlpha: false, colorSpace: .rgb, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue | CGBitmapInfo.floatComponents.rawValue | CGImageByteOrderInfo.order16Little.rawValue),
            
            ParameterPreset(bitsPerPixel: 128, bitsPerComponent: 32, hasAlpha: true,  colorSpace: .rgb, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.floatComponents.rawValue),
            ParameterPreset(bitsPerPixel: 128, bitsPerComponent: 32, hasAlpha: false, colorSpace: .rgb, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue | CGBitmapInfo.floatComponents.rawValue),
            
            
            ParameterPreset(bitsPerPixel: 8,   bitsPerComponent: 8,  hasAlpha: true,  colorSpace: .monochrome, bitmapInfo: CGImageAlphaInfo.alphaOnly.rawValue),
            ParameterPreset(bitsPerPixel: 8,   bitsPerComponent: 8,  hasAlpha: false, colorSpace: .monochrome, bitmapInfo: CGImageAlphaInfo.none.rawValue),
            ParameterPreset(bitsPerPixel: 16,  bitsPerComponent: 8,  hasAlpha: false, colorSpace: .monochrome, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue),
            ParameterPreset(bitsPerPixel: 16,  bitsPerComponent: 8,  hasAlpha: true,  colorSpace: .monochrome, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
            ParameterPreset(bitsPerPixel: 16,  bitsPerComponent: 16, hasAlpha: false, colorSpace: .monochrome, bitmapInfo: CGImageAlphaInfo.none.rawValue),
            
            ParameterPreset(bitsPerPixel: 16,  bitsPerComponent: 16, hasAlpha: false, colorSpace: .monochrome, bitmapInfo: CGImageAlphaInfo.none.rawValue | CGBitmapInfo.floatComponents.rawValue | CGBitmapInfo.byteOrder16Little.rawValue),
            ParameterPreset(bitsPerPixel: 32,  bitsPerComponent: 32, hasAlpha: false, colorSpace: .monochrome, bitmapInfo: CGImageAlphaInfo.none.rawValue | CGBitmapInfo.floatComponents.rawValue)
        ]
        
    }
    
}


private extension Array {
    
    /// Returns the element which is closest to the `target`.
    ///
    /// - Precondition: The smaller element would be returned.
    ///
    /// - Returns: The return value is `nil` if the array is empty.
    ///
    /// - Complexity: O(*n*), where *n* is the length of array.
    func nearestElement<T: Comparable & SignedNumeric>(by predicate: (_ instance: Element) throws -> T) rethrows -> Element? {
        guard let firstElement = self.first else { return nil }
        guard self.count != 1 else { return firstElement }
        
        return try self.reduce(firstElement) { partialResult, element in
            abs(try predicate(element)) < abs(try predicate(partialResult)) ? element : partialResult
        }
    }
    
}
