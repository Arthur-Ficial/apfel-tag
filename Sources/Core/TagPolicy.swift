// ============================================================================
// TagPolicy.swift - normalization of raw model tags. Pure, deterministic.
// ============================================================================

import Foundation

public enum TagPolicy {
    /// Clean a raw list of tags from the model:
    /// - trim surrounding whitespace
    /// - drop empties
    /// - de-duplicate case-insensitively (keeping first-seen casing/order)
    /// - cap to `maxTags` when provided (>= 0)
    public static func normalize(_ raw: [String], maxTags: Int? = nil) -> [String] {
        var seen = Set<String>()
        var out: [String] = []
        for tag in raw {
            let trimmed = tag.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let key = trimmed.lowercased()
            if seen.contains(key) { continue }
            seen.insert(key)
            out.append(trimmed)
        }
        if let m = maxTags, m >= 0, out.count > m {
            out = Array(out.prefix(m))
        }
        return out
    }
}

/// A named group of tags (e.g. "topics" -> [...]). Used for `--kind all`.
public struct TagGroup: Equatable, Sendable {
    public let kind: String
    public let values: [String]
    public init(kind: String, values: [String]) {
        self.kind = kind
        self.values = values
    }
}

/// The full result of a tagging run: one group for a single kind, or several
/// for `--kind all`.
public struct TagSet: Equatable, Sendable {
    public let groups: [TagGroup]
    public init(groups: [TagGroup]) { self.groups = groups }

    /// Convenience for a single-group result keyed "tags".
    public init(tags: [String]) { self.groups = [TagGroup(kind: "tags", values: tags)] }

    /// All values across groups, de-duplicated, in order.
    public var allValues: [String] { TagPolicy.normalize(groups.flatMap { $0.values }) }
}
