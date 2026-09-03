import AppKit

@MainActor
public final class SidebarViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, NSSearchFieldDelegate {
    private var headerContainer: NSView!
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

    private var allHeadings: [HeadingItem] = []
    private var filteredHeadings: [HeadingItem] = []
    private var filterQuery: String = ""

    public override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 250, height: 600))
        self.view.autoresizingMask = [.width, .height]
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupHeader()
        setupTableView()
        setupStatsFooter()
        setupBindings()
    }

    private func setupHeader() {
        headerContainer = NSView()
        headerContainer.translatesAutoresizingMaskIntoConstraints = false

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

        filterField = NSSearchField()
        filterField.placeholderString = "Filter headings..."
        filterField.delegate = self
        filterField.translatesAutoresizingMaskIntoConstraints = false
        filterField.font = NSFont.systemFont(ofSize: 12)

        headerContainer.addSubview(titleLabel)
        headerContainer.addSubview(countBadge)
        headerContainer.addSubview(filterField)

        view.addSubview(headerContainer)

        NSLayoutConstraint.activate([
            headerContainer.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            headerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 14),
            headerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -14),

            titleLabel.topAnchor.constraint(equalTo: headerContainer.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor),

            countBadge.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            countBadge.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor),
            countBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 22),
            countBadge.heightAnchor.constraint(equalToConstant: 16),

            filterField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            filterField.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor),
            filterField.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor),
            filterField.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor)
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
        let state = DocumentState.shared

        state.onHeadingsUpdated = { [weak self] headings in
            self?.allHeadings = headings
            self?.applyFilter()
        }

        state.onStatsUpdated = { [weak self] in
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
        emptyLabel.isHidden = !filteredHeadings.isEmpty

        tableView.reloadData()
    }

    private func updateStatsUI() {
        let state = DocumentState.shared

        syncStatusDot.layer?.backgroundColor = state.isWatching ? NSColor.systemGreen.cgColor : NSColor.secondaryLabelColor.cgColor
        syncStatusLabel.stringValue = state.isWatching ? "Live Sync Active" : "Static View"
        fileSizeLabel.stringValue = state.formattedFileSize
        wordsLabel.stringValue = "\(state.wordCount) words"
        readTimeLabel.stringValue = "~\(state.readingTimeMinutes) min"
        modifiedLabel.stringValue = state.formattedLastModified.isEmpty ? "" : "Modified: \(state.formattedLastModified)"
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
        DocumentState.shared.scrollTo(headingId: heading.id)
    }

    // MARK: - NSTableViewDataSource & Delegate
    public func numberOfRows(in tableView: NSTableView) -> Int {
        return filteredHeadings.count
    }

    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < filteredHeadings.count else { return nil }
        let heading = filteredHeadings[row]

        let cellId = NSUserInterfaceItemIdentifier("HeadingCell")
        var cellView = tableView.makeView(withIdentifier: cellId, owner: self) as? NSTableCellView

        if cellView == nil {
            cellView = NSTableCellView()
            cellView?.identifier = cellId

            let textField = NSTextField(labelWithString: "")
            textField.translatesAutoresizingMaskIntoConstraints = false
            textField.lineBreakMode = .byTruncatingTail
            cellView?.addSubview(textField)
            cellView?.textField = textField

            NSLayoutConstraint.activate([
                textField.leadingAnchor.constraint(equalTo: cellView!.leadingAnchor),
                textField.trailingAnchor.constraint(equalTo: cellView!.trailingAnchor, constant: -4),
                textField.centerYAnchor.constraint(equalTo: cellView!.centerYAnchor)
            ])
        }

        let indent = CGFloat(max(0, heading.level - 1)) * 12
        cellView?.textField?.stringValue = heading.title

        switch heading.level {
        case 1:
            cellView?.textField?.font = NSFont.systemFont(ofSize: 12.5, weight: .semibold)
            cellView?.textField?.textColor = .labelColor
        case 2:
            cellView?.textField?.font = NSFont.systemFont(ofSize: 12, weight: .medium)
            cellView?.textField?.textColor = .labelColor
        default:
            cellView?.textField?.font = NSFont.systemFont(ofSize: 11.5, weight: .regular)
            cellView?.textField?.textColor = .secondaryLabelColor
        }

        // Apply indentation constraint
        if cellView?.textField != nil {
            for constraint in cellView!.constraints where constraint.firstAttribute == .leading {
                constraint.constant = indent + 6
            }
        }

        return cellView
    }
}
