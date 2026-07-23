#!/usr/bin/env bash
# Mazzite — Phase 3: Final cleanup + systemd enable
#
# - Remove cruft that opens blank windows on the Mango session
# - Enable the Noctalia v5 user systemd unit globally
# - Lint the bootc image

set -euxo pipefail

# xwaylandvideobridge opens blank windows on non-KDE compositors
dnf5 -y remove xwaylandvideobridge 2>/dev/null || true

# fw-fanctrl is Framework-specific; not useful on a generic image
dnf5 -y remove fw-fanctrl 2>/dev/null || true

# Enable the Noctalia v5 user systemd unit globally so any user
# logging into a Mango session gets the desktop shell.
#
# `systemctl --global enable` writes the symlink in
# /etc/systemd/user/default.target.wants/, which is what we want.
systemctl --global enable noctalia.service 2>/dev/null || true

# Clean package cache
dnf5 clean all
rm -rf /var/cache/dnf /var/cache/rpm-ostree /var/cache/libdnf5
rm -f /var/log/dnf5.log /var/log/dnf5.rpm.log /var/log/hawkey.log

# Final lint pass — bootc validates the image is bootable
bootc container lint || true
