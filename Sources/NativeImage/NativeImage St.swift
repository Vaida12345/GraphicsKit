//
//  NativeImage Structure.swift
//
//
//  Created by Vaida on 4/13/22.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//

import CoreGraphics
import SwiftUI
import UniformTypeIdentifiers
import FinderItem


public extension NativeImage {
    
    /// The pixel size of `NativeImage`.
    ///
    /// - Remark: This variable measures the first representation of the image.
    @inlinable
    var pixelSize: CGSize? {
        guard let cgImage else { return nil }
        return CGSize(width: cgImage.width, height: cgImage.height)
    }
    
    /// The `tiffRepresentation` or the `pngData` of the image.
    private var imageData: Data? {
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
        return self.tiffRepresentation
#elseif canImport(UIKit)
        return self.pngData()
#endif
    }
    
    /// The app icon of the app, if available.
    @inlinable
    static var appIcon: NativeImage? {
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
        guard let AppIconName = Bundle.main.object(forInfoDictionaryKey: "CFBundleIconName") as? String else { return nil }
        return NativeImage(named: AppIconName)
#elseif canImport(UIKit)
        guard let icons = Bundle.main.object(forInfoDictionaryKey: "CFBundleIcons") as? [String: Any] else { return nil }
        guard let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any] else { return nil }
        guard let AppIconName = primaryIcon["CFBundleIconName"] as? String else { return nil }
        return NativeImage(named: AppIconName)
#endif
    }
    
    /// Initialize with a cgImage, if the cgImage is not `nil`.
    @inlinable
    convenience init?(cgImage: CGImage?) {
        guard let cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
    
    /// Initializes a `NativeImage` with the contents at the specified file.
    ///
    /// - Parameters:
    ///   - source: The file representing the location of the asset.
    @inlinable
    convenience init?(at source: FinderItem) {
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
        self.init(contentsOf: source.url)
#elseif canImport(UIKit)
        try? self.init(data: Data(contentsOf: source.url))
#endif
    }
    
    /// Reloads the image to prevent it from breaking.
    func reload() -> NativeImage {
        guard let imageData else { return NativeImage() }
        return NativeImage(data: imageData) ?? NativeImage()
    }
    
    /// Returns the data of the image with a new codec.
    ///
    /// A `quality` value of 1.0 specifies to use lossless compression if destination format supports it. A value of 0.0 implies to use maximum compression.
    ///
    /// - Parameters:
    ///   - format: The format of the image.
    ///   - quality: The image compression quality.
    ///
    /// - throws: ``CoreGraphics/CGImage/DataError``
    @inlinable
    func data(format: ImageFormatOption = .png, quality: CGFloat = 1) throws -> Data {
#if canImport(CoreImage)
        guard let cgImage else { throw CGImage.DataError.noImage }
        return try cgImage.data(format: format, quality: quality)
#else
        fatalError("Incompatible format sent to framework")
#endif
    }
    
    /// Write a `NativeImage` as in the format of `option` to the `destination`.
    ///
    /// - Parameters:
    ///   - destination: The file representing the path to save the image.
    ///   - format: The format of the image, pass `nil` to auto infer from the extension name of `destination`.
    ///   - quality: The image compression quality.
    func write(to destination: FinderItem, format: ImageFormatOption? = nil, quality: Double = 1) throws {
        let _option = format != nil ? format! : try NativeImage.ImageFormatOption.inferredFrom(extension: destination.extension)
        let imageData = try self.data(format: _option, quality: quality)
        
        try imageData.write(to: destination)
    }
    
    /// The options for saving an image.
    enum ImageFormatOption: String, CaseIterable, CustomStringConvertible {
        
        /// Portable Network Graphics (PNG) format.
        case png = "public.png"
        
        /// Tagged Image File Format (TIFF).
        case tiff = "public.tiff"
        
        /// High Efficiency Image File (HEIF) format.
        case heic = "public.heic"
        
        /// Portable Document Format (PDF) format.
        case pdf = "com.adobe.pdf"
        
        /// JPEG format.
        case jpeg = "public.jpeg"
        
        /// Photoshop Document (PSD) format.
        case psd = "com.adobe.photoshop-image"
        
        /// Apple icon (ICNS) format.
        case icns = "com.apple.icns"

        public var description: String {
            self.rawValue
        }
        
        /// The option.
        @inlinable
        @available(macOS 13, iOS 16.0, tvOS 16.0, watchOS 9, *)
        public var format: UTType {
            UTType(self.rawValue)!
        }
        
        /// The identifier of the format.
        @inlinable
        public var identifier: String {
            self.rawValue
        }
        
        
        internal static func inferredFrom(extension: String) throws -> ImageFormatOption {
            precondition(!`extension`.isEmpty, "The provided file has empty extension. Please specify the extension, or state the image format explicitly by passing to `format`.")
            switch `extension`.lowercased() {
            case "png":
                return .png
            case "tif", "tiff":
                return .tiff
            case "heif", "heifs", "heic", "heics", "avci", "avcs", "hif":
                return .heic
            case "pdf":
                return .pdf
            case "jpg", "jpeg", "jpe", "jif", "jfif", "jfi":
                return .jpeg
            case "psd":
                return .psd
            case "icns":
                return .icns
            default:
                throw InferFormatError.cannotInferType(`extension`)
            }
        }
        
        enum InferFormatError: Error, CustomStringConvertible {
            
            case cannotInferType(String)
            
            
            var title: String {
                "Cannot infer image type from given extension"
            }
            
            var message: String {
                switch self {
                case .cannotInferType(let string):
                    "The extension `\(string)` is not recognized."
                }
            }
            
            
            public var description: String {
                "\(title): \(message)"
            }
            
            /// - Invariant: This is inherited from `GenericError.description`
            public var localizedDescription: String {
                description
            }
            
            /// - Invariant: This is inherited from ``GenericError/description``
            public var errorDescription: String? {
                description
            }
            
            /// - Invariant: This is inherited from ``GenericError/message``
            public var failureReason: String? {
                self.message
            }
            
        }
    }
    
}
