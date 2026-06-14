# apfel-tag - project instructions

## The Golden Goal

apfel-tag does ONE thing: turn text on stdin into content tags on stdout, classified 100% on-device by Apple's `SystemLanguageModel(useCase: .contentTagging)`. It IS a focused, pipe-friendly UNIX tool - plain or JSON output, correct exit codes, label kinds (tags, topics, emotions, actions), no API keys and no network. It is NOT a chat tool, an HTTP server, an MCP host, or a general FoundationModels CLI - that is what its sister tool [apfel](https://github.com/Arthur-Ficial/apfel) is for. Every decision is scored against tagging text cleanly from the command line; anything that grows a second product into this tool is out of scope. Distribution stays Homebrew-tap only, on-device only, honest about its limits.

**On-device content tagging from the command line.** Sister tool to
[apfel](https://github.com/Arthur-Ficial/apfel). Pipe text in, get tags out,
classified by `SystemLanguageModel(useCase: .contentTagging)`. 100% on-device.

## Architecture
- `ApfelTagCore` (Sources/Core): pure Swift, no FoundationModels - arg parsing
  (Args), tag normalization (TagPolicy), output formatting (Output), kinds
  (TagKind), exit codes. Fully unit-tested.
- `apfel-tag` executable (Sources): FoundationModels content-tagging integration
  wiring stdin -> model -> ApfelTagCore -> stdout.
- Tests: `swift run apfel-tag-tests` (pure unit), `Tests/integration/` (pytest,
  model-dependent).

## Build & release
- `make test` (build + unit + integration), `make build`, `make install`.
- `.version` is the source of truth; `make release TYPE=patch|minor|major`.
- Distribution: Homebrew tap only (`Arthur-Ficial/homebrew-tap`, Formula/apfel-tag.rb).
- No server, no MCP, no nixpkgs - keep it a single focused UNIX tool.

## Non-negotiables
- 100% on-device. Honest about limits. Swift 6 strict concurrency. TDD.
- Stay focused: tagging only. Do not grow a second product into this tool.
