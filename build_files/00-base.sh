#!/usr/bin/env bash
# Mazzite — Phase 1: Base system tweaks
#
# Installs MangoWM and Noctalia v5 (git) on top of bazzite-nvidia.
# Note: bazzite-nvidia:stable ships with the Terra repository already
# enabled (terra-release + terra-release-extras + terra-release-mesa
# are installed in the base image's build), so `dnf5 --enable-repo=terra`
# is mostly defensive — it makes the source explicit if a future Bazzite
# base strips Terra.
#
# We DO NOT touch any nvidia-* / libnvidia-egl-* / libva-nvidia-driver
# packages. The Bazzite nvidia EGL sidecar must stay intact for Mango
# to be able to bind an EGL context at runtime. See references in the
# ublue-custom-images skill for the diagnostic if you see a silent
# black screen on the Mango session.

set -euxo pipefail

# ------------------------------------------------------------------
# MangoWM compositor (Terra, package `mangowm`, binary `/usr/bin/mango`)
# ------------------------------------------------------------------
# Terra is pre-enabled. We pass --enable-repo to be explicit in case
# a future Bazzite base image strips the Terra repo.
dnf5 -y --enable-repo=terra install mangowm

# ------------------------------------------------------------------
# Noctalia v5 (git)
# ------------------------------------------------------------------
# Source: https://copr.fedorainfracloud.org/coprs/lionheartp/Hyprland/
# Built for Fedora 44 (which is what bazzite-nvidia:stable is on
# as of mid-2026).
#
# The COPR repo is added in the Containerfile's `ADD` step, not here,
# so the .repo file is preserved in /etc/yum.repos.d/ and the package
# is fetchable on this build.
#
# Also install the explicit runtime deps the COPR package `Requires:`s
# (hicolor-icon-theme, dejavu-sans-fonts) so the build is resilient to
# future Bazzite base-image changes that might drop them.
dnf5 -y install noctalia-git libwebp hicolor-icon-theme dejavu-sans-fonts

# ------------------------------------------------------------------
# Desktop tooling — fills gaps Noctalia doesn't cover
# ------------------------------------------------------------------
dnf5 -y install \
  foot                 `# Wayland terminal (Super+Enter; also used by drop-down scratchpad)` \
  fuzzel               `# app launcher (fallback to Noctalia)` \
  wl-clipboard         `# wl-copy / wl-paste` \
  swayidle swaylock    `# idle daemon + screen locker` \
  pamixer pavucontrol  `# volume tools` \
  imv                  `# image viewer` \
  wev                  `# input event debugger` \
  wlsunset             `# night light` \
  playerctl            `# media key controls` \
  xdg-desktop-portal-gnome \
  xdg-desktop-portal-gtk

# ------------------------------------------------------------------
# Qt/GTK theming bridge
# ------------------------------------------------------------------
dnf5 -y install \
  qt6ct kvantum        `# Qt6 theme selector + engine` \
  adw-gtk3-theme       `# libadwaita → GTK3 theme bridge`

# ------------------------------------------------------------------
# Nerd Fonts (Cascadia Code — used by Mango, fuzzel, neovim)
# ------------------------------------------------------------------
dnf5 -y --enable-repo=terra install cascadiacode-nerd-fonts

# ------------------------------------------------------------------
# Force Wayland for Qt apps
# ------------------------------------------------------------------
mkdir -p /etc/environment.d
cat > /etc/environment.d/qt6ct.conf << 'EOF'
QT_QPA_PLATFORM=wayland
QT_QPA_PLATFORMTHEME=qt6ct
QT_STYLE_OVERRIDE=kvantum
EOF