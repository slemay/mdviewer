import Foundation

public struct DocumentStats: Sendable {
    public let wordCount: Int
    public let charCount: Int
    public let readingTimeMinutes: Int
    public let headings: [HeadingItem]
}

public enum TOCParser {
    public static func parse(markdown: String) -> DocumentStats {
        let lines = markdown.components(separatedBy: .newlines)
        var headings: [HeadingItem] = []
        var inCodeBlock = false
        var wordCount = 0
        var charCount = 0

        // Track slug counts to handle duplicate headings like # Overview, # Overview -> overview, overview-1
        var slugOccurrences: [String: Int] = [:]

        for (lineIndex, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Check for code fences
            if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") {
                inCodeBlock.toggle()
                continue
            }

            if inCodeBlock {
                continue
            }

            // Calculate words & characters
            charCount += line.count
            let words = line.split { $0.isWhitespace || $0.isPunctuation }
            wordCount += words.count

            // Heading detection (# ... ######)
            if trimmed.hasPrefix("#") {
                var level = 0
                for char in trimmed {
                    if char == "#" {
                        level += 1
                    } else {
                        break
                    }
                }

                if level >= 1 && level <= 6 {
                    let remainder = trimmed.dropFirst(level)
                    if remainder.first == " " || remainder.first == "\t" {
                        let rawTitle = remainder.trimmingCharacters(in: .whitespaces)
                        let cleanTitle = stripMarkdownFormatting(from: rawTitle)
                        if !cleanTitle.isEmpty {
                            let baseSlug = slugify(cleanTitle)
                            let finalSlug: String
                            if let count = slugOccurrences[baseSlug] {
                                slugOccurrences[baseSlug] = count + 1
                                finalSlug = "\(baseSlug)-\(count)"
                            } else {
                                slugOccurrences[baseSlug] = 1
                                finalSlug = baseSlug
                            }

                            headings.append(HeadingItem(
                                id: finalSlug,
                                title: cleanTitle,
                                level: level,
                                lineIndex: lineIndex
                            ))
                        }
                    }
                }
            }
        }

        let readTime = max(1, Int(ceil(Double(wordCount) / 200.0)))

        return DocumentStats(
            wordCount: wordCount,
            charCount: charCount,
            readingTimeMinutes: readTime,
            headings: headings
        )
    }

    public static func slugify(_ text: String) -> String {
        let lower = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        // Keep alphanumeric, hyphens, and whitespace
        let filtered = lower.filter { $0.isLetter || $0.isNumber || $0.isWhitespace || $0 == "-" }
        let withHyphens = filtered.split { $0.isWhitespace || $0 == "-" }.joined(separator: "-")
        return withHyphens.isEmpty ? "heading" : withHyphens
    }

    private static func stripMarkdownFormatting(from text: String) -> String {
        var result = text
        // Strip images ![alt](url) -> alt
        result = result.replacingOccurrences(of: #"!\[(.*?)\]\(.*?\)"#, with: "$1", options: .regularExpression)
        // Strip links [text](url) -> text
        result = result.replacingOccurrences(of: #"\[(.*?)\]\(.*?\)"#, with: "$1", options: .regularExpression)
        // Strip bold/italic ***text***, **text**, *text*, __text__, _text_
        result = result.replacingOccurrences(of: #"(\*\*|\*|__|_|~~|`)"#, with: "", options: .regularExpression)
        return result.trimmingCharacters(in: .whitespaces)
    }
}
