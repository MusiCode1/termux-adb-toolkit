#!/data/data/com.termux/files/usr/bin/sh
export PATH="/data/data/com.termux/files/usr/bin:/system/bin:/system/xbin:$PATH"
termux-toast "מפעיל ADB + Shizuku..."
adbtool start 2>&1 | tail -1 | xargs -I{} termux-toast "{}"
ADB_PORT=$(getprop persist.adb.tcp.port 2>/dev/null)
termux-toast "ADB מחובר בפורט $ADB_PORT — חבר גם מהמחשב: adb connect <IP>:$ADB_PORT"
