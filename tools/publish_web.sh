#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
tools/export_web.sh
stage="$PWD/build/publish"
remote="https://github.com/yeetozer/meltemi-play.git"
if [ ! -d "$stage/.git" ]; then
 git clone --branch main "$remote" "$stage"
else
 test "$(git -C "$stage" remote get-url origin)" = "$remote"
 test "$(git -C "$stage" branch --show-current)" = main
 test -z "$(git -C "$stage" status --porcelain)"
 git -C "$stage" pull --rebase origin main
fi
# Overlay only: preserve native install files and all other published content.
test ! -e build/web/ios
cp -a build/web/. "$stage/"
touch "$stage/.nojekyll"
git -C "$stage" add .
git -C "$stage" -c user.name=yeetozer -c user.email=yigitozer@hotmail.com commit -m "Publish Meltemi web build" || test -z "$(git -C "$stage" status --porcelain)"
git -C "$stage" pull --rebase origin main
git -C "$stage" push -u origin main
