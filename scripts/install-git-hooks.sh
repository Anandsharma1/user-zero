#!/usr/bin/env bash
# Point this repo's git hooks at .githooks/ (tracked, reviewable).
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
chmod +x .githooks/* scripts/*.sh
git config core.hooksPath .githooks
echo "hooks: core.hooksPath = .githooks"
git config --get core.hooksPath
