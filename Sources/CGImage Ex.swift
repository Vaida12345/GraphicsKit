//
//  CoreGraphics Image Extensions.swift
//
//
//  Created by Vaida on 7/19/22.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//

import Foundation
import CoreGraphics
import ImageIO
import OSLog


public extension CGImage {
    
    /// The pixel size of the cgImage.
    @inlinable
    var size: CGSize {
        CGSize(width: self.width, height: self.height)
    }
    
    /// A replacement for `cropping(to:)`.
    @inlinable
    func cropped(to target: CGRect) -> CGImage? {
        let context = CGContext.createContext(referencing: self, size: target.size)
        
        context.interpolationQuality = .high
        
        let rect = CGRect(origin: CGPoint(x: -target.origin.x, y: -target.origin.y), size: self.size)
        context.draw(self, in: rect)
        return context.makeImage()
    }
    
    /// Returns the data of the image with a new codec.
    ///
    /// A `quality` value of 1.0 specifies to use lossless compression if destination format supports it. A value of 0.0 implies to use maximum compression.
    ///
    /// - Parameters:
    ///   - format: The format of the image.
    ///   - quality: The quality of image compression.
    ///   - properties: The set of properties you would like to associate with the image.
    ///
    /// - throws: ``DataError``
    ///
    /// ## Topics
    /// ### Potential Error
    /// - ``DataError``
    @inlinable
    func data(format: NativeImage.ImageFormatOption = .png, quality: CGFloat = 1, properties: [CFString : Any] = [:]) throws -> Data {
        guard
            let mutableData = CFDataCreateMutable(nil, 0),
            let destination = CGImageDestinationCreateWithData(mutableData, format.identifier as CFString, format == .icns ? 10 : 1, nil)
        else { throw DataError.invalidFormat }
        
        switch format {
        case .icns:
            
            for scale in 0 ..< 2*6 {
                if scale == 4 || scale == 5 { continue } // Error would be shown when trying to add 64 x 64 icon.
                
                let power = scale % 2 + 1
                let width = pow(2.0, Double(scale / 2 + power + 3))
                
                guard let image = self.resized(to: .square(width)) else { continue }
                
                let dimensions = [kCGImagePropertyDPIWidth: 72 * power, kCGImagePropertyDPIHeight: 72 * power]
                CGImageDestinationAddImage(
                    destination,
                    image,
                    properties.merging(dimensions, uniquingKeysWith: { lhs, _ in lhs }) as CFDictionary
                )
            }
            
            
        default:
            CGImageDestinationAddImage(
                destination,
                self,
                properties.merging([kCGImageDestinationLossyCompressionQuality: quality], uniquingKeysWith: { lhs, _ in lhs }) as CFDictionary
            )
        }
        
        guard CGImageDestinationFinalize(destination) else { throw DataError.invalidFormat }
        return mutableData as Data
    }
    
    enum DataError: Error, CustomStringConvertible {
        case invalidFormat
        case cannotFinalizeData
        /// No CoreGraphics Image under the given image
        case noImage
        
        
        public var title: String {
            "Cannot form data from an image"
        }
        
        public var message: String {
            switch self {
            case .invalidFormat:
                "The format is invalid."
            case .cannotFinalizeData:
                "Cannot finalize the destination data."
            case .noImage:
                "No CoreGraphics Image under the given image"
            }
        }
        
        public var description: String {
            "\(title): \(message)"
        }
        
        /// - Invariant: This is inherited from `GenericError.description`
        public var localizedDescription: String {
            description
        }
        
        public var errorDescription: String? {
            description
        }
        
        public var failureReason: String? {
            self.message
        }
    }
    
    /// Resize and embed the image in a size.
    ///
    /// - Parameters:
    ///   - canvasSize: The canvas size.
    func embed(in canvasSize: CGSize) -> CGImage? {
        if self.size == canvasSize { return self }
        let context = CGContext.createContext(referencing: self, size: canvasSize)
        
        context.interpolationQuality = .high
        
        let rect = CGRect(center: canvasSize.center, size: self.size.aspectRatio(.fit, in: canvasSize))
        context.draw(self, in: rect)
        return context.makeImage()
    }
    
    /// Embed the image in a square.
    ///
    /// It changes the canvas size into a square of `max(width, height)`.
    @inlinable
    func embedInSquare() -> CGImage? {
        if self.size.isSquare { return self }
        
        let resultSize = CGSize.square(size.longerSide)
        let context = CGContext.createContext(size: resultSize, bitsPerComponent: self.bitsPerComponent, space: self.colorSpace, withAlpha: true)
        context.interpolationQuality = .high
        
        let rect = CGRect(center: CGPoint(x: size.longerSide / 2, y: size.longerSide / 2), size: size)
        context.draw(self, in: rect)
        return context.makeImage()
    }
    
    /// Resizes a `CGImage`.
    ///
    /// > Important:
    /// >
    /// > The method should be rarely used. To change the size of a ``NativeImage``, use
    /// >
    /// > ```swift
    /// > image.size = CGSize(x: Double, y: Double)
    /// > ```
    ///
    /// - Parameters:
    ///   - newSize: The changed size of image.
    ///
    /// - Returns: The `CGImage`, which is resized.
    @inlinable
    func resized(to newSize: CGSize) -> CGImage? {
        if self.size == newSize { return self }
        let context = CGContext.createContext(referencing: self, size: newSize)
        
        context.interpolationQuality = .high
        context.draw(self, in: CGRect(origin: .zero, size: newSize))
        return context.makeImage()
    }
    
}


#if canImport(CoreImage) && canImport(Vision)
import CoreImage
import Vision
import SwiftUI


public extension CGImage {
    
    /// Fills the image in a given size.
    ///
    /// The function would perform any necessary rescaling. Some borders may be cropped.
    ///
    /// - Parameters:
    ///   - size: The container size
    ///   - type: Pass `nil` if you do not want to use the `vision` framework.
    ///
    /// ## Topics
    /// ### Parameter Type
    /// - ``SaliencyType``
    @inlinable
    @available(macOS 13, iOS 16.0, tvOS 16.0, watchOS 9, *)
    func fill(in size: CGSize, type: SaliencyType? = nil) async -> CGImage? {
        if self.size == size { return self }
        
        guard let type else {
            let context = CGContext.createContext(referencing: self, size: size)
            
            context.interpolationQuality = .high
            
            let rect = CGRect(center: size.center, size: self.size.aspectRatio(.fill, in: size))
            context.draw(self, in: rect)
            return context.makeImage()
        }
        
        let request: VNImageBasedRequest = {
            switch type {
            case .attentionBased:
                return VNGenerateAttentionBasedSaliencyImageRequest()
            case .objectnessBased:
                return VNGenerateObjectnessBasedSaliencyImageRequest()
            }
        }()
        
        let scaledSize = self.size.aspectRatio(.fill, in: size)
        let context = CGContext.createContext(referencing: self, size: scaledSize)
        
        context.interpolationQuality = .high
        
        let rect = CGRect(center: scaledSize.center, size: scaledSize)
        context.draw(self, in: rect)
        guard let scaled = context.makeImage() else { return nil }
        
        
        let requestHandler = VNImageRequestHandler(cgImage: scaled)
        do {
            try requestHandler.perform([request])
        } catch {
            let logger = Logger(subsystem: "The Support Framework", category: "CGImage Extensions")
            logger.error("Unable to perform \(String(describing: type)) request on the given image, will return nil: \(error)")
            return nil
        }
        guard let saliencyObservation = request.results?.first as? VNSaliencyImageObservation else { return nil }
        guard let salientObjects = saliencyObservation.salientObjects else { return nil }
        
        var unionOfSalientRegions: CGRect = .null
        
        for salientObject in salientObjects {
            unionOfSalientRegions = unionOfSalientRegions.union(salientObject.boundingBox)
        }
        let salientRect = VNImageRectForNormalizedRect(unionOfSalientRegions,
                                                       Int(scaledSize.width),
                                                       Int(scaledSize.height))
        
        let center = salientRect.center
        
        let possibleBounds = CGRect(center: CGPoint(x: scaledSize.width / 2, y: scaledSize.height / 2), size: CGSize(width: scaledSize.width - size.width, height: scaledSize.height - size.height))
        let shiftedCenter = CGPoint(x: min(max(center.x, possibleBounds.minX), possibleBounds.maxX), y: min(max(center.y, possibleBounds.minY), possibleBounds.maxY))
        
        return scaled.cropped(to: CGRect(center: shiftedCenter, size: size))
    }
    
    /// Fills the image in a square.
    ///
    /// - Parameters:
    ///   - type: Pass `nil` if you do not want to use the `vision` framework.
    ///
    /// ## Topics
    /// ### Parameter Type
    /// - ``SaliencyType``
    @inlinable
    @available(macOS 13, iOS 16.0, tvOS 16.0, watchOS 9, *)
    func fillInSquare(type: SaliencyType? = nil) async -> CGImage? {
        if self.size.isSquare { return self }
        
        let resultSize = CGSize.square(size.shorterSide)
        return await self.fill(in: resultSize, type: type)
    }
    
    enum SaliencyType {
        
        /// An object that produces a heat map that identifies the parts of an image most likely to draw attention.
        case attentionBased
        
        /// A request that generates a heat map that identifies the parts of an image most likely to represent objects.
        case objectnessBased
    }
    
    @inlinable
    static func make(from pixelBuffer: CVPixelBuffer) -> CGImage? {
        let context = CIContext()
        let ciImage = CIImage(cvImageBuffer: pixelBuffer)
        return context.createCGImage(ciImage, from: ciImage.extent)
    }
    
}
#endif
