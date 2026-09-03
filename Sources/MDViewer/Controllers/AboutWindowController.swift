import AppKit

@MainActor
public final class AboutWindowController: NSWindowController {
    public static let shared = AboutWindowController()

    public init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 420),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        super.init(window: window)

        window.title = "About MDViewer"
        window.isReleasedWhenClosed = false
        window.center()

        setupContent()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupContent() {
        guard let win = window else { return }

        let container = NSView(frame: win.contentView?.bounds ?? .zero)
        container.autoresizingMask = [.width, .height]

        let iconView = NSImageView()
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.translatesAutoresizingMaskIntoConstraints = false
        if let icon = NSApplication.shared.applicationIconImage {
            iconView.image = icon
        } else if let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "png") ?? Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
                  let icon = NSImage(contentsOf: iconURL) {
            iconView.image = icon
        }

        let nameLabel = NSTextField(labelWithString: "MDViewer")
        nameLabel.font = .systemFont(ofSize: 18, weight: .bold)
        nameLabel.alignment = .center
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        let versionLabel = NSTextField(labelWithString: "Version \(version) (\(build))")
        versionLabel.font = .systemFont(ofSize: 12)
        versionLabel.textColor = .secondaryLabelColor
        versionLabel.alignment = .center
        versionLabel.translatesAutoresizingMaskIntoConstraints = false

        let descLabel = NSTextField(labelWithString: "Fast, native Markdown viewer for macOS")
        descLabel.font = .systemFont(ofSize: 12, weight: .medium)
        descLabel.alignment = .center
        descLabel.translatesAutoresizingMaskIntoConstraints = false

        let tabView = NSTabView()
        tabView.translatesAutoresizingMaskIntoConstraints = false

        // Tab 1: Overview
        let overviewTab = NSTabViewItem(identifier: "overview")
        overviewTab.label = "About"
        let overviewView = NSView()

        let copyrightLabel = NSTextField(wrappingLabelWithString: "Copyright © 2026. All rights reserved.\nDesigned and crafted with Swift and AppKit.\n\nOffline, privacy-first, zero telemetry.")
        copyrightLabel.font = .systemFont(ofSize: 11)
        copyrightLabel.textColor = .secondaryLabelColor
        copyrightLabel.alignment = .center
        copyrightLabel.translatesAutoresizingMaskIntoConstraints = false
        overviewView.addSubview(copyrightLabel)

        let repoButton = NSButton(title: "GitHub Repository", target: self, action: #selector(openRepo))
        repoButton.bezelStyle = .rounded
        repoButton.translatesAutoresizingMaskIntoConstraints = false
        overviewView.addSubview(repoButton)

        NSLayoutConstraint.activate([
            copyrightLabel.topAnchor.constraint(equalTo: overviewView.topAnchor, constant: 16),
            copyrightLabel.leadingAnchor.constraint(equalTo: overviewView.leadingAnchor, constant: 20),
            copyrightLabel.trailingAnchor.constraint(equalTo: overviewView.trailingAnchor, constant: -20),

            repoButton.topAnchor.constraint(equalTo: copyrightLabel.bottomAnchor, constant: 14),
            repoButton.centerXAnchor.constraint(equalTo: overviewView.centerXAnchor)
        ])
        overviewTab.view = overviewView
        tabView.addTabViewItem(overviewTab)

        // Tab 2: Acknowledgments & Licenses
        let ackTab = NSTabViewItem(identifier: "licenses")
        ackTab.label = "Acknowledgments"
        let ackView = NSView()

        let scroll = NSTextView.scrollableTextView()
        scroll.drawsBackground = false
        scroll.translatesAutoresizingMaskIntoConstraints = false

        let textView = scroll.documentView as! NSTextView
        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.textColor = .labelColor
        textView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        textView.string = Self.licensesText

        ackView.addSubview(scroll)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: ackView.topAnchor, constant: 6),
            scroll.leadingAnchor.constraint(equalTo: ackView.leadingAnchor, constant: 6),
            scroll.trailingAnchor.constraint(equalTo: ackView.trailingAnchor, constant: -6),
            scroll.bottomAnchor.constraint(equalTo: ackView.bottomAnchor, constant: -6)
        ])
        ackTab.view = ackView
        tabView.addTabViewItem(ackTab)

        container.addSubview(iconView)
        container.addSubview(nameLabel)
        container.addSubview(versionLabel)
        container.addSubview(descLabel)
        container.addSubview(tabView)

        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: container.topAnchor, constant: 18),
            iconView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 64),
            iconView.heightAnchor.constraint(equalToConstant: 64),

            nameLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 8),
            nameLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),

            versionLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            versionLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),

            descLabel.topAnchor.constraint(equalTo: versionLabel.bottomAnchor, constant: 6),
            descLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),

            tabView.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 12),
            tabView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            tabView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            tabView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
        ])

        win.contentView = container
    }

    @objc private func openRepo() {
        if let url = URL(string: "https://github.com/slemay/mdviewer") {
            NSWorkspace.shared.open(url)
        }
    }

    private static let licensesText = """
    MDViewer bundles and uses the following open-source libraries under permissive licenses:

    ------------------------------------------------------------
    Marked.js
    Copyright (c) 2011-2024, Christopher Jeffrey (https://github.com/chjj/)
    Licensed under the MIT License.

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    ------------------------------------------------------------
    KaTeX
    Copyright (c) 2013-2020 Khan Academy and other contributors
    Licensed under the MIT License.

    ------------------------------------------------------------
    Prism.js
    Copyright (c) 2012 Lea Verou
    Licensed under the MIT License.

    ------------------------------------------------------------
    Mermaid.js
    Copyright (c) 2014-2024 Knut Sveidqvist and contributors
    Licensed under the MIT License.
    """
}
