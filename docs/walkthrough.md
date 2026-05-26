# Walkthrough — termux-adb-toolkit

## 2026-05-26 15:30

### v1.1 — אשף הגדרות, config.env, תיקוני באגים

#### מה בוצע?

**1. אשף אינטראקטיבי ב-setup.sh**

- בתחילת ההרצה: שואל ADB_PORT, CF_TUNNEL_NAME, CF_HOSTNAME
- שומר ל-`config.env` (מוחרג מ-git)
- `config.env.example` נוסף לריפו כדוגמה

**2. Cloudflare login בסקריפט**

- אם הוגדר CF_TUNNEL_NAME: `cloudflared tunnel login` רץ אוטומטית לפני ההתקנה
- אם המנהרה לא קיימת: `cloudflared tunnel create <name>` רץ אוטומטית
- אם כבר מחובר (cert.pem קיים): דילוג

**3. adbtool קורא config.env**

- ADB_PORT נלקח מ-config.env במקום hardcoded 5588
- TOOLKIT_DIR מחושב יחסית לנתיב הסקריפט

**4. תיקון `echo "\n"` בבאש**

- `echo "\n"` בבאש כותב `\n` ממש → גרם ל-`nfpath=` ב-zshrc של zsh
- תוקן ל-`printf '\n...\n'`

#### מעקפים ופתרונות

- **`echo "\n"` בבאש**: בניגוד לזאש, בבאש `\n` לא מתפרש כשורה חדשה. להשתמש תמיד ב-`printf '\n'` בסקריפטי bash שכותבים לקבצי zsh

## 2026-05-26 12:45

### v1.0 — יצירת הפרויקט והכלים הבסיסיים

הפרויקט נולד מתוך הגדרת Termux מאפס על OnePlus 15, ובעיית הפורט הדינמי של ADB Wireless Debugging.

#### מה בוצע?

**1. הגדרת סביבת Termux**

- `setup.sh` — הגדרת סביבה מלאה: zsh, Oh My Zsh, Powerlevel10k, פלאגינים, fzf, sshd כשירות
- `install-deps.sh` — התקנת תלויות: android-tools, cloudflared, mdns-scan, openssh, termux-services + התקנת rish מ-APK של Shizuku

**2. כלי ADB**

- `adbtool port --tcp` — מציאת פורט TCP קבוע דרך getprop
- `adbtool port` — מציאת פורט TLS דינמי דרך getprop ו-mDNS fallback
- `adbtool fix-port` — הגדרת פורט TCP קבוע (ברירת מחדל: 5588) דרך Shizuku/rish, כולל persist.adb.tcp.port
- `adbtool start` — bootstrap מלא: גילוי פורט TLS → חיבור ADB → הפעלת Shizuku → הגדרת פורט קבוע

**3. Cloudflare Tunnel**

- `adbtool tunnel up/down/status` — ניהול שירות cloudflared דרך termux-services/runit
- cloudflared service script נוצר ידנית (לא כלול בחבילת openssh של Termux)
- מנהרה: `myphone.musicode.ovh` → SSH על פורט 8022

**4. Shizuku**

- `adbtool shizuku start/status` — הפעלת שרת Shizuku דרך ADB
- `rish` חולץ מ-APK של Shizuku, `rish_shizuku.dex` הועבר ל-`$PREFIX/share/shizuku/`
- הגדרה נדרשת: Developer Options → "השבתת ניטור הרשאות" → ON
- `RISH_APPLICATION_ID=com.termux` מוגדר ב-`.zshrc`

**5. CLI + השלמה אוטומטית**

- `adbtool` — נקודת כניסה אחת לכל הכלים (במקום סקריפטים נפרדים)
- `completions/adbtool.bash` — השלמה לבאש
- `completions/_adbtool` — השלמה לזאש (compdef)

#### החלטות ארכיטקטורה

- **נקודת כניסה אחת (`adbtool`) במקום סקריפטים נפרדים**: מונע התנגשויות שמות (כגון `start`), מאפשר `help` מרכזי והשלמה אוטומטית נקייה
- **פורט TCP קבוע 5588 במקום Wireless Debugging**: לאחר bootstrap ראשוני, ADB עובד ללא WiFi דרך הפורט הקבוע + `persist.adb.tcp.port`
- **cloudflared כשירות disabled-by-default**: המנהרה לא עולה אוטומטית, נפתחת ידנית עם `adbtool tunnel up`

#### מעקפים ופתרונות

- **`/data/app` לא נגיש מ-Termux ישירות**: חיפוש APK של Shizuku דרך `adb shell find` ולא `find` ישיר
- **`sv status <name>` נכשל ב-SSH session**: `$SVDIR` לא מוגדר בסשן non-interactive → כל פקודות sv משתמשות בנתיב מלא
- **`pkg upgrade` בתוך סקריפט קורס**: מחליף ספריות בשימוש → יש להריץ `pkg upgrade` ידנית לפני הסקריפט ולאתחל Termux
