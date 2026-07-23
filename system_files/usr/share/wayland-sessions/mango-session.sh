#!/usr/bin/env bash
# Mazzite — MangoWM session wrapper
#
# Launched by SDDM when the user picks "MangoWM (Noctalia v5)" at the
# greeter. SDDM exports XDG_SESSION_DESKTOP=mangowm-noctalia into the
# session, which is what the noctalia.service user unit keys off of to
# decide whether to start.
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
# XDG_SESSION_DESKTOP comes from SDDM as "mangowm-noctalia" — keep it
# (don't override), it's what gates noctalia.service.
export DESKTOP_SESSION="${XDG_SESSION_DESKTOP:-mangowm-noctalia}"

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
