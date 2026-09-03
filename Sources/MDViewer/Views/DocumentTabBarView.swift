import AppKit

// MARK: - DocumentTab Model
@MainActor
public final class DocumentTab: Equatable {
    public let id = UUID()
    public var documentState: DocumentState

    public init(documentState: DocumentState) {
        self.documentState = documentState
    }

    public convenience init() {
        self.init(documentState: DocumentState())
    }

    public nonisolated static func == (lhs: DocumentTab, rhs: DocumentTab) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - DocumentTabItemView
@MainActor
public final class DocumentTabItemView: NSView {
    public let tab: DocumentTab
    public var isActive: Bool = false {
        didSet { updateAppearance() }
    }

    public var onSelect: (() -> Void)?
    public var onClose: (() -> Void)?

    private var iconView: NSImageView!
    private var titleLabel: NSTextField!
    private var closeButton: NSButton!
    private var topAccentBar: NSView!
    private var rightDivider: NSView!
    private var isHovered: Bool = false {
        didSet { updateAppearance() }
    }
    private var trackingArea: NSTrackingArea?

    public init(tab: DocumentTab) {
        self.tab = tab
        super.init(frame: .zero)
        setupViews()
        updateAppearance()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeInActiveApp, .inVisibleRect]
        let area = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(area)
        self.trackingArea = area
    }

    public override func mouseEntered(with event: NSEvent) {
        isHovered = true
    }

    public override func mouseExited(with event: NSEvent) {
        isHovered = false
    }

    public override func mouseDown(with event: NSEvent) {
        onSelect?()
    }

    private func setupViews() {
        wantsLayer = true
        layer?.cornerRadius = 7
        layer?.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        // Top Accent Bar (shows active color indicator like modern IDEs)
        topAccentBar = NSView()
        topAccentBar.wantsLayer = true
        topAccentBar.layer?.backgroundColor = NSColor.controlAccentColor.cgColor
        topAccentBar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(topAccentBar)

        // Document Icon
        iconView = NSImageView()
        iconView.imageScaling = .scaleProportionallyDown
        iconView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconView)

        // Title Label
        titleLabel = NSTextField(labelWithString: tab.documentState.fileName)
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        // Close Button
        closeButton = NSButton()
        closeButton.isBordered = false
        closeButton.title = ""
        let closeImg = NSImage(systemSymbolName: "xmark", accessibilityDescription: "Close Tab")?
            .withSymbolConfiguration(.init(pointSize: 9.5, weight: .bold))
        closeButton.image = closeImg
        closeButton.contentTintColor = .secondaryLabelColor
        closeButton.target = self
        closeButton.action = #selector(closeClicked)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(closeButton)

        // Right Divider Line (for inactive tabs)
        rightDivider = NSView()
        rightDivider.wantsLayer = true
        rightDivider.layer?.backgroundColor = NSColor.separatorColor.cgColor
        rightDivider.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rightDivider)

        NSLayoutConstraint.activate([
            topAccentBar.topAnchor.constraint(equalTo: topAnchor),
            topAccentBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            topAccentBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            topAccentBar.heightAnchor.constraint(equalToConstant: 2.5),

            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 14),
            iconView.heightAnchor.constraint(equalToConstant: 14),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 6),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -4),

            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            closeButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 16),
            closeButton.heightAnchor.constraint(equalToConstant: 16),

            rightDivider.trailingAnchor.constraint(equalTo: trailingAnchor),
            rightDivider.centerYAnchor.constraint(equalTo: centerYAnchor),
            rightDivider.widthAnchor.constraint(equalToConstant: 1),
            rightDivider.heightAnchor.constraint(equalToConstant: 14),

            widthAnchor.constraint(greaterThanOrEqualToConstant: 130),
            widthAnchor.constraint(lessThanOrEqualToConstant: 220)
        ])
    }

    public func updateTitle(_ title: String) {
        titleLabel.stringValue = title
        toolTip = tab.documentState.fileURL?.path ?? title
    }

    private func updateAppearance() {
        titleLabel.stringValue = tab.documentState.fileName
        toolTip = tab.documentState.fileURL?.path ?? tab.documentState.fileName

        if isActive {
            // Authentic elevated active card styling
            layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
            layer?.borderWidth = 1
            layer?.borderColor = NSColor.separatorColor.withAlphaComponent(0.7).cgColor

            topAccentBar.isHidden = false
            rightDivider.isHidden = true

            titleLabel.font = NSFont.systemFont(ofSize: 11.5, weight: .semibold)
            titleLabel.textColor = .labelColor

            let activeIcon = NSImage(systemSymbolName: "doc.text.fill", accessibilityDescription: nil)
            iconView.image = activeIcon
            iconView.contentTintColor = .controlAccentColor

            closeButton.isHidden = false
            closeButton.contentTintColor = .secondaryLabelColor

            // Subtle drop shadow
            shadow = NSShadow()
            shadow?.shadowColor = NSColor.black.withAlphaComponent(0.08)
            shadow?.shadowOffset = NSSize(width: 0, height: -1)
            shadow?.shadowBlurRadius = 2
        } else {
            // Inactive recessed tab styling
            topAccentBar.isHidden = true
            rightDivider.isHidden = false
            shadow = nil

            if isHovered {
                layer?.backgroundColor = NSColor.quaternaryLabelColor.withAlphaComponent(0.35).cgColor
                layer?.borderWidth = 0.5
                layer?.borderColor = NSColor.separatorColor.withAlphaComponent(0.3).cgColor
            } else {
                layer?.backgroundColor = NSColor.clear.cgColor
                layer?.borderWidth = 0
            }

            titleLabel.font = NSFont.systemFont(ofSize: 11.5, weight: .regular)
            titleLabel.textColor = .secondaryLabelColor

            let inactiveIcon = NSImage(systemSymbolName: "doc.text", accessibilityDescription: nil)
            iconView.image = inactiveIcon
            iconView.contentTintColor = .secondaryLabelColor

            closeButton.isHidden = !isHovered
            closeButton.contentTintColor = .tertiaryLabelColor
        }
    }

    @objc private func closeClicked() {
        onClose?()
    }
}

// MARK: - DocumentTabBarView
@MainActor
public final class DocumentTabBarView: NSVisualEffectView {
    public var onSelectTab: ((Int) -> Void)?
    public var onCloseTab: ((Int) -> Void)?
    public var onNewTab: (() -> Void)?
    public var onFileDropped: ((URL) -> Void)?

    private var tabsStack: NSStackView!
    private var scrollView: NSScrollView!
    private var addTabButton: NSButton!
    private var bottomBorder: NSView!

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        material = .headerView
        blendingMode = .withinWindow
        state = .active
        wantsLayer = true

        // Register for file drag-and-drop onto the tab bar
        registerForDraggedTypes([.fileURL])

        // Bottom separator border
        bottomBorder = NSView()
        bottomBorder.wantsLayer = true
        bottomBorder.layer?.backgroundColor = NSColor.separatorColor.cgColor
        bottomBorder.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bottomBorder)

        // Add Tab (+) Button
        addTabButton = NSButton()
        addTabButton.isBordered = false
        addTabButton.title = ""
        let plusImg = NSImage(systemSymbolName: "plus", accessibilityDescription: "New Tab")?
            .withSymbolConfiguration(.init(pointSize: 11, weight: .semibold))
        addTabButton.image = plusImg
        addTabButton.contentTintColor = .secondaryLabelColor
        addTabButton.toolTip = "New Tab / Open Markdown File (Cmd+T)"
        addTabButton.target = self
        addTabButton.action = #selector(addTabClicked)
        addTabButton.wantsLayer = true
        addTabButton.layer?.cornerRadius = 5
        addTabButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(addTabButton)

        // Tabs Stack inside Scroll View
        tabsStack = NSStackView()
        tabsStack.orientation = .horizontal
        tabsStack.alignment = .bottom
        tabsStack.spacing = 1
        tabsStack.translatesAutoresizingMaskIntoConstraints = false

        scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.hasHorizontalScroller = false
        scrollView.hasVerticalScroller = false
        scrollView.documentView = tabsStack
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)

        NSLayoutConstraint.activate([
            bottomBorder.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomBorder.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomBorder.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomBorder.heightAnchor.constraint(equalToConstant: 1),

            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.trailingAnchor.constraint(equalTo: addTabButton.leadingAnchor, constant: -6),

            tabsStack.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor),
            tabsStack.topAnchor.constraint(equalTo: scrollView.contentView.topAnchor),
            tabsStack.bottomAnchor.constraint(equalTo: scrollView.contentView.bottomAnchor),

            addTabButton.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -8),
            addTabButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            addTabButton.widthAnchor.constraint(equalToConstant: 24),
            addTabButton.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    public func reload(tabs: [DocumentTab], activeIndex: Int) {
        tabsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for (idx, tab) in tabs.enumerated() {
            let itemView = DocumentTabItemView(tab: tab)
            itemView.isActive = (idx == activeIndex)
            itemView.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                itemView.heightAnchor.constraint(equalToConstant: 32)
            ])

            itemView.onSelect = { [weak self] in
                self?.onSelectTab?(idx)
            }

            itemView.onClose = { [weak self] in
                self?.onCloseTab?(idx)
            }

            tabsStack.addArrangedSubview(itemView)
        }
    }

    @objc private func addTabClicked() {
        onNewTab?()
    }

    // MARK: - Drag & Drop Destination
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
