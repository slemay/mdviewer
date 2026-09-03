import Foundation

public struct HeadingItem: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let level: Int
    public let lineIndex: Int

    public init(id: String, title: String, level: Int, lineIndex: Int) {
        self.id = id
        self.title = title
        self.level = level
        self.lineIndex = lineIndex
    }
}
