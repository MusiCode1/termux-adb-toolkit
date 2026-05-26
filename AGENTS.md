# AGENTS.md

## Project
Shell scripts toolkit for Termux on Android. No build system — pure POSIX sh scripts.

## Structure
- `bin/` — executable scripts, installed to `$PREFIX/bin/` via `install-deps.sh`
- `setup.sh` — full environment setup (zsh + omz + p10k + sshd + toolkit)
- `install-deps.sh` — installs pkg dependencies and links bin/ scripts

## Conventions
- Shebang: `#!/data/data/com.termux/files/usr/bin/sh` (Termux sh path)
- POSIX sh only — no bash-isms in `bin/` scripts
- `setup.sh` may use bash (`#!/bin/bash`)
- No hardcoded IPs, tunnel names, or device-specific values in scripts
- Cloudflare tunnel name is device-specific — document in README, not hardcoded

## Testing
No test runner. Test manually on device:
```bash
chmod +x bin/* && ./install-deps.sh
adb-port
shizuku status
tunnel status
```
