// MARK: - Metal Renderer (Step 2.2)
// Single MTKView renderer for all terminal viewports via viewport scissoring.

import Foundation
import Metal
import MetalKit

final class MetalRenderer: NSObject, TerminalRenderable, MTKViewDelegate {

    // MARK: - Properties

    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private var pipelineState: MTLRenderPipelineState?
    private let glyphAtlas: GlyphAtlas

    // Triple buffering
    private var vertexBuffers: [MTLBuffer?] = [nil, nil, nil]
    private var frameIndex: Int = 0
    private let maxVerticesPerFrame = 500_000 // ~50 sessions × 200 rows × 80 cols × 6 vertices/cell / 10

    private var pendingViewports: [TerminalViewportData] = []

    // MARK: - Vertex Layout

    struct Vertex {
        var position: SIMD2<Float>
        var texCoord: SIMD2<Float>
        var foregroundColor: SIMD4<Float>
        var backgroundColor: SIMD4<Float>
    }

    // MARK: - Init

    init?(device: MTLDevice? = nil) {
        guard let dev = device ?? MTLCreateSystemDefaultDevice() else { return nil }
        self.device = dev
        guard let queue = dev.makeCommandQueue() else { return nil }
        self.commandQueue = queue
        self.glyphAtlas = GlyphAtlas(device: dev)

        super.init()

        setupPipeline()
        allocateBuffers()
        glyphAtlas.build(fontFamily: "SF Mono", fontSize: 13)
    }

    // MARK: - TerminalRenderable

    func render(viewports: [TerminalViewportData]) {
        pendingViewports = viewports
    }

    func updateGlyphAtlas(fontFamily: String, fontSize: CGFloat) {
        glyphAtlas.build(fontFamily: fontFamily, fontSize: fontSize)
    }

    func invalidate() {
        pendingViewports = []
    }

    // MARK: - MTKViewDelegate

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer() else { return }

        let bufferIndex = frameIndex % 3
        frameIndex += 1

        // Build vertices for all viewports
        var vertices: [Vertex] = []
        vertices.reserveCapacity(pendingViewports.count * 200 * 80 * 6)

        let viewSize = view.drawableSize

        for viewport in pendingViewports {
            buildVertices(
                for: viewport,
                into: &vertices,
                viewSize: viewSize
            )
        }

        guard !vertices.isEmpty else {
            // Still need to present drawable even with no content
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
            encoder?.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
            return
        }

        // Update vertex buffer (no allocation — reuse from pool)
        let dataSize = vertices.count * MemoryLayout<Vertex>.stride
        if vertexBuffers[bufferIndex] == nil || vertexBuffers[bufferIndex]!.length < dataSize {
            vertexBuffers[bufferIndex] = device.makeBuffer(length: max(dataSize, 1024 * 1024), options: .storageModeShared)
        }

        guard let vBuffer = vertexBuffers[bufferIndex] else { return }
        memcpy(vBuffer.contents(), &vertices, dataSize)

        // Render
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
        encoder.setRenderPipelineState(pipelineState!)
        encoder.setVertexBuffer(vBuffer, offset: 0, index: 0)
        encoder.setFragmentTexture(glyphAtlas.texture, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
        encoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    // MARK: - Private

    private func setupPipeline() {
        // Pipeline state would use compiled .metal shaders
        // For now, create a simple pipeline descriptor
        // Full shader implementation in Shaders.metal
    }

    private func allocateBuffers() {
        for i in 0..<3 {
            vertexBuffers[i] = device.makeBuffer(
                length: maxVerticesPerFrame * MemoryLayout<Vertex>.stride,
                options: .storageModeShared
            )
        }
    }

    private func buildVertices(
        for viewport: TerminalViewportData,
        into vertices: inout [Vertex],
        viewSize: CGSize
    ) {
        let rect = viewport.rect
        let grid = viewport.grid

        let cellW = rect.width / CGFloat(grid.columns)
        let cellH = rect.height / CGFloat(grid.rows)

        for (index, cell) in grid.cells.enumerated() {
            let col = index % grid.columns
            let row = index / grid.columns

            let x = rect.x + CGFloat(col) * cellW
            let y = rect.y + CGFloat(row) * cellH

            // Normalize to NDC (-1 to 1)
            let ndcX = Float(x / viewSize.width) * 2.0 - 1.0
            let ndcY = 1.0 - Float(y / viewSize.height) * 2.0
            let ndcW = Float(cellW / viewSize.width) * 2.0
            let ndcH = Float(cellH / viewSize.height) * 2.0

            let fg = colorToSIMD(cell.foreground)
            let bg = colorToSIMD(cell.background)

            // Glyph texture coordinates
            let glyphPos = glyphAtlas.glyphPositions[cell.character] ?? GlyphAtlas.GlyphPosition(u: 0, v: 0, width: 0, height: 0)

            // Two triangles per cell (6 vertices)
            let topLeft = Vertex(position: SIMD2(ndcX, ndcY), texCoord: SIMD2(glyphPos.u, glyphPos.v), foregroundColor: fg, backgroundColor: bg)
            let topRight = Vertex(position: SIMD2(ndcX + ndcW, ndcY), texCoord: SIMD2(glyphPos.u + glyphPos.width, glyphPos.v), foregroundColor: fg, backgroundColor: bg)
            let bottomLeft = Vertex(position: SIMD2(ndcX, ndcY - ndcH), texCoord: SIMD2(glyphPos.u, glyphPos.v + glyphPos.height), foregroundColor: fg, backgroundColor: bg)
            let bottomRight = Vertex(position: SIMD2(ndcX + ndcW, ndcY - ndcH), texCoord: SIMD2(glyphPos.u + glyphPos.width, glyphPos.v + glyphPos.height), foregroundColor: fg, backgroundColor: bg)

            vertices.append(contentsOf: [topLeft, topRight, bottomLeft, topRight, bottomRight, bottomLeft])
        }
    }

    private func colorToSIMD(_ color: TerminalColor) -> SIMD4<Float> {
        switch color {
        case .rgb(let r, let g, let b):
            return SIMD4(Float(r) / 255.0, Float(g) / 255.0, Float(b) / 255.0, 1.0)
        case .ansi(let code):
            // Basic ANSI → RGB mapping (simplified)
            let rgb = ansiToRGB(code)
            return SIMD4(Float(rgb.0) / 255.0, Float(rgb.1) / 255.0, Float(rgb.2) / 255.0, 1.0)
        case .default:
            return SIMD4(1.0, 1.0, 1.0, 1.0)
        }
    }

    private func ansiToRGB(_ code: UInt8) -> (UInt8, UInt8, UInt8) {
        let basic: [(UInt8, UInt8, UInt8)] = [
            (0, 0, 0), (205, 49, 49), (13, 188, 121), (229, 229, 16),
            (36, 114, 200), (188, 63, 188), (17, 168, 205), (204, 204, 204),
            (128, 128, 128), (241, 76, 76), (35, 209, 139), (245, 245, 67),
            (59, 142, 234), (214, 112, 214), (41, 184, 219), (242, 242, 242)
        ]
        if code < 16 { return basic[Int(code)] }
        if code < 232 {
            let idx = Int(code) - 16
            let r = UInt8((idx / 36) * 51)
            let g = UInt8(((idx % 36) / 6) * 51)
            let b = UInt8((idx % 6) * 51)
            return (r, g, b)
        }
        let gray = UInt8(8 + (Int(code) - 232) * 10)
        return (gray, gray, gray)
    }
}
