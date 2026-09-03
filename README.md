# MDViewer 📖

An ultra-fast, native macOS Markdown reader and live previewer built with Swift and AppKit.

Designed to feel right at home on modern macOS with unified toolbars, full-height translucent sidebars, smooth animations, and instant kernel-level live sync when files are saved externally in editors like Neovim, Helix, or VS Code.

---

## ✨ Features

- **⚡️ Instant Live File Sync**: Automatically monitors opened files with kernel events (`DispatchSourceFileSystemObject`). Saves made in terminal or external editors refresh instantaneously while preserving exact scroll position.
- **🗂 Native Multi-Tab & Multi-Window Support**:
  - Open documents in tabs (`Cmd + T`) or independent windows (`Cmd + N`).
  - Native macOS tab bar with `+` button, drag-and-drop tab reordering, and detachable tabs.
  - Cycle through tabs using standard macOS shortcuts (`Cmd + Shift + [` / `Cmd + Shift + ]`).
  - Merge all windows into tabs (`Window > Merge All Windows`) or move tabs into separate windows.
  - Independent `DocumentState`, kernel file watchers, search states, and scroll positions per tab/window.
- **🎯 Universal Drag & Drop**:
  - Drag `.md` files directly onto the **open window** (sidebar, toolbar, or content area) with an animated visual HUD indicator.
  - Drag files onto the **Dock icon** or the **`MDViewer.app` bundle in Finder** to open immediately.
  - Drop multiple markdown files at once to open them as separate tabs automatically.
  - Drop a directory onto the app to automatically open its `README.md`.
- **📑 Hierarchical Outline (TOC)**: Automatically extracts `H1`–`H6` headings into an interactive sidebar with search filtering and smooth jump-to-section navigation.
- **📊 Document Statistics**: Real-time word count, character count, estimated reading time, file size, and last modified timestamp.
- **🧮 Mathematics (KaTeX)**: Full inline (`$...$`) and block (`$$...$$`) LaTeX equation rendering with bundled TeX fonts.
- **🎨 Code Syntax Highlighting**: Automatic language detection, line numbers, and one-click copy button with clipboard feedback.
- **📊 Mermaid Diagrams**: Native rendering of flowcharts, sequence diagrams, and architecture maps (````mermaid`).
- **💡 GitHub Callouts**: Native styling for `[!NOTE]`, `[!TIP]`, `[!IMPORTANT]`, `[!WARNING]`, and `[!CAUTION]`.
- **🌗 Themes & Typography**:
  - Themes: System (Auto Light/Dark), GitHub Light, GitHub Dark, Dracula, Nord, Sepia.
  - Typography: San Francisco (Sans), New York (Serif), SF Mono.
  - Interactive font scaling (`Cmd +` / `Cmd -` / `Cmd 0`).
- **🔍 In-Page Search**: Fast animated find bar (`Cmd + F`) positioned cleanly below the toolbar with match count and cycling.
- **📄 Export & Share**: Direct export to PDF (`Cmd + P`), Copy Rendered HTML (`Cmd + Shift + C`), or copy raw Markdown.
- **📐 Window State Persistence**: Automatically remembers window dimensions, screen coordinates, and sidebar split width across launches using native AppKit frame autosave.
- **🎨 Native macOS App Icon**: Bundled with a custom high-resolution Apple icon (`AppIcon.icns`) supporting 16×16 through 1024×1024 @2x Retina.
- **📦 100% Offline**: Zero external network dependencies. All fonts, styles, and parsers are bundled inside the app.

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
| `Cmd + Q` | Quit MDViewer |

---

## 🏗 Architecture

```
mdviewer/
├── Package.swift                    # Swift Package Manager manifest (macOS 14+)
├── Info.plist                       # macOS bundle metadata, document types & icon config
├── scripts/
│   ├── build_app.sh                 # Compiles & packages build/MDViewer.app
│   └── install_cli.sh               # Installs ~/.local/bin/mdviewer CLI launcher
├── Sources/
│   └── MDViewer/
│       ├── App/
│       │   ├── main.swift           # Native AppKit entrypoint
│       │   └── AppDelegate.swift    # AppKit lifecycle, macOS menus, Dock/Finder drop
│       ├── Controllers/
│       │   └── MainWindowController.swift # NSWindowController, NSSplitViewController, NSToolbar, Native Tabbing
│       ├── Models/
│       │   ├── DocumentState.swift  # Isolated document model per window/tab & listener callbacks
│       │   ├── HeadingItem.swift    # TOC outline item model
│       │   └── Theme.swift          # Themes & font family definitions
│       ├── Services/
│       │   ├── WindowManager.swift  # Multi-window & multi-tab coordinator
│       │   ├── DragDropHelper.swift # Multi-source pasteboard extraction & file resolution
│       │   ├── FileWatcher.swift    # Kernel DispatchSourceFileSystemObject watcher
│       │   ├── TOCParser.swift      # Regex/AST heading extractor & statistics calculator
│       │   └── Exporter.swift       # PDF export & HTML clipboard service
│       ├── Views/
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
