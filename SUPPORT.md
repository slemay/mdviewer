# MDViewer Support & Help Center

Welcome to the **MDViewer Support Page**. If you encounter an issue, have a question, or would like to request a feature, we are here to help.

---

### 📬 How to Contact Support & Report Issues

The fastest way to get support is through our official GitHub repository:

* **Bug Reports & Issues:** [https://github.com/slemay/mdviewer/issues](https://github.com/slemay/mdviewer/issues)
* **Feature Requests & Ideas:** [https://github.com/slemay/mdviewer/issues/new](https://github.com/slemay/mdviewer/issues/new)
* **Source Repository:** [https://github.com/slemay/mdviewer](https://github.com/slemay/mdviewer)

When submitting a bug report, please include:
1. Your macOS version (e.g., macOS 14 Sonoma, macOS 15 Sequoia).
2. The version of MDViewer (check `MDViewer > About MDViewer`).
3. A brief description of what happened and steps to reproduce.
4. (Optional) A snippet of the Markdown file causing the issue.

---

### ❓ Frequently Asked Questions (FAQ)

#### 1. How do I open Markdown files in MDViewer?
You have multiple convenient ways:
* **Double-Click:** Set MDViewer as your default app for `.md` files in Finder (`Right-click file > Get Info > Open with > Change All...`).
* **Drag & Drop:** Drag any `.md` file or folder directly onto the MDViewer window or Dock icon.
* **File Menu:** Press `Cmd + O` to open a file picker.
* **Terminal:** Type `mdviewer path/to/document.md`.

#### 2. How does Live Sync work?
MDViewer automatically monitors opened files using macOS kernel-level events (`DispatchSourceFileSystemObject`). Whenever you save changes in your favorite external editor (such as Neovim, Helix, VS Code, or Sublime Text), MDViewer refreshes instantly while preserving your exact scroll position.

#### 3. How do I install the command-line tool?
Go to **MDViewer > Settings...** (`Cmd + ,`), select the **Terminal Integration** tab, and click **Install to ~/.local/bin**. Ensure `~/.local/bin` is in your `$PATH`.

#### 4. Which Markdown extensions are supported?
* **Mathematics (KaTeX):** Inline equations (`$E=mc^2$`) and display blocks (`$$\int f(x) dx$$`).
* **Diagrams (Mermaid):** Flowcharts, sequence diagrams, and architecture maps (` ```mermaid `).
* **Code Syntax Highlighting (Prism):** Syntax highlighting with line numbers and one-click copy button.
* **GitHub Callouts:** Native support for `[!NOTE]`, `[!TIP]`, `[!IMPORTANT]`, `[!WARNING]`, and `[!CAUTION]`.
* **Task Lists & Tables:** GitHub Flavored Markdown (GFM) tables and checkboxes.

#### 5. How do I export to PDF or HTML?
* **Export PDF:** Choose `File > Save as PDF...` (`Cmd + P`).
* **Copy Rendered HTML:** Choose `Edit > Copy Rendered HTML` (`Cmd + Shift + C`).
* **Copy Markdown Source:** Choose `Edit > Copy Markdown Source`.

#### 6. How do I customize themes and typography?
Use the toolbar menus or press `Cmd + ,` to open **Settings**, where you can configure:
* **Themes:** System (Auto Light/Dark), GitHub Light, GitHub Dark, Dracula, Nord, Sepia.
* **Typography:** San Francisco (Sans), New York (Serif), SF Mono.
* **Font & Media Scaling:** `Cmd + +` to zoom in, `Cmd + -` to zoom out, `Cmd + 0` to reset. All images, Mermaid diagrams, and embedded media scale proportionally with your font size without clipping.

#### 7. Why did MDViewer display "Cannot Open Document"?
MDViewer performs pre-flight verification on all files before opening to ensure security and prevent rendering glitches. It verifies:
* That the target file exists and has read permissions.
* That the file is not an unsupported binary format (e.g., images, archives, PDFs, executables).
* That the file does not contain binary null bytes (`0x00`) or unreadable encodings (catching binary files disguised as `.md`).
* If opening a folder, that the folder contains a `README.md` or `index.md`.

---

### 🔒 Privacy

MDViewer is strictly offline and privacy-first. We do not collect telemetry, track usage, or upload documents to external servers. See our [Privacy Policy](PRIVACY.md) for full details.
