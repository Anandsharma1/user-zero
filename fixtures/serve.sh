#!/usr/bin/env bash
# Serve both fixture apps and print the origins a charter should drive.
#
#   fixtures/serve.sh [--port N]     (default: first free port from 8801)
#
# Static files only: no backend, no database, nothing to isolate. That is why
# fixture charters are observation-only, and why a fixture calibration is a floor
# rather than a substitute for a real-product run (fixtures/README.md).

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORT=""

while [ $# -gt 0 ]; do
  case "$1" in
    --port) PORT="$2"; shift 2 ;;
    -h|--help) sed -n '2,10p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) echo "serve: unknown argument: $1" >&2; exit 2 ;;
  esac
done

command -v python3 >/dev/null || { echo "serve: python3 required" >&2; exit 2; }

# Serve ONLY fixtures/apps/. Serving the fixtures directory itself exposed
# controls.tsv -- the answer key -- at /controls.tsv, fetchable by the very
# browser the explorer drives, along with the charters and calibration files.
# The registry, probe, charters and README deliberately live one level up.
APPS="$HERE/apps"
[ -d "$APPS" ] || { echo "serve: $APPS missing" >&2; exit 1; }
for forbidden in controls.tsv probe.sh README.md explorer; do
  if [ -e "$APPS/$forbidden" ]; then
    echo "serve: refusing to start — $forbidden is inside the served directory." >&2
    echo "       That would hand the answer key to the explorer over HTTP." >&2
    exit 1
  fi
done

free_port() {
  python3 - <<'PY'
import socket
for p in range(8801, 8899):
    s = socket.socket()
    try:
        s.bind(("127.0.0.1", p)); print(p); break
    except OSError:
        continue
    finally:
        s.close()
PY
}
[ -n "$PORT" ] || PORT="$(free_port)"
[ -n "$PORT" ] || { echo "serve: no free port in 8801-8898" >&2; exit 1; }

cat <<EOF
Serving fixtures on 127.0.0.1:$PORT

  broken app (negative controls) : http://127.0.0.1:$PORT/broken-app/index.html
                                  http://127.0.0.1:$PORT/broken-app/queue.html
  clean app  (positive control)  : http://127.0.0.1:$PORT/clean-app/index.html

Health gate: the dashboard must return 200 and render its table before a
charter starts. The broken app logs a console error on load by design
(control KD-C01) -- that is a seeded defect, not a broken fixture.

Only fixtures/apps/ is served. The control registry, charters and calibration
files sit outside it and are not reachable over HTTP.

Arm check:  fixtures/probe.sh
Stop:       Ctrl-C
EOF

exec python3 -m http.server "$PORT" --bind 127.0.0.1 --directory "$APPS"
