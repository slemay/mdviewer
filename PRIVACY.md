# Privacy Policy for MDViewer

**Last Updated:** September 3, 2026

MDViewer ("the Application") is developed as an offline-first, native Markdown viewer for macOS. We believe in privacy by design.

---

### 1. Zero Data Collection

* **We do not collect, transmit, store, or sell any personal data.**
* The Application does not contain any analytics, telemetry, tracking libraries, crash reporters, or advertising SDKs.
* No accounts, logins, or personal information are required to use MDViewer.

---

### 2. Local Document Processing

* All Markdown parsing, math rendering (KaTeX), code syntax highlighting (Prism), and diagram generation (Mermaid) happen **strictly on your device**.
* Your files, documents, text content, and file paths never leave your local machine and are never transmitted to any external server.

---

### 3. Network Usage

* The Application does not communicate with external servers for its core functionality.
* The only network activity that may occur is when a Markdown document explicitly references an external image URL (e.g., `![badge](https://example.com/badge.svg)`). In this case, macOS WebKit fetches the image directly from that third-party server to display it within your preview. No data is sent by MDViewer.

---

### 4. App Sandboxing & Permissions

MDViewer complies fully with Apple's Mac App Store Sandboxing guidelines:
* **User-Selected Files:** The Application only accesses files that you explicitly open via double-click in Finder, drag & drop onto the app window, or the standard system Open dialog (`NSOpenPanel`).
* **Temporary File Descriptors:** File monitoring for live sync operates via kernel-level file descriptors strictly scoped to open documents.

---

### 5. Third-Party Libraries

MDViewer bundles the following open-source libraries:
* **Marked.js** (MIT License) - Markdown compilation
* **KaTeX** (MIT License) - LaTeX math typesetting
* **Prism.js** (MIT License) - Code syntax highlighting
* **Mermaid.js** (MIT License) - Diagram rendering

All libraries are bundled statically within the application binary and operate 100% offline without remote network connections.

---

### 6. Contact & Inquiries

If you have any questions or feedback regarding this Privacy Policy, please open an issue on GitHub or reach out:

* **GitHub Issues:** [https://github.com/slemay/mdviewer/issues](https://github.com/slemay/mdviewer/issues)
* **Repository:** [https://github.com/slemay/mdviewer](https://github.com/slemay/mdviewer)
