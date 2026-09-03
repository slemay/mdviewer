import AppKit
import WebKit

@MainActor
public final class ContentViewController: NSViewController, WKNavigationDelegate, WKScriptMessageHandler, NSSearchFieldDelegate {
    public private(set) var webView: DroppableWKWebView!
    private var searchOverlay: NSVisualEffectView!
    private var searchField: NSSearchField!
    private var searchCounterLabel: NSTextField!
    private var prevSearchButton: NSButton!
    private var nextSearchButton: NSButton!
    private var closeSearchButton: NSButton!

    private var isIndexLoaded = false
    private var pendingRender: (content: String, preserveScroll: Bool)?

    public override func loadView() {
        let container = DroppableContainerView(frame: NSRect(x: 0, y: 0, width: 640, height: 480))
        container.autoresizingMask = [.width, .height]
        container.onFileDropped = { url in
            DocumentState.shared.openFile(url: url)
        }
        self.view = container
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        setupSearchOverlay()
        setupBindings()
        loadIndexHTML()
    }

    private func setupWebView() {
        let config = WKWebViewConfiguration()
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs

        let contentController = WKUserContentController()
        contentController.add(self, name: "openExternalURL")
        contentController.add(self, name: "logMessage")
        config.userContentController = contentController

        webView = DroppableWKWebView(frame: view.bounds, configuration: config)
        webView.autoresizingMask = [.width, .height]
        webView.navigationDelegate = self
        webView.setValue(false, forKey: "drawsBackground")

        webView.onFileDropped = { url in
            DocumentState.shared.openFile(url: url)
        }

        view.addSubview(webView)
    }

    private func setupSearchOverlay() {
        searchOverlay = NSVisualEffectView()
        searchOverlay.material = .hudWindow
        searchOverlay.blendingMode = .withinWindow
        searchOverlay.state = .active
        searchOverlay.wantsLayer = true
        searchOverlay.layer?.cornerRadius = 8
        searchOverlay.layer?.borderWidth = 1
        searchOverlay.layer?.borderColor = NSColor.separatorColor.cgColor
        searchOverlay.translatesAutoresizingMaskIntoConstraints = false
        searchOverlay.isHidden = true

        searchField = NSSearchField()
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.placeholderString = "Find in page..."
        searchField.delegate = self
        searchField.target = self
        searchField.action = #selector(searchFieldAction(_:))

        searchCounterLabel = NSTextField(labelWithString: "")
        searchCounterLabel.translatesAutoresizingMaskIntoConstraints = false
        searchCounterLabel.font = NSFont.systemFont(ofSize: 11)
        searchCounterLabel.textColor = .secondaryLabelColor

        prevSearchButton = NSButton(image: NSImage(systemSymbolName: "chevron.up", accessibilityDescription: "Previous")!, target: self, action: #selector(prevSearchClicked))
        prevSearchButton.isBordered = false
        prevSearchButton.translatesAutoresizingMaskIntoConstraints = false

        nextSearchButton = NSButton(image: NSImage(systemSymbolName: "chevron.down", accessibilityDescription: "Next")!, target: self, action: #selector(nextSearchClicked))
        nextSearchButton.isBordered = false
        nextSearchButton.translatesAutoresizingMaskIntoConstraints = false

        closeSearchButton = NSButton(image: NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: "Close")!, target: self, action: #selector(closeSearchClicked))
        closeSearchButton.isBordered = false
        closeSearchButton.translatesAutoresizingMaskIntoConstraints = false

        searchOverlay.addSubview(searchField)
        searchOverlay.addSubview(searchCounterLabel)
        searchOverlay.addSubview(prevSearchButton)
        searchOverlay.addSubview(nextSearchButton)
        searchOverlay.addSubview(closeSearchButton)

        view.addSubview(searchOverlay)

        NSLayoutConstraint.activate([
            searchOverlay.topAnchor.constraint(equalTo: view.topAnchor, constant: 60),
            searchOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            searchOverlay.heightAnchor.constraint(equalToConstant: 38),

            searchField.leadingAnchor.constraint(equalTo: searchOverlay.leadingAnchor, constant: 8),
            searchField.centerYAnchor.constraint(equalTo: searchOverlay.centerYAnchor),
            searchField.widthAnchor.constraint(equalToConstant: 160),

            searchCounterLabel.leadingAnchor.constraint(equalTo: searchField.trailingAnchor, constant: 6),
            searchCounterLabel.centerYAnchor.constraint(equalTo: searchOverlay.centerYAnchor),

            prevSearchButton.leadingAnchor.constraint(equalTo: searchCounterLabel.trailingAnchor, constant: 6),
            prevSearchButton.centerYAnchor.constraint(equalTo: searchOverlay.centerYAnchor),

            nextSearchButton.leadingAnchor.constraint(equalTo: prevSearchButton.trailingAnchor, constant: 4),
            nextSearchButton.centerYAnchor.constraint(equalTo: searchOverlay.centerYAnchor),

            closeSearchButton.leadingAnchor.constraint(equalTo: nextSearchButton.trailingAnchor, constant: 6),
            closeSearchButton.trailingAnchor.constraint(equalTo: searchOverlay.trailingAnchor, constant: -8),
            closeSearchButton.centerYAnchor.constraint(equalTo: searchOverlay.centerYAnchor)
        ])
    }

    private func setupBindings() {
        let state = DocumentState.shared

        state.onDocumentLoaded = { [weak self] content, preserveScroll in
            self?.renderMarkdown(content: content, preserveScroll: preserveScroll)
        }

        state.onThemeUpdated = { [weak self] theme in
            self?.applyTheme(theme)
        }

        state.onFontUpdated = { [weak self] fontFamily, fontSize in
            self?.applyFont(fontFamily: fontFamily, fontSize: fontSize)
        }

        state.onScrollToHeading = { [weak self] headingId in
            self?.scrollToHeading(headingId: headingId)
        }

        state.onSearchRequested = { [weak self] query in
            self?.executeSearch(query: query)
        }

        state.onSearchNext = { [weak self] in
            self?.nextSearch()
        }

        state.onSearchPrev = { [weak self] in
            self?.prevSearch()
        }
    }

    private func loadIndexHTML() {
        guard let indexURL = resolveIndexHTMLURL() else {
            print("Error: Could not find index.html")
            return
        }
        let readAccessURL = indexURL.deletingLastPathComponent().deletingLastPathComponent()
        webView.loadFileURL(indexURL, allowingReadAccessTo: readAccessURL)
    }

    private func resolveIndexHTMLURL() -> URL? {
        #if SWIFT_PACKAGE
        if let url = Bundle.module.url(forResource: "index", withExtension: "html", subdirectory: "Resources") {
            return url
        }
        if let url = Bundle.module.url(forResource: "index", withExtension: "html") {
            return url
        }
        #endif

        if let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "Resources") {
            return url
        }
        if let url = Bundle.main.url(forResource: "index", withExtension: "html") {
            return url
        }

        let devPath = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Sources/MDViewer/Resources/index.html")
        if FileManager.default.fileExists(atPath: devPath.path) {
            return devPath
        }

        return nil
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isIndexLoaded = true
        let state = DocumentState.shared
        applyTheme(state.theme)
        applyFont(fontFamily: state.fontFamily, fontSize: state.fontSize)

        if let pending = pendingRender {
            renderMarkdown(content: pending.content, preserveScroll: pending.preserveScroll)
            pendingRender = nil
        } else if !state.rawContent.isEmpty {
            renderMarkdown(content: state.rawContent, preserveScroll: false)
        }
    }

    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "openExternalURL", let urlStr = message.body as? String, let url = URL(string: urlStr) {
            NSWorkspace.shared.open(url)
        }
    }

    private func renderMarkdown(content: String, preserveScroll: Bool) {
        guard isIndexLoaded else {
            pendingRender = (content, preserveScroll)
            return
        }

        guard let jsonData = try? JSONSerialization.data(withJSONObject: [content, preserveScroll]),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return
        }

        let js = "window.renderMarkdown(\(jsonString)[0], \(jsonString)[1]);"
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    private func applyTheme(_ theme: AppTheme) {
        guard isIndexLoaded else { return }
        webView.evaluateJavaScript("window.setTheme('\(theme.rawValue)');", completionHandler: nil)
    }

    private func applyFont(fontFamily: AppFontFamily, fontSize: Double) {
        guard isIndexLoaded else { return }
        webView.evaluateJavaScript("window.setFont('\(fontFamily.rawValue)', \(fontSize));", completionHandler: nil)
    }

    private func scrollToHeading(headingId: String) {
        guard isIndexLoaded else { return }
        webView.evaluateJavaScript("window.scrollToHeading('\(headingId)');", completionHandler: nil)
    }

    public func toggleSearch() {
        if searchOverlay.isHidden {
            searchOverlay.isHidden = false
            view.window?.makeFirstResponder(searchField)
        } else {
            closeSearchClicked()
        }
    }

    @objc private func searchFieldAction(_ sender: NSSearchField) {
        executeSearch(query: sender.stringValue)
    }

    public func controlTextDidChange(_ obj: Notification) {
        if let field = obj.object as? NSSearchField, field == searchField {
            executeSearch(query: field.stringValue)
        }
    }

    private func executeSearch(query: String) {
        guard isIndexLoaded else { return }
        let escaped = query.replacingOccurrences(of: "'", with: "\\'")
        webView.evaluateJavaScript("window.performSearch('\(escaped)');") { [weak self] result, _ in
            let count = result as? Int ?? 0
            Task { @MainActor in
                self?.updateSearchUI(count: count, index: count > 0 ? 0 : -1)
            }
        }
    }

    @objc private func nextSearchClicked() {
        nextSearch()
    }

    private func nextSearch() {
        guard isIndexLoaded else { return }
        webView.evaluateJavaScript("window.nextSearchMatch();") { [weak self] result, _ in
            let idx = result as? Int ?? -1
            Task { @MainActor in
                self?.updateSearchUI(count: DocumentState.shared.searchMatchCount, index: idx)
            }
        }
    }

    @objc private func prevSearchClicked() {
        prevSearch()
    }

    private func prevSearch() {
        guard isIndexLoaded else { return }
        webView.evaluateJavaScript("window.prevSearchMatch();") { [weak self] result, _ in
            let idx = result as? Int ?? -1
            Task { @MainActor in
                self?.updateSearchUI(count: DocumentState.shared.searchMatchCount, index: idx)
            }
        }
    }

    @objc private func closeSearchClicked() {
        searchOverlay.isHidden = true
        searchField.stringValue = ""
        executeSearch(query: "")
        view.window?.makeFirstResponder(webView)
    }

    private func updateSearchUI(count: Int, index: Int) {
        DocumentState.shared.updateSearchResults(count: count, index: index)
        if count == 0 {
            searchCounterLabel.stringValue = searchField.stringValue.isEmpty ? "" : "0 found"
            prevSearchButton.isEnabled = false
            nextSearchButton.isEnabled = false
        } else {
            searchCounterLabel.stringValue = "\(index + 1) of \(count)"
            prevSearchButton.isEnabled = true
            nextSearchButton.isEnabled = true
        }
    }
}
