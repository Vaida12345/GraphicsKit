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
        let rgbColorSpaces: [CFString] = [
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

        for colorSpace in rgbColorSpaces {
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
        let cmykColorSpaces: [CFString] = [
            CGColorSpace.genericCMYK,
        ]

        for colorSpace in cmykColorSpaces {
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
    
    @Suite
    struct CombinationTests {
        func bitmapHasAlpha(_ bitmapInfo: CGImageAlphaInfo) -> Bool {
            return [CGImageAlphaInfo.first, .last, .premultipliedLast, .premultipliedFirst].contains(bitmapInfo)
        }
        
        @Test func createContext_MonochromeCombinations() async throws {
            let spaces: [CGColorSpace] = [
                CGColorSpace(name: CGColorSpace.genericGrayGamma2_2),
                CGColorSpace(name: CGColorSpace.linearGray),
                CGColorSpace(name: CGColorSpace.extendedGray),
                CGColorSpace(name: CGColorSpace.extendedLinearGray),
            ].compactMap { $0 }
            
            #expect(!spaces.isEmpty)
            
            let bitsPerComponentValues = [1, 2, 4, 8, 12, 16, 24, 32]
            let sizes = [CGSize(width: 1, height: 1), CGSize(width: 7, height: 13), CGSize(width: 128, height: 64)]
            let alphaOptions = [false, true]
            
            for space in spaces {
                for bits in bitsPerComponentValues {
                    for size in sizes {
                        for withAlpha in alphaOptions {
                            let context = CGContext.createContext(size: size, bitsPerComponent: bits, space: space, withAlpha: withAlpha)
                            #expect(context.width == Int(size.width))
                            #expect(context.height == Int(size.height))
                            #expect(context.bitsPerComponent > 0)
                            #expect(context.colorSpace != nil)
                            if withAlpha {
                                #expect(bitmapHasAlpha(context.bitmapInfo.alpha))
                            }
                        }
                    }
                }
            }
        }
        
        @Test func createContext_RGBCombinations() async throws {
            let spaces: [CGColorSpace] = [
                CGColorSpace(name: CGColorSpace.sRGB),
                CGColorSpace(name: CGColorSpace.linearSRGB),
                CGColorSpace(name: CGColorSpace.extendedSRGB),
                CGColorSpace(name: CGColorSpace.extendedLinearSRGB),
                CGColorSpace(name: CGColorSpace.displayP3),
                CGColorSpace(name: CGColorSpace.extendedLinearDisplayP3),
            ].compactMap { $0 }
            
            #expect(!spaces.isEmpty)
            
            let bitsPerComponentValues = [5, 8, 10, 12, 16, 24, 32, 64]
            let sizes = [CGSize(width: 1, height: 1), CGSize(width: 3, height: 2), CGSize(width: 255, height: 17)]
            let alphaOptions = [false, true]
            
            for space in spaces {
                for bits in bitsPerComponentValues {
                    for size in sizes {
                        for withAlpha in alphaOptions {
                            let context = CGContext.createContext(size: size, bitsPerComponent: bits, space: space, withAlpha: withAlpha)
                            #expect(context.width == Int(size.width))
                            #expect(context.height == Int(size.height))
                            #expect(context.bitsPerComponent > 0)
                            #expect(context.colorSpace != nil)
                            if withAlpha {
                                #expect(bitmapHasAlpha(context.bitmapInfo.alpha))
                            }
                        }
                    }
                }
            }
        }
        
        @Test func createContext_CMYKCombinations() async throws {
            let spaces: [CGColorSpace] = [
                CGColorSpace(name: CGColorSpace.genericCMYK),
            ].compactMap { $0 }
            
            #expect(!spaces.isEmpty)
            
            let bitsPerComponentValues = [1, 8, 16, 24, 32, 64]
            let sizes = [CGSize(width: 1, height: 1), CGSize(width: 9, height: 9), CGSize(width: 64, height: 65)]
            let alphaOptions = [false, true]
            
            for space in spaces {
                for bits in bitsPerComponentValues {
                    for size in sizes {
                        for withAlpha in alphaOptions {
                            let context = CGContext.createContext(size: size, bitsPerComponent: bits, space: space, withAlpha: withAlpha)
                            #expect(context.width == Int(size.width))
                            #expect(context.height == Int(size.height))
                            #expect(context.bitsPerComponent > 0)
                            #expect(context.colorSpace != nil)
                            if withAlpha {
                                #expect(bitmapHasAlpha(context.bitmapInfo.alpha))
                            }
                        }
                    }
                }
            }
        }
        
        @Test func createContext_ModelFallbackCombinations() async throws {
            let nonRGBSpaces: [CGColorSpace] = [
                CGColorSpace(name: CGColorSpace.linearGray),
                CGColorSpace(name: CGColorSpace.genericCMYK),
            ].compactMap { $0 }
            
            #expect(!nonRGBSpaces.isEmpty)
            
            let bitsPerComponentValues = [0, 3, 6, 9, 15, 31, 100]
            let sizes = [CGSize(width: 2, height: 2), CGSize(width: 11, height: 5)]
            
            for space in nonRGBSpaces {
                for bits in bitsPerComponentValues {
                    for size in sizes {
                        let context = CGContext.createContext(size: size, bitsPerComponent: bits, space: space, withAlpha: true)
                        #expect(context.width == Int(size.width))
                        #expect(context.height == Int(size.height))
                        #expect(context.colorSpace?.model == .rgb || context.colorSpace?.model == space.model)
                    }
                }
            }
        }
    }
}
