# MDViewer 📖

An ultra-fast, native macOS Markdown reader and live previewer built with Swift and AppKit.

Designed to feel right at home on modern macOS with unified toolbars, translucent sidebars, smooth animations, and instant kernel-level live sync when files are saved externally in editors like Neovim, Helix, or VS Code.

---

## ✨ Features

- **⚡️ Instant Live File Sync**: Automatically monitors opened files with kernel events (`DispatchSourceFileSystemObject`). Saves made in terminal or external editors refresh instantaneously while preserving exact scroll position.
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
- **🔍 In-Page Search**: Fast animated find bar (`Cmd + F`) with match count and cycling.
- **📄 Export & Share**: Direct export to PDF (`Cmd + P`), Copy Rendered HTML (`Cmd + Shift + C`), or copy raw Markdown.
- **📦 100% Offline**: Zero external network dependencies. All fonts, styles, and parsers are bundled inside the app.

---

## 🚀 Quick Start

### Build & Package the App

```bash
./scripts/build_app.sh
```

This compiles the release binary, creates the macOS application bundle at `build/MDViewer.app`, and applies ad-hoc codesigning.

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

---

## ⌨️ Keyboard Shortcuts

| Shortcut | Description |
| :--- | :--- |
| `Cmd + O` | Open a markdown document via file picker |
| `Cmd + R` | Force reload the current document |
| `Cmd + Option + S` | Toggle Outline Sidebar |
| `Cmd + F` | Toggle in-page search overlay |
| `Cmd + P` | Save document as PDF |
| `Cmd + Shift + C` | Copy rendered HTML to clipboard |
| `Cmd + +` | Increase font size |
| `Cmd + -` | Decrease font size |
| `Cmd + 0` | Reset font size to default (16px) |
| `Cmd + W` | Close window |
| `Cmd + Q` | Quit MDViewer |

---

## 🏗 Architecture

```
mdviewer/
├── Package.swift                    # Swift Package Manager manifest (macOS 14+)
├── Info.plist                       # macOS bundle metadata & file association
├── scripts/
│   ├── build_app.sh                 # Compiles & packages build/MDViewer.app
│   └── install_cli.sh               # Installs ~/.local/bin/mdviewer CLI launcher
├── Sources/
│   └── MDViewer/
│       ├── App/
│       │   ├── main.swift           # Native AppKit entrypoint
│       │   └── AppDelegate.swift    # AppKit lifecycle, macOS menus, open events
│       ├── Controllers/
│       │   └── MainWindowController.swift # NSWindowController, NSSplitViewController, NSToolbar
│       ├── Models/
│       │   ├── DocumentState.swift  # Observable document model & listener callbacks
│       │   ├── HeadingItem.swift    # TOC outline item model
│       │   └── Theme.swift          # Themes & font family definitions
│       ├── Services/
│       │   ├── FileWatcher.swift    # Kernel DispatchSourceFileSystemObject watcher
│       │   ├── TOCParser.swift      # Regex/AST heading extractor & statistics calculator
│       │   └── Exporter.swift       # PDF export & HTML clipboard service
│       ├── Views/
│       │   ├── ContentViewController.swift # WKWebView container & in-page search bar
│       │   ├── SidebarViewController.swift # NSTableView outline & stats footer card
│       │   └── DroppableWKWebView.swift    # Drag & drop file destination
│       └── Resources/
│           ├── index.html           # Offline HTML skeleton
│           ├── styles.css           # GitHub-grade typography & theme CSS
│           ├── app.js               # Marked.js + KaTeX + Prism + Mermaid JS bridge
│           └── vendor/              # Bundled offline JS & CSS libraries
```
