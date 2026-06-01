// ============================================================================
// apfel-tag - classify piped text into tags using Apple's on-device
// content-tagging model (SystemLanguageModel(useCase: .contentTagging)).
// 100% on-device, no network. Sister tool to apfel.
// ============================================================================

import Foundation
import FoundationModels
import ApfelTagCore

// MARK: - Generable shapes

/// Single-category tag result (default, topics, emotions, actions).
@Generable
struct TagResult: Equatable {
    @Guide(description: "Relevant short labels for the requested category, lowercase.")
    var tags: [String]
}

/// Multi-category result for `--kind all`.
@Generable
struct AllTagsResult: Equatable {
    @Guide(description: "Subject topics, lowercase.")
    var topics: [String]
    @Guide(description: "Emotional tone labels, lowercase.")
    var emotions: [String]
    @Guide(description: "Actions or activities described, lowercase.")
    var actions: [String]
}

// MARK: - Helpers

func fail(_ message: String, code: Int32) -> Never {
    FileHandle.standardError.write(Data("error: \(message)\n".utf8))
    exit(code)
}

func readStdin() -> String {
    guard isatty(STDIN_FILENO) == 0 else { return "" }
    var lines: [String] = []
    while let line = readLine(strippingNewline: false) { lines.append(line) }
    return lines.joined().trimmingCharacters(in: .whitespacesAndNewlines)
}

func makeModel(permissive: Bool) -> SystemLanguageModel {
    if permissive {
        return SystemLanguageModel(useCase: .contentTagging, guardrails: .permissiveContentTransformations)
    }
    return SystemLanguageModel(useCase: .contentTagging)
}

// MARK: - Main

let argv = Array(CommandLine.arguments.dropFirst())

let args: TagArgs
do {
    args = try TagArgs.parse(argv, env: ProcessInfo.processInfo.environment)
} catch let e as ArgError {
    fail(e.message, code: ExitCodes.usage)
}

switch args.mode {
case .version:
    print("apfel-tag v\(buildVersion)")
    exit(ExitCodes.ok)
case .help:
    print(helpText)
    exit(ExitCodes.ok)
case .run:
    break
}

let input = readStdin()
guard !input.isEmpty else {
    fail("no input provided -- pipe text to classify, e.g. echo \"...\" | apfel-tag", code: ExitCodes.usage)
}

let model = makeModel(permissive: args.permissive)

func runTagging() async -> TagSet {
    let session = LanguageModelSession(model: model)
    do {
        if args.kind == .all {
            let r = try await session.respond(
                to: "Extract topics, emotions, and actions from the following text:\n\n\(input)",
                generating: AllTagsResult.self
            ).content
            return TagSet(groups: [
                TagGroup(kind: "topics", values: TagPolicy.normalize(r.topics, maxTags: args.maxTags)),
                TagGroup(kind: "emotions", values: TagPolicy.normalize(r.emotions, maxTags: args.maxTags)),
                TagGroup(kind: "actions", values: TagPolicy.normalize(r.actions, maxTags: args.maxTags)),
            ])
        } else {
            let prompt = args.kind == .tags
                ? input
                : "Extract \(args.kind.guidance) from the following text:\n\n\(input)"
            let r = try await session.respond(to: prompt, generating: TagResult.self).content
            return TagSet(tags: TagPolicy.normalize(r.tags, maxTags: args.maxTags))
        }
    } catch {
        fail(classify(error), code: ExitCodes.error)
    }
}

let set = await runTagging()
let rendered = TagOutputFormatter.render(set, as: args.output)
print(rendered, terminator: args.output == .json ? "\n" : "\n")

/// Map FoundationModels errors to short, friendly messages.
func classify(_ error: Error) -> String {
    let desc = String(reflecting: error).lowercased()
    if desc.contains("refus") || desc.contains("unsafe") || desc.contains("guardrail") {
        return "the on-device model refused the request (try --permissive). \(error.localizedDescription)"
    }
    if desc.contains("unavailable") || desc.contains("notready") || desc.contains("noteligible") {
        return "Apple Intelligence is unavailable. Enable it in System Settings, or check `apfel-tag` requirements."
    }
    return error.localizedDescription
}
