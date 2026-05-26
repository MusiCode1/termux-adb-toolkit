#!/data/data/com.termux/files/usr/bin/sh
export PATH="/data/data/com.termux/files/usr/bin:/system/bin:/system/xbin:$PATH"
sv down /data/data/com.termux/files/usr/var/service/cloudflared
termux-toast "מנהרה עצורה ⏸"
