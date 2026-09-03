# MDViewer 📖

An ultra-fast, native macOS Markdown reader and live previewer built with Swift and AppKit.

Designed to feel right at home on modern macOS with unified toolbars, full-height translucent sidebars, smooth animations, and instant kernel-level live sync when files are saved externally in editors like Neovim, Helix, or VS Code.

---

## ✨ Features

- **⚡️ Instant Live File Sync**: Automatically monitors opened files with kernel events (`DispatchSourceFileSystemObject`). Saves made in terminal or external editors refresh instantaneously while preserving exact scroll position.
- **🗂 Prominent Document Tab Bar & Multi-Window Support**:
  - Always-visible, dedicated tab bar displaying tabs even on a single open document or untitled state.
  - Tactile, modern elevated card tabs with active color indicator strip, rounded top corners, document icons, and interactive close (`✕`) buttons.
  - Quick `(+)` action directly on the tab bar to open new markdown documents at all times.
  - Open documents in tabs (`Cmd + T`) or independent windows (`Cmd + N`).
  - Cycle through tabs using standard macOS shortcuts (`Cmd + Shift + [` / `Cmd + Shift + ]`).
  - Independent `DocumentState`, kernel file watchers, search states, and scroll positions per tab/window.
- **🎯 Universal Drag & Drop**:
  - Drag `.md` files directly onto the **open window** (tab bar, sidebar, toolbar, or content area) with an animated visual HUD indicator.
  - Drag files onto the **Dock icon** or the **`MDViewer.app` bundle in Finder** to open immediately.
  - Drop multiple markdown files at once to open them as separate tabs automatically.
  - Drop a directory onto the app to automatically open its `README.md`.
- **📑 Hierarchical Outline (TOC) & Smart Link Navigation**:
  - Automatically extracts `H1`–`H6` headings into a clean interactive sidebar with search filtering.
  - Multi-tier in-page link resolver bridging GitHub-style double-hyphen slugs (`--`), section number prefixes (e.g. `#42-...` -> `4.2`), and text keywords.
  - Smooth animated jump-to-section navigation with an eye-catching accent pulse glow (`.heading-target-pulse`).
- **🖼 Proportional Image & Object Scaling**:
  - Zooming (`Cmd +` / `Cmd -` or the Settings slider) scales not just text, but all images (`img`), Mermaid diagrams, and media objects proportionally via `--object-scale`.
  - Max reading width automatically expands with zoom level to ensure images and text never get cramped.
- **🛡 Pre-flight File Validation**:
  - Thoroughly tests files before opening (`MarkdownValidator.swift`) across all launch points (Finder, CLI, Drag & Drop, and Open panel).
  - Rejects binary files, checks permissions, resolves folders with `README.md`, and inspects file headers for null bytes (`0x00`) with native `NSAlert` modal feedback.
- **📊 Document Statistics**: Real-time word count, character count, estimated reading time, file size, and last modified timestamp.
- **🧮 Mathematics (KaTeX)**: Full inline (`$...$`) and block (`$$...$$`) LaTeX equation rendering with bundled TeX fonts.
- **🎨 Code Syntax Highlighting**: Automatic language detection, line numbers, and one-click copy button with clipboard feedback.
- **📊 Mermaid Diagrams**: Native rendering of flowcharts, sequence diagrams, and architecture maps (````mermaid`).
- **💡 GitHub Callouts**: Native styling for `[!NOTE]`, `[!TIP]`, `[!IMPORTANT]`, `[!WARNING]`, and `[!CAUTION]`.
- **🌗 Themes & Typography**:
  - Themes: System (Auto Light/Dark), GitHub Light, GitHub Dark, Dracula, Nord, Sepia.
  - Typography: San Francisco (Sans), New York (Serif), SF Mono.
  - Interactive font and object scaling (`Cmd +` / `Cmd -` / `Cmd 0`).
- **🔍 In-Page Search**: Fast animated find bar (`Cmd + F`) positioned cleanly below the toolbar with match count and cycling.
- **📄 Export & Share**: Direct export to PDF (`Cmd + P`), Copy Rendered HTML (`Cmd + Shift + C`), or copy raw Markdown.
- **📐 Window State Persistence**: Automatically remembers window dimensions, screen coordinates, and sidebar split width across launches using native AppKit frame autosave.
- **🎨 Native macOS App Icon**: Bundled with a custom high-resolution Apple icon (`AppIcon.icns`) supporting 16×16 through 1024×1024 @2x Retina.
- **📦 100% Offline & Privacy First**: Zero tracking, zero telemetry. All fonts, styles, and parsers are bundled inside the app.
- **🛡 Mac App Store & Sandbox Ready**: Built with official Mac App Store entitlements (`com.apple.security.app-sandbox`), native Settings window (`Cmd + ,`), About window with full open-source licensing acknowledgments, and 1-click CLI installer.

---

## 🚀 Quick Start

### Build & Package the App

```bash
./scripts/build_app.sh
```

This compiles the release binary, bundles all offline assets, generates `build/MDViewer.app`, and applies ad-hoc codesigning.

### Install CLI Launcher (`mdviewer`)

```bash
./scripts/install_cli.sh
```

Installs `mdviewer` to `~/.local/bin/mdviewer`. You can then open any markdown file directly from your terminal:

```bash
mdviewer README.md
```

### Launch Directly with `open`

```bash
open -a ./build/MDViewer.app sample.md
```

Or simply drag & drop any `.md` file onto `MDViewer.app` or its running window!

---

## ⌨️ Keyboard Shortcuts

| Shortcut | Description |
| :--- | :--- |
| `Cmd + N` | Open a new window |
| `Cmd + T` | Open a new tab |
| `Cmd + O` | Open a markdown document via file picker |
| `Cmd + Option + O` | Open document in a new window |
| `Cmd + R` | Force reload the current document |
| `Cmd + Shift + [` | Switch to previous tab |
| `Cmd + Shift + ]` | Switch to next tab |
| `Cmd + Shift + T` | Toggle tab bar visibility |
| `Cmd + Option + S` | Toggle Outline Sidebar |
| `Cmd + F` | Toggle in-page search overlay |
| `Cmd + P` | Save document as PDF |
| `Cmd + Shift + C` | Copy rendered HTML to clipboard |
| `Cmd + +` | Increase font size |
| `Cmd + -` | Decrease font size |
| `Cmd + 0` | Reset font size to default (16px) |
| `Cmd + W` | Close active window or tab |
| `Cmd + Option + W` | Close all open windows |
| `Cmd + ,` | Open Settings / Preferences |
| `Cmd + Q` | Quit MDViewer |

---

## 🏗 Architecture

```
mdviewer/
├── Package.swift                    # Swift Package Manager manifest (macOS 14+)
├── Info.plist                       # macOS bundle metadata, document types & icon config
├── MDViewer.entitlements            # Mac App Store sandbox & security entitlements
├── scripts/
│   ├── build_app.sh                 # Compiles & packages build/MDViewer.app
│   └── install_cli.sh               # Installs ~/.local/bin/mdviewer CLI launcher
├── Sources/
│   └── MDViewer/
│       ├── App/
│       │   ├── main.swift           # Native AppKit entrypoint
│       │   └── AppDelegate.swift    # AppKit lifecycle, macOS menus, Dock/Finder drop
│       ├── Controllers/
│       │   ├── MainWindowController.swift     # NSWindowController, NSSplitViewController, NSToolbar, Tabs
│       │   ├── PreferencesWindowController.swift # Settings window (Theme, Font, Scale, Live Sync, CLI)
│       │   └── AboutWindowController.swift       # About window with MIT Open-Source Acknowledgments
│       ├── Models/
│       │   ├── DocumentState.swift  # Isolated document model per window/tab & listener callbacks
│       │   ├── HeadingItem.swift    # TOC outline item model
│       │   └── Theme.swift          # Themes & font family definitions
│       ├── Services/
│       │   ├── WindowManager.swift     # Multi-window & multi-tab coordinator
│       │   ├── MarkdownValidator.swift # Pre-flight validation, encoding check & binary detection
│       │   ├── DragDropHelper.swift    # Multi-source pasteboard extraction & file resolution
│       │   ├── FileWatcher.swift       # Kernel DispatchSourceFileSystemObject watcher
│       │   ├── TOCParser.swift         # Regex/AST heading extractor & statistics calculator
│       │   └── Exporter.swift          # PDF export & HTML clipboard service
│       ├── Views/
│       │   ├── DocumentTabBarView.swift    # Tactile elevated card tabs with close buttons & (+) action
│       │   ├── ContentViewController.swift # WKWebView container & in-page search bar
│       │   ├── SidebarViewController.swift # NSTableView outline & stats footer card
│       │   ├── DroppableContainerView.swift# Window-level drag & drop with HUD overlay
│       │   └── DroppableWKWebView.swift    # WebKit drag & drop destination
│       └── Resources/
│           ├── AppIcon.icns         # High-resolution multi-scale Apple icon
│           ├── AppIcon.png          # 1024x1024 master icon PNG
│           ├── index.html           # Offline HTML skeleton
│           ├── styles.css           # GitHub-grade typography & theme CSS
│           ├── app.js               # Marked.js + KaTeX + Prism + Mermaid JS bridge
│           └── vendor/              # Bundled offline JS, CSS, and KaTeX fonts
```

---

## 🔒 Privacy & Support

- **Privacy Policy:** [PRIVACY.md](PRIVACY.md) &bull; [Web Version](https://slemay.github.io/mdviewer/privacy.html)
- **Support & FAQ:** [SUPPORT.md](SUPPORT.md) &bull; [Web Version](https://slemay.github.io/mdviewer/support.html)
- **Issue Tracker:** [GitHub Issues](https://github.com/slemay/mdviewer/issues)
