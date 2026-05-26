#!/data/data/com.termux/files/usr/bin/sh
export PATH="/data/data/com.termux/files/usr/bin:/system/bin:/system/xbin:$PATH"
termux-toast "מפעיל ADB + Shizuku..."
adbtool start 2>&1 | tail -1 | xargs -I{} termux-toast "{}"
