// ============================================================================
// Output.swift - format a TagSet as plain text or JSON. Pure, deterministic.
// ============================================================================

import Foundation

public enum OutputFormat: String, Sendable, Equatable {
    case plain
    case json
}

public enum TagOutputFormatter {
    /// Plain output: one tag per line (pipe-friendly: `| while read tag`).
    /// Across all groups, de-duplicated.
    public static func plain(_ set: TagSet) -> String {
        set.allValues.joined(separator: "\n")
    }

    /// JSON output.
    /// - Single group -> `{"tags":[...]}` (stable key for piping into `jq`).
    /// - Multiple groups (`--kind all`) -> `{"topics":[...],"emotions":[...],...}`.
    public static func json(_ set: TagSet) -> String {
        let obj: [String: [String]]
        if set.groups.count <= 1 {
            obj = ["tags": set.groups.first?.values ?? []]
        } else {
            var d: [String: [String]] = [:]
            for g in set.groups { d[g.kind] = g.values }
            obj = d
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(obj),
              let str = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return str
    }

    public static func render(_ set: TagSet, as format: OutputFormat) -> String {
        switch format {
        case .plain: return plain(set)
        case .json:  return json(set)
        }
    }
}
