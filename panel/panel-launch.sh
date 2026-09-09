#!/data/data/com.termux/files/usr/bin/bash
# panel-launch.sh — launch a Termux:GUI panel and auto-answer the JavaScript
# permission dialog via adb (the "Allow Javascript without dialog" toggle is a
# confirmed non-persistent bug in Termux:GUI, so we dismiss the dialog ourselves).
#
# Works because we revived adb-over-tcp on localhost:5588.
set -uo pipefail

PANEL="${1:-node $HOME/adb-panel.mjs}"     # command that opens the panel
D="localhost:5588"
# "allow Javascript" button coordinates (right button of the Termux:GUI JS dialog)
ALLOW_X="${ALLOW_X:-970}"
ALLOW_Y="${ALLOW_Y:-1670}"

adb connect "$D" >/dev/null 2>&1

# launch the panel (its activity appears in the foreground).
# eval so ~ and $vars in the passed command are expanded (plain $PANEL would not).
eval "$PANEL" &
PANEL_PID=$!

# Wait for the JS dialog and tap "allow" ONLY when it's actually up — blind
# timed taps risk hitting the panel's own buttons. Detect via the UI tree.
for i in $(seq 1 16); do
  sleep 0.5
  if adb -s "$D" shell 'uiautomator dump /data/local/tmp/ui.xml >/dev/null 2>&1; grep -qi "allow Javascript" /data/local/tmp/ui.xml && echo YES' 2>/dev/null | grep -q YES; then
    adb -s "$D" shell input tap "$ALLOW_X" "$ALLOW_Y" >/dev/null 2>&1
    break
  fi
done

wait "$PANEL_PID"
