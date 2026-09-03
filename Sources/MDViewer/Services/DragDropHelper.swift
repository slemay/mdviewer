import AppKit

public enum DragDropHelper {
    public static let supportedExtensions: Set<String> = [
        "md", "markdown", "mdown", "mkdn", "txt", "text"
    ]

    public static func extractMarkdownURL(from pasteboard: NSPasteboard) -> URL? {
        // 1. Try modern NSURL objects
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
            for url in urls {
                if isValidMarkdownFile(url: url) {
                    return url
                }
            }
        }

        // 2. Try pasteboardItems string(forType: .fileURL)
        if let items = pasteboard.pasteboardItems {
            for item in items {
                if let str = item.string(forType: .fileURL), let url = URL(string: str) {
                    if isValidMarkdownFile(url: url) {
                        return url
                    }
                }
            }
        }

        // 3. Try legacy NSFilenamesPboardType
        let filenamesType = NSPasteboard.PasteboardType("NSFilenamesPboardType")
        if let paths = pasteboard.propertyList(forType: filenamesType) as? [String] {
            for path in paths {
                let url = URL(fileURLWithPath: path)
                if isValidMarkdownFile(url: url) {
                    return url
                }
            }
        }

        return nil
    }

    public static func isValidMarkdownFile(url: URL) -> Bool {
        return MarkdownValidator.validate(url: url).isValid
    }

    public static func resolveEffectiveURL(for url: URL) -> URL {
        return MarkdownValidator.validate(url: url).effectiveURL ?? url
    }
}
