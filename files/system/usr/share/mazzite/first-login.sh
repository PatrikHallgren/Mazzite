#!/usr/bin/env bash
# Mazzite first-login seed script.
# Runs once per user (per home dir) the first time a Mango session
# is started. Idempotent — re-running is a no-op.
#
# What it does:
#   1. Seed ~/.config/mango/config.conf from /usr/share/mazzite/mango.conf
#      if the user has no config.
#   2. Seed ~/.config/noctalia/config.toml from /usr/share/mazzite/noctalia.toml
#      if the user has no config.
#   3. Touch ~/.local/share/mazzite/.seeded so it doesn't run again.

set -euo pipefail

SEED_FLAG="${XDG_DATA_HOME:-$HOME/.local/share}/mazzite/.seeded"
mkdir -p "$(dirname "$SEED_FLAG")"

if [[ -f "$SEED_FLAG" ]]; then
    exit 0
fi

# 1. Mango config
mkdir -p "$HOME/.config/mango"
if [[ ! -f "$HOME/.config/mango/config.conf" ]] && [[ -f /usr/share/mazzite/mango.conf ]]; then
    cp /usr/share/mazzite/mango.conf "$HOME/.config/mango/config.conf"
    echo "Mazzite: seeded ~/.config/mango/config.conf"
fi

# 2. Noctalia config
mkdir -p "$HOME/.config/noctalia"
if [[ ! -f "$HOME/.config/noctalia/config.toml" ]] && [[ -f /usr/share/mazzite/noctalia.toml ]]; then
    cp /usr/share/mazzite/noctalia.toml "$HOME/.config/noctalia/config.toml"
    echo "Mazzite: seeded ~/.config/noctalia/config.toml"
fi

# 3. Mark done
touch "$SEED_FLAG"
echo "Mazzite: first-login seed complete"
