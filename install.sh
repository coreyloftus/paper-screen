#!/bin/bash
# Builds PaperScreen and installs it to /Applications so Spotlight and Raycast find it.
set -euo pipefail
cd "$(dirname "$0")"
./build.sh
osascript -e 'tell application id "local.cml.paperscreen" to quit' 2>/dev/null || true
sleep 1
rm -rf /Applications/PaperScreen.app
cp -R build/PaperScreen.app /Applications/
open /Applications/PaperScreen.app
echo "Installed /Applications/PaperScreen.app"
