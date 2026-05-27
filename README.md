# termux-adb-toolkit

A collection of scripts for managing Android devices via ADB from Termux.

## Requirements

- [Termux](https://f-droid.org/packages/com.termux/) from **F-Droid** (not Google Play)
- [Shizuku](https://shizuku.rikka.app/) installed and running
- Developer Options → Wireless Debugging enabled (for initial setup)
- Developer Options → Disable permission monitoring → **ON**
- `git` — install via `pkg install git` (required for cloning this repo)

## Quick Start

```bash
# 1. Update packages first (required — prevents SSL library conflicts)
pkg upgrade -y
# Restart Termux

# 2. Clone and run
git clone https://github.com/MusiCode1/termux-adb-toolkit
cd termux-adb-toolkit
chmod +x setup.sh && ./setup.sh
```

## adbtool

The main CLI. Wraps all toolkit functionality in a single command.

```bash
adbtool start              # Bootstrap: connect ADB, start Shizuku, set stable port
adbtool port               # Show current TLS port (Wireless Debugging)
adbtool port --tcp         # Show current TCP port
adbtool fix-port [PORT]    # Set stable TCP port via Shizuku (default: 5588)
adbtool tunnel up          # Start Cloudflare tunnel
adbtool tunnel down        # Stop Cloudflare tunnel
adbtool tunnel status      # Check tunnel status
adbtool shizuku start      # Start Shizuku
adbtool shizuku status     # Check Shizuku status
adbtool help               # Show help
```

### `adbtool start` — what it does

1. Finds the Wireless Debugging TLS port
2. Connects ADB via TLS
3. Starts Shizuku
4. Sets a stable TCP port (default: 5588) via Shizuku + restarts adbd
5. Reconnects ADB on the new TCP port automatically

After running, connect from a remote machine:
```bash
adb connect <phone-ip>:5588
```

## Individual scripts

The following standalone scripts are also available in `$PREFIX/bin/` after `install-deps.sh`:

| Script | Description |
|--------|-------------|
| `adb-port` | Show current ADB port (TLS or TCP) |
| `adb-fix-port [PORT]` | Set stable TCP port via Shizuku |
| `tunnel [up\|down\|status]` | Manage Cloudflare tunnel |
| `shizuku [start\|status]` | Manage Shizuku |

## Shizuku Setup

1. Install Shizuku from Play Store / F-Droid
2. Start via Wireless Debugging (in Shizuku app)
3. Developer Options → **Disable permission monitoring → ON**
4. Disable battery optimization for both Termux and Shizuku
5. Run `adbtool start` or `install-deps.sh` to install `rish`

## Cloudflare Tunnel

The `tunnel` script requires a pre-configured `cloudflared` tunnel.
See `cloudflared tunnel create` and configure `~/.cloudflared/`.

## Termux:Widget Shortcuts

Install [Termux:Widget](https://f-droid.org/packages/com.termux.widget/) to add home screen shortcuts.
Shortcuts are installed automatically by `install-deps.sh` to `~/.shortcuts/`:

| Shortcut | Action |
|----------|--------|
| `adbtool-start.sh` | Bootstrap ADB + Shizuku |
| `tunnel-up.sh` | Start CF tunnel |
| `tunnel-down.sh` | Stop CF tunnel |
| `tunnel-status.sh` | Show tunnel/SSH/ADB status as toast |

## Agent Automation (AI)

For agents automating this device via Appium, ADB, or SSH — see the skill:

```
skills/phone-automation/SKILL.md
```

Covers: SSH tunnel setup, ADB connection, Appium MCP, Hebrew text input, gotchas.

On controlling machines with `~/.agents/skills/`, run `install-deps.sh` to auto-link the skill.

## Files

```
bin/
  adbtool           main CLI (wraps all commands)
  adb-port          discover current ADB port
  adb-fix-port      set stable ADB TCP port via Shizuku
  tunnel            toggle Cloudflare tunnel
  shizuku           start/status Shizuku
  start             standalone bootstrap (same as adbtool start)
completions/
  adbtool.bash      bash tab completion
  _adbtool          zsh tab completion
shortcuts/
  adbtool-start.sh  Termux:Widget shortcut — bootstrap
  tunnel-up.sh      Termux:Widget shortcut — tunnel on
  tunnel-down.sh    Termux:Widget shortcut — tunnel off
  tunnel-status.sh  Termux:Widget shortcut — status toast
skills/
  phone-automation/ agent skill — automation guide
install-deps.sh     install pkg dependencies, link scripts, register skill
setup.sh            full Termux environment setup (zsh, omz, p10k, sshd, toolkit)
```
