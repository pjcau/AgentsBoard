// MARK: - Glyph Atlas (Step 2.2)
// Pre-renders all font glyphs into a shared Metal texture atlas.

import Foundation
import Metal
import CoreText
import CoreGraphics

final class GlyphAtlas {

    // MARK: - Properties

    private(set) var texture: MTLTexture?
    private(set) var cellWidth: CGFloat = 0
    private(set) var cellHeight: CGFloat = 0
    private(set) var glyphPositions: [Character: GlyphPosition] = [:]

    private let device: MTLDevice
    private var currentFont: CTFont?

    struct GlyphPosition {
        let u: Float  // texture coordinate X (0-1)
        let v: Float  // texture coordinate Y (0-1)
        let width: Float
        let height: Float
    }

    // MARK: - Init

    init(device: MTLDevice) {
        self.device = device
    }

    // MARK: - Build Atlas

    func build(fontFamily: String, fontSize: CGFloat) {
        let font = CTFontCreateWithName(fontFamily as CFString, fontSize, nil)
        self.currentFont = font

        // Calculate cell size from font metrics
        var advances = [CGSize](repeating: .zero, count: 1)
        var glyphs: [CGGlyph] = [0]
        var mChar: [UniChar] = [UniChar(0x4D)] // 'M' for width
        CTFontGetGlyphsForCharacters(font, &mChar, &glyphs, 1)
        CTFontGetAdvancesForGlyphs(font, .horizontal, &glyphs, &advances, 1)

        cellWidth = ceil(advances[0].width)
        cellHeight = ceil(CTFontGetAscent(font) + CTFontGetDescent(font) + CTFontGetLeading(font))

        // Atlas dimensions: 16x8 grid of printable ASCII (128 chars)
        let cols = 16
        let rows = 8
        let atlasWidth = Int(cellWidth) * cols
        let atlasHeight = Int(cellHeight) * rows

        guard atlasWidth > 0, atlasHeight > 0 else { return }

        // Create bitmap context
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        guard let context = CGContext(
            data: nil,
            width: atlasWidth,
            height: atlasHeight,
            bitsPerComponent: 8,
            bytesPerRow: atlasWidth * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return }

        context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 0))
        context.fill(CGRect(x: 0, y: 0, width: atlasWidth, height: atlasHeight))

        // Render each printable ASCII character
        for charCode in 0..<128 {
            let col = charCode % cols
            let row = charCode / cols

            let x = CGFloat(col) * cellWidth
            let y = CGFloat(atlasHeight) - CGFloat(row + 1) * cellHeight + CTFontGetDescent(font)

            let char = Character(UnicodeScalar(charCode)!)
            let string = String(char) as CFString
            let attrString = CFAttributedStringCreate(
                nil,
                string,
                [kCTFontAttributeName: font, kCTForegroundColorAttributeName: CGColor.white] as CFDictionary
            )!
            let line = CTLineCreateWithAttributedString(attrString)

            context.textPosition = CGPoint(x: x, y: y)
            CTLineDraw(line, context)

            glyphPositions[char] = GlyphPosition(
                u: Float(col) / Float(cols),
                v: Float(row) / Float(rows),
                width: 1.0 / Float(cols),
                height: 1.0 / Float(rows)
            )
        }

        // Create Metal texture from bitmap
        guard let image = context.makeImage() else { return }

        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: atlasWidth,
            height: atlasHeight,
            mipmapped: false
        )
        descriptor.usage = [.shaderRead]

        guard let tex = device.makeTexture(descriptor: descriptor),
              let data = context.data else { return }

        tex.replace(
            region: MTLRegionMake2D(0, 0, atlasWidth, atlasHeight),
            mipmapLevel: 0,
            withBytes: data,
            bytesPerRow: atlasWidth * 4
        )

        self.texture = tex
    }
}
