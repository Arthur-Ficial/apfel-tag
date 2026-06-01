# apfel-tag - project instructions

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
