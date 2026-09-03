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
        if DragDropHelper.extractMarkdownURL(from: sender.draggingPasteboard) != nil {
            return .copy
        }
        return []
    }

    public override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        if DragDropHelper.extractMarkdownURL(from: sender.draggingPasteboard) != nil {
            return .copy
        }
        return []
    }

    public override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let url = DragDropHelper.extractMarkdownURL(from: sender.draggingPasteboard) else {
            return false
        }
        let effective = DragDropHelper.resolveEffectiveURL(for: url)
        onFileDropped?(effective)
        return true
    }
}
