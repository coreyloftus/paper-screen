#!/bin/bash
# Builds build/PaperScreen.app (ad-hoc signed, menu bar only).
set -euo pipefail
cd "$(dirname "$0")"
swift build -c release
APP=build/PaperScreen.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$(swift build -c release --show-bin-path)/PaperScreen" "$APP/Contents/MacOS/"
cp Resources/Info.plist "$APP/Contents/"
codesign --force --sign - "$APP"
echo "Built $APP"
