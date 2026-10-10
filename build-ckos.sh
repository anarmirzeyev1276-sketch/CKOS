#!/usr/bin/env bash
# CKOS ISO builder (Debian trixie + light XFCE + Chromium + Thunar)
# Usage: bash build-ckos.sh [amd64|arm64]   (run as root, internet needed)
# Output: ckos/live-image-<arch>.hybrid.iso
set -euo pipefail
ARCH="${1:-amd64}"

apt-get update
apt-get install -y live-build debootstrap debian-archive-keyring

mkdir -p ckos && cd ckos
lb clean --purge || true

EXTRA=()
[ "$ARCH" = "arm64" ] && EXTRA=(--bootloaders grub-efi --linux-flavours arm64)

lb config \
  --distribution trixie \
  --architectures "$ARCH" \
  --mirror-bootstrap http://deb.debian.org/debian \
  --mirror-chroot http://deb.debian.org/debian \
  --mirror-binary http://deb.debian.org/debian \
  --binary-images iso-hybrid \
  --debian-installer none \
  --archive-areas main \
  --apt-recommends false \
  --apt-indices false \
  --firmware-chroot false \
  --iso-application CKOS --iso-volume CKOS \
  --bootappend-live "boot=live components quiet username=ckos hostname=ckos" \
  "${EXTRA[@]}"

mkdir -p config/package-lists
cat > config/package-lists/ckos.list.chroot <<'EOL'
xfce4-session
xfwm4
xfce4-panel
xfdesktop4
xfce4-settings
xfce4-terminal
lightdm
thunar
gvfs
chromium
network-manager
network-manager-gnome
sudo
dbus-x11
fonts-dejavu-core
EOL

mkdir -p config/hooks/normal
cat > config/hooks/normal/0100-brand.hook.chroot <<'EOL'
#!/bin/sh
sed -i 's/^PRETTY_NAME=.*/PRETTY_NAME="CKOS"/; s/^NAME=.*/NAME="CKOS"/' /etc/os-release
EOL
chmod +x config/hooks/normal/0100-brand.hook.chroot

lb build
ls -lh ./*.iso
