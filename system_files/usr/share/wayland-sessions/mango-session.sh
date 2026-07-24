#!/usr/bin/env bash
# Mazzite — MangoWM session wrapper
#
# Launched by SDDM (Bazzite's plasmalogin) when the user picks
# "MangoWM (Noctalia v5)" at the greeter. Plasmalogin takes
# XDG_SESSION_DESKTOP from the `DesktopNames=` field of the .desktop
# file, not the filename, so it exports XDG_SESSION_DESKTOP=MangoWM
# for our session. The noctalia.service user unit gates on that value.
# This script also `import-environment`s the relevant vars into the user
# systemd manager — see the block below before `exec /usr/bin/mango`.
#
# Responsibilities:
#   1. Pre-flight check that `mango` binary exists.
#   2. Export MangoWM's expected env vars (XDG_CURRENT_DESKTOP=MangoWM).
#   3. If the user has no Mango config yet, seed ~/.config/mango/config.conf
#      from /usr/share/mazzite/mango.conf (the Mazzite-default we ship).
#   4. Hand off to /usr/bin/mango. The user-level noctalia.service unit
#      picks up from there once the Wayland display is up.
#
# Logs go to ~/.local/share/mazzite/mango-session.log for post-mortem.

set -euo pipefail

LOG_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/mazzite"
LOG_FILE="$LOG_DIR/mango-session.log"
mkdir -p "$LOG_DIR"

exec 1>>"$LOG_FILE" 2>&1
echo "--- mango-session.sh started at $(date -Iseconds) ---"
echo "    XDG_SESSION_DESKTOP=${XDG_SESSION_DESKTOP:-unset}"

# MangoWM expects these; SDDM usually sets them but be defensive.
export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=MangoWM
# XDG_SESSION_DESKTOP comes from SDDM as "MangoWM" (DesktopNames= field in
# mangowm-noctalia.desktop). Keep it — it's what gates noctalia.service.
export DESKTOP_SESSION="${XDG_SESSION_DESKTOP:-mangowm-noctalia}"

# Push the session-identifying vars into the user systemd manager's
# environment. The user manager was spawned by PAM/plasmalogin before
# this script ran and has its env frozen at that point — without these
# imports, ConditionEnvironment= in noctalia.service evaluates against
# a manager env that has no XDG_SESSION_DESKTOP, and the gate silently
# fails (no journal entry, unit never even attempted). WAYLAND_DISPLAY
# is included so the unit's second gate also sees the right value.
if command -v systemctl >/dev/null 2>&1; then
    systemctl --user import-environment \
        XDG_SESSION_DESKTOP \
        XDG_CURRENT_DESKTOP \
        DESKTOP_SESSION \
        XDG_SESSION_TYPE \
        WAYLAND_DISPLAY || true
fi

# Activate graphical-session.target so any user unit with
# WantedBy=graphical-session.target (e.g. noctalia.service) auto-starts.
# Without this, graphical-session.target stays inactive — it's a "refuse
# manual start" target reached only via dependency, and Mango's session
# script is the only thing here that can pull it in. We start our own
# mazzite-session.service (shipped in /usr/lib/systemd/user) which has
# Wants=graphical-session.target, so the target comes up transitively.
if command -v systemctl >/dev/null 2>&1; then
    systemctl --user start mazzite-session.service || true
fi

if ! command -v mango >/dev/null 2>&1; then
    echo "FATAL: /usr/bin/mango not found. Did the terra-extras layer install?" >&2
    notify-send "MangoWM missing" "The mango binary is not installed." 2>/dev/null || true
    exit 1
fi

# Seed the user Mango config from the Mazzite default on first run,
# unless the user already has one (in which case we leave it alone).
# first-login.sh handles both the Mango and Noctalia seed files.
if [[ -x /usr/share/mazzite/first-login.sh ]]; then
    /usr/share/mazzite/first-login.sh || true
fi

echo "Starting /usr/bin/mango"
exec /usr/bin/mango
