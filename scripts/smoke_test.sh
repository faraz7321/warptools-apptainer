#!/usr/bin/env bash
set -euo pipefail

# Backwards-compatible wrapper (the task statement expects scripts/test.sh).
exec "$(dirname "$0")/test.sh" "$@"
