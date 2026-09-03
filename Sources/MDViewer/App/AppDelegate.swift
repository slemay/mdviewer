import AppKit

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    public static private(set) var shared: AppDelegate?

    public var mainWindowController: MainWindowController? {
        WindowManager.shared.activeWindowController
    }

    public override init() {
        super.init()
        AppDelegate.shared = self
    }

    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Set App Icon
        if let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns") ?? Bundle.main.url(forResource: "AppIcon", withExtension: "png"),
           let iconImage = NSImage(contentsOf: iconURL) {
            NSApplication.shared.applicationIconImage = iconImage
        }

        setupMainMenu()

        // Check CLI argument paths
        var openedCLIFile = false
        let args = CommandLine.arguments.dropFirst()
        for arg in args {
            if !arg.hasPrefix("-") {
                let expanded = NSString(string: arg).expandingTildeInPath
                let url = URL(fileURLWithPath: expanded)
                if FileManager.default.fileExists(atPath: url.path) {
                    WindowManager.shared.openFile(url: url)
                    openedCLIFile = true
                }
            }
        }

        // If no file opened from arguments, create initial window
        if !openedCLIFile {
            WindowManager.shared.createNewWindow()
        }
    }

    public func application(_ application: NSApplication, openFile filename: String) -> Bool {
        let url = URL(fileURLWithPath: filename)
        let effective = DragDropHelper.resolveEffectiveURL(for: url)
        WindowManager.shared.openFile(url: effective)
        return true
    }

    public func application(_ application: NSApplication, open urls: [URL]) {
        for (index, url) in urls.enumerated() {
            let effective = DragDropHelper.resolveEffectiveURL(for: url)
            WindowManager.shared.openFile(url: effective, inNewTab: index > 0)
        }
    }

    public func application(_ sender: NSApplication, openFiles filenames: [String]) {
        for (index, filename) in filenames.enumerated() {
            let url = URL(fileURLWithPath: filename)
            if DragDropHelper.isValidMarkdownFile(url: url) {
                let effective = DragDropHelper.resolveEffectiveURL(for: url)
                WindowManager.shared.openFile(url: effective, inNewTab: index > 0)
            }
        }
        sender.reply(toOpenOrPrint: .success)
    }

    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    private func setupMainMenu() {
        let mainMenu = NSMenu()

        // 1. App Menu
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(NSMenuItem(title: "About MDViewer", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: ""))
        appMenu.addItem(.separator())
        appMenu.addItem(NSMenuItem(title: "Hide MDViewer", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h"))
        let hideOthers = NSMenuItem(title: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthers.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(hideOthers)
        appMenu.addItem(NSMenuItem(title: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: ""))
        appMenu.addItem(.separator())
        appMenu.addItem(NSMenuItem(title: "Quit MDViewer", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        // 2. File Menu
        let fileMenuItem = NSMenuItem()
        let fileMenu = NSMenu(title: "File")

        let newWindowItem = NSMenuItem(title: "New Window", action: #selector(newWindowAction), keyEquivalent: "n")
        newWindowItem.target = self
        fileMenu.addItem(newWindowItem)

        let newTabItem = NSMenuItem(title: "New Tab", action: #selector(newTabAction), keyEquivalent: "t")
        newTabItem.target = self
        fileMenu.addItem(newTabItem)

        fileMenu.addItem(.separator())

        let openItem = NSMenuItem(title: "Open...", action: #selector(MainWindowController.openDocumentAction), keyEquivalent: "o")
        openItem.target = nil // Responder chain: routes to active window controller
        fileMenu.addItem(openItem)

        let openNewWinItem = NSMenuItem(title: "Open in New Window...", action: #selector(openInNewWindowAction), keyEquivalent: "o")
        openNewWinItem.keyEquivalentModifierMask = [.command, .option]
        openNewWinItem.target = self
        fileMenu.addItem(openNewWinItem)

        let reloadItem = NSMenuItem(title: "Reload File", action: #selector(MainWindowController.reloadDocumentAction), keyEquivalent: "r")
        reloadItem.target = nil // Responder chain: routes to active window controller
        fileMenu.addItem(reloadItem)

        fileMenu.addItem(.separator())

        let exportPDFItem = NSMenuItem(title: "Save as PDF...", action: #selector(MainWindowController.exportPDFAction), keyEquivalent: "p")
        exportPDFItem.target = nil
        fileMenu.addItem(exportPDFItem)

        fileMenu.addItem(.separator())

        let closeItem = NSMenuItem(title: "Close Window / Tab", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        closeItem.target = nil
        fileMenu.addItem(closeItem)

        let closeAllItem = NSMenuItem(title: "Close All Windows", action: #selector(closeAllWindowsAction), keyEquivalent: "w")
        closeAllItem.keyEquivalentModifierMask = [.command, .option]
        closeAllItem.target = self
        fileMenu.addItem(closeAllItem)

        fileMenuItem.submenu = fileMenu
        mainMenu.addItem(fileMenuItem)

        // 3. Edit Menu
        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(NSMenuItem(title: "Undo", action: #selector(UndoManager.undo), keyEquivalent: "z"))
        editMenu.addItem(NSMenuItem(title: "Redo", action: #selector(UndoManager.redo), keyEquivalent: "Z"))
        editMenu.addItem(.separator())
        editMenu.addItem(NSMenuItem(title: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x"))
        editMenu.addItem(NSMenuItem(title: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c"))

        let copyHTMLItem = NSMenuItem(title: "Copy Rendered HTML", action: #selector(MainWindowController.copyHTMLAction), keyEquivalent: "C")
        copyHTMLItem.keyEquivalentModifierMask = [.command, .shift]
        copyHTMLItem.target = nil
        editMenu.addItem(copyHTMLItem)

        let copyMDItem = NSMenuItem(title: "Copy Markdown Source", action: #selector(MainWindowController.copyMarkdownAction), keyEquivalent: "")
        copyMDItem.target = nil
        editMenu.addItem(copyMDItem)

        editMenu.addItem(NSMenuItem(title: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v"))
        editMenu.addItem(NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"))
        editMenu.addItem(.separator())

        let findItem = NSMenuItem(title: "Find...", action: #selector(MainWindowController.toggleSearchAction), keyEquivalent: "f")
        findItem.target = nil
        editMenu.addItem(findItem)

        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        // 4. View Menu
        let viewMenuItem = NSMenuItem()
        let viewMenu = NSMenu(title: "View")
        let actualSizeItem = NSMenuItem(title: "Actual Size", action: #selector(resetZoomAction), keyEquivalent: "0")
        actualSizeItem.target = self
        viewMenu.addItem(actualSizeItem)

        let zoomInItem = NSMenuItem(title: "Zoom In", action: #selector(zoomInAction), keyEquivalent: "+")
        zoomInItem.target = self
        viewMenu.addItem(zoomInItem)

        let zoomOutItem = NSMenuItem(title: "Zoom Out", action: #selector(zoomOutAction), keyEquivalent: "-")
        zoomOutItem.target = self
        viewMenu.addItem(zoomOutItem)

        viewMenu.addItem(.separator())

        let toggleTabBarItem = NSMenuItem(title: "Toggle Tab Bar", action: #selector(NSWindow.toggleTabBar(_:)), keyEquivalent: "T")
        toggleTabBarItem.keyEquivalentModifierMask = [.command, .shift]
        toggleTabBarItem.target = nil
        viewMenu.addItem(toggleTabBarItem)

        viewMenuItem.submenu = viewMenu
        mainMenu.addItem(viewMenuItem)

        // 5. Window Menu
        let windowMenuItem = NSMenuItem()
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(NSMenuItem(title: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m"))
        windowMenu.addItem(NSMenuItem(title: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: ""))
        windowMenu.addItem(.separator())

        let prevTabItem = NSMenuItem(title: "Show Previous Tab", action: #selector(NSWindow.selectPreviousTab(_:)), keyEquivalent: "[")
        prevTabItem.keyEquivalentModifierMask = [.command, .shift]
        prevTabItem.target = nil
        windowMenu.addItem(prevTabItem)

        let nextTabItem = NSMenuItem(title: "Show Next Tab", action: #selector(NSWindow.selectNextTab(_:)), keyEquivalent: "]")
        nextTabItem.keyEquivalentModifierMask = [.command, .shift]
        nextTabItem.target = nil
        windowMenu.addItem(nextTabItem)

        let moveTabItem = NSMenuItem(title: "Move Tab to New Window", action: #selector(NSWindow.moveTabToNewWindow(_:)), keyEquivalent: "")
        moveTabItem.target = nil
        windowMenu.addItem(moveTabItem)

        let mergeWindowsItem = NSMenuItem(title: "Merge All Windows", action: #selector(NSWindow.mergeAllWindows(_:)), keyEquivalent: "")
        mergeWindowsItem.target = nil
        windowMenu.addItem(mergeWindowsItem)

        windowMenu.addItem(.separator())
        windowMenu.addItem(NSMenuItem(title: "Bring All to Front", action: #selector(NSApplication.arrangeInFront(_:)), keyEquivalent: ""))
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)

        NSApplication.shared.mainMenu = mainMenu
    }

    @objc private func newWindowAction() {
        WindowManager.shared.createNewWindow()
    }

    @objc private func newTabAction() {
        WindowManager.shared.createNewWindow(asTab: true)
    }

    @objc private func openInNewWindowAction() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.text, .plainText]
        panel.allowsOtherFileTypes = true
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        if panel.runModal() == .OK {
            for url in panel.urls {
                WindowManager.shared.createNewWindow(opening: url, asTab: false)
            }
        }
    }

    @objc private func closeAllWindowsAction() {
        for wc in WindowManager.shared.windowControllers {
            wc.window?.performClose(nil)
        }
    }

    @objc private func resetZoomAction() {
        WindowManager.shared.activeDocumentState?.resetZoom()
    }

    @objc private func zoomInAction() {
        WindowManager.shared.activeDocumentState?.zoomIn()
    }

    @objc private func zoomOutAction() {
        WindowManager.shared.activeDocumentState?.zoomOut()
    }
}
