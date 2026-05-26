#!/data/data/com.termux/files/usr/bin/sh
export PATH="/data/data/com.termux/files/usr/bin:/system/bin:/system/xbin:$PATH"
RLM=$(printf '\xe2\x80\x8f')  # U+200F Right-to-Left Mark

# Cloudflare tunnel
CF=$(sv status /data/data/com.termux/files/usr/var/service/cloudflared 2>&1)
echo "$CF" | grep -q "^run:" \
  && CF_STATUS="${RLM}▶ מנהרה פעילה" \
  || CF_STATUS="${RLM}⏸ מנהרה עצורה"

# SSH
SSH=$(sv status /data/data/com.termux/files/usr/var/service/sshd 2>&1)
echo "$SSH" | grep -q "^run:" \
  && SSH_STATUS="✓ SSH" \
  || SSH_STATUS="✗ SSH"

# ADB
ADB_PORT=$(/system/bin/getprop service.adb.tcp.port 2>/dev/null)
[ -n "$ADB_PORT" ] && [ "$ADB_PORT" != "0" ] && [ "$ADB_PORT" != "-1" ] \
  && ADB_STATUS="✓ ADB :$ADB_PORT" \
  || ADB_STATUS="✗ ADB"

termux-toast "${RLM}${CF_STATUS} | ${SSH_STATUS} | ${ADB_STATUS}"
