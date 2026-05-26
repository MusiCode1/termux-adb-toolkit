# termux-adb-toolkit

A collection of scripts for managing Android devices via ADB from Termux.

## Requirements

- [Termux](https://f-droid.org/packages/com.termux/) from **F-Droid** (not Google Play)
- [Shizuku](https://shizuku.rikka.app/) installed and running
- Developer Options → Wireless Debugging enabled (for initial setup)
- Developer Options → Disable permission monitoring → **ON**
- `git` — installed via `pkg install git` (required for cloning this repo)

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

## Tools

### `adb-port`
Discover the current ADB port (Wireless Debugging or TCP).

```bash
adb-port          # TLS port (Wireless Debugging)
adb-port --tcp    # TCP port (classic adb-over-tcp)
```

### `adb-fix-port`
Set ADB to listen on a **stable TCP port** via Shizuku.
After running, you can connect with `adb connect <ip>:5588` — no TLS pairing needed.

```bash
adb-fix-port        # default port: 5588
adb-fix-port 1234   # custom port
```

### `tunnel`
Toggle the Cloudflare tunnel on/off.

```bash
tunnel up
tunnel down
tunnel status
```

### `shizuku`
Start or check Shizuku status.

```bash
shizuku start
shizuku status
```

## Shizuku Setup

1. Install Shizuku from Play Store / F-Droid
2. Start via Wireless Debugging (in Shizuku app)
3. Developer Options → **Disable permission monitoring → ON**
4. Disable battery optimization for both Termux and Shizuku
5. Run `shizuku start` or `install-deps.sh` to install `rish`

## Cloudflare Tunnel

The `tunnel` script requires a pre-configured `cloudflared` tunnel.
See `cloudflared tunnel create` and configure `~/.cloudflared/`.

## Files

```
bin/
  adb-port        discover current ADB port
  adb-fix-port    set stable ADB TCP port via Shizuku
  tunnel          toggle Cloudflare tunnel
  shizuku         start/status Shizuku
install-deps.sh   install all pkg dependencies + rish
setup.sh          full Termux environment setup (zsh, omz, p10k, sshd, tools)
```
