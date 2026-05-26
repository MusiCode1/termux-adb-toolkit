#!/data/data/com.termux/files/usr/bin/sh
export PATH="/data/data/com.termux/files/usr/bin:/system/bin:/system/xbin:$PATH"
RLM=$(printf '\xe2\x80\x8f')
sv down /data/data/com.termux/files/usr/var/service/cloudflared
termux-toast "${RLM}⏸ מנהרה עצורה"
