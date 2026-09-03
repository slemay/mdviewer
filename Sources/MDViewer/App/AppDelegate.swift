import AppKit

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    public static private(set) var shared: AppDelegate?
    public private(set) var mainWindowController: MainWindowController?

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

        let windowController = MainWindowController()
        self.mainWindowController = windowController
        windowController.showWindow(nil)
        windowController.window?.makeKeyAndOrderFront(nil)

        // Process any CLI argument paths
        let args = CommandLine.arguments.dropFirst()
        for arg in args {
            if !arg.hasPrefix("-") {
                let expanded = NSString(string: arg).expandingTildeInPath
                let url = URL(fileURLWithPath: expanded)
                if FileManager.default.fileExists(atPath: url.path) {
                    DocumentState.shared.openFile(url: url)
                    break
                }
            }
        }
    }

    public func application(_ application: NSApplication, openFile filename: String) -> Bool {
        let url = URL(fileURLWithPath: filename)
        let effective = DragDropHelper.resolveEffectiveURL(for: url)
        DocumentState.shared.openFile(url: effective)
        mainWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
        return true
    }

    public func application(_ application: NSApplication, open urls: [URL]) {
        if let first = urls.first {
            let effective = DragDropHelper.resolveEffectiveURL(for: first)
            DocumentState.shared.openFile(url: effective)
            mainWindowController?.window?.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }

    public func application(_ sender: NSApplication, openFiles filenames: [String]) {
        for filename in filenames {
            let url = URL(fileURLWithPath: filename)
            if DragDropHelper.isValidMarkdownFile(url: url) {
                let effective = DragDropHelper.resolveEffectiveURL(for: url)
                DocumentState.shared.openFile(url: effective)
                mainWindowController?.window?.makeKeyAndOrderFront(nil)
                NSApplication.shared.activate(ignoringOtherApps: true)
                break
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
        let openItem = NSMenuItem(title: "Open...", action: #selector(MainWindowController.openDocumentAction), keyEquivalent: "o")
        openItem.target = mainWindowController
        fileMenu.addItem(openItem)

        let reloadItem = NSMenuItem(title: "Reload File", action: #selector(MainWindowController.reloadDocumentAction), keyEquivalent: "r")
        reloadItem.target = mainWindowController
        fileMenu.addItem(reloadItem)

        fileMenu.addItem(.separator())

        let exportPDFItem = NSMenuItem(title: "Save as PDF...", action: #selector(MainWindowController.exportPDFAction), keyEquivalent: "p")
        exportPDFItem.target = mainWindowController
        fileMenu.addItem(exportPDFItem)

        fileMenu.addItem(.separator())
        fileMenu.addItem(NSMenuItem(title: "Close Window", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w"))
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
        copyHTMLItem.target = mainWindowController
        editMenu.addItem(copyHTMLItem)

        let copyMDItem = NSMenuItem(title: "Copy Markdown Source", action: #selector(MainWindowController.copyMarkdownAction), keyEquivalent: "")
        copyMDItem.target = mainWindowController
        editMenu.addItem(copyMDItem)

        editMenu.addItem(NSMenuItem(title: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v"))
        editMenu.addItem(NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"))
        editMenu.addItem(.separator())

        let findItem = NSMenuItem(title: "Find...", action: #selector(MainWindowController.toggleSearchAction), keyEquivalent: "f")
        findItem.target = mainWindowController
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

        viewMenuItem.submenu = viewMenu
        mainMenu.addItem(viewMenuItem)

        // 5. Window Menu
        let windowMenuItem = NSMenuItem()
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(NSMenuItem(title: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m"))
        windowMenu.addItem(NSMenuItem(title: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: ""))
        windowMenu.addItem(.separator())
        windowMenu.addItem(NSMenuItem(title: "Bring All to Front", action: #selector(NSApplication.arrangeInFront(_:)), keyEquivalent: ""))
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)

        NSApplication.shared.mainMenu = mainMenu
    }

    @objc private func resetZoomAction() {
        DocumentState.shared.resetZoom()
    }

    @objc private func zoomInAction() {
        DocumentState.shared.zoomIn()
    }

    @objc private func zoomOutAction() {
        DocumentState.shared.zoomOut()
    }
}
