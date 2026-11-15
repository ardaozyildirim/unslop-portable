#!/usr/bin/env bash
# Brings new upstream (heydamir/unslop) changes into skills/unslop-portable.
# Usage: scripts/sync-upstream.sh [--check]
#   --check   only report whether upstream moved, change nothing
# The last upstream commit this port has absorbed is recorded in the UPSTREAM file.
set -euo pipefail

UPSTREAM_URL="https://github.com/heydamir/unslop"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

BASE="$(tr -d '[:space:]' < UPSTREAM)"
git remote get-url upstream >/dev/null 2>&1 || git remote add upstream "$UPSTREAM_URL"
git fetch --quiet upstream main
HEAD_SHA="$(git rev-parse upstream/main)"

if [ "$BASE" = "$HEAD_SHA" ]; then
  echo "Up to date with upstream ($HEAD_SHA)."
  exit 0
fi

echo "Upstream moved: ${BASE:0:7} -> ${HEAD_SHA:0:7}"
git --no-pager log --oneline "$BASE..$HEAD_SHA"
echo
echo "Files changed upstream:"
git --no-pager diff --stat "$BASE" "$HEAD_SHA"
[ "${1:-}" = "--check" ] && exit 2

if [ -n "$(git status --porcelain)" ]; then
  echo "Working tree is not clean. Commit or stash first."
  exit 1
fi

BRANCH="sync/upstream-${HEAD_SHA:0:7}"
git switch -c "$BRANCH"

# Map upstream's skills/unslop/ onto this port's skills/unslop-portable/.
# Only header lines are rewritten, never file contents.
PATCH="$(mktemp)"
git diff --binary "$BASE" "$HEAD_SHA" -- skills/unslop \
  | sed -E '/^(diff --git|--- |\+\+\+ |rename (from|to) |copy (from|to) )/ s#skills/unslop/#skills/unslop-portable/#g' > "$PATCH"

if [ -s "$PATCH" ]; then
  if ! git apply --3way "$PATCH"; then
    echo
    echo "Some hunks conflict with this port's changes (SKILL.md header, scripts/*.mjs)."
    echo "Resolve the conflict markers, keeping the port's front matter and browser discovery,"
    echo "then run: git add -A && git commit"
    echo "Patch kept at $PATCH"
    exit 1
  fi
fi

echo "$HEAD_SHA" > UPSTREAM
git add -A
git commit -q -m "chore: sync skill with upstream ${HEAD_SHA:0:7}"

cat <<MSG

Synced skills/ onto branch $BRANCH.
Still to review by hand (not synced automatically):
  - LICENSE, README.md, examples/ upstream changes (see the stat above)
  - If LICENSE changed upstream, copy it over verbatim.
  - Keep the "unofficial port" notice, credit to Damir Sokolovsky, and the
    "What this port changes" list accurate (CC BY 4.0 requires indicating changes).
MSG
