---
name: phone-automation
description: |
  Complete guide for agents performing UI automation or ADB operations on the user's
  Android phone (OnePlus 15, CPH2747) via termux-adb-toolkit.

  Load this skill when asked to:
  - Connect to the user's phone
  - Run adbtool commands
  - Perform UI automation (tap, swipe, search, open app)
  - Use Appium MCP against the phone
  - Troubleshoot ADB or tunnel issues

  Triggers when user mentions:
  - "בטלפון", "על הטלפון", "במכשיר", "ב-OnePlus"
  - "adbtool", "termux-adb-toolkit"
  - "ADB tunnel", "myphone", "localhost:5588"
allowed-tools: Bash(adb:*) Bash(ssh:*) Bash(tmux:*)
---

# Phone Automation Guide

## Architecture

```
CT cli-agents  ──SSH tunnel──▶  Termux (myphone)  ──ADB──▶  Android OS
     │                                                            │
     └──────────── Appium MCP (localhost:5588) ─────────────────▶┘
```

- SSH alias: `myphone` (Cloudflare tunnel → phone)
- ADB over TCP: `localhost:5588` (forwarded via SSH `-L 5588:localhost:5588`)
- Appium connects to ADB device `localhost:5588`

---

## Step 1 — Establish Connection

```bash
# Check if tunnel session already exists
tmux has-session -t adb-tunnel 2>/dev/null && echo "already up" || \
  tmux new-session -d -s adb-tunnel "ssh -L 5588:localhost:5588 myphone -N"

# Connect ADB
adb connect localhost:5588

# Verify
adb -s localhost:5588 shell echo ok   # should print: ok
```

---

## Step 2 — adbtool commands (run on the phone via SSH)

```bash
ssh myphone "adbtool start"           # bootstrap: ADB + Shizuku + stable port
ssh myphone "adbtool port"            # show current TLS port
ssh myphone "adbtool port --tcp"      # show TCP port
ssh myphone "adbtool tunnel up"       # start Cloudflare tunnel
ssh myphone "adbtool tunnel down"     # stop tunnel
ssh myphone "adbtool tunnel status"   # check tunnel
ssh myphone "adbtool shizuku status"  # check Shizuku
```

---

## Step 3 — Appium MCP (UI automation)

Create a session targeting the phone:
```json
{
  "appium:udid": "localhost:5588",
  "appium:noReset": true
}
```

To open a specific app:
```json
{
  "appium:appPackage": "com.google.android.apps.maps",
  "appium:appActivity": "com.google.android.maps.MapsActivity",
  "appium:noReset": true,
  "appium:autoLaunch": true
}
```

---

## Step 4 — phone-session-guard (MANDATORY before any UI operation)

Before touching the UI, always run the guard scripts.
See skill: `phone-session-guard`

```bash
# Before operations
bash ~/.agents/skills/phone-session-guard/scripts/phone-save-state.sh

# ... do UI work ...

# After operations
bash ~/.agents/skills/phone-session-guard/scripts/phone-restore-state.sh
```

The guard: wakes screen, checks for lockscreen, extends screen timeout, saves/restores foreground app.

---

## Hebrew Text Input

**`adb shell input text` does NOT support Hebrew** (ASCII only).

Preferred approaches in order:
1. **URL-encoded intent** — bypass keyboard entirely:
   ```bash
   # Example: open Google Maps searching for a Hebrew location
   adb -s localhost:5588 shell am start \
     -a android.intent.action.VIEW \
     -d "geo:0,0?q=%D7%9B%D7%95%D7%AA%D7%9C+%D7%94%D7%9E%D7%A2%D7%A8%D7%91%D7%99" \
     com.google.android.apps.maps
   ```
2. **Clipboard paste** — set via Appium, then paste:
   ```python
   driver.set_clipboard("כותל המערבי")
   # then tap clipboard suggestion above keyboard
   ```
3. **ADBKeyboard** — requires app installation + active IME.

---

## Gotchas

- **Bun.js** — does not work on Termux (SIGSYS/seccomp crash, non-PIE binary). Use Node.js instead.
- **ADB port** — stable TCP port is 5588. If adbtool wasn't run yet, the TLS port changes on every reboot.
- **Screen lock** — `phone-save-state.sh` aborts (exit 2) if screen is locked. User must unlock manually.
- **SSH tunnel drop** — if `adb devices` shows empty, the tmux session `adb-tunnel` may have died. Re-run Step 1.
- **Appium session** — always delete the session after use: `appium_session_management(action=delete)`.
