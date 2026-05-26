#!/bin/bash
# setup.sh — full Termux environment setup
#
# Run MANUALLY before this script:
#   pkg upgrade -y
#   (restart Termux)
#   Then: chmod +x setup.sh && ./setup.sh

set -e

# Install packages
pkg install -y nodejs zsh git curl fzf openssh termux-services

# Oh My Zsh (sets zsh as default shell)
RUNZSH=no CHSH=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Plugins
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-history-substring-search ~/.oh-my-zsh/custom/plugins/zsh-history-substring-search
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting

# Powerlevel10k
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

# Configure .zshrc
sed -i 's/^plugins=(.*)/plugins=(git extract colored-man-pages zsh-autosuggestions zsh-history-substring-search zsh-syntax-highlighting)/' ~/.zshrc
sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc

cat >> ~/.zshrc << 'EOF'

# history-substring-search
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# fzf
eval "$(fzf --zsh)"

# Shizuku
export RISH_APPLICATION_ID=com.termux
EOF

# Meslo font
mkdir -p ~/.termux
curl -fLo ~/.termux/font.ttf \
  https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf
termux-reload-settings

# sshd service
mkdir -p "$PREFIX/share/termux-services/sshd/log"
cat > "$PREFIX/share/termux-services/sshd/run" << 'SVCEOF'
#!/data/data/com.termux/files/usr/bin/sh
exec /data/data/com.termux/files/usr/sbin/sshd -D -e 2>&1
SVCEOF
chmod +x "$PREFIX/share/termux-services/sshd/run"
ln -sf "$PREFIX/share/termux-services/sshd" "$PREFIX/var/service/sshd" 2>/dev/null || true

# Install toolkit dependencies
TOOLKIT_DIR="$(cd "$(dirname "$0")" && pwd)"
bash "$TOOLKIT_DIR/install-deps.sh"

echo ""
echo "Done! Close and reopen Termux, then run:"
echo "  sv-enable sshd && sv up sshd"
echo "  exec zsh"
