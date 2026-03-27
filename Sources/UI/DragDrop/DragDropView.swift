// MARK: - Drag & Drop System (Step 17.1)
// File and image drag-and-drop into agent sessions.

import SwiftUI
import AgentsBoardCore
import UniformTypeIdentifiers

/// Represents a file attachment for an agent session.
struct FileAttachment: Identifiable {
    let id = UUID()
    let path: String
    let filename: String
    let fileType: UTType?
    let size: Int64
    let isImage: Bool
    #if canImport(AppKit)
    var thumbnailImage: NSImage?
    #endif
}

/// Processes dropped files into agent-compatible format.
struct AttachmentProcessor {

    func process(urls: [URL]) -> [FileAttachment] {
        urls.compactMap { url in
            guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
                  let size = attrs[.size] as? Int64 else { return nil }

            let ext = url.pathExtension.lowercased()
            let isImage = ["png", "jpg", "jpeg", "gif", "svg", "webp"].contains(ext)
            let fileType = UTType(filenameExtension: ext)

            #if canImport(AppKit)
            let thumbnail = isImage ? NSImage(contentsOf: url) : nil
            return FileAttachment(
                path: url.path,
                filename: url.lastPathComponent,
                fileType: fileType,
                size: size,
                isImage: isImage,
                thumbnailImage: thumbnail
            )
            #else
            return FileAttachment(
                path: url.path,
                filename: url.lastPathComponent,
                fileType: fileType,
                size: size,
                isImage: isImage
            )
            #endif
        }
    }

    /// Converts attachments to the format expected by each provider.
    func formatForProvider(_ attachment: FileAttachment, provider: AgentProvider) -> String {
        ShellPathEscaper.formatForProvider(
            attachment.path,
            isImage: attachment.isImage,
            providerName: provider == .claude ? "claude" : "other"
        )
    }
}

/// Drop zone overlay on session cards.
struct DropZoneView: View {
    let isTargeted: Bool
    let isValid: Bool

    var body: some View {
        if isTargeted {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    isValid ? Color.green : Color.red,
                    style: StrokeStyle(lineWidth: 2, dash: [8])
                )
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isValid ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                )
                .overlay {
                    VStack(spacing: 8) {
                        Image(systemName: isValid ? "arrow.down.doc" : "xmark.circle")
                            .font(.title)
                            .foregroundStyle(isValid ? .green : .red)
                        Text(isValid ? L10n.Drop.dropHere : L10n.Drop.unsupported)
                            .font(.callout)
                            .foregroundStyle(isValid ? .green : .red)
                    }
                }
        }
    }
}

/// Drop zone overlay specifically for terminal areas.
struct TerminalDropZoneView: View {
    let isTargeted: Bool

    var body: some View {
        if isTargeted {
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(
                    Color.green,
                    style: StrokeStyle(lineWidth: 2, dash: [6])
                )
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.green.opacity(0.08))
                )
                .overlay {
                    VStack(spacing: 6) {
                        Image(systemName: "arrow.down.doc.fill")
                            .font(.title2)
                            .foregroundStyle(.green)
                        Text(L10n.Drop.dropFilesToTerminal)
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
                .allowsHitTesting(false)
        }
    }
}

/// Preview of attachments before sending.
struct AttachmentPreviewView: View {
    let attachments: [FileAttachment]
    let onRemove: (UUID) -> Void
    let onSend: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("\(attachments.count) \(L10n.Drop.filesAttached)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button(L10n.send) { onSend() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(attachments) { attachment in
                        AttachmentChip(attachment: attachment) {
                            onRemove(attachment.id)
                        }
                    }
                }
            }
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct AttachmentChip: View {
    let attachment: FileAttachment
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            #if canImport(AppKit)
            if let thumb = attachment.thumbnailImage {
                Image(nsImage: thumb)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                Image(systemName: "doc")
                    .font(.caption)
            }
            #else
            Image(systemName: attachment.isImage ? "photo" : "doc")
                .font(.caption)
            #endif
            Text(attachment.filename)
                .font(.caption)
                .lineLimit(1)
            Button { onRemove() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
}
