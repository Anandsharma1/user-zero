#!/usr/bin/env bash
# Install the ui-qa harness into a target repository.
#
#   scripts/install.sh /path/to/target-repo [--dest skills/ui-qa]
#                      [--platforms "claude codex"] [--explorer-dir qa/product-explorer]
#                      [--adapter playwright-mcp]
#
# What it does:
#   1. copies the canonical skill to <target>/<dest>            (replaced: harness code)
#   2. generates the platform pointer stubs in <target>          (replaced: generated)
#   3. scaffolds <target>/<explorer-dir>/ from templates         (NEVER overwritten: yours)
#   4. records the choices in <target>/.ui-qa-install.json       (so upgrades reuse them)
#   5. prints the manual steps it deliberately will not do for you
#
# The split in 1-3 is the point: everything the harness owns is replaceable on
# upgrade, everything you own is untouched.
#
# Every caller-supplied path fragment is validated before use, because --dest
# reaches `rm -rf`. Relative, no '..', no absolute paths, no shell metacharacters.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib-common.sh
. "$HERE/lib-common.sh"

SRC="$(cd "$HERE/.." && pwd)"
TARGET=""
DEST=""
PLATFORMS=""
EXPLORER_DIR=""
ADAPTER=""

while [ $# -gt 0 ]; do
  case "$1" in
    --dest) DEST="$2"; shift 2 ;;
    --platforms) PLATFORMS="$2"; shift 2 ;;
    --explorer-dir) EXPLORER_DIR="$2"; shift 2 ;;
    --adapter) ADAPTER="$2"; shift 2 ;;
    -h|--help) sed -n '2,22p' "${BASH_SOURCE[0]}"; exit 0 ;;
    -*) echo "install: unknown option: $1" >&2; exit 2 ;;
    *) [ -z "$TARGET" ] || { echo "install: unexpected argument: $1" >&2; exit 2; }
       TARGET="$1"; shift ;;
  esac
done

[ -n "$TARGET" ] || { echo "install: target repository path required" >&2; exit 2; }
[ -d "$TARGET" ] || { echo "install: not a directory: $TARGET" >&2; exit 1; }
TARGET="$(cd "$TARGET" && pwd)"
[ "$TARGET" != "$SRC" ] || { echo "install: target is the harness repo itself" >&2; exit 2; }
case "$SRC" in "$TARGET"/*) echo "install: target contains the harness repo" >&2; exit 2 ;; esac

# --- Reuse the previous install's choices unless overridden. Without this, a
# --- later upgrade cannot find a non-default explorer directory.
MANIFEST="$TARGET/.ui-qa-install.json"
manifest_get() {  # crude but dependency-free; the file is ours and one level deep
  [ -f "$MANIFEST" ] || return 0
  sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" "$MANIFEST" | head -1
}
[ -n "$DEST" ]         || DEST="$(manifest_get dest)";                 DEST="${DEST:-skills/ui-qa}"
[ -n "$EXPLORER_DIR" ] || EXPLORER_DIR="$(manifest_get explorer_dir)"; EXPLORER_DIR="${EXPLORER_DIR:-qa/product-explorer}"
[ -n "$PLATFORMS" ]    || PLATFORMS="$(manifest_get platforms)";       PLATFORMS="${PLATFORMS:-claude codex}"
[ -n "$ADAPTER" ]      || ADAPTER="$(manifest_get adapter)";           ADAPTER="${ADAPTER:-playwright-mcp}"

validate_rel_path "$DEST" "--dest" || exit 2
validate_rel_path "$EXPLORER_DIR" "--explorer-dir" || exit 2
for v in "$DEST" "$EXPLORER_DIR"; do
  if is_forbidden_dest "$v"; then
    echo "install: refusing to target '$v' — reserved directory" >&2; exit 2
  fi
done
if is_platform_path "$DEST"; then
  cat >&2 <<EOF
install: refusing --dest '$DEST' — it is inside a platform directory this
         installer generates into. The canonical skill would be overwritten by
         its own pointer stub, leaving a SKILL.md that points at itself.
         Use a path outside ${UI_QA_PLATFORM_ROOTS// /, }.
EOF
  exit 2
fi
case "$ADAPTER" in *[!A-Za-z0-9._-]*) echo "install: bad --adapter: $ADAPTER" >&2; exit 2 ;; esac
for p in $PLATFORMS; do
  case "$p" in claude|codex|cursor|gemini) ;; *) echo "install: unknown platform: $p" >&2; exit 2 ;; esac
done
[ -f "$SRC/skills/ui-qa/adapters/$ADAPTER.md" ] || {
  echo "install: no adapter file for '$ADAPTER'" >&2; exit 1; }

# No component of the destination may be a symlink, or writes escape the target.
assert_no_symlink_path "$TARGET" "$DEST" || exit 2
assert_no_symlink_path "$TARGET" "$EXPLORER_DIR" || exit 2

resolved_dest="$TARGET/$DEST"

# Belt and braces: the resolved destination must still be inside the target.
safe_mkdir_p "$TARGET" "$DEST" || exit 2
case "$(cd "$resolved_dest" && pwd -P)" in
  "$(cd "$TARGET" && pwd -P)"/*) ;;
  *) echo "install: refusing: --dest resolves outside the target: $DEST" >&2; exit 2 ;;
esac

# --- Ownership gate. The manifest lives in the target and can say anything --
# --- including ".git" -- so deletion is authorized by a marker THIS installer
# --- wrote, never by the configured path alone. A directory we did not create
# --- is never removed.
if [ -e "$resolved_dest" ] && [ -n "$(ls -A "$resolved_dest" 2>/dev/null)" ]; then
  if [ ! -f "$resolved_dest/$UI_QA_MARKER" ]; then
    cat >&2 <<EOF
install: refusing to replace '$DEST' — it is not empty and carries no
         $UI_QA_MARKER marker, so this installer did not create it.

         If you really want the harness there, move or delete the directory
         yourself first. (Deletion is gated on a marker rather than on the
         configured path because .ui-qa-install.json lives in the target and
         could name any directory, including .git.)
EOF
    exit 2
  fi
  rm -rf "$resolved_dest"
fi

# 1. canonical skill --------------------------------------------------------
rm -rf "$resolved_dest"
mkdir -p "$(dirname "$resolved_dest")"
cp -r "$SRC/skills/ui-qa" "$resolved_dest"
cat > "$resolved_dest/$UI_QA_MARKER" <<EOF
This directory is managed by the user-zero ui-qa installer and is REPLACED on
upgrade. Do not put your own files here -- profile, charters, and calibration
inputs belong in $EXPLORER_DIR.
Its presence is what authorizes the installer to replace this directory.
EOF
echo "install: skill      -> $DEST"

# 2. platform stubs ---------------------------------------------------------
"$SRC/scripts/sync-platform-dirs.sh" --root "$TARGET" --base "$DEST" \
  --platforms "$PLATFORMS" --adapter "$ADAPTER"

# 3. explorer scaffold (never clobbered) -----------------------------------
for sub in charters calibration/seeds dossiers; do
  safe_mkdir_p "$TARGET" "$EXPLORER_DIR/$sub" || exit 2
done
copy_if_absent() {
  if [ -e "$TARGET/$2" ] || [ -L "$TARGET/$2" ]; then
    echo "install: kept       -> $2 (exists)"
  else
    safe_prepare_file "$TARGET" "$2" || exit 2
    # Literal bash substitution -- never sed -- so a crafted --dest cannot
    # become part of an executable substitution program.
    substitute_literal '<skill>' "$DEST" < "$SRC/templates/$1" > "$TARGET/$2"
    echo "install: scaffold   -> $2"
  fi
}
copy_if_absent PROFILE.md                        "$EXPLORER_DIR/PROFILE.md"
copy_if_absent charter.md                        "$EXPLORER_DIR/charters/EXAMPLE-charter.md"
copy_if_absent calibration/known-defects.md      "$EXPLORER_DIR/calibration/known-defects.md"
copy_if_absent calibration/accepted-exemplars.md "$EXPLORER_DIR/calibration/accepted-exemplars.md"

# 4. record the choices ----------------------------------------------------
# Symlink-guarded like every other write: a stray symlink at this path would
# redirect the manifest out of the repo, and stray symlinks happen.
safe_prepare_file "$TARGET" ".ui-qa-install.json" || exit 2
cat > "$MANIFEST" <<EOF
{
  "_comment": "Written by user-zero scripts/install.sh. Upgrades reuse these unless overridden.",
  "dest": "$DEST",
  "explorer_dir": "$EXPLORER_DIR",
  "platforms": "$PLATFORMS",
  "adapter": "$ADAPTER"
}
EOF
echo "install: manifest   -> .ui-qa-install.json"

# 5. what we will not do for you -------------------------------------------
cat <<EOF

Installed. Four manual steps remain, deliberately:

1. Ignore the evidence directory. Add to the target's .gitignore:

     qa-output/

2. Register the browser adapter's MCP server. See $DEST/adapters/$ADAPTER.md
   (Claude Code reads .mcp.json; Codex needs its own config under CODEX_HOME).
   Restart the agent session afterwards and verify the tools actually loaded.

3. Fill in $EXPLORER_DIR/PROFILE.md by running the two-role onboarding
   procedure in $DEST/references/profile-schema.md, then have a human approve
   it. Until it is approved, no run may claim authority.

4. Optionally tell your agents the harness is here, in AGENTS.md / CLAUDE.md
   (not written automatically -- those files are yours):

     UI QA: read $DEST/SKILL.md before any UI QA, charter run, or /ui-qa request.

Then: /ui-qa                       list charters
      /ui-qa explore <route>       synthesize a charter for a new surface
      /ui-qa <charter> --calibrate calibrate before you believe a run

Every completed run must pass the coverage/evidence gate before its findings
are read as coverage:

      $DEST/scripts/verify-run.sh qa-output/<run_id>
EOF
