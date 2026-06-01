#!/usr/bin/env bash
set -euo pipefail
v=${1:-$(cat .version)}
gh release view "v$v" --repo Arthur-Ficial/apfel-tag --json tagName,assets \
  --jq '"release \(.tagName): \([.assets[].name]|join(","))"' || { echo "FAIL: no release v$v"; exit 1; }
git fetch --tags origin >/dev/null 2>&1 || true
git rev-parse "v$v" >/dev/null 2>&1 && echo "PASS: tag v$v" || echo "WARN: tag v$v not found locally"
echo "Release v$v verified."
