#!/bin/bash
# install-deps.sh — install all dependencies for termux-adb-toolkit
#
# Run AFTER: pkg upgrade -y (and restart Termux)

set -e

echo "Installing dependencies..."
pkg install -y \
  android-tools \
  cloudflared \
  mdns-scan \
  openssh \
  termux-services

echo ""
echo "Installing rish from Shizuku APK..."
if [ -f "$PREFIX/bin/rish" ] && [ -f "$PREFIX/share/shizuku/rish_shizuku.dex" ]; then
  echo "  rish already installed — skipping."
else
  SHIZUKU_APK=$(adb shell find /data/app -name "base.apk" 2>/dev/null | grep -i "shizuku\|moe.shizuku" | tr -d '\r' | head -1)
  if [ -z "$SHIZUKU_APK" ]; then
    echo "  WARNING: rish not found and ADB not connected."
    echo "  Connect ADB (Wireless Debugging) and re-run, or install rish manually."
  else
    mkdir -p "$PREFIX/share/shizuku"
    adb pull "$SHIZUKU_APK" "$TMPDIR/shizuku.apk"
    unzip -p "$TMPDIR/shizuku.apk" assets/rish > "$PREFIX/bin/rish"
    unzip -p "$TMPDIR/shizuku.apk" assets/rish_shizuku.dex > "$PREFIX/share/shizuku/rish_shizuku.dex"
    chmod 400 "$PREFIX/share/shizuku/rish_shizuku.dex"
    chmod +x "$PREFIX/bin/rish"
    sed -i "s|BASEDIR=\$(dirname \"\$0\")|BASEDIR=$PREFIX/share/shizuku|" "$PREFIX/bin/rish"
    echo "  rish installed."
  fi
fi

echo ""
echo "Installing adbtool..."
TOOLKIT_DIR="$(cd "$(dirname "$0")" && pwd)"
chmod +x "$TOOLKIT_DIR/bin/adbtool"
ln -sf "$TOOLKIT_DIR/bin/adbtool" "$PREFIX/bin/adbtool"
echo "  linked: adbtool"

echo ""
echo "Installing completions..."
mkdir -p "$PREFIX/share/bash-completion/completions"
mkdir -p "$PREFIX/share/zsh/site-functions"
cp "$TOOLKIT_DIR/completions/adbtool.bash" "$PREFIX/share/bash-completion/completions/adbtool"
cp "$TOOLKIT_DIR/completions/_adbtool"     "$PREFIX/share/zsh/site-functions/_adbtool"
echo "  bash: $PREFIX/share/bash-completion/completions/adbtool"
echo "  zsh:  $PREFIX/share/zsh/site-functions/_adbtool"

echo ""
echo "Setting RISH_APPLICATION_ID in ~/.zshrc..."
if ! grep -q "RISH_APPLICATION_ID" ~/.zshrc 2>/dev/null; then
  printf '\nexport RISH_APPLICATION_ID=com.termux\n' >> ~/.zshrc
fi

# Enable zsh completions path if not already set
if ! grep -q "zsh/site-functions" ~/.zshrc 2>/dev/null; then
  printf '\nfpath=(%s $fpath)\nautoload -Uz compinit && compinit\n' \
    "$PREFIX/share/zsh/site-functions" >> ~/.zshrc
fi

echo ""
echo "Done. Restart Termux or run: source ~/.zshrc"
echo "Then try: adbtool <TAB>"
