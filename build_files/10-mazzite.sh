#!/usr/bin/env bash
# Mazzite — Phase 2: Mango + Noctalia system files
#
# The system files themselves are dropped into the image by the
# Containerfile's `COPY system_files /` step. This script exists
# for any post-install wiring that's easier to do as a script
# than as a Dockerfile RUN.

set -euxo pipefail

# Ensure the Mango session entry is present.
# The `mangowm` Terra package ships its own `mango.desktop`, but
# we ship a custom one (`mangowm-noctalia.desktop`) that sets the
# right XDG vars and runs the session wrapper. Keep both visible
# in SDDM.
test -f /usr/share/wayland-sessions/mangowm-noctalia.desktop
test -x /usr/share/wayland-sessions/mango-session.sh
test -f /usr/lib/systemd/user/noctalia.service

# First-login seed helper (seeds ~/.config/{mango,noctalia}/ on
# first Mango session start). Marked executable.
chmod +x /usr/share/mazzite/first-login.sh

# The `mango-session.sh` wrapper also needs to be executable.
chmod +x /usr/share/wayland-sessions/mango-session.sh
