#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/web
systemd-run --user --scope -p MemoryMax=3G timeout 15m "$HOME/.local/bin/godot" --headless --path game --editor --import
systemd-run --user --scope -p MemoryMax=3G timeout 15m "$HOME/.local/bin/godot" --headless --path game --export-release Web "$PWD/build/web/index.html"

python3 tools/finalize_web.py
