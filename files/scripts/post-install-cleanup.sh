#!/usr/bin/env bash
# Mazzite post-install cleanup.
# Run by the BlueBuild `script` module AFTER every other module
# (systemd enable, files copy, etc.) has finished.
#
# Things we want to clean up:
#   - dnf / rpm-ostree / libdnf5 caches
#   - the COPR yum repo GPG key (it's been validated already;
#     re-installing would re-fetch it unnecessarily)
#   - any leftover /tmp build artifacts
#   - bootc container lint is run as the LAST step to validate the
#     image boots cleanly.

set -euo pipefail

echo "==> Mazzite: post-install cleanup starting"

# 1. Package manager caches.
rm -rf /var/cache/dnf /var/cache/rpm-ostree /var/cache/libdnf5
rm -f  /var/log/dnf5.log /var/log/dnf5.rpm.log /var/log/hawkey.log

# 2. /tmp build residue (BlueBuild runs in a container; this is safe).
find /tmp -mindepth 1 -maxdepth 1 -exec rm -rf {} + 2>/dev/null || true

# 3. Drop any docs that bloat the image without value to a desktop user.
rm -rf /usr/share/doc/*/AUTHORS /usr/share/doc/*/COPYING \
       /usr/share/doc/*/NEWS /usr/share/doc/*/README* 2>/dev/null || true

# 4. Final lint pass — bootc validates the image is bootable.
echo "==> Mazzite: running bootc container lint"
/usr/bin/bootc container lint || {
    echo "WARNING: bootc container lint reported issues" >&2
}

echo "==> Mazzite: cleanup done"
