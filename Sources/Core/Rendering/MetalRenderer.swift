// MARK: - Metal Renderer (Step 2.2)
// Single MTKView renderer for all terminal viewports via viewport scissoring.

#if canImport(Metal)

import Foundation
import Metal
import MetalKit

public final class MetalRenderer: NSObject, TerminalRenderable, MTKViewDelegate {

    // MARK: - Properties

    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private var pipelineState: MTLRenderPipelineState?
    private let glyphAtlas: GlyphAtlas

    // Triple buffering
    private var vertexBuffers: [MTLBuffer?] = [nil, nil, nil]
    private var frameIndex: Int = 0
    private let maxVerticesPerFrame = 500_000

    private var pendingViewports: [TerminalViewportData] = []

    // Per-viewport vertex ranges for scissored draw calls
    private struct ViewportDrawRange {
        let scissorRect: MTLScissorRect
        let vertexStart: Int
        let vertexCount: Int
    }

    // MARK: - Vertex Layout

    struct Vertex {
        var position: SIMD2<Float>
        var texCoord: SIMD2<Float>
        var foregroundColor: SIMD4<Float>
        var backgroundColor: SIMD4<Float>
    }

    // MARK: - Init

    public init?(device: MTLDevice? = nil) {
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

    public func render(viewports: [TerminalViewportData]) {
        pendingViewports = viewports
    }

    public func updateGlyphAtlas(fontFamily: String, fontSize: CGFloat) {
        glyphAtlas.build(fontFamily: fontFamily, fontSize: fontSize)
    }

    public func invalidate() {
        pendingViewports = []
    }

    // MARK: - MTKViewDelegate

    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    public func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer() else { return }

        let bufferIndex = frameIndex % 3
        frameIndex += 1

        let viewSize = view.drawableSize
        let drawableWidth = Int(viewSize.width)
        let drawableHeight = Int(viewSize.height)

        // Ensure vertex buffer exists
        guard let vBuffer = vertexBuffers[bufferIndex] else {
            presentEmpty(commandBuffer: commandBuffer, descriptor: renderPassDescriptor, drawable: drawable)
            return
        }

        let maxVertices = vBuffer.length / MemoryLayout<Vertex>.stride
        let vertexPtr = vBuffer.contents().bindMemory(to: Vertex.self, capacity: maxVertices)
        let vertexBuffer = UnsafeMutableBufferPointer(start: vertexPtr, count: maxVertices)

        // Build vertices for all viewports directly into the MTLBuffer
        var totalVertexCount = 0
        var drawRanges: [ViewportDrawRange] = []
        drawRanges.reserveCapacity(pendingViewports.count)

        let invViewW: Float = 2.0 / Float(viewSize.width)
        let invViewH: Float = 2.0 / Float(viewSize.height)

        for viewport in pendingViewports {
            let startVertex = totalVertexCount
            let verticesWritten = buildVertices(
                for: viewport,
                into: vertexBuffer,
                offset: totalVertexCount,
                maxVertices: maxVertices,
                invViewW: invViewW,
                invViewH: invViewH
            )
            totalVertexCount += verticesWritten

            if verticesWritten > 0 {
                // Compute scissor rect from viewport rect (in pixel coordinates)
                let rect = viewport.rect
                let sx = max(0, Int(rect.x))
                let sy = max(0, Int(rect.y))
                let sw = min(drawableWidth - sx, Int(rect.width))
                let sh = min(drawableHeight - sy, Int(rect.height))

                if sw > 0 && sh > 0 {
                    drawRanges.append(ViewportDrawRange(
                        scissorRect: MTLScissorRect(x: sx, y: sy, width: sw, height: sh),
                        vertexStart: startVertex,
                        vertexCount: verticesWritten
                    ))
                }
            }
        }

        guard totalVertexCount > 0, let pipeline = pipelineState else {
            presentEmpty(commandBuffer: commandBuffer, descriptor: renderPassDescriptor, drawable: drawable)
            return
        }

        // Render with per-viewport scissoring
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
        encoder.setRenderPipelineState(pipeline)
        encoder.setVertexBuffer(vBuffer, offset: 0, index: 0)
        encoder.setFragmentTexture(glyphAtlas.texture, index: 0)

        for range in drawRanges {
            encoder.setScissorRect(range.scissorRect)
            encoder.drawPrimitives(
                type: .triangle,
                vertexStart: range.vertexStart,
                vertexCount: range.vertexCount
            )
        }

        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    // MARK: - Private

    private func presentEmpty(commandBuffer: MTLCommandBuffer, descriptor: MTLRenderPassDescriptor, drawable: MTLDrawable) {
        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
        encoder?.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    private func setupPipeline() {
        // SPM does not compile .metal files, so we compile the shader source at runtime.
        let library: MTLLibrary
        do {
            library = try device.makeLibrary(source: MetalRenderer.shaderSource, options: nil)
        } catch {
            print("[MetalRenderer] Failed to compile Metal shaders: \(error)")
            return
        }

        guard let vertexFunction = library.makeFunction(name: "vertexShader"),
              let fragmentFunction = library.makeFunction(name: "fragmentShader") else {
            print("[MetalRenderer] Failed to find shader functions in compiled library")
            return
        }

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        // Enable alpha blending for glyph compositing
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            print("[MetalRenderer] Failed to create pipeline state: \(error)")
        }
    }

    private func allocateBuffers() {
        for i in 0..<3 {
            vertexBuffers[i] = device.makeBuffer(
                length: maxVerticesPerFrame * MemoryLayout<Vertex>.stride,
                options: .storageModeShared
            )
        }
    }

    /// Writes vertices directly into the MTLBuffer, returning the number of vertices written.
    /// All math uses Float to avoid CGFloat conversion overhead per cell.
    private func buildVertices(
        for viewport: TerminalViewportData,
        into buffer: UnsafeMutableBufferPointer<Vertex>,
        offset: Int,
        maxVertices: Int,
        invViewW: Float,
        invViewH: Float
    ) -> Int {
        let rect = viewport.rect
        let grid = viewport.grid

        let columns = grid.columns
        let rows = grid.rows
        let cellCount = grid.cells.count

        // Pre-compute as Float — avoid per-cell CGFloat conversions
        let rectX = Float(rect.x)
        let rectY = Float(rect.y)
        let cellW = Float(rect.width) / Float(columns)
        let cellH = Float(rect.height) / Float(rows)

        // NDC conversion factors (pre-multiplied)
        let ndcCellW = cellW * invViewW
        let ndcCellH = cellH * invViewH

        let verticesPerCell = 6
        let totalNeeded = cellCount * verticesPerCell
        guard offset + totalNeeded <= maxVertices else { return 0 }

        var writeIndex = offset

        for index in 0..<cellCount {
            let cell = grid.cells[index]
            let col = index % columns
            let row = index / columns

            let x = rectX + Float(col) * cellW
            let y = rectY + Float(row) * cellH

            // Normalize to NDC (-1 to 1)
            let ndcX = x * invViewW - 1.0
            let ndcY = 1.0 - y * invViewH

            let fg = colorToSIMD(cell.foregroundColor)
            let bg = colorToSIMD(cell.backgroundColor)

            // Glyph texture coordinates — keyed by codepoint for zero-cost lookup
            let glyphPos = glyphAtlas.glyphPositions[cell.codepoint]
                ?? GlyphAtlas.GlyphPosition(u: 0, v: 0, width: 0, height: 0)

            let texLeft = glyphPos.u
            let texRight = glyphPos.u + glyphPos.width
            let texTop = glyphPos.v
            let texBottom = glyphPos.v + glyphPos.height

            // Two triangles per cell (6 vertices), written directly into the buffer
            // Triangle 1: topLeft, topRight, bottomLeft
            buffer[writeIndex] = Vertex(
                position: SIMD2(ndcX, ndcY),
                texCoord: SIMD2(texLeft, texTop),
                foregroundColor: fg, backgroundColor: bg
            )
            buffer[writeIndex + 1] = Vertex(
                position: SIMD2(ndcX + ndcCellW, ndcY),
                texCoord: SIMD2(texRight, texTop),
                foregroundColor: fg, backgroundColor: bg
            )
            buffer[writeIndex + 2] = Vertex(
                position: SIMD2(ndcX, ndcY - ndcCellH),
                texCoord: SIMD2(texLeft, texBottom),
                foregroundColor: fg, backgroundColor: bg
            )
            // Triangle 2: topRight, bottomRight, bottomLeft
            buffer[writeIndex + 3] = Vertex(
                position: SIMD2(ndcX + ndcCellW, ndcY),
                texCoord: SIMD2(texRight, texTop),
                foregroundColor: fg, backgroundColor: bg
            )
            buffer[writeIndex + 4] = Vertex(
                position: SIMD2(ndcX + ndcCellW, ndcY - ndcCellH),
                texCoord: SIMD2(texRight, texBottom),
                foregroundColor: fg, backgroundColor: bg
            )
            buffer[writeIndex + 5] = Vertex(
                position: SIMD2(ndcX, ndcY - ndcCellH),
                texCoord: SIMD2(texLeft, texBottom),
                foregroundColor: fg, backgroundColor: bg
            )

            writeIndex += verticesPerCell
        }

        return writeIndex - offset
    }

    private func colorToSIMD(_ color: TerminalColor) -> SIMD4<Float> {
        switch color {
        case .rgb(let r, let g, let b):
            return SIMD4(Float(r) / 255.0, Float(g) / 255.0, Float(b) / 255.0, 1.0)
        case .ansi(let code):
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

    // MARK: - Embedded Shader Source

    /// Metal shader source compiled at runtime via device.makeLibrary(source:options:).
    /// This is necessary because SPM does not compile .metal files.
    private static let shaderSource = """
    #include <metal_stdlib>
    using namespace metal;

    struct Vertex {
        float2 position;
        float2 texCoord;
        float4 foregroundColor;
        float4 backgroundColor;
    };

    struct VertexOut {
        float4 position [[position]];
        float2 texCoord;
        float4 foregroundColor;
        float4 backgroundColor;
    };

    vertex VertexOut vertexShader(
        const device Vertex* vertices [[buffer(0)]],
        uint vertexId [[vertex_id]]
    ) {
        VertexOut out;
        Vertex v = vertices[vertexId];
        out.position = float4(v.position, 0.0, 1.0);
        out.texCoord = v.texCoord;
        out.foregroundColor = v.foregroundColor;
        out.backgroundColor = v.backgroundColor;
        return out;
    }

    fragment float4 fragmentShader(
        VertexOut in [[stage_in]],
        texture2d<float> glyphAtlas [[texture(0)]]
    ) {
        constexpr sampler texSampler(mag_filter::linear, min_filter::linear);
        float4 glyphSample = glyphAtlas.sample(texSampler, in.texCoord);
        float4 color = mix(in.backgroundColor, in.foregroundColor, glyphSample.a);
        return color;
    }
    """
}

#else

// MARK: - NullRenderer (non-macOS platforms)

public final class NullRenderer: TerminalRenderable {
    public init() {}
    public func render(viewports: [TerminalViewportData]) {}
    public func updateGlyphAtlas(fontFamily: String, fontSize: CGFloat) {}
    public func invalidate() {}
}

#endif
