import AppKit
import WebKit

public final class DroppableWKWebView: WKWebView {
    public var onFileDropped: ((URL) -> Void)?

    public override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        super.init(frame: frame, configuration: configuration)
        registerForDraggedTypes([.fileURL])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        registerForDraggedTypes([.fileURL])
    }

    public override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if getMarkdownFileURL(from: sender.draggingPasteboard) != nil {
            return .copy
        }
        return []
    }

    public override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let url = getMarkdownFileURL(from: sender.draggingPasteboard) else {
            return false
        }
        onFileDropped?(url)
        return true
    }

    private func getMarkdownFileURL(from pasteboard: NSPasteboard) -> URL? {
        guard let items = pasteboard.pasteboardItems else { return nil }
        for item in items {
            if let string = item.string(forType: .fileURL), let url = URL(string: string) {
                let ext = url.pathExtension.lowercased()
                if ["md", "markdown", "mdown", "txt", ""].contains(ext) {
                    return url
                }
            }
        }
        return nil
    }
}
