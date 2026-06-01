#!/usr/bin/env bash
# apfel-tag release: bump, build, test, commit, tag, push, GitHub release, tap update.
set -euo pipefail
TYPE="${1:-patch}"
cd "$(dirname "$0")/.."

# Preflight (clean, main, synced)
[ -z "$(git status --porcelain)" ] || { echo "tree not clean"; exit 1; }
[ "$(git rev-parse --abbrev-ref HEAD)" = "main" ] || { echo "not on main"; exit 1; }
git fetch origin main --quiet
[ "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)" ] || { echo "not synced with origin/main"; exit 1; }

case "$TYPE" in patch) make release-patch;; minor) make release-minor;; major) make release-major;; *) echo "bad TYPE"; exit 1;; esac
version=$(cat .version)
echo "=== releasing v$version ==="

make unit
python3 -m pytest Tests/integration/ -q

git add .version README.md Sources/BuildInfo.swift
git commit -m "release v$version"
git tag -a "v$version" -m "v$version"
git push origin HEAD:main
git push origin "v$version"

asset=$(make package-release-asset | tail -1)
sha256=$(shasum -a 256 "$asset" | awk '{print $1}')
prev=$(git tag --sort=-v:refname | grep -v "v$version" | head -1 || true)
notes="## apfel-tag v$version"$'\n\n'
[ -n "$prev" ] && notes+=$(git log --oneline "$prev"..HEAD~1 | sed 's/^/- /')$'\n\n'
notes+="Install: \`brew install Arthur-Ficial/tap/apfel-tag\`"
gh release create "v$version" "$asset" --repo Arthur-Ficial/apfel-tag --title "v$version" --notes "$notes"

# Update tap
TAP=$(mktemp -d)
git clone "https://x-access-token:$(gh auth token)@github.com/Arthur-Ficial/homebrew-tap.git" "$TAP" --quiet
make update-homebrew-formula HOMEBREW_FORMULA_OUTPUT="$TAP/Formula/apfel-tag.rb" HOMEBREW_FORMULA_SHA256="$sha256"
( cd "$TAP"; git add Formula/apfel-tag.rb; git -c user.name="Arthur Ficial" -c user.email="arti.ficial@fullstackoptimization.com" commit -m "apfel-tag v$version"; git push origin HEAD )
echo "=== Release v$version complete ==="
echo "  https://github.com/Arthur-Ficial/apfel-tag/releases/tag/v$version"
