// ============================================================================
// apfel-tag unit tests - pure Swift harness (no XCTest). Run:
//   swift run apfel-tag-tests
// ============================================================================

import Foundation
import ApfelTagCore

// MARK: - Minimal harness

nonisolated(unsafe) var _passed = 0
nonisolated(unsafe) var _failed = 0

struct TestFailure: Error, CustomStringConvertible {
    let description: String
    init(_ msg: String) { description = msg }
}

func test(_ name: String, _ block: () throws -> Void) {
    do {
        try block()
        print("  ✅ \(name)")
        _passed += 1
    } catch {
        print("  ❌ \(name): \(error)")
        _failed += 1
    }
}

func assertEqual<T: Equatable>(_ a: T, _ b: T, _ msg: String = "") throws {
    guard a == b else { throw TestFailure("\(a) != \(b)\(msg.isEmpty ? "" : " — \(msg)")") }
}
func assertTrue(_ v: Bool, _ msg: String = "") throws {
    guard v else { throw TestFailure("expected true\(msg.isEmpty ? "" : " — \(msg)")") }
}
func assertNil<T>(_ v: T?, _ msg: String = "") throws {
    guard v == nil else { throw TestFailure("expected nil\(msg.isEmpty ? "" : " — \(msg)")") }
}
func suite(_ name: String, _ block: () -> Void) {
    print("\n\(name)")
    block()
}

// MARK: - Args

func runArgsTests() {
    test("defaults") {
        let a = try TagArgs.parse([])
        try assertEqual(a.mode, .run)
        try assertEqual(a.output, .plain)
        try assertEqual(a.kind, .tags)
        try assertNil(a.maxTags)
        try assertTrue(!a.permissive && !a.quiet && !a.noColor)
    }
    test("-o json / --output json") {
        try assertEqual(try TagArgs.parse(["-o", "json"]).output, .json)
        try assertEqual(try TagArgs.parse(["--output", "json"]).output, .json)
    }
    test("invalid output throws") {
        do { _ = try TagArgs.parse(["-o", "yaml"]); throw TestFailure("should throw") }
        catch let e as ArgError { try assertTrue(e.message.contains("invalid output")) }
    }
    test("--output missing value throws") {
        do { _ = try TagArgs.parse(["-o"]); throw TestFailure("should throw") }
        catch let e as ArgError { try assertTrue(e.message.contains("requires a value")) }
    }
    test("--kind values") {
        try assertEqual(try TagArgs.parse(["--kind", "emotions"]).kind, .emotions)
        try assertEqual(try TagArgs.parse(["--kind", "ALL"]).kind, .all)
    }
    test("invalid kind throws") {
        do { _ = try TagArgs.parse(["--kind", "vibes"]); throw TestFailure("should throw") }
        catch let e as ArgError { try assertTrue(e.message.contains("invalid kind")) }
    }
    test("--max-tags positive") {
        try assertEqual(try TagArgs.parse(["--max-tags", "3"]).maxTags, 3)
    }
    test("--max-tags zero/negative throws") {
        for v in ["0", "-1"] {
            do { _ = try TagArgs.parse(["--max-tags", v]); throw TestFailure("should throw for \(v)") }
            catch let e as ArgError { try assertTrue(e.message.contains("positive")) }
        }
    }
    test("--permissive / -q / --no-color") {
        try assertTrue(try TagArgs.parse(["--permissive"]).permissive)
        try assertTrue(try TagArgs.parse(["-q"]).quiet)
        try assertTrue(try TagArgs.parse(["--no-color"]).noColor)
    }
    test("NO_COLOR env sets noColor") {
        try assertTrue(try TagArgs.parse([], env: ["NO_COLOR": "1"]).noColor)
        try assertTrue(!(try TagArgs.parse([], env: ["NO_COLOR": ""]).noColor))
    }
    test("help / version modes") {
        try assertEqual(try TagArgs.parse(["--help"]).mode, .help)
        try assertEqual(try TagArgs.parse(["-h"]).mode, .help)
        try assertEqual(try TagArgs.parse(["--version"]).mode, .version)
        try assertEqual(try TagArgs.parse(["-v"]).mode, .version)
    }
    test("unknown option throws") {
        do { _ = try TagArgs.parse(["--bogus"]); throw TestFailure("should throw") }
        catch let e as ArgError { try assertTrue(e.message.contains("unknown option")) }
    }
}

// MARK: - TagPolicy

func runTagPolicyTests() {
    test("trims and drops empties") {
        try assertEqual(TagPolicy.normalize(["  a ", "", "  ", "b"]), ["a", "b"])
    }
    test("dedups case-insensitively, preserves first casing + order") {
        try assertEqual(TagPolicy.normalize(["Swift", "swift", "Apple", "SWIFT"]), ["Swift", "Apple"])
    }
    test("maxTags caps") {
        try assertEqual(TagPolicy.normalize(["a", "b", "c", "d"], maxTags: 2), ["a", "b"])
    }
    test("maxTags larger than count is a no-op") {
        try assertEqual(TagPolicy.normalize(["a", "b"], maxTags: 9), ["a", "b"])
    }
    test("TagSet.allValues dedups across groups") {
        let set = TagSet(groups: [
            TagGroup(kind: "topics", values: ["news", "finance"]),
            TagGroup(kind: "actions", values: ["finance", "report"]),
        ])
        try assertEqual(set.allValues, ["news", "finance", "report"])
    }
}

// MARK: - Output

func runOutputTests() {
    test("plain is newline-joined") {
        try assertEqual(TagOutputFormatter.plain(TagSet(tags: ["a", "b", "c"])), "a\nb\nc")
    }
    test("json single group uses 'tags' key") {
        let json = TagOutputFormatter.json(TagSet(tags: ["x", "y"]))
        try assertTrue(json.contains("\"tags\""))
        try assertTrue(json.contains("\"x\"") && json.contains("\"y\""))
    }
    test("json all-kind uses category keys") {
        let set = TagSet(groups: [
            TagGroup(kind: "topics", values: ["a"]),
            TagGroup(kind: "emotions", values: ["joy"]),
            TagGroup(kind: "actions", values: ["run"]),
        ])
        let json = TagOutputFormatter.json(set)
        try assertTrue(json.contains("\"topics\"") && json.contains("\"emotions\"") && json.contains("\"actions\""))
    }
    test("render dispatches on format") {
        let set = TagSet(tags: ["one"])
        try assertEqual(TagOutputFormatter.render(set, as: .plain), "one")
        try assertTrue(TagOutputFormatter.render(set, as: .json).contains("\"tags\""))
    }
}

// MARK: - TagKind

func runTagKindTests() {
    test("parse case-insensitive") {
        try assertEqual(TagKind.parse("Topics"), .topics)
        try assertEqual(TagKind.parse("ALL"), .all)
        try assertNil(TagKind.parse("nope"))
    }
    test("allCases covers the five kinds") {
        try assertEqual(Set(TagKind.allCases), Set([.tags, .topics, .emotions, .actions, .all]))
    }
}

// MARK: - Run

suite("ArgsTests") { runArgsTests() }
suite("TagPolicyTests") { runTagPolicyTests() }
suite("OutputTests") { runOutputTests() }
suite("TagKindTests") { runTagKindTests() }

print("\n─────────────────────────────────")
if _failed == 0 {
    print("✅ All \(_passed) tests passed")
} else {
    print("❌ \(_failed) failed, \(_passed) passed")
    exit(1)
}
