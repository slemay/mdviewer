import Foundation

@MainActor
public final class DocumentState {
    public static let shared = DocumentState()

    // Current Document
    public var fileURL: URL?
    public var fileName: String = "Untitled"
    public var rawContent: String = ""
    public var lastModified: Date?
    public var fileSize: Int64 = 0
    public var isWatching: Bool = false

    // Appearance
    public var theme: AppTheme = .system {
        didSet { onThemeUpdated?(theme) }
    }
    public var fontFamily: AppFontFamily = .sans {
        didSet { onFontUpdated?(fontFamily, fontSize) }
    }
    public var fontSize: Double = 16.0 {
        didSet { onFontUpdated?(fontFamily, fontSize) }
    }

    // Outline & Stats
    public var headings: [HeadingItem] = []
    public var wordCount: Int = 0
    public var charCount: Int = 0
    public var readingTimeMinutes: Int = 0

    // Search
    public var searchQuery: String = ""
    public var searchMatchCount: Int = 0
    public var searchMatchIndex: Int = -1

    // Callbacks
    public var onDocumentLoaded: ((_ content: String, _ preserveScroll: Bool) -> Void)?
    public var onMetadataChanged: ((_ fileName: String, _ fileURL: URL?) -> Void)?
    public var onHeadingsUpdated: (([HeadingItem]) -> Void)?
    public var onStatsUpdated: (() -> Void)?
    public var onThemeUpdated: ((AppTheme) -> Void)?
    public var onFontUpdated: ((AppFontFamily, Double) -> Void)?
    public var onScrollToHeading: ((String) -> Void)?
    public var onSearchRequested: ((String) -> Void)?
    public var onSearchNext: (() -> Void)?
    public var onSearchPrev: (() -> Void)?
    public var onSearchResultsChanged: ((_ count: Int, _ currentIndex: Int) -> Void)?

    private var fileWatcher: FileWatcher?

    public init() {}

    public var formattedFileSize: String {
        guard fileSize > 0 else { return "0 B" }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }

    public var formattedLastModified: String {
        guard let date = lastModified else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    public func openFile(url: URL) {
        stopWatching()

        self.fileURL = url
        self.fileName = url.lastPathComponent
        onMetadataChanged?(self.fileName, self.fileURL)

        reloadCurrentFile(preserveScroll: false)
        startWatching(url: url)
    }

    public func reloadCurrentFile(preserveScroll: Bool = true) {
        guard let url = fileURL else { return }

        do {
            let data = try Data(contentsOf: url)
            guard let content = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) else {
                return
            }

            self.rawContent = content

            if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path) {
                self.fileSize = attributes[.size] as? Int64 ?? 0
                self.lastModified = attributes[.modificationDate] as? Date
            }

            let stats = TOCParser.parse(markdown: content)
            self.headings = stats.headings
            self.wordCount = stats.wordCount
            self.charCount = stats.charCount
            self.readingTimeMinutes = stats.readingTimeMinutes

            onMetadataChanged?(self.fileName, self.fileURL)
            onHeadingsUpdated?(self.headings)
            onStatsUpdated?()
            onDocumentLoaded?(content, preserveScroll)
        } catch {
            print("Error loading markdown file: \(error)")
        }
    }

    private func startWatching(url: URL) {
        let watcher = FileWatcher(url: url)
        watcher.onChange = { [weak self] in
            Task { @MainActor in
                self?.reloadCurrentFile(preserveScroll: true)
            }
        }
        watcher.start()
        self.fileWatcher = watcher
        self.isWatching = true
        onStatsUpdated?()
    }

    public func stopWatching() {
        fileWatcher?.stop()
        fileWatcher = nil
        isWatching = false
        onStatsUpdated?()
    }

    public func zoomIn() {
        if fontSize < 32.0 {
            fontSize += 1.5
        }
    }

    public func zoomOut() {
        if fontSize > 11.0 {
            fontSize -= 1.5
        }
    }

    public func resetZoom() {
        fontSize = 16.0
    }

    public func scrollTo(headingId: String) {
        onScrollToHeading?(headingId)
    }

    public func setSearch(query: String) {
        self.searchQuery = query
        onSearchRequested?(query)
    }

    public func searchNext() {
        onSearchNext?()
    }

    public func searchPrev() {
        onSearchPrev?()
    }

    public func updateSearchResults(count: Int, index: Int) {
        self.searchMatchCount = count
        self.searchMatchIndex = index
        onSearchResultsChanged?(count, index)
    }
}
