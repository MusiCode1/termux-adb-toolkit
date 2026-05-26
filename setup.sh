#!/bin/bash
# setup.sh — full Termux environment setup
#
# Run MANUALLY before this script:
#   pkg upgrade -y
#   (restart Termux)
#   Then: chmod +x setup.sh && ./setup.sh

set -e
TOOLKIT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ─── Wizard ───────────────────────────────────────────────────────────────────

echo "╔════════════════════════════════════╗"
echo "║        adbtool setup wizard        ║"
echo "╚════════════════════════════════════╝"
echo ""

# Load existing config if present
[ -f "$TOOLKIT_DIR/config.env" ] && source "$TOOLKIT_DIR/config.env"

_ask() {
  local prompt="$1" default="$2" var="$3"
  printf "%s [%s]: " "$prompt" "${default}"
  read -r input
  eval "$var=\"${input:-$default}\""
}

_ask "ADB stable TCP port"         "${ADB_PORT:-5588}"       ADB_PORT
_ask "Cloudflare tunnel name"      "${CF_TUNNEL_NAME:-}"     CF_TUNNEL_NAME
_ask "Public SSH hostname"         "${CF_HOSTNAME:-}"        CF_HOSTNAME

echo ""
echo "Config:"
echo "  ADB_PORT        = $ADB_PORT"
echo "  CF_TUNNEL_NAME  = ${CF_TUNNEL_NAME:-(skip)}"
echo "  CF_HOSTNAME     = ${CF_HOSTNAME:-(skip)}"
echo ""
printf "Continue? [Y/n]: "
read -r confirm
case "$confirm" in
  [nN]*) echo "Aborted."; exit 0 ;;
esac

# Save config
cat > "$TOOLKIT_DIR/config.env" << EOF
ADB_PORT=$ADB_PORT
CF_TUNNEL_NAME=$CF_TUNNEL_NAME
CF_HOSTNAME=$CF_HOSTNAME
EOF
echo ""
echo "Saved to config.env."
echo ""

# ─── Packages ─────────────────────────────────────────────────────────────────

echo "[ 1/6 ] Installing packages..."
pkg install -y nodejs zsh git curl fzf openssh termux-services cloudflared

# ─── Cloudflare login ─────────────────────────────────────────────────────────

if [ -n "$CF_TUNNEL_NAME" ]; then
  echo ""
  if [ -f "$HOME/.cloudflared/cert.pem" ]; then
    echo "Cloudflare: already logged in — skipping."
  else
    echo "┌─────────────────────────────────────────────┐"
    echo "│  Cloudflare login required                  │"
    echo "│  A browser URL will appear — open it and    │"
    echo "│  authorize your Cloudflare account.         │"
    echo "└─────────────────────────────────────────────┘"
    echo ""
    cloudflared tunnel login
    echo "Logged in."
  fi
  echo ""

  # Create tunnel if it doesn't exist yet
  if ! cloudflared tunnel list 2>/dev/null | grep -q "$CF_TUNNEL_NAME"; then
    echo "Creating tunnel: $CF_TUNNEL_NAME..."
    cloudflared tunnel create "$CF_TUNNEL_NAME"
    echo ""
  else
    echo "Tunnel '$CF_TUNNEL_NAME' already exists — skipping creation."
    echo ""
  fi
fi

# ─── Oh My Zsh ────────────────────────────────────────────────────────────────

echo ""
echo "[ 2/6 ] Installing Oh My Zsh..."
if [ -d "$HOME/.oh-my-zsh" ]; then
  echo "  Already installed — skipping."
else
  RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# ─── Plugins & Theme ──────────────────────────────────────────────────────────

echo ""
echo "[ 3/6 ] Installing plugins & Powerlevel10k..."
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

[ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] || \
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
[ -d "$ZSH_CUSTOM/plugins/zsh-history-substring-search" ] || \
  git clone https://github.com/zsh-users/zsh-history-substring-search "$ZSH_CUSTOM/plugins/zsh-history-substring-search"
[ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] || \
  git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
[ -d "$ZSH_CUSTOM/themes/powerlevel10k" ] || \
  git clone --depth=1 https://github.com/romkatv/powerlevel10k "$ZSH_CUSTOM/themes/powerlevel10k"

# ─── Configure .zshrc ─────────────────────────────────────────────────────────

echo ""
echo "[ 4/6 ] Configuring .zshrc..."
sed -i 's/^plugins=(.*)/plugins=(git extract colored-man-pages zsh-autosuggestions zsh-history-substring-search zsh-syntax-highlighting)/' ~/.zshrc
sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc

grep -q "history-substring-search-up" ~/.zshrc || cat >> ~/.zshrc << 'EOF'

# history-substring-search
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# fzf
eval "$(fzf --zsh)"

# Shizuku
export RISH_APPLICATION_ID=com.termux
EOF

# ─── Font ─────────────────────────────────────────────────────────────────────

echo ""
echo "[ 5/6 ] Installing Meslo Nerd Font..."
mkdir -p ~/.termux
curl -fLo ~/.termux/font.ttf \
  https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf
termux-reload-settings

# ─── Services & toolkit ───────────────────────────────────────────────────────

echo ""
echo "[ 6/6 ] Installing services & toolkit..."

# sshd
mkdir -p "$PREFIX/share/termux-services/sshd/log"
if [ ! -f "$PREFIX/share/termux-services/sshd/run" ]; then
  cat > "$PREFIX/share/termux-services/sshd/run" << 'SVCEOF'
#!/data/data/com.termux/files/usr/bin/sh
exec /data/data/com.termux/files/usr/sbin/sshd -D -e 2>&1
SVCEOF
  chmod +x "$PREFIX/share/termux-services/sshd/run"
fi
ln -sf "$PREFIX/share/termux-services/sshd" "$PREFIX/var/service/sshd" 2>/dev/null || true

# cloudflared service (if tunnel configured)
if [ -n "$CF_TUNNEL_NAME" ]; then
  mkdir -p "$PREFIX/share/termux-services/cloudflared/log"
  cat > "$PREFIX/share/termux-services/cloudflared/run" << SVCEOF
#!/data/data/com.termux/files/usr/bin/sh
exec cloudflared tunnel run $CF_TUNNEL_NAME 2>&1
SVCEOF
  chmod +x "$PREFIX/share/termux-services/cloudflared/run"
  touch "$PREFIX/share/termux-services/cloudflared/down"
  ln -sf "$PREFIX/share/termux-services/cloudflared" "$PREFIX/var/service/cloudflared" 2>/dev/null || true
  echo "  cloudflared service created (disabled by default — run: adbtool tunnel up)"
fi

# Install toolkit
bash "$TOOLKIT_DIR/install-deps.sh"

# ─── Done ─────────────────────────────────────────────────────────────────────

echo ""
echo "╔════════════════════════════════════╗"
echo "║             All done!              ║"
echo "╚════════════════════════════════════╝"
echo ""
echo "Close and reopen Termux, then:"
echo "  sv-enable sshd && sv up sshd"
echo "  adbtool start     ← when WiFi + Wireless Debugging active"
echo "  exec zsh"
