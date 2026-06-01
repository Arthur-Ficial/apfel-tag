// ============================================================================
// TagKind.swift - the kinds of labels apfel-tag can request from the
// on-device content-tagging model. Pure: no FoundationModels dependency.
// ============================================================================

/// The category of labels to extract from the input text.
public enum TagKind: String, Sendable, Equatable, CaseIterable {
    /// General topic/keyword tags (default).
    case tags
    /// Subject topics.
    case topics
    /// Emotional tone labels.
    case emotions
    /// Action/verb labels.
    case actions
    /// All categories at once (topics + emotions + actions).
    case all

    /// Parse a user-supplied `--kind` value (case-insensitive). Returns nil if
    /// unrecognized.
    public static func parse(_ raw: String) -> TagKind? {
        TagKind(rawValue: raw.lowercased())
    }

    /// Human-readable guidance handed to the model to steer the labels.
    public var guidance: String {
        switch self {
        case .tags:     return "general topic and keyword tags"
        case .topics:   return "subject topics"
        case .emotions: return "emotional tone labels"
        case .actions:  return "actions or activities described"
        case .all:      return "topics, emotions, and actions"
        }
    }
}
