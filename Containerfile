# Mazzite — Bazzite-NVIDIA + MangoWM + Noctalia v5 (git)
#
# Build arg selects the base. GitHub Actions sets it via matrix.
# Mirrors the ublue-os/image-template pattern used by UBlueOS.

ARG BASE_IMAGE=ghcr.io/ublue-os/bazzite-nvidia:stable

# Context stage: holds build scripts and the COPR repo file
# without baking them into the runtime image layers.
FROM scratch AS ctx
COPY build_files /
# COPR repo for noctalia-git. Fedora version is filled in at build
# time from /etc/os-release via the sed below.
COPY build_files/copr/lionheartp-Hyprland.repo.in /lionheartp-Hyprland.repo.in

# Main stage: the actual OS image
FROM ${BASE_IMAGE}

# Copy build scripts into the image
COPY --from=ctx / /

# ---------------------------------------------------------------
# Fix /opt (atomic images symlink /opt to /var/opt, which breaks
# RPMs that expect a real /opt directory). Same fix as UBlueOS.
# ---------------------------------------------------------------
RUN rm /opt && mkdir /opt

# ---------------------------------------------------------------
# Install the lionheartp/Hyprland COPR repo (for noctalia-git).
# The .in file has the literal `%OS_VERSION%` placeholder; we
# sed-substitute to the actual Fedora version from /etc/os-release.
# ---------------------------------------------------------------
RUN set -eux; \
    OS_VERSION="$(. /etc/os-release && echo "${VERSION_ID}")"; \
    BASE_ARCH="$(uname -m)"; \
    sed -e "s/%OS_VERSION%/${OS_VERSION}/g" -e "s/%BASEARCH%/${BASE_ARCH}/g" \
        /lionheartp-Hyprland.repo.in > /etc/yum.repos.d/lionheartp-Hyprland.repo; \
    rm /lionheartp-Hyprland.repo.in; \
    cat /etc/yum.repos.d/lionheartp-Hyprland.repo

### === System files (Mango session, Noctalia service, default configs) ===
# These are placed in their final paths at build time and persist
# into the bootc image. Done BEFORE the build scripts run so the
# scripts can sanity-check them.
COPY system_files /

### === Phase 1: Base system tweaks (MangoWM, Noctalia, desktop tools) ===
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /00-base.sh

### === Phase 2: Mazzite system files wiring ===
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /10-mazzite.sh

### === Phase 3: Final cleanup + systemd enable ===
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /20-cleanup.sh

### === Final bootc lint ===
RUN bootc container lint || true
