//
//  Specular.swift
//  NativeImage
//
//  Created by Vaida on 2026-04-13.
//

import CoreGraphics
import Essentials


extension CGImage {
    
    /// A a specular effect to the image.
    ///
    /// The resulting image is similar to a macOS file preview
    public func addSpecular() async -> CGImage? {
        let aspectRatio = max(self.size.width / self.size.height, self.size.height / self.size.width)
        let margin = linearInterpolate(aspectRatio, in: 1...2, to: 0.837 ... 0.955)
        let contextSize = CGSize(width: self.size.width / margin, height: self.size.height / margin)
        let context = CGContext.createContext(size: contextSize, bitsPerComponent: 8, space: nil, withAlpha: true)
        
        context.setAllowsAntialiasing(true)
        context.setShouldAntialias(true)
        context.interpolationQuality = .high
        
        let imageRect = CGRect(center: contextSize.center, size: self.size)
        let cornerRadius = self.size.shorterSide / 10
        
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
            blur: self.size.shorterSide / 50 ,
            color: CGColor(gray: 0, alpha: 0.3)
        )
        context.addPath(clipPath)
        context.setFillColor(CGColor(gray: 1, alpha: 1)) // covered by the image; just used to cast shadow
        context.fillPath()
        context.restoreGState()
        
        // --- Image: aspectFill + clipped to rounded rect ---
        context.saveGState()
        context.addPath(clipPath)
        context.clip()
        
        context.draw(self, in: imageRect)
        
        context.restoreGState()
        
        let borderWidth = self.size.shorterSide / 200
        
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
        context.setStrokeColor(CGColor(gray: 1, alpha: 0.33))
        context.setLineWidth(borderWidth)
        context.strokePath()
        
        return context.makeImage()
    }
}
