#!/bin/bash

# omarchy:summary=Launch the FlightWatch radar screensaver (QML)
# omarchy:group=system
# omarchy:name=launch-screensaver

# Exit early if the radar is already running
pgrep -f '[q]ml6.*Radar\.qml' && exit 0

# Allow the screensaver to be turned off but also force-started
if omarchy-toggle-enabled screensaver-off && [[ $1 != "force" ]]; then
  exit 1
fi

# Hide the mouse cursor while the radar is up
hyprctl eval 'hl.config({ cursor = { invisible = true } })' &>/dev/null || hyprctl keyword cursor:invisible true &>/dev/null || true

# Run the radar fullscreen; restore the cursor once it exits
QT_QPA_PLATFORM=wayland qml6 "$HOME/.local/share/fw-radar/Radar.qml"

hyprctl eval 'hl.config({ cursor = { invisible = false } })' &>/dev/null || hyprctl keyword cursor:invisible false &>/dev/null || true
