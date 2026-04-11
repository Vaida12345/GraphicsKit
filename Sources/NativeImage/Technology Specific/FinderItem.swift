//
//  FinderItem.swift
//  GraphicsKit
//
//  Created by Vaida on 9/26/24.
//

import FinderItem
import SwiftUI
import Essentials
#if !os(tvOS) && !os(watchOS)
import QuickLookThumbnailing
#endif


public extension View {
    
    /// Render the view to given destination.
    ///
    /// ## Rendering
    /// The following components will cause the result to be rendered in `TIFF`!
    /// - `material`
    ///
    /// - Parameters:
    ///   - destination: The destination
    ///   - format: The resulting format, if `nil`, the format is auto-inferred.
    ///   - scale: The scale to the view
    @inlinable
    @MainActor
    func render(to destination: FinderItem, format: NativeImage.ImageFormatOption? = nil, scale: Double = 2) throws {
        let renderer = ImageRenderer(content: self)
        if format == .pdf || destination.extension == "pdf" {
            var succeed = false
            renderer.render { size, render in
                var mediaBox = CGRect(origin: .zero, size: size.scaled(by: scale))
                guard let consumer = CGDataConsumer(url: destination.url as CFURL),
                      let pdfContext = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else { return }
                pdfContext.beginPDFPage(nil)
                pdfContext.scaleBy(x: scale, y: scale)
                render(pdfContext)
                pdfContext.endPDFPage()
                pdfContext.closePDF()
                succeed = true
            }
            if !succeed {
                throw FinderItem.FileError(code: .cannotWrite(reason: .noPermission), source: destination)
            }
        } else {
            renderer.scale = scale
            try renderer.cgImage?.write(to: destination, format: format)
        }
    }
}


public extension CGImage {
    
    /// Write a `CGImage` as in the format of `option` to the `destination`.
    ///
    /// A `quality` value of 1.0 specifies to use lossless compression if destination format supports it. A value of 0.0 implies to use maximum compression.
    ///
    /// - Tip: To set image metadata, use ``CGImage/data(format:quality:properties:)`` instead.
    ///
    /// - Parameters:
    ///   - destination: The `FinderItem` representing the path to save the image.
    ///   - format: The format of the image, pass `nil` to auto infer from the extension name of `destination`.
    ///   - quality: The image compression quality.
    func write(to destination: FinderItem, format: NativeImage.ImageFormatOption? = nil, quality: CGFloat = 1) throws {
        do {
            let _option = format != nil ? format! : try NativeImage.ImageFormatOption.inferredFrom(extension: destination.extension)
            let imageData = try self.data(format: _option, quality: quality)
            
            try imageData.write(to: destination)
        } catch {
            throw try FinderItem.FileError.parse(orThrow: error)
        }
    }
    
}


public extension FinderItem.LoadableContent {
    
    /// Returns the image at the location, if exists.
    static var image: FinderItem.LoadableContent<NativeImage, any Error> {
        .init { (source: FinderItem) throws -> NativeImage in
            guard source.isFile else {
                throw FinderItem.FileError(code: .cannotRead(reason: .corruptFile), source: source)
            }
            let data = try Data(at: source)
            if let image = NativeImage(data: data) {
                return image
            } else {
                throw FinderItem.FileError(code: .cannotRead(reason: .corruptFile), source: source)
            }
        }
    }
    
    /// Returns the image at the location, if exists.
    static var cgImage: FinderItem.LoadableContent<CGImage, any Error> {
        .init { (source: FinderItem) throws -> CGImage in
            try self.image.contentLoader(source).cgImage!
        }
    }
    
}

public extension FinderItem.AsyncLoadableContent where Result == NativeImage {
    
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    /// Returns the icon at the location.
    ///
    /// The resulting image is scaled down to the required `size`.
    ///
    /// This method can returned custom icon. However, it may also produce wrong generic icons.
    ///
    /// - Parameters:
    ///   - size: The size of the image.
    ///
    /// - Returns: If the file does not exist, or no representations larger than `size`, returns nil.
    ///
    /// - SeeAlso: ``bestIcon(size:)``.
    @available(*, deprecated, renamed: "bestIcon", message: "It is dangerous to use this method directly, as it may produce unexpected results.")
    static func icon(size: CGSize? = nil) -> FinderItem.AsyncLoadableContent<NativeImage, any Error> {
        .init { (source: FinderItem) throws -> NativeImage in
            guard source.exists else { throw FinderItem.FileError(code: .cannotRead(reason: .noSuchFile), source: source) }
            let icons = NSWorkspace.shared.icon(forFile: source.path)
            
            guard let size else { return icons }
            
            if let first = icons.representations.first(where: { CGFloat($0.pixelsHigh) >= size.height && CGFloat($0.pixelsWide) >= size.width }),
               let image = first.cgImage(forProposedRect: nil, context: nil, hints: nil),
               let scaled = image.resized(to: image.size.aspectRatio(.fit, in: size)) {
                return NativeImage(cgImage: scaled)
            } else {
                throw FinderItem.FileError(code: .cannotRead(reason: .corruptFile), source: source)
            }
        }
    }
#endif
    
#if !os(tvOS) && !os(watchOS)
    private static func generateImage(type: QLThumbnailGenerator.Request.RepresentationTypes, url: URL, size: CGSize) async throws -> (NativeImage, QLThumbnailRepresentation.RepresentationType) {
        let result = try await QLThumbnailGenerator.shared.generateBestRepresentation(for: .init(fileAt: url, size: size, scale: 1, representationTypes: type))
        
#if os(macOS)
        return (result.nsImage, result.type)
#elseif os(iOS) || os(visionOS)
        return (result.uiImage, result.type)
#endif
    }
    
    /// Generate the preview image for the given source.
    ///
    /// - Parameters:
    ///   - size: The size of the image.
    ///
    /// - Returns: If the file does not exist, or no representations larger than `size`, returns nil.
    ///
    /// - SeeAlso: ``bestIcon(size:)``.
    static func preview(size: CGSize) -> FinderItem.AsyncLoadableContent<NativeImage, any Error> {
        .init { source in
            guard source.exists else { throw FinderItem.FileError(code: .cannotRead(reason: .noSuchFile), source: source) }
            do {
                return try await generateImage(type: .thumbnail, url: source.url, size: size).0
            } catch {
                return try await generateImage(type: .icon, url: source.url, size: size).0
            }
        }
    }
#endif
    
    
    /// The best representation, the preview or icon, of a file.
    ///
    /// The returned result depends on the platform and file.
    ///
    /// On macOS, file preview is returned in a style similar to Finder icon.
    ///
    /// ```swift
    /// switch platform {
    /// case .macOS:
    ///     custom_icon ?? file_preview.iconStyle ?? generic_icon
    /// default:
    ///     file_preview ?? generic_icon
    /// }
    /// ```
    ///
    /// - Returns: A image fitted in `size`.
    static func bestIcon(size: CGSize) -> FinderItem.AsyncLoadableContent<NativeImage, any Error> {
        .init { source in
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
            if try source.load(.hasCustomIcon) {
                return try await source.load(.icon(size: size))
            } else {
                if let thumbnail = try? await generateImage(type: .thumbnail, url: source.url, size: size), thumbnail.1 == .thumbnail || thumbnail.1 == .lowQualityThumbnail {
                    guard let cgImage = thumbnail.0.cgImage, let rendered = await renderIconStyle(cgImage: cgImage) else { return thumbnail.0 }
                    return NativeImage(cgImage: rendered)
                }
                
                return try await generateImage(type: .icon, url: source.url, size: size).0
            }
#else
            return try await source.load(.preview(size: size))
#endif
        }
    }
    
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    private static func renderIconStyle(cgImage: CGImage) async -> CGImage? {
        let aspectRatio = max(cgImage.size.width / cgImage.size.height, cgImage.size.height / cgImage.size.width)
        let margin = linearInterpolate(aspectRatio, in: 1...2, to: 0.837 ... 0.955)
        let contextSize = CGSize(width: cgImage.size.width / margin, height: cgImage.size.height / margin)
        let context = CGContext.createContext(size: contextSize, bitsPerComponent: cgImage.bitsPerComponent, space: cgImage.colorSpace, withAlpha: true)
        
        context.setAllowsAntialiasing(true)
        context.setShouldAntialias(true)
        context.interpolationQuality = .high
        
        let imageRect = CGRect(center: contextSize.center, size: cgImage.size)
        let cornerRadius = cgImage.size.shorterSide / 10
        
        let clipPath = CGPath(
            roundedRect: imageRect,
            cornerWidth: cornerRadius,
            cornerHeight: cornerRadius,
            transform: nil
        )
        
        // --- Shadow ---
        // CoreGraphics caveat: if you clip then shadow, the shadow is clipped too.
        // So we draw a rounded-rect "caster" with shadow first, then draw the clipped image on top.
        context.saveGState()
        context.setShadow(
            offset: .zero,
            blur: cgImage.size.shorterSide / 50 ,
            color: NSColor.black.withAlphaComponent(0.3).cgColor
        )
        context.addPath(clipPath)
        context.setFillColor(NSColor.white.cgColor) // covered by the image; just used to cast shadow
        context.fillPath()
        context.restoreGState()
        
        // --- Image: aspectFill + clipped to rounded rect ---
        context.saveGState()
        context.addPath(clipPath)
        context.clip()
        
        context.draw(cgImage, in: imageRect)
        
        context.restoreGState()
        
        let borderWidth = cgImage.size.shorterSide / 200
        
        // --- RoundedRectangle stroke overlay ---
        // Matches your:
        // .stroke(..., lineWidth: margin)
        //
        // That frame reduction means inset by margin/4 per side.
        let strokeRect = imageRect.insetBy(dx: borderWidth / 4, dy: borderWidth / 4)
        let strokePath = CGPath(
            roundedRect: strokeRect,
            cornerWidth: cornerRadius,
            cornerHeight: cornerRadius,
            transform: nil
        )
        
        context.addPath(strokePath)
        context.setStrokeColor(NSColor.white.withAlphaComponent(0.33).cgColor)
        context.setLineWidth(borderWidth)
        context.strokePath()
        
        return context.makeImage()
    }
#endif
    
}
