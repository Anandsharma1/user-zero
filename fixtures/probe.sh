#!/usr/bin/env bash
# Prove every declared control is ARMED: its defect present AND its fix absent.
#
#   fixtures/probe.sh [--class <class>] [--quiet]
#
# This is the calibration protocol's "live probe" made mechanical. A control
# described in prose is `registered` and counts for nothing; it is `armed` only
# when its defect is verifiably present before the run.
#
# Armed requires BOTH:
#   probe      present (or "-")      -- the defect's own text is there
#   antiprobe  absent  (or "-")      -- the obvious fix is not there
#
# The antiprobe column exists because a positive probe alone survives the repair
# it is meant to detect: adding an aria-label to an unnamed icon button fixes the
# defect without removing the button markup, so a probe on the markup would keep
# reporting ARMED against a control that no longer exists.
#
# It greps the SOURCE files under fixtures/apps/, never the DOM, and this script
# lives outside the served directory -- see fixtures/README.md §The blindness rule.

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPS="$HERE/apps"
FILTER=""; QUIET=0

while [ $# -gt 0 ]; do
  case "$1" in
    --class) FILTER="$2"; shift 2 ;;
    --quiet) QUIET=1; shift ;;
    -h|--help) sed -n '2,22p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) echo "probe: unknown argument: $1" >&2; exit 2 ;;
  esac
done

armed=0; missing=0; repaired=0
CLASSES_FILE="$(mktemp)"; trap 'rm -f "$CLASSES_FILE"' EXIT

while IFS=$'\t' read -r id class page probe antiprobe signature; do
  case "${id:-}" in ''|'#'*) continue ;; esac
  [ -n "$FILTER" ] && [ "$class" != "$FILTER" ] && continue

  if [ ! -f "$APPS/$page" ]; then
    echo "MISSING  $id  ($class)  page not found: apps/$page"
    missing=$((missing+1)); continue
  fi

  present=1
  if [ "$probe" != "-" ] && ! grep -qF -- "$probe" "$APPS/$page"; then present=0; fi

  fixed=0
  if [ "$antiprobe" != "-" ] && grep -qF -- "$antiprobe" "$APPS/$page"; then fixed=1; fi

  if [ "$present" -eq 1 ] && [ "$fixed" -eq 0 ]; then
    [ "$QUIET" -eq 1 ] || echo "ARMED    $id  ($class)  apps/$page"
    armed=$((armed+1))
    printf '%s\n' "$class" >> "$CLASSES_FILE"
  elif [ "$fixed" -eq 1 ]; then
    echo "REPAIRED $id  ($class)  the fix marker '$antiprobe' is present in apps/$page"
    echo "         this control no longer exists; remove it or re-break the fixture"
    repaired=$((repaired+1))
  else
    echo "MISSING  $id  ($class)  probe no longer present in apps/$page"
    echo "         signature was: $signature"
    missing=$((missing+1))
  fi
done < "$HERE/controls.tsv"

class_count=$(sort -u "$CLASSES_FILE" 2>/dev/null | grep -c . || true)

echo
echo "probe: $armed armed, $missing missing, $repaired repaired, across $class_count defect classes"
[ "$armed" -gt 0 ] && sort -u "$CLASSES_FILE" | sed 's/^/       - /'

floor_ok=1
[ "$armed" -ge 5 ] || { echo "probe: FLOOR — fewer than 5 armed controls"; floor_ok=0; }
[ "$class_count" -ge 3 ] || { echo "probe: FLOOR — fewer than 3 defect classes"; floor_ok=0; }

if [ "$missing" -gt 0 ] || [ "$repaired" -gt 0 ]; then
  echo "probe: FAIL — fixture drift. Restore the defects or remove their control"
  echo "       records; do not calibrate against a stale denominator."
  exit 1
fi
[ "$floor_ok" -eq 1 ] || { echo "probe: FAIL — control floor not met"; exit 1; }

echo "probe: PASS — every declared control is present, unrepaired, and the floor is met."
echo "       Predeclare the in-scope set, then run blind."
