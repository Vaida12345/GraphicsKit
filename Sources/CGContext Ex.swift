//
//  CoreGraphicsContext Extensions.swift
//
//
//  Created by Vaida on 9/19/22.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//

import CoreGraphics
import Essentials
import OSLog


public extension CGContext {
    
    /// Alpha option for ``createContext(size:bitsPerComponent:space:alpha:)``.
    enum CreateContextAlphaOption {
        case none, hasAlpha, alphaOnly
    }
    
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
        createContext(size: size, bitsPerComponent: bitsPerComponent, space: space, alpha: withAlpha ? .hasAlpha : .none)
    }
    
    /// Creates a valid default context by its parameters.
    ///
    /// - Parameters:
    ///   - size: The size, in pixels, of the required bitmap.
    ///   - bitsPerComponent: The number of bits to use for each component of a pixel in memory.
    ///   - space: The color space to use for the bitmap context.
    ///   - withAlpha: Indicating whether the image has alpha channel.
    ///
    /// - Returns: The best match for the given parameters. If a match for the colorSpace cannot be found, `rgb` would be used instead.
    static func createContext(size: CGSize, bitsPerComponent: Int, space: CGColorSpace, alpha: CreateContextAlphaOption) -> CGContext {
        let logger = Logger(subsystem: "NativeImage", category: "CGContext.createContext")
        
        let optimalPreset = ParameterPreset.allCases
            .filter { preset in
                guard preset.alpha == alpha && preset.colorModel == space.model else { return false }
                // CGColorSpace which uses extended range requires floating point or CIF10 bitmap context
                guard space.name.isNil(or: { ($0 as String).localizedStandardContains("extended") => preset.isSuitableForExtendedColorSpace }) else { return false }
                
                // CIF10 bitmap context requires extended sRGB color space
                if preset.bitmapInfo & CGImagePixelFormatInfo.RGBCIF10.rawValue == CGImagePixelFormatInfo.RGBCIF10.rawValue {
                    guard let name = space.name else { return false }
                    return (name as String).localizedStandardContains("extended")
                }
                
                return true
            }
            .nearestElement { instance in
                instance.bitsPerComponent - bitsPerComponent
            }
        
        if let optimalPreset {
            if let optimal = CGContext(
                data: nil,
                width: Int(size.width),
                height: Int(size.height),
                bitsPerComponent: optimalPreset.bitsPerComponent,
                bytesPerRow: 0,
                space: space,
                bitmapInfo: optimalPreset.bitmapInfo
            ) {
                logger.info("Return with optimal preset & original color space.")
                return optimal
            }
            
            logger.info("Return with optimal preset & default color space with the same color model.")
            // optimal is not available, can only be colorspace issue.
            return CGContext(
                data: nil,
                width: Int(size.width),
                height: Int(size.height),
                bitsPerComponent: optimalPreset.bitsPerComponent,
                bytesPerRow: 0,
                space: optimalPreset.makeDefaultColorSpace(),
                bitmapInfo: optimalPreset.bitmapInfo
            )! // safe to unwrap, as tests ensures this is not nil.
        }
        
        
        // didn't find a suitable match for the given color space.
        // how about colorspace in the same colorspace model?
        let fallbackPreset = ParameterPreset.allCases
            .filter { preset in
                preset.alpha == alpha && preset.colorModel == space.model
            }
            .nearestElement { instance in
                instance.bitsPerComponent - bitsPerComponent
            }
        
        if let fallbackPreset {
            logger.info("Return with fallback preset & default color space with the same color model.")
            return CGContext(
                data: nil,
                width: Int(size.width),
                height: Int(size.height),
                bitsPerComponent: fallbackPreset.bitsPerComponent,
                bytesPerRow: 0,
                space: fallbackPreset.makeDefaultColorSpace(),
                bitmapInfo: fallbackPreset.bitmapInfo
            )! // safe to unwrap, as tests ensures this is not nil.
        }
        
        // most likely invalid colorspace model
        // let's do RGB.
        let finalPreset = ParameterPreset.allCases
            .filter { preset in
                preset.alpha == alpha && preset.colorModel == .rgb
            }
            .nearestElement { instance in
                instance.bitsPerComponent - bitsPerComponent
            }
        
        logger.info("Return with RGB Context.")
        return CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: finalPreset!.bitsPerComponent,
            bytesPerRow: 0,
            space: finalPreset!.makeDefaultColorSpace(),
            bitmapInfo: finalPreset!.bitmapInfo
        )! // safe to unwrap, as tests ensures this is not nil.
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
    internal struct ParameterPreset: CaseIterable {
        
        internal let bitsPerPixel: Int
        
        internal let bitsPerComponent: Int
        
        internal var alpha: CreateContextAlphaOption {
            let checks = [
                bitmapInfo & CGImageAlphaInfo.first.rawValue == CGImageAlphaInfo.first.rawValue,
                bitmapInfo & CGImageAlphaInfo.last.rawValue == CGImageAlphaInfo.first.rawValue,
                bitmapInfo & CGImageAlphaInfo.premultipliedFirst.rawValue == CGImageAlphaInfo.first.rawValue,
                bitmapInfo & CGImageAlphaInfo.premultipliedLast.rawValue == CGImageAlphaInfo.first.rawValue,
            ]
            if checks.contains(true) {
                return .hasAlpha
            } else if bitmapInfo & CGImageAlphaInfo.alphaOnly.rawValue == CGImageAlphaInfo.alphaOnly.rawValue {
                return .alphaOnly
            } else {
                return .none
            }
        }
        
        internal var isSuitableForExtendedColorSpace: Bool {
            let checks = [
                bitmapInfo & CGImageComponentInfo.float.rawValue == CGImageComponentInfo.float.rawValue,
                bitmapInfo & CGImagePixelFormatInfo.RGBCIF10.rawValue == CGImagePixelFormatInfo.RGBCIF10.rawValue
            ]
            return checks.contains(true)
        }
        
        internal let colorModel: CGColorSpaceModel
        
        internal let bitmapInfo: UInt32
        
        
        #if os(macOS)
        internal static let allCases: [ParameterPreset] = sharedCases + macOSCases
        #else
        internal static let allCases: [ParameterPreset] = sharedCases
        #endif
        
        private static let sharedCases: [ParameterPreset] = [
            /*
             8  bits per pixel,         8  bits per component,         kCGImageAlphaOnly
             8  bits per pixel,         8  bits per component,         kCGImageAlphaNone
             16 bits per pixel,         8  bits per component,         kCGImageAlphaNoneSkipLast
             16 bits per pixel,         8  bits per component,         kCGImageAlphaPremultipliedLast
             16 bits per pixel,         16 bits per component,         kCGImageAlphaNone
             16 bits per pixel,         16 bits per component,         kCGImageAlphaNone|kCGBitmapFloatComponents|kCGBitmapByteOrder16Little
             32 bits per pixel,         32 bits per component,         kCGImageAlphaNone|kCGBitmapFloatComponents
             */
// Don't use alphaOnly.
//            ParameterPreset(bitsPerPixel: 8, bitsPerComponent: 8, colorModel: .monochrome,
//                            bitmapInfo: CGImageAlphaInfo.alphaOnly.rawValue),
            ParameterPreset(bitsPerPixel: 8, bitsPerComponent: 8, colorModel: .monochrome,
                            bitmapInfo: CGImageAlphaInfo.none.rawValue),
            ParameterPreset(bitsPerPixel: 16, bitsPerComponent: 8, colorModel: .monochrome,
                            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue),
            ParameterPreset(bitsPerPixel: 16, bitsPerComponent: 8, colorModel: .monochrome,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
            ParameterPreset(bitsPerPixel: 16, bitsPerComponent: 16, colorModel: .monochrome,
                            bitmapInfo: CGImageAlphaInfo.none.rawValue | CGImageComponentInfo.float.rawValue | CGImageByteOrderInfo.order16Little.rawValue),
            ParameterPreset(bitsPerPixel: 32, bitsPerComponent: 32, colorModel: .monochrome,
                            bitmapInfo: CGImageAlphaInfo.none.rawValue | CGImageComponentInfo.float.rawValue),
            
            /*
             16  bits per pixel,         5  bits per component,         kCGImageAlphaNoneSkipFirst
             32  bits per pixel,         8  bits per component,         kCGImageAlphaNoneSkipFirst
             32  bits per pixel,         8  bits per component,         kCGImageAlphaNoneSkipLast
             32  bits per pixel,         8  bits per component,         kCGImageAlphaPremultipliedFirst
             32  bits per pixel,         8  bits per component,         kCGImageAlphaPremultipliedLast
             32  bits per pixel,         10 bits per component,         kCGImageAlphaNone|kCGImagePixelFormatRGBCIF10|kCGImageByteOrder32Little
             64  bits per pixel,         16 bits per component,         kCGImageAlphaPremultipliedLast
             64  bits per pixel,         16 bits per component,         kCGImageAlphaNoneSkipLast
             64  bits per pixel,         16 bits per component,         kCGImageAlphaPremultipliedLast|kCGBitmapFloatComponents|kCGImageByteOrder16Little
             64  bits per pixel,         16 bits per component,         kCGImageAlphaNoneSkipLast|kCGBitmapFloatComponents|kCGImageByteOrder16Little
             128 bits per pixel,         32 bits per component,         kCGImageAlphaPremultipliedLast|kCGBitmapFloatComponents
             128 bits per pixel,         32 bits per component,         kCGImageAlphaNoneSkipLast|kCGBitmapFloatComponents
             */
            ParameterPreset(bitsPerPixel: 16, bitsPerComponent: 5, colorModel: .rgb,
                            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue),
            ParameterPreset(bitsPerPixel: 32, bitsPerComponent: 8, colorModel: .rgb,
                            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue),
            ParameterPreset(bitsPerPixel: 32, bitsPerComponent: 8, colorModel: .rgb,
                            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue),
            ParameterPreset(bitsPerPixel: 32, bitsPerComponent: 8, colorModel: .rgb,
                            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue),
            ParameterPreset(bitsPerPixel: 32, bitsPerComponent: 8, colorModel: .rgb,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
            ParameterPreset(bitsPerPixel: 32, bitsPerComponent: 10, colorModel: .rgb,
                            bitmapInfo: CGImageAlphaInfo.none.rawValue | CGImagePixelFormatInfo.RGBCIF10.rawValue | CGImageByteOrderInfo.order32Little.rawValue),
            ParameterPreset(bitsPerPixel: 64, bitsPerComponent: 16, colorModel: .rgb,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
            ParameterPreset(bitsPerPixel: 64, bitsPerComponent: 16, colorModel: .rgb,
                            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue),
            ParameterPreset(bitsPerPixel: 64, bitsPerComponent: 16, colorModel: .rgb,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGImageComponentInfo.float.rawValue | CGImageByteOrderInfo.order16Little.rawValue),
            ParameterPreset(bitsPerPixel: 64, bitsPerComponent: 16, colorModel: .rgb,
                            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue | CGImageComponentInfo.float.rawValue | CGImageByteOrderInfo.order16Little.rawValue),
            ParameterPreset(bitsPerPixel: 128, bitsPerComponent: 32, colorModel: .rgb,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGImageComponentInfo.float.rawValue),
            ParameterPreset(bitsPerPixel: 128, bitsPerComponent: 32, colorModel: .rgb,
                            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue | CGImageComponentInfo.float.rawValue),
            
            /*
             32  bits per pixel,         8  bits per component,         kCGImageAlphaNone
             64  bits per pixel,         16 bits per component,         kCGImageAlphaNone
             64  bits per pixel,         16 bits per component,         kCGImageAlphaNone|kCGBitmapFloatComponents
             128 bits per pixel,         32 bits per component,         kCGImageAlphaNone|kCGBitmapFloatComponents
             128 bits per pixel,         32 bits per component,         kCGImageAlphaNone|kCGBitmapFloatComponents|kCGBitmapByteOrder32Little
             128 bits per pixel,         32 bits per component,         kCGImageAlphaNone|kCGBitmapFloatComponents|kCGBitmapByteOrder32Big
             */
            ParameterPreset(bitsPerPixel: 32, bitsPerComponent: 8, colorModel: .cmyk,
                            bitmapInfo: CGImageAlphaInfo.none.rawValue),
            ParameterPreset(bitsPerPixel: 64, bitsPerComponent: 16, colorModel: .cmyk,
                            bitmapInfo: CGImageAlphaInfo.none.rawValue),
            ParameterPreset(bitsPerPixel: 64, bitsPerComponent: 16, colorModel: .cmyk,
                            bitmapInfo: CGImageAlphaInfo.none.rawValue | CGImageComponentInfo.float.rawValue | CGImageByteOrderInfo.order16Little.rawValue),
            ParameterPreset(bitsPerPixel: 128, bitsPerComponent: 32, colorModel: .cmyk,
                            bitmapInfo: CGImageAlphaInfo.none.rawValue | CGImageComponentInfo.float.rawValue),
            ParameterPreset(bitsPerPixel: 128, bitsPerComponent: 32, colorModel: .cmyk,
                            bitmapInfo: CGImageAlphaInfo.none.rawValue | CGImageComponentInfo.float.rawValue | CGImageByteOrderInfo.order32Little.rawValue),
            ParameterPreset(bitsPerPixel: 128, bitsPerComponent: 32, colorModel: .cmyk,
                            bitmapInfo: CGImageAlphaInfo.none.rawValue | CGImageComponentInfo.float.rawValue | CGImageByteOrderInfo.order32Big.rawValue),
        ]
        
        func makeDefaultColorSpace() -> CGColorSpace {
            switch self.colorModel {
            case .monochrome:
                CGColorSpace(name: CGColorSpace.linearGray)!
            case .rgb:
                if self.bitmapInfo & CGImagePixelFormatInfo.RGBCIF10.rawValue == CGImagePixelFormatInfo.RGBCIF10.rawValue {
                    CGColorSpace(name: CGColorSpace.extendedSRGB)!
                } else {
                    CGColorSpace(name: CGColorSpace.sRGB)!
                }
            case .cmyk:
                CGColorSpace(name: CGColorSpace.genericCMYK)!
                
            default:
                fatalError()
            }
        }
        
        private static let macOSCases: [ParameterPreset] = [
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
