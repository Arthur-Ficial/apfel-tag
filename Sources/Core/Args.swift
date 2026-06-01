// ============================================================================
// Args.swift - pure argument parsing for apfel-tag. No I/O, no exit().
// ============================================================================

import Foundation

public struct ArgError: Error, Equatable, CustomStringConvertible {
    public let message: String
    public init(_ message: String) { self.message = message }
    public var description: String { message }
}

public struct TagArgs: Equatable, Sendable {
    public enum Mode: Equatable, Sendable { case run, help, version }

    public var mode: Mode = .run
    public var output: OutputFormat = .plain
    public var kind: TagKind = .tags
    public var maxTags: Int? = nil
    public var permissive: Bool = false
    public var quiet: Bool = false
    public var noColor: Bool = false

    public init() {}

    /// Pure parser. `env` is injectable for testing (NO_COLOR).
    /// Throws `ArgError` on invalid input.
    public static func parse(_ args: [String], env: [String: String] = [:]) throws -> TagArgs {
        var result = TagArgs()
        if env["NO_COLOR"].map({ !$0.isEmpty }) == true { result.noColor = true }

        var i = 0
        while i < args.count {
            let arg = args[i]
            switch arg {
            case "-h", "--help":
                result.mode = .help
                return result
            case "-v", "--version":
                result.mode = .version
                return result
            case "-o", "--output":
                i += 1
                guard i < args.count else { throw ArgError("\(arg) requires a value (plain|json)") }
                guard let fmt = OutputFormat(rawValue: args[i].lowercased()) else {
                    throw ArgError("invalid output format '\(args[i])' (expected plain or json)")
                }
                result.output = fmt
            case "--kind":
                i += 1
                guard i < args.count else { throw ArgError("--kind requires a value (\(TagKind.allCases.map(\.rawValue).joined(separator: "|")))") }
                guard let k = TagKind.parse(args[i]) else {
                    throw ArgError("invalid kind '\(args[i])' (expected \(TagKind.allCases.map(\.rawValue).joined(separator: ", ")))")
                }
                result.kind = k
            case "--max-tags":
                i += 1
                guard i < args.count, let n = Int(args[i]), n > 0 else {
                    throw ArgError("--max-tags requires a positive number")
                }
                result.maxTags = n
            case "--permissive":
                result.permissive = true
            case "-q", "--quiet":
                result.quiet = true
            case "--no-color":
                result.noColor = true
            default:
                throw ArgError("unknown option: \(arg)")
            }
            i += 1
        }
        return result
    }
}
