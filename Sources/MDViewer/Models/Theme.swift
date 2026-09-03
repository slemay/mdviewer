import Foundation

public enum AppTheme: String, CaseIterable, Identifiable, Sendable {
    case system = "system"
    case githubLight = "github-light"
    case githubDark = "github-dark"
    case dracula = "dracula"
    case nord = "nord"
    case sepia = "sepia"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .system: return "System (Auto)"
        case .githubLight: return "GitHub Light"
        case .githubDark: return "GitHub Dark"
        case .dracula: return "Dracula"
        case .nord: return "Nord"
        case .sepia: return "Sepia"
        }
    }

    public var iconName: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .githubLight: return "sun.max"
        case .githubDark: return "moon.fill"
        case .dracula: return "sparkles"
        case .nord: return "snowflake"
        case .sepia: return "book.closed"
        }
    }
}

public enum AppFontFamily: String, CaseIterable, Identifiable, Sendable {
    case sans = "sans"
    case serif = "serif"
    case mono = "mono"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .sans: return "San Francisco (Sans)"
        case .serif: return "New York (Serif)"
        case .mono: return "SF Mono"
        }
    }
}
