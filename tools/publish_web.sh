#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
tools/export_web.sh
stage="$PWD/build/publish"
mkdir -p "$stage"
cp -a build/web/. "$stage/"
touch "$stage/.nojekyll"
if [ ! -d "$stage/.git" ]; then
 git -C "$stage" init -b main
 git -C "$stage" remote add origin https://github.com/yeetozer/meltemi-play.git
fi
git -C "$stage" add .
git -C "$stage" -c user.name=yeetozer -c user.email=yigitozer@hotmail.com commit -m "Publish Meltemi web build" || test -z "$(git -C "$stage" status --porcelain)"
git -C "$stage" push -u origin main
