import AppKit

public final class DroppableContainerView: NSView {
    public var onFileDropped: ((URL) -> Void)?
    private var dropOverlay: NSVisualEffectView!

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        registerForDraggedTypes([.fileURL])

        // Visual drop overlay indicator
        dropOverlay = NSVisualEffectView()
        dropOverlay.material = .hudWindow
        dropOverlay.blendingMode = .withinWindow
        dropOverlay.state = .active
        dropOverlay.wantsLayer = true
        dropOverlay.layer?.cornerRadius = 16
        dropOverlay.layer?.borderWidth = 2
        dropOverlay.layer?.borderColor = NSColor.controlAccentColor.cgColor
        dropOverlay.translatesAutoresizingMaskIntoConstraints = false
        dropOverlay.isHidden = true

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        let iconView = NSImageView(image: NSImage(systemSymbolName: "arrow.down.doc.fill", accessibilityDescription: "Drop File")!)
        iconView.symbolConfiguration = .init(pointSize: 44, weight: .medium)
        iconView.contentTintColor = .controlAccentColor

        let label = NSTextField(labelWithString: "Drop Markdown File to Open")
        label.font = NSFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .labelColor

        stack.addArrangedSubview(iconView)
        stack.addArrangedSubview(label)
        dropOverlay.addSubview(stack)

        addSubview(dropOverlay, positioned: .above, relativeTo: nil)

        NSLayoutConstraint.activate([
            dropOverlay.centerXAnchor.constraint(equalTo: centerXAnchor),
            dropOverlay.centerYAnchor.constraint(equalTo: centerYAnchor),
            dropOverlay.widthAnchor.constraint(equalToConstant: 280),
            dropOverlay.heightAnchor.constraint(equalToConstant: 160),

            stack.centerXAnchor.constraint(equalTo: dropOverlay.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: dropOverlay.centerYAnchor)
        ])
    }

    public override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if DragDropHelper.extractMarkdownURL(from: sender.draggingPasteboard) != nil {
            dropOverlay.isHidden = false
            return .copy
        }
        return []
    }

    public override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        if DragDropHelper.extractMarkdownURL(from: sender.draggingPasteboard) != nil {
            dropOverlay.isHidden = false
            return .copy
        }
        return []
    }

    public override func draggingExited(_ sender: NSDraggingInfo?) {
        dropOverlay.isHidden = true
    }

    public override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        dropOverlay.isHidden = true
        guard let url = DragDropHelper.extractMarkdownURL(from: sender.draggingPasteboard) else {
            return false
        }
        let effective = DragDropHelper.resolveEffectiveURL(for: url)
        onFileDropped?(effective)
        return true
    }
}
