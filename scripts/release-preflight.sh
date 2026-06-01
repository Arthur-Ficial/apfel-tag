#!/usr/bin/env bash
# apfel-tag release preflight: clean tree, on main, synced, build, tests, policy, version.
set -euo pipefail
fail() { echo "FAIL: $1"; exit 1; }
pass() { echo "PASS: $1"; }

[ -z "$(git status --porcelain)" ] || fail "working tree not clean"
pass "working tree clean"
b=$(git rev-parse --abbrev-ref HEAD); [ "$b" = "main" ] || fail "on '$b', expected main"
pass "on main"
git fetch origin main --quiet 2>/dev/null || true
if git rev-parse origin/main >/dev/null 2>&1; then
  [ "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)" ] || fail "not in sync with origin/main"
  pass "in sync with origin/main"
fi
make build >/dev/null || fail "build failed"
pass "release build + man page"
make unit >/dev/null || fail "unit tests failed"
pass "unit tests"
python3 -m pytest Tests/integration/ -q >/dev/null || fail "integration tests failed"
pass "integration tests"
for f in LICENSE README.md; do [ -f "$f" ] || fail "$f missing"; done
pass "policy files"
v=$(cat .version); bin_v=$(.build/release/apfel-tag --version | sed 's/apfel-tag v//'); \
  [ "$v" = "$bin_v" ] || fail "version mismatch (.version=$v binary=$bin_v)"
pass "version matches ($v)"
echo "ALL CHECKS PASSED"
