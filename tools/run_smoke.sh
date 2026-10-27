#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
for script in tests/test_runner.gd tests/steer_consistency.gd tests/smoke.gd; do
 systemd-run --user --scope -p MemoryMax=3G timeout 15m "$HOME/.local/bin/godot" --headless --path game --script "$script"
done
