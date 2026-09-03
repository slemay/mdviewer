import Foundation
import AppKit

public struct MarkdownValidationResult: Sendable {
    public let isValid: Bool
    public let effectiveURL: URL?
    public let failureReason: String?

    public static func valid(url: URL) -> MarkdownValidationResult {
        MarkdownValidationResult(isValid: true, effectiveURL: url, failureReason: nil)
    }

    public static func invalid(reason: String) -> MarkdownValidationResult {
        MarkdownValidationResult(isValid: false, effectiveURL: nil, failureReason: reason)
    }
}

public enum MarkdownValidator {
    public static let supportedExtensions: Set<String> = [
        "md", "markdown", "mdown", "mkdn", "mkd", "mdwn", "mdtxt", "mdtext", "text", "txt"
    ]

    public static let knownBinaryExtensions: Set<String> = [
        "png", "jpg", "jpeg", "gif", "webp", "bmp", "tiff", "heic", "svgz", "ico", "psd", "ai",
        "pdf", "zip", "tar", "gz", "bz2", "xz", "7z", "rar", "dmg", "iso", "pkg", "deb", "rpm",
        "exe", "bin", "dylib", "so", "a", "o", "class", "pyc", "wasm", "app", "framework",
        "mp3", "m4a", "wav", "flac", "aac", "ogg", "mp4", "mov", "avi", "mkv", "webm", "m4v",
        "sqlite", "sqlite3", "db", "db3", "parquet", "arrow", "feather",
        "doc", "docx", "xls", "xlsx", "ppt", "pptx", "pages", "numbers", "keynote"
    ]

    /// Validates whether a file at `url` exists, is readable, and contains valid Markdown/plain-text data.
    public static func validate(url: URL) -> MarkdownValidationResult {
        let path = url.path
        var isDir: ObjCBool = false

        // 1. Existence check
        guard FileManager.default.fileExists(atPath: path, isDirectory: &isDir) else {
            return .invalid(reason: "The file at '\(url.lastPathComponent)' does not exist.")
        }

        // 2. Directory check: look for README.md or index.md inside
        if isDir.boolValue {
            let candidates = ["README.md", "readme.md", "README.markdown", "Readme.md", "INDEX.md", "index.md"]
            for candidate in candidates {
                let candidateURL = url.appendingPathComponent(candidate)
                if FileManager.default.fileExists(atPath: candidateURL.path) {
                    return validate(url: candidateURL)
                }
            }
            return .invalid(reason: "The folder '\(url.lastPathComponent)' does not contain a README.md or index.md file.")
        }

        // 3. Known binary extension check
        let ext = url.pathExtension.lowercased()
        if knownBinaryExtensions.contains(ext) {
            return .invalid(reason: "'\(url.lastPathComponent)' is a binary file (.\(ext)) and cannot be opened as Markdown.")
        }

        // 4. File readability check (permissions)
        guard FileManager.default.isReadableFile(atPath: path) else {
            return .invalid(reason: "Permission denied: Cannot read '\(url.lastPathComponent)'.")
        }

        // 5. Inspect initial bytes for null bytes (binary heuristic) and valid text encoding
        do {
            let fileHandle = try FileHandle(forReadingFrom: url)
            defer { try? fileHandle.close() }

            guard let initialData = try fileHandle.read(upToCount: 8192), !initialData.isEmpty else {
                // Empty files are valid text documents
                return .valid(url: url)
            }

            // Detect binary null bytes (0x00)
            if containsBinaryNullBytes(initialData) {
                return .invalid(reason: "'\(url.lastPathComponent)' contains binary data and cannot be displayed as a text document.")
            }

            // Verify decodable text encoding
            if String(data: initialData, encoding: .utf8) == nil &&
               String(data: initialData, encoding: .ascii) == nil &&
               String(data: initialData, encoding: .isoLatin1) == nil &&
               String(data: initialData, encoding: .utf16) == nil {
                return .invalid(reason: "'\(url.lastPathComponent)' does not appear to be a readable text or Markdown document.")
            }

            return .valid(url: url)
        } catch {
            return .invalid(reason: "Unable to read '\(url.lastPathComponent)': \(error.localizedDescription)")
        }
    }

    /// Git-style heuristic: check for null bytes (0x00) in the initial byte chunk
    public static func containsBinaryNullBytes(_ data: Data) -> Bool {
        for byte in data {
            if byte == 0 {
                return true
            }
        }
        return false
    }

    /// Helper to show a native NSAlert if validation fails
    @MainActor
    public static func presentAlertIfInvalid(for url: URL, in window: NSWindow? = nil) -> Bool {
        let result = validate(url: url)
        if !result.isValid {
            let alert = NSAlert()
            alert.messageText = "Cannot Open Document"
            alert.informativeText = result.failureReason ?? "The selected file is not a valid Markdown or text document."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            if let window = window {
                alert.beginSheetModal(for: window, completionHandler: nil)
            } else {
                alert.runModal()
            }
            return false
        }
        return true
    }
}
