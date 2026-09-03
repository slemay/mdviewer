import AppKit

@MainActor
public final class PreferencesWindowController: NSWindowController {
    public static let shared = PreferencesWindowController()

    private var themePopup: NSPopUpButton!
    private var fontPopup: NSPopUpButton!
    private var fontSizeSlider: NSSlider!
    private var fontSizeLabel: NSTextField!
    private var liveSyncCheckbox: NSButton!
    private var cliStatusLabel: NSTextField!

    public init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 350),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        super.init(window: window)

        window.title = "Settings"
        window.isReleasedWhenClosed = false
        window.center()

        setupContent()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupContent() {
        guard let win = window else { return }

        let tabView = NSTabView(frame: win.contentView?.bounds ?? .zero)
        tabView.autoresizingMask = [.width, .height]

        // --- Tab 1: General ---
        let generalTab = NSTabViewItem(identifier: "general")
        generalTab.label = "General"
        generalTab.view = createGeneralTabView()
        tabView.addTabViewItem(generalTab)

        // --- Tab 2: Terminal CLI ---
        let cliTab = NSTabViewItem(identifier: "cli")
        cliTab.label = "Terminal Integration"
        cliTab.view = createCLITabView()
        tabView.addTabViewItem(cliTab)

        win.contentView = tabView
    }

    private func createGeneralTabView() -> NSView {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 480, height: 310))

        let grid = NSGridView()
        grid.translatesAutoresizingMaskIntoConstraints = false
        grid.rowSpacing = 16
        grid.columnSpacing = 16

        // 1. Theme
        let themeTitle = NSTextField(labelWithString: "Default Theme:")
        themeTitle.alignment = .right
        themeTitle.font = .systemFont(ofSize: 13, weight: .medium)

        themePopup = NSPopUpButton(frame: .zero, pullsDown: false)
        for theme in AppTheme.allCases {
            let item = NSMenuItem(title: theme.displayName, action: #selector(themeChanged(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = theme
            themePopup.menu?.addItem(item)
        }
        let currentTheme = UserDefaults.standard.string(forKey: "MDViewerTheme") ?? AppTheme.system.rawValue
        if let idx = AppTheme.allCases.firstIndex(where: { $0.rawValue == currentTheme }) {
            themePopup.selectItem(at: idx)
        }

        // 2. Typography
        let fontTitle = NSTextField(labelWithString: "Default Font:")
        fontTitle.alignment = .right
        fontTitle.font = .systemFont(ofSize: 13, weight: .medium)

        fontPopup = NSPopUpButton(frame: .zero, pullsDown: false)
        for font in AppFontFamily.allCases {
            let item = NSMenuItem(title: font.displayName, action: #selector(fontChanged(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = font
            fontPopup.menu?.addItem(item)
        }
        let currentFont = UserDefaults.standard.string(forKey: "MDViewerFontFamily") ?? AppFontFamily.sans.rawValue
        if let idx = AppFontFamily.allCases.firstIndex(where: { $0.rawValue == currentFont }) {
            fontPopup.selectItem(at: idx)
        }

        // 3. Font Size
        let sizeTitle = NSTextField(labelWithString: "Font Scale:")
        sizeTitle.alignment = .right
        sizeTitle.font = .systemFont(ofSize: 13, weight: .medium)

        let sizeStack = NSStackView()
        sizeStack.orientation = .horizontal
        sizeStack.spacing = 8

        fontSizeSlider = NSSlider(value: 16.0, minValue: 12.0, maxValue: 26.0, target: self, action: #selector(fontSizeSliderChanged(_:)))
        fontSizeSlider.isContinuous = true
        let savedSize = UserDefaults.standard.double(forKey: "MDViewerFontSize")
        fontSizeSlider.doubleValue = savedSize > 0 ? savedSize : 16.0

        fontSizeLabel = NSTextField(labelWithString: "\(Int(fontSizeSlider.doubleValue)) pt")
        fontSizeLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        fontSizeLabel.textColor = .secondaryLabelColor

        sizeStack.addArrangedSubview(fontSizeSlider)
        sizeStack.addArrangedSubview(fontSizeLabel)

        // 4. Live Sync
        let syncTitle = NSTextField(labelWithString: "Live Sync:")
        syncTitle.alignment = .right
        syncTitle.font = .systemFont(ofSize: 13, weight: .medium)

        liveSyncCheckbox = NSButton(checkboxWithTitle: "Automatically reload document when file changes on disk", target: self, action: #selector(liveSyncToggled(_:)))
        liveSyncCheckbox.state = UserDefaults.standard.bool(forKey: "MDViewerDisableLiveSync") ? .off : .on

        grid.addRow(with: [themeTitle, themePopup])
        grid.addRow(with: [fontTitle, fontPopup])
        grid.addRow(with: [sizeTitle, sizeStack])
        grid.addRow(with: [syncTitle, liveSyncCheckbox])

        view.addSubview(grid)
        NSLayoutConstraint.activate([
            grid.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            grid.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -10),
            fontSizeSlider.widthAnchor.constraint(equalToConstant: 160)
        ])

        return view
    }

    private func createCLITabView() -> NSView {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 480, height: 310))

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false

        let headerLabel = NSTextField(labelWithString: "Command-Line Tool (mdviewer)")
        headerLabel.font = .systemFont(ofSize: 14, weight: .semibold)

        let descLabel = NSTextField(wrappingLabelWithString: "Open and preview any markdown file directly from your terminal or shell by typing: mdviewer <file.md>")
        descLabel.font = .systemFont(ofSize: 12)
        descLabel.textColor = .secondaryLabelColor

        let buttonRow = NSStackView()
        buttonRow.orientation = .horizontal
        buttonRow.spacing = 10

        let installButton = NSButton(title: "Install to ~/.local/bin", target: self, action: #selector(installCLIToDefaultLocation))
        installButton.bezelStyle = .rounded

        let copyCmdButton = NSButton(title: "Copy Terminal Alias", target: self, action: #selector(copyTerminalAlias))
        copyCmdButton.bezelStyle = .rounded

        buttonRow.addArrangedSubview(installButton)
        buttonRow.addArrangedSubview(copyCmdButton)

        cliStatusLabel = NSTextField(labelWithString: "")
        cliStatusLabel.font = .systemFont(ofSize: 11)
        cliStatusLabel.textColor = .systemGreen

        stack.addArrangedSubview(headerLabel)
        stack.addArrangedSubview(descLabel)
        stack.addArrangedSubview(buttonRow)
        stack.addArrangedSubview(cliStatusLabel)

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 30),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30)
        ])

        return view
    }

    @objc private func themeChanged(_ sender: NSMenuItem) {
        guard let theme = sender.representedObject as? AppTheme else { return }
        UserDefaults.standard.set(theme.rawValue, forKey: "MDViewerTheme")
        for wc in WindowManager.shared.windowControllers {
            for tab in wc.tabs {
                tab.documentState.theme = theme
            }
        }
    }

    @objc private func fontChanged(_ sender: NSMenuItem) {
        guard let font = sender.representedObject as? AppFontFamily else { return }
        UserDefaults.standard.set(font.rawValue, forKey: "MDViewerFontFamily")
        for wc in WindowManager.shared.windowControllers {
            for tab in wc.tabs {
                tab.documentState.fontFamily = font
            }
        }
    }

    @objc private func fontSizeSliderChanged(_ sender: NSSlider) {
        let size = round(sender.doubleValue)
        fontSizeLabel.stringValue = "\(Int(size)) pt"
        UserDefaults.standard.set(size, forKey: "MDViewerFontSize")
        for wc in WindowManager.shared.windowControllers {
            for tab in wc.tabs {
                tab.documentState.fontSize = size
            }
        }
    }

    @objc private func liveSyncToggled(_ sender: NSButton) {
        let disabled = sender.state == .off
        UserDefaults.standard.set(disabled, forKey: "MDViewerDisableLiveSync")
    }

    @objc private func installCLIToDefaultLocation() {
        let panel = NSOpenPanel()
        panel.message = "Choose a directory in your PATH to install the 'mdviewer' CLI tool (e.g. ~/.local/bin):"
        panel.prompt = "Install Here"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false

        let realHome = URL(fileURLWithPath: NSHomeDirectory())
        let defaultBin = realHome.appendingPathComponent(".local/bin")
        if FileManager.default.fileExists(atPath: defaultBin.path) {
            panel.directoryURL = defaultBin
        } else {
            panel.directoryURL = realHome
        }

        guard panel.runModal() == .OK, let selectedDir = panel.url else { return }

        let targetScript = selectedDir.appendingPathComponent("mdviewer")
        do {
            let appBundlePath = Bundle.main.bundlePath
            let scriptContent = """
            #!/bin/bash
            # MDViewer CLI Launch Helper
            if [ -z "$1" ]; then
                open -a "\(appBundlePath)"
            else
                open -a "\(appBundlePath)" "$@"
            fi
            """
            try scriptContent.write(to: targetScript, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: targetScript.path)

            cliStatusLabel.stringValue = "✓ Installed successfully to \(targetScript.path)"
            cliStatusLabel.textColor = .systemGreen
        } catch {
            cliStatusLabel.stringValue = "Error installing: \(error.localizedDescription)"
            cliStatusLabel.textColor = .systemRed
        }
    }

    @objc private func copyTerminalAlias() {
        let appBundlePath = Bundle.main.bundlePath
        let aliasCmd = "alias mdviewer='open -a \"\(appBundlePath)\"'"
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(aliasCmd, forType: .string)

        cliStatusLabel.stringValue = "✓ Copied alias to clipboard! Paste into ~/.zshrc or ~/.bash_profile"
        cliStatusLabel.textColor = .systemGreen
    }
}
