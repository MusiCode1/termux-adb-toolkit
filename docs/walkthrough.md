# Walkthrough — termux-adb-toolkit

## 2026-05-26 12:45

### v1.3 — agent skill, תיקון ADB reconnect, תיעוד אוטומציה

#### מה בוצע?

**1. Agent skill — `phone-automation`**

- נוצרה תיקייה `skills/phone-automation/SKILL.md`
- מסביר לסוכנים איך להתחבר לטלפון (SSH tunnel + ADB), להשתמש ב-adbtool, Appium MCP, phone-session-guard, והזנת עברית
- `install-deps.sh` מוסיף symlink אוטומטי ל-`~/.agents/skills/` אם הספרייה קיימת (מכונות שליטה)

**2. תיקון `adbtool start` — reconnect אוטומטי**

- לאחר `stop adbd; start adbd`, חיבור ה-TLS נופל — הפורט TCP פתוח אבל אין חיבור
- נוסף שלב 5/5: ממתין 2 שניות ומריץ `adb connect localhost:$ADB_PORT` אוטומטית
- הפורט נלקח מ-`$ADB_PORT` (משתנה, לא קשיח)
- מסר סיום מציין שיש להתחבר גם מהמחשב המקומי

**3. עדכון `adbtool-start.sh` (widget)**

- נוסף toast שני עם הפורט הפעיל והנחיה להתחבר גם מהמחשב המקומי
- הפורט נקרא דינמית מ-`persist.adb.tcp.port`

**4. עדכון `AGENTS.md`**

- נוסף סקשן ראשי המפנה לסקיל `phone-automation`
- מציין שם הקובץ ואיך הוא מותקן

#### החלטות ארכיטקטורה

- **symlink מ-install-deps.sh**: הסקיל חי בתוך הפרויקט; `install-deps.sh` יוצר symlink רק אם `~/.agents/skills/` קיים — כך הסקריפט עובד גם על הטלפון (מדלג) וגם על מכונת שליטה (מקשר)

#### מעקפים ופתרונות

- **adbd restart מוחק TLS connection**: אחרי שינוי הפורט ל-TCP, ה-adbd עולה מחדש ו-TLS נופל. הפתרון: `sleep 2` ואז reconnect על הפורט החדש

## 2026-05-26 17:30

### v1.2 — widget shortcuts, Termux:Boot, תיקוני CF tunnel

#### מה בוצע?

**1. Widget shortcuts**

- `shortcuts/tunnel-status.sh` — מציג toast עם סטטוס מנהרה/SSH/ADB
- `shortcuts/tunnel-up.sh` / `tunnel-down.sh` — הפעלה/עצירת מנהרה
- `shortcuts/adbtool-start.sh` — bootstrap ADB + Shizuku
- `install-deps.sh` מתקין shortcuts ל-`~/.shortcuts/` אוטומטית

**2. Termux:Boot**

- `~/.termux/boot/start-services.sh` — מפעיל sshd בהפעלת מכשיר
- `termux-api` package נוסף לתלויות (`termux-toast`)

**3. תיקוני CF tunnel**

- מנהרה קיימת ללא credentials → fetch token דרך `cloudflared tunnel token`
- service script מזהה אם יש `tunnel-token` ומשתמש ב-`--token` flag
- cloudflared עבר לתוך `pkg install` (היה אחרי התקנה)
- `cloudflared tunnel login` מופעל אחרי התקנת חבילות

**4. תיקון OMZ**

- הוסר `CHSH=yes` — OMZ שואל את המשתמש כרגיל (יש ממילא מעורבות אינטראקטיבית)

#### החלטות ארכיטקטורה

- **toast מתחיל במילה עברית**: `printf '\xe2\x80\x8f'` לא עובד ב-sh של Termux. פתרון: להתחיל עם מילה עברית כדי ש-BiDi יכוון ימין אוטומטית
- **token במקום delete+recreate**: `cloudflared tunnel token <name>` עובד עם `cert.pem` בלבד — לא צריך למחוק מנהרה קיימת

#### מעקפים ופתרונות

- **`printf '\xe2\x80\x8f'` מדפיס טקסט מילולי בטרמוקס sh**: להתחיל הודעה במילה עברית במקום
- **`cloudflared tunnel delete` נכשל**: ה-API של CF דוחה מחיקה אם המנהרה עדיין "קיימת" בעיניו → שימוש ב-token של מנהרה קיימת

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
