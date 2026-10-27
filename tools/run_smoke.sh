#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
for script in tests/test_runner.gd tests/steer_consistency.gd tests/steer_fidelity.gd tests/calm_probe.gd tests/calm_regression.gd tests/smoke.gd; do
 systemd-run --user --scope -p MemoryMax=3G timeout 15m "$HOME/.local/bin/godot" --headless --path game --script "$script"
done
