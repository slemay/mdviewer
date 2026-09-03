import AppKit

@MainActor
public final class MainWindowController: NSWindowController, NSToolbarDelegate, NSWindowDelegate {
    public static let windowAutosaveName = "MDViewerMainWindow"
    private var isSetupComplete = false

    public let documentState: DocumentState
    private var splitVC: NSSplitViewController!
    private var sidebarVC: SidebarViewController!
    private var contentVC: ContentViewController!
    private var sidebarSplitItem: NSSplitViewItem!

    public init(documentState: DocumentState) {
        self.documentState = documentState

        let window = NSWindow(
            contentRect: NSRect(x: 120, y: 120, width: 1060, height: 740),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        super.init(window: window)

        window.title = "MDViewer"
        window.minSize = NSSize(width: 650, height: 450)
        window.isReleasedWhenClosed = false
        window.toolbarStyle = .unified

        // Enable native macOS window tabbing
        window.tabbingMode = .preferred
        window.tabbingIdentifier = "MDViewerDocumentWindow"

        setupSplitView()
        setupToolbar()
        setupStateObservers()

        // Restore window frame & position AFTER all view controllers are mounted
        let restored = window.setFrameUsingName(Self.windowAutosaveName)
        if !restored {
            window.center()
        }
        window.setFrameAutosaveName(Self.windowAutosaveName)
        window.delegate = self
        isSetupComplete = true
    }

    public convenience init() {
        self.init(documentState: DocumentState())
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func newWindowForTab(_ sender: Any?) {
        WindowManager.shared.createNewWindow(asTab: true)
    }

    private func setupSplitView() {
        splitVC = NSSplitViewController()

        sidebarVC = SidebarViewController(documentState: documentState)
        sidebarSplitItem = NSSplitViewItem(sidebarWithViewController: sidebarVC)
        sidebarSplitItem.minimumThickness = 190
        sidebarSplitItem.maximumThickness = 320
        sidebarSplitItem.allowsFullHeightLayout = true

        contentVC = ContentViewController(documentState: documentState)
        let contentItem = NSSplitViewItem(viewController: contentVC)

        splitVC.addSplitViewItem(sidebarSplitItem)
        splitVC.addSplitViewItem(contentItem)

        window?.contentViewController = splitVC
    }

    private func setupToolbar() {
        let toolbar = NSToolbar(identifier: "MDViewerMainToolbar")
        toolbar.allowsUserCustomization = false
        toolbar.autosavesConfiguration = false
        toolbar.displayMode = .iconOnly
        toolbar.delegate = self

        window?.toolbar = toolbar
    }

    private func setupStateObservers() {
        documentState.onMetadataChanged = { [weak self] fileName, fileURL in
            guard let self = self, let win = self.window else { return }
            win.title = fileName
            win.representedURL = fileURL
            if let path = fileURL?.path {
                win.subtitle = path
            }
        }
    }

    // MARK: - NSToolbarDelegate
    private let toggleSidebarId = NSToolbarItem.Identifier("ToggleSidebar")
    private let openFileId = NSToolbarItem.Identifier("OpenFile")
    private let reloadFileId = NSToolbarItem.Identifier("ReloadFile")
    private let typographyId = NSToolbarItem.Identifier("Typography")
    private let fontSizeId = NSToolbarItem.Identifier("FontSize")
    private let themeId = NSToolbarItem.Identifier("Theme")
    private let searchId = NSToolbarItem.Identifier("Search")
    private let exportId = NSToolbarItem.Identifier("Export")

    public func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [
            .toggleSidebar,
            openFileId,
            reloadFileId,
            .flexibleSpace,
            typographyId,
            fontSizeId,
            themeId,
            searchId,
            exportId
        ]
    }

    public func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [
            .toggleSidebar,
            openFileId,
            reloadFileId,
            .flexibleSpace,
            typographyId,
            fontSizeId,
            themeId,
            searchId,
            exportId
        ]
    }

    public func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        switch itemIdentifier {
        case .toggleSidebar:
            return nil

        case openFileId:
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Open"
            item.paletteLabel = "Open File"
            item.toolTip = "Open Markdown File (Cmd+O)"
            item.image = NSImage(systemSymbolName: "folder", accessibilityDescription: "Open")
            item.target = self
            item.action = #selector(openDocumentAction)
            return item

        case reloadFileId:
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Reload"
            item.paletteLabel = "Reload File"
            item.toolTip = "Reload Current File (Cmd+R)"
            item.image = NSImage(systemSymbolName: "arrow.clockwise", accessibilityDescription: "Reload")
            item.target = self
            item.action = #selector(reloadDocumentAction)
            return item

        case typographyId:
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Font"
            item.paletteLabel = "Font Family"

            let popUp = NSPopUpButton(frame: .zero, pullsDown: false)
            popUp.bezelStyle = .texturedRounded
            for font in AppFontFamily.allCases {
                let menuItem = NSMenuItem(title: font.displayName, action: #selector(fontFamilySelected(_:)), keyEquivalent: "")
                menuItem.target = self
                menuItem.representedObject = font
                popUp.menu?.addItem(menuItem)
            }
            item.view = popUp
            return item

        case fontSizeId:
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Size"
            item.paletteLabel = "Font Size"

            let segmented = NSSegmentedControl(labels: ["A-", "A+"], trackingMode: .momentary, target: self, action: #selector(fontSizeChanged(_:)))
            segmented.segmentStyle = .texturedRounded
            item.view = segmented
            return item

        case themeId:
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Theme"
            item.paletteLabel = "Theme"

            let popUp = NSPopUpButton(frame: .zero, pullsDown: false)
            popUp.bezelStyle = .texturedRounded
            for theme in AppTheme.allCases {
                let menuItem = NSMenuItem(title: theme.displayName, action: #selector(themeSelected(_:)), keyEquivalent: "")
                menuItem.target = self
                menuItem.image = NSImage(systemSymbolName: theme.iconName, accessibilityDescription: theme.displayName)
                menuItem.representedObject = theme
                popUp.menu?.addItem(menuItem)
            }
            item.view = popUp
            return item

        case searchId:
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Find"
            item.paletteLabel = "Find in Page"
            item.toolTip = "Find in Page (Cmd+F)"
            item.image = NSImage(systemSymbolName: "magnifyingglass", accessibilityDescription: "Find")
            item.target = self
            item.action = #selector(toggleSearchAction)
            return item

        case exportId:
            let item = NSMenuToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Export"
            item.paletteLabel = "Export and Share"
            item.toolTip = "Export and Share Options"
            item.image = NSImage(systemSymbolName: "square.and.arrow.up", accessibilityDescription: "Export")

            let menu = NSMenu()
            let pdfItem = NSMenuItem(title: "Save as PDF...", action: #selector(exportPDFAction), keyEquivalent: "p")
            pdfItem.target = self
            menu.addItem(pdfItem)

            menu.addItem(.separator())

            let htmlItem = NSMenuItem(title: "Copy Rendered HTML", action: #selector(copyHTMLAction), keyEquivalent: "C")
            htmlItem.keyEquivalentModifierMask = [.command, .shift]
            htmlItem.target = self
            menu.addItem(htmlItem)

            let mdItem = NSMenuItem(title: "Copy Markdown Source", action: #selector(copyMarkdownAction), keyEquivalent: "")
            mdItem.target = self
            menu.addItem(mdItem)

            item.menu = menu
            return item

        default:
            return nil
        }
    }

    // MARK: - Actions
    @objc public func openDocumentAction() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.text, .plainText]
        panel.allowsOtherFileTypes = true
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        let handler: (NSApplication.ModalResponse) -> Void = { [weak self] response in
            guard response == .OK, let self = self else { return }
            for (idx, url) in panel.urls.enumerated() {
                if idx == 0 && self.documentState.fileURL == nil {
                    self.documentState.openFile(url: url)
                } else {
                    WindowManager.shared.openFile(url: url, inNewTab: true)
                }
            }
        }

        if let win = window {
            panel.beginSheetModal(for: win, completionHandler: handler)
        } else if panel.runModal() == .OK {
            handler(.OK)
        }
    }

    @objc public func reloadDocumentAction() {
        documentState.reloadCurrentFile(preserveScroll: true)
    }

    @objc private func fontFamilySelected(_ sender: NSMenuItem) {
        if let font = sender.representedObject as? AppFontFamily {
            documentState.fontFamily = font
        }
    }

    @objc private func fontSizeChanged(_ sender: NSSegmentedControl) {
        if sender.selectedSegment == 0 {
            documentState.zoomOut()
        } else {
            documentState.zoomIn()
        }
    }

    @objc private func themeSelected(_ sender: NSMenuItem) {
        if let theme = sender.representedObject as? AppTheme {
            documentState.theme = theme
        }
    }

    @objc public func toggleSearchAction() {
        contentVC.toggleSearch()
    }

    @objc public func exportPDFAction() {
        guard let webView = contentVC.webView else { return }
        Exporter.savePDFDirectly(webView: webView, suggestedFileName: documentState.fileName)
    }

    @objc public func copyHTMLAction() {
        guard let webView = contentVC.webView else { return }
        Exporter.copyRenderedHTML(webView: webView)
    }

    @objc public func copyMarkdownAction() {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(documentState.rawContent, forType: .string)
    }

    // MARK: - NSWindowDelegate
    public func windowDidMove(_ notification: Notification) {
        guard isSetupComplete else { return }
        window?.saveFrame(usingName: Self.windowAutosaveName)
    }

    public func windowDidResize(_ notification: Notification) {
        guard isSetupComplete else { return }
        window?.saveFrame(usingName: Self.windowAutosaveName)
    }

    public func windowWillClose(_ notification: Notification) {
        guard isSetupComplete else { return }
        window?.saveFrame(usingName: Self.windowAutosaveName)
        documentState.stopWatching()
        WindowManager.shared.removeWindowController(self)
    }
}
