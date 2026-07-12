#!/usr/bin/env bash
# Generate the apfel-tag Homebrew formula.
set -euo pipefail
VERSION=""; SHA256=""; OUTPUT=""
while [ $# -gt 0 ]; do case "$1" in
  --version) VERSION="$2"; shift 2;;
  --sha256) SHA256="$2"; shift 2;;
  --output) OUTPUT="$2"; shift 2;;
  *) echo "unknown arg: $1" >&2; exit 1;;
esac; done
[ -n "$VERSION" ] && [ -n "$SHA256" ] && [ -n "$OUTPUT" ] || { echo "usage: --version --sha256 --output" >&2; exit 1; }
cat > "$OUTPUT" <<EOF
class ApfelTag < Formula
  desc "On-device content tagging CLI - classify piped text into tags"
  homepage "https://github.com/Arthur-Ficial/apfel-tag"
  url "https://github.com/Arthur-Ficial/apfel-tag/releases/download/v${VERSION}/apfel-tag-${VERSION}-arm64-macos.tar.gz"
  sha256 "${SHA256}"
  license "MIT"

  depends_on arch: :arm64
  # macOS-only hard block: this tap installs a prebuilt macOS binary with no
  # xcode build-dep, so a bare top-level \`depends_on :macos\` is the only thing
  # that hard-blocks Linux - a versioned \`depends_on macos: :tahoe\` alone is
  # auto-satisfied on Linux ("macOS >= 26 (or Linux)"), and arm64 Linux exists.
  # The version floor lives inside \`on_macos\` because combining both forms
  # top-level is deprecated (prints a runtime warning on every formula load).
  # Same pattern and rationale as Formula/apfel.rb.
  depends_on :macos
  on_macos do
    depends_on macos: :tahoe
  end

  def install
    bin.install "apfel-tag"
    man1.install "apfel-tag.1"
  end

  def caveats
    <<~EOS
      apfel-tag classifies piped text into tags using Apple's on-device
      content-tagging model. No API keys, no network - 100% local.

      Usage:
        echo "Your text here" | apfel-tag
        echo "Your text here" | apfel-tag -o json | jq -r '.tags[]'
        echo "Your text here" | apfel-tag --kind emotions

      Requires macOS 26+ on Apple Silicon with Apple Intelligence enabled.
    EOS
  end

  test do
    assert_match "apfel-tag v#{version}", shell_output("#{bin}/apfel-tag --version")
    assert_path_exists man1/"apfel-tag.1"
  end
end
EOF
echo "wrote formula -> $OUTPUT"
