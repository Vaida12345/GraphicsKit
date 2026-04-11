import CoreGraphics
import Testing
@testable import NativeImage

@Suite
struct CGContextCreateTests {
    @Test func defaultPresetIsValid() async throws {
        for preset in CGContext.ParameterPreset.allCases {
            let context = CGContext(
                data: nil,
                width: 10,
                height: 10,
                bitsPerComponent: preset.bitsPerComponent,
                bytesPerRow: 0,
                space: preset.makeDefaultColorSpace(),
                bitmapInfo: preset.bitmapInfo
            )
            #expect(context != nil)
        }
    }
    
    @Test(.disabled()) func grayColorSpace() async throws {
        let grayColorSpaces: [CFString] = [
            CGColorSpace.genericGrayGamma2_2,
            CGColorSpace.extendedGray,
            CGColorSpace.linearGray,
            CGColorSpace.extendedLinearGray,
        ]
        
        for colorSpace in grayColorSpaces {
            for preset in CGContext.ParameterPreset.allCases.filter({ $0.colorModel == .monochrome }) {
                let context = CGContext(
                    data: nil,
                    width: 10,
                    height: 10,
                    bitsPerComponent: preset.bitsPerComponent,
                    bytesPerRow: 0,
                    space: CGColorSpace(name: colorSpace)!,
                    bitmapInfo: preset.bitmapInfo
                )
            }
        }
    }
    
    @Test(.disabled()) func rgbColorSpace() async throws {
        let grayColorSpaces: [CFString] = [
            CGColorSpace.sRGB,
            CGColorSpace.linearSRGB,
            CGColorSpace.extendedSRGB,
            CGColorSpace.adobeRGB1998,
            CGColorSpace.genericRGBLinear,
            CGColorSpace.extendedLinearSRGB,
            
            CGColorSpace.displayP3,
            CGColorSpace.displayP3_PQ,
            CGColorSpace.displayP3_HLG,
            CGColorSpace.extendedLinearDisplayP3
        ]
        
        for colorSpace in grayColorSpaces {
            print(colorSpace)
            let colorSpace = CGColorSpace(name: colorSpace)!
            for preset in CGContext.ParameterPreset.allCases.filter({ $0.colorModel == .rgb }) {
                let context = CGContext(
                    data: nil,
                    width: 10,
                    height: 10,
                    bitsPerComponent: preset.bitsPerComponent,
                    bytesPerRow: preset.bitsPerPixel * 10 / 8,
                    space: colorSpace,
                    bitmapInfo: preset.bitmapInfo
                )
            }
        }
    }
    
    @Test func cmykColorSpace() async throws {
        let grayColorSpaces: [CFString] = [
            CGColorSpace.genericCMYK,
        ]
        
        for colorSpace in grayColorSpaces {
            let colorSpace = CGColorSpace(name: colorSpace)!
            for preset in CGContext.ParameterPreset.allCases.filter({ $0.colorModel == .cmyk }) {
                let context = CGContext(
                    data: nil,
                    width: 10,
                    height: 10,
                    bitsPerComponent: preset.bitsPerComponent,
                    bytesPerRow: 0,
                    space: colorSpace,
                    bitmapInfo: preset.bitmapInfo
                )
                #expect(context != nil)
            }
        }
    }
}


