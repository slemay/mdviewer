import AppKit

@MainActor
public final class WindowManager {
    public static let shared = WindowManager()

    public private(set) var windowControllers: [MainWindowController] = []

    public var activeWindowController: MainWindowController? {
        let app = NSApplication.shared
        if let keyWin = app.keyWindow, let wc = keyWin.windowController as? MainWindowController {
            return wc
        }
        if let mainWin = app.mainWindow, let wc = mainWin.windowController as? MainWindowController {
            return wc
        }
        return windowControllers.last
    }

    public var activeDocumentState: DocumentState? {
        activeWindowController?.documentState
    }

    private init() {}

    @discardableResult
    public func createNewWindow(opening url: URL? = nil, asTab: Bool = false) -> MainWindowController {
        let parentWC = activeWindowController
        let wc = MainWindowController()
        windowControllers.append(wc)

        if asTab, let parentWindow = parentWC?.window {
            parentWindow.addTabbedWindow(wc.window!, ordered: .above)
        } else if windowControllers.count > 1, let prevWin = parentWC?.window {
            // Cascade new independent window from the previous window
            let origin = prevWin.frame.origin
            let nextOrigin = NSPoint(x: origin.x + 28, y: origin.y - 28)
            wc.window?.setFrameOrigin(nextOrigin)
        }

        wc.showWindow(nil)
        wc.window?.makeKeyAndOrderFront(nil)

        if let url = url {
            let result = MarkdownValidator.validate(url: url)
            if result.isValid, let effective = result.effectiveURL {
                wc.documentState.openFile(url: effective)
            }
        }

        return wc
    }

    public func openFile(url: URL, inNewWindow: Bool = false, inNewTab: Bool = false) {
        let result = MarkdownValidator.validate(url: url)
        guard result.isValid, let effective = result.effectiveURL else {
            _ = MarkdownValidator.presentAlertIfInvalid(for: url, in: activeWindowController?.window)
            return
        }

        // 1. Check if file is already open in an existing window or tab
        for wc in windowControllers {
            if let idx = wc.tabs.firstIndex(where: { $0.documentState.fileURL?.standardizedFileURL == effective.standardizedFileURL }) {
                wc.switchToTab(index: idx)
                wc.window?.makeKeyAndOrderFront(nil)
                NSApplication.shared.activate(ignoringOtherApps: true)
                return
            }
        }

        // 2. Explicit new window requested
        if inNewWindow {
            createNewWindow(opening: effective, asTab: false)
            NSApplication.shared.activate(ignoringOtherApps: true)
            return
        }

        // 3. If active window exists, open into a tab in that window
        if let active = activeWindowController {
            active.openFileInNewTab(url: effective)
            active.window?.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
            return
        }

        // 4. Otherwise create a new window
        createNewWindow(opening: effective, asTab: false)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    public func removeWindowController(_ wc: MainWindowController) {
        windowControllers.removeAll { $0 === wc }
        if windowControllers.isEmpty && NSApplication.shared.activationPolicy() == .regular {
            NSApplication.shared.terminate(nil)
        }
    }
}
