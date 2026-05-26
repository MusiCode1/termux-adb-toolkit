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
SHIZUKU_APK=$(adb shell find /data/app -name "base.apk" 2>/dev/null | grep -i "shizuku\|moe.shizuku" | tr -d '\r' | head -1)

if [ -z "$SHIZUKU_APK" ]; then
  echo "  WARNING: Shizuku APK not found. Install Shizuku first, then re-run this script."
else
  mkdir -p "$PREFIX/share/shizuku"
  adb pull "$SHIZUKU_APK" "$TMPDIR/shizuku.apk"
  unzip -p "$TMPDIR/shizuku.apk" assets/rish > "$PREFIX/bin/rish"
  unzip -p "$TMPDIR/shizuku.apk" assets/rish_shizuku.dex > "$PREFIX/share/shizuku/rish_shizuku.dex"
  chmod 400 "$PREFIX/share/shizuku/rish_shizuku.dex"
  chmod +x "$PREFIX/bin/rish"
  # Point rish to the correct DEX location
  sed -i "s|BASEDIR=\$(dirname \"\$0\")|BASEDIR=$PREFIX/share/shizuku|" "$PREFIX/bin/rish"
  echo "  rish installed."
fi

echo ""
echo "Installing toolkit scripts..."
TOOLKIT_DIR="$(cd "$(dirname "$0")" && pwd)"
chmod +x "$TOOLKIT_DIR"/bin/*
for f in "$TOOLKIT_DIR"/bin/*; do
  ln -sf "$f" "$PREFIX/bin/$(basename $f)"
  echo "  linked: $(basename $f)"
done

echo ""
echo "Setting RISH_APPLICATION_ID in ~/.zshrc..."
if ! grep -q "RISH_APPLICATION_ID" ~/.zshrc 2>/dev/null; then
  echo "\nexport RISH_APPLICATION_ID=com.termux" >> ~/.zshrc
fi

echo ""
echo "Done. Restart Termux or run: source ~/.zshrc"
