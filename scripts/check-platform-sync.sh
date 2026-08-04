#!/usr/bin/env bash
# Fail if the generated platform stubs differ from what the generator would
# write right now. The stubs are generated, so the check is exact: regenerate
# into a scratch tree and diff.
#
# Usage:
#   scripts/check-platform-sync.sh [--root DIR] [--base REL] [--platforms "a b"]
#                                  [--adapter NAME] [--from-index]
#
# --from-index  Check the CONTENT GIT IS ABOUT TO COMMIT rather than the working
#               tree. Partial staging can otherwise commit a stale stub while the
#               working tree is clean, which is a false green. The pre-commit
#               hook always uses this.
#
# Exit: 0 in sync | 1 drift (diff printed) | 2 bad usage

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib-common.sh
. "$HERE/lib-common.sh"

ROOT="$(cd "$HERE/.." && pwd)"
BASE="skills/ui-qa"
PLATFORMS="claude codex"
ADAPTER="playwright-mcp"
FROM_INDEX=0

while [ $# -gt 0 ]; do
  case "$1" in
    --root) ROOT="$2"; shift 2 ;;
    --base) BASE="$2"; shift 2 ;;
    --platforms) PLATFORMS="$2"; shift 2 ;;
    --adapter) ADAPTER="$2"; shift 2 ;;
    --from-index) FROM_INDEX=1; shift ;;
    -h|--help) sed -n '2,18p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) echo "check: unknown argument: $1" >&2; exit 2 ;;
  esac
done

validate_rel_path "$BASE" "--base" || exit 2

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
ACTUAL="$TMP/actual"     # what would be committed (or what is on disk)
EXPECT="$TMP/expect"     # what the generator produces from that same content
mkdir -p "$ACTUAL" "$EXPECT"

if [ "$FROM_INDEX" -eq 1 ]; then
  git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1 || {
    echo "check: --from-index requires a git repository" >&2; exit 2; }
  # Materialize the index exactly as `git commit` would write it.
  git -C "$ROOT" checkout-index -a -f --prefix="$ACTUAL/"
  SOURCE_LABEL="staged index"
else
  # Copy only the paths the check reasons about, so an unrelated build dir
  # cannot slow this down or leak into the diff.
  mkdir -p "$ACTUAL/$(dirname "$BASE")"
  [ -d "$ROOT/$BASE" ] && cp -r "$ROOT/$BASE" "$ACTUAL/$BASE"
  for d in .claude .codex .agents .cursor .gemini; do
    [ -d "$ROOT/$d" ] && cp -r "$ROOT/$d" "$ACTUAL/$d"
  done
  SOURCE_LABEL="working tree"
fi

[ -f "$ACTUAL/$BASE/SKILL.md" ] || {
  echo "check: no canonical skill at $BASE/SKILL.md in the $SOURCE_LABEL" >&2; exit 1; }

# Generate from the same canonical content the actual tree carries.
mkdir -p "$EXPECT/$(dirname "$BASE")"
cp -r "$ACTUAL/$BASE" "$EXPECT/$BASE"

# ...using the generator from that same tree. Under --from-index, running the
# working-tree generator would compare staged content against an UNSTAGED
# generator, so an unstaged generator edit reads as stub drift and a staged one
# reads as clean -- both wrong.
GEN="$HERE/sync-platform-dirs.sh"
if [ "$FROM_INDEX" -eq 1 ]; then
  if [ -f "$ACTUAL/scripts/sync-platform-dirs.sh" ] && [ -f "$ACTUAL/scripts/lib-common.sh" ]; then
    chmod +x "$ACTUAL/scripts/sync-platform-dirs.sh"
    GEN="$ACTUAL/scripts/sync-platform-dirs.sh"
  else
    echo "check: note — no staged generator found; using the working-tree generator" >&2
  fi
fi

"$GEN" --root "$EXPECT" --base "$BASE" \
  --platforms "$PLATFORMS" --adapter "$ADAPTER" >/dev/null

# Diff the union of platform dirs present in EITHER tree. Using the union is
# what makes a wrong --platforms value fail loudly instead of silently
# skipping the dirs it did not generate.
status=0
for d in .claude .codex .agents .cursor .gemini; do
  a="$ACTUAL/$d"; e="$EXPECT/$d"
  [ -d "$a" ] || [ -d "$e" ] || continue
  mkdir -p "$a" "$e"
  if ! diff -ru "$a" "$e" > "$TMP/diff$d" 2>&1; then
    echo "check: platform stubs out of sync in $SOURCE_LABEL: $d"
    cat "$TMP/diff$d"
    status=1
  fi
done

if [ "$status" -ne 0 ]; then
  cat <<'EOF'

Fix: regenerate, then stage the regenerated files.

  ./scripts/sync-platform-dirs.sh
  git add -A

Stubs are generated. Never hand-edit them -- change the canonical skill under
the --base directory (or the generator's heredocs) and regenerate. If the diff
shows a whole platform directory as unexpected, the --platforms value used here
disagrees with what is committed.
EOF
  exit 1
fi

echo "check: platform stubs in sync ($SOURCE_LABEL)"
