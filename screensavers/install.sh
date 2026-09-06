#!/usr/bin/env bash
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
DEST="$HOME/.local/share/skyradar-screensaver"

mkdir -p "$DEST"
cp "$SRC/skyradar-screensaver.qml" "$DEST/skyradar-screensaver.qml"
cp "$SRC/map.js" "$DEST/map.js"

# Install the launch override, backing up the original first.
if [[ -f /usr/bin/omarchy-launch-screensaver && ! -f /usr/bin/omarchy-launch-screensaver.orig ]]; then
  sudo cp /usr/bin/omarchy-launch-screensaver /usr/bin/omarchy-launch-screensaver.orig
fi
sudo cp "$SRC/skyradar-screensaver.sh" /usr/bin/omarchy-launch-screensaver
sudo chmod 755 /usr/bin/omarchy-launch-screensaver

echo "Installed."
echo "Test it with:  omarchy-launch-screensaver force"
echo "(press any key or move the mouse to exit)"
