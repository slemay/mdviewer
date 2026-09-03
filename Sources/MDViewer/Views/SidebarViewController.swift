import AppKit

@MainActor
public final class SidebarViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, NSSearchFieldDelegate {
    private var headerContainer: NSStackView!
    private var headerTopConstraint: NSLayoutConstraint!
    private var filterField: NSSearchField!
    private var countBadge: NSTextField!
    private var scrollView: NSScrollView!
    private var tableView: NSTableView!
    private var emptyLabel: NSTextField!

    // Bottom Stats Views
    private var statsContainer: NSVisualEffectView!
    private var syncStatusDot: NSView!
    private var syncStatusLabel: NSTextField!
    private var fileSizeLabel: NSTextField!
    private var wordsLabel: NSTextField!
    private var readTimeLabel: NSTextField!
    private var modifiedLabel: NSTextField!

    public let documentState: DocumentState

    private var allHeadings: [HeadingItem] = []
    private var filteredHeadings: [HeadingItem] = []
    private var filterQuery: String = ""

    public init(documentState: DocumentState) {
        self.documentState = documentState
        super.init(nibName: nil, bundle: nil)
    }

    public convenience init() {
        self.init(documentState: DocumentState.shared)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func loadView() {
        let container = SidebarDropView(frame: NSRect(x: 0, y: 0, width: 250, height: 600))
        container.autoresizingMask = [.width, .height]
        container.onFileDropped = { [weak self] url in
            self?.documentState.openFile(url: url)
        }
        self.view = container
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupHeader()
        setupTableView()
        setupStatsFooter()
        setupBindings()

        // Populate initial headings and statistics if document already loaded
        if !documentState.headings.isEmpty {
            self.allHeadings = documentState.headings
            self.applyFilter()
        }
        self.updateStatsUI()
    }

    public override func viewWillAppear() {
        super.viewWillAppear()
        NotificationCenter.default.addObserver(self, selector: #selector(windowDidEnterFullScreen), name: NSWindow.didEnterFullScreenNotification, object: view.window)
        NotificationCenter.default.addObserver(self, selector: #selector(windowDidExitFullScreen), name: NSWindow.didExitFullScreenNotification, object: view.window)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func windowDidEnterFullScreen() {
        headerTopConstraint?.constant = 16
    }

    @objc private func windowDidExitFullScreen() {
        headerTopConstraint?.constant = 52
    }

    private func setupHeader() {
        headerContainer = NSStackView()
        headerContainer.orientation = .vertical
        headerContainer.alignment = .leading
        headerContainer.spacing = 8
        headerContainer.translatesAutoresizingMaskIntoConstraints = false

        // Row 1: Title & Badge
        let titleRow = NSStackView()
        titleRow.orientation = .horizontal
        titleRow.alignment = .centerY
        titleRow.spacing = 8
        titleRow.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = NSTextField(labelWithString: "Outline")
        titleLabel.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        countBadge = NSTextField(labelWithString: "0")
        countBadge.font = NSFont.systemFont(ofSize: 10, weight: .bold)
        countBadge.textColor = .secondaryLabelColor
        countBadge.alignment = .center
        countBadge.wantsLayer = true
        countBadge.layer?.backgroundColor = NSColor.secondaryLabelColor.withAlphaComponent(0.15).cgColor
        countBadge.layer?.cornerRadius = 8
        countBadge.translatesAutoresizingMaskIntoConstraints = false
        countBadge.isHidden = true

        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.translatesAutoresizingMaskIntoConstraints = false

        titleRow.addArrangedSubview(titleLabel)
        titleRow.addArrangedSubview(spacer)
        titleRow.addArrangedSubview(countBadge)

        // Row 2: Filter Field
        filterField = NSSearchField()
        filterField.placeholderString = "Filter headings..."
        filterField.delegate = self
        filterField.translatesAutoresizingMaskIntoConstraints = false
        filterField.font = NSFont.systemFont(ofSize: 12)
        filterField.isHidden = true

        headerContainer.addArrangedSubview(titleRow)
        headerContainer.addArrangedSubview(filterField)

        view.addSubview(headerContainer)

        // Top offset of 52 ensures clean spacing below macOS traffic light buttons
        headerTopConstraint = headerContainer.topAnchor.constraint(equalTo: view.topAnchor, constant: 52)

        NSLayoutConstraint.activate([
            headerTopConstraint,
            headerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 14),
            headerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -14),
            titleRow.widthAnchor.constraint(equalTo: headerContainer.widthAnchor),
            filterField.widthAnchor.constraint(equalTo: headerContainer.widthAnchor)
        ])
    }

    private func setupTableView() {
        scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false

        tableView = NSTableView()
        tableView.headerView = nil
        tableView.style = .sourceList
        tableView.rowHeight = 26
        tableView.intercellSpacing = NSSize(width: 0, height: 2)
        tableView.backgroundColor = .clear

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("HeadingColumn"))
        column.resizingMask = .autoresizingMask
        tableView.addTableColumn(column)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.target = self
        tableView.action = #selector(tableRowClicked)

        scrollView.documentView = tableView
        view.addSubview(scrollView)

        emptyLabel = NSTextField(labelWithString: "No Headings Found")
        emptyLabel.font = NSFont.systemFont(ofSize: 12)
        emptyLabel.textColor = .secondaryLabelColor
        emptyLabel.alignment = .center
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.isHidden = true
        view.addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func setupStatsFooter() {
        statsContainer = NSVisualEffectView()
        statsContainer.material = .sidebar
        statsContainer.blendingMode = .withinWindow
        statsContainer.state = .active
        statsContainer.translatesAutoresizingMaskIntoConstraints = false
        statsContainer.wantsLayer = true
        statsContainer.layer?.borderWidth = 1
        statsContainer.layer?.borderColor = NSColor.separatorColor.cgColor

        let divider = NSBox()
        divider.boxType = .separator
        divider.translatesAutoresizingMaskIntoConstraints = false
        statsContainer.addSubview(divider)

        syncStatusDot = NSView()
        syncStatusDot.wantsLayer = true
        syncStatusDot.layer?.cornerRadius = 3.5
        syncStatusDot.layer?.backgroundColor = NSColor.systemGreen.cgColor
        syncStatusDot.translatesAutoresizingMaskIntoConstraints = false

        syncStatusLabel = NSTextField(labelWithString: "Live Sync Active")
        syncStatusLabel.font = NSFont.systemFont(ofSize: 10.5, weight: .medium)
        syncStatusLabel.textColor = .secondaryLabelColor
        syncStatusLabel.translatesAutoresizingMaskIntoConstraints = false

        fileSizeLabel = NSTextField(labelWithString: "0 B")
        fileSizeLabel.font = NSFont.systemFont(ofSize: 10.5)
        fileSizeLabel.textColor = .secondaryLabelColor
        fileSizeLabel.alignment = .right
        fileSizeLabel.translatesAutoresizingMaskIntoConstraints = false

        wordsLabel = NSTextField(labelWithString: "0 words")
        wordsLabel.font = NSFont.systemFont(ofSize: 11)
        wordsLabel.textColor = .labelColor
        wordsLabel.translatesAutoresizingMaskIntoConstraints = false

        readTimeLabel = NSTextField(labelWithString: "~0 min")
        readTimeLabel.font = NSFont.systemFont(ofSize: 11)
        readTimeLabel.textColor = .secondaryLabelColor
        readTimeLabel.alignment = .right
        readTimeLabel.translatesAutoresizingMaskIntoConstraints = false

        modifiedLabel = NSTextField(labelWithString: "")
        modifiedLabel.font = NSFont.systemFont(ofSize: 9.5)
        modifiedLabel.textColor = .tertiaryLabelColor
        modifiedLabel.lineBreakMode = .byTruncatingTail
        modifiedLabel.translatesAutoresizingMaskIntoConstraints = false

        statsContainer.addSubview(syncStatusDot)
        statsContainer.addSubview(syncStatusLabel)
        statsContainer.addSubview(fileSizeLabel)
        statsContainer.addSubview(wordsLabel)
        statsContainer.addSubview(readTimeLabel)
        statsContainer.addSubview(modifiedLabel)

        view.addSubview(statsContainer)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: 10),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: statsContainer.topAnchor),

            statsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            statsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            statsContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            statsContainer.heightAnchor.constraint(equalToConstant: 74),

            divider.topAnchor.constraint(equalTo: statsContainer.topAnchor),
            divider.leadingAnchor.constraint(equalTo: statsContainer.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: statsContainer.trailingAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1),

            syncStatusDot.leadingAnchor.constraint(equalTo: statsContainer.leadingAnchor, constant: 12),
            syncStatusDot.topAnchor.constraint(equalTo: statsContainer.topAnchor, constant: 10),
            syncStatusDot.widthAnchor.constraint(equalToConstant: 7),
            syncStatusDot.heightAnchor.constraint(equalToConstant: 7),

            syncStatusLabel.centerYAnchor.constraint(equalTo: syncStatusDot.centerYAnchor),
            syncStatusLabel.leadingAnchor.constraint(equalTo: syncStatusDot.trailingAnchor, constant: 6),

            fileSizeLabel.centerYAnchor.constraint(equalTo: syncStatusDot.centerYAnchor),
            fileSizeLabel.trailingAnchor.constraint(equalTo: statsContainer.trailingAnchor, constant: -12),

            wordsLabel.topAnchor.constraint(equalTo: syncStatusLabel.bottomAnchor, constant: 6),
            wordsLabel.leadingAnchor.constraint(equalTo: statsContainer.leadingAnchor, constant: 12),

            readTimeLabel.centerYAnchor.constraint(equalTo: wordsLabel.centerYAnchor),
            readTimeLabel.trailingAnchor.constraint(equalTo: statsContainer.trailingAnchor, constant: -12),

            modifiedLabel.topAnchor.constraint(equalTo: wordsLabel.bottomAnchor, constant: 4),
            modifiedLabel.leadingAnchor.constraint(equalTo: statsContainer.leadingAnchor, constant: 12),
            modifiedLabel.trailingAnchor.constraint(equalTo: statsContainer.trailingAnchor, constant: -12)
        ])
    }

    private func setupBindings() {
        documentState.onHeadingsUpdated = { [weak self] headings in
            self?.allHeadings = headings
            self?.applyFilter()
        }

        documentState.onStatsUpdated = { [weak self] in
            self?.updateStatsUI()
        }
    }

    private func applyFilter() {
        if filterQuery.trimmingCharacters(in: .whitespaces).isEmpty {
            filteredHeadings = allHeadings
        } else {
            filteredHeadings = allHeadings.filter {
                $0.title.localizedCaseInsensitiveContains(filterQuery)
            }
        }

        countBadge.stringValue = "\(allHeadings.count)"
        countBadge.isHidden = allHeadings.isEmpty
        filterField.isHidden = allHeadings.count < 5
        emptyLabel.isHidden = !filteredHeadings.isEmpty

        tableView.reloadData()
    }

    private func updateStatsUI() {
        syncStatusDot.layer?.backgroundColor = documentState.isWatching ? NSColor.systemGreen.cgColor : NSColor.secondaryLabelColor.cgColor
        syncStatusLabel.stringValue = documentState.isWatching ? "Live Sync Active" : "Static View"
        fileSizeLabel.stringValue = documentState.formattedFileSize
        wordsLabel.stringValue = "\(documentState.wordCount) words"
        readTimeLabel.stringValue = "~\(documentState.readingTimeMinutes) min"
        modifiedLabel.stringValue = documentState.formattedLastModified.isEmpty ? "" : "Modified: \(documentState.formattedLastModified)"
    }

    public func controlTextDidChange(_ obj: Notification) {
        if let field = obj.object as? NSSearchField, field == filterField {
            filterQuery = field.stringValue
            applyFilter()
        }
    }

    @objc private func tableRowClicked() {
        let row = tableView.clickedRow
        guard row >= 0, row < filteredHeadings.count else { return }
        let heading = filteredHeadings[row]
        documentState.scrollTo(headingId: heading.id)
    }

    // MARK: - NSTableViewDataSource & Delegate
    public func numberOfRows(in tableView: NSTableView) -> Int {
        return filteredHeadings.count
    }

    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < filteredHeadings.count else { return nil }
        let heading = filteredHeadings[row]

        let cellId = NSUserInterfaceItemIdentifier("HeadingCell")
        let cellView = (tableView.makeView(withIdentifier: cellId, owner: self) as? HeadingTableCellView)
            ?? HeadingTableCellView(frame: NSRect(x: 0, y: 0, width: 240, height: 26))
        cellView.identifier = cellId
        cellView.configure(with: heading)
        return cellView
    }
}

// MARK: - Dedicated Outline Cell View
final class HeadingTableCellView: NSTableCellView {
    private var leadingConstraint: NSLayoutConstraint!

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        let tf = NSTextField(labelWithString: "")
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.lineBreakMode = .byTruncatingTail
        addSubview(tf)
        self.textField = tf

        leadingConstraint = tf.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6)
        NSLayoutConstraint.activate([
            leadingConstraint,
            tf.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            tf.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    func configure(with heading: HeadingItem) {
        let indent = CGFloat(max(0, heading.level - 1)) * 12
        leadingConstraint.constant = indent + 6
        textField?.stringValue = heading.title

        switch heading.level {
        case 1:
            textField?.font = NSFont.systemFont(ofSize: 12.5, weight: .semibold)
            textField?.textColor = .labelColor
        case 2:
            textField?.font = NSFont.systemFont(ofSize: 12, weight: .medium)
            textField?.textColor = .labelColor
        default:
            textField?.font = NSFont.systemFont(ofSize: 11.5, weight: .regular)
            textField?.textColor = .secondaryLabelColor
        }
    }
}

// MARK: - Dedicated Sidebar Drop View
final class SidebarDropView: NSView {
    var onFileDropped: ((URL) -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([.fileURL])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        registerForDraggedTypes([.fileURL])
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if DragDropHelper.extractMarkdownURL(from: sender.draggingPasteboard) != nil {
            return .copy
        }
        return []
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        if DragDropHelper.extractMarkdownURL(from: sender.draggingPasteboard) != nil {
            return .copy
        }
        return []
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let url = DragDropHelper.extractMarkdownURL(from: sender.draggingPasteboard) else {
            return false
        }
        let effective = DragDropHelper.resolveEffectiveURL(for: url)
        onFileDropped?(effective)
        return true
    }
}
