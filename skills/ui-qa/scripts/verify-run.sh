#!/usr/bin/env bash
# Thin shim: the run gate lives in verify_run.py.
#
# The gate was originally shell and accumulated exactly the class of defects
# shell invites for this kind of work -- `read` dropping a final unterminated
# line (so a one-line network dump was scanned as zero lines), exit codes used
# as counters wrapping at 256, and path containment by string comparison rather
# than by resolving symlinks. Python has a TSV reader, a real regex engine, and
# os.path.realpath; the whole class went away with the language, not one fix at
# a time.
#
# This wrapper exists so every documented invocation keeps working.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v python3 >/dev/null 2>&1; then
  echo "verify-run: python3 is required for the run gate (see docs/OPERATIONS.md §0)" >&2
  exit 2
fi

exec python3 "$HERE/verify_run.py" "$@"
