#!/data/data/com.termux/files/usr/bin/sh
export PATH="/data/data/com.termux/files/usr/bin:/system/bin:/system/xbin:$PATH"
RLM=$(printf '\xe2\x80\x8f')
sv up /data/data/com.termux/files/usr/var/service/cloudflared
sleep 2
STATUS=$(sv status /data/data/com.termux/files/usr/var/service/cloudflared 2>&1)
echo "$STATUS" | grep -q "^run:" \
  && termux-toast "${RLM}▶ מנהרה פעילה" \
  || termux-toast "${RLM}✗ שגיאה בהפעלת המנהרה"
