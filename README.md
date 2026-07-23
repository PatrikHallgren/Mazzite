# Mazzite

A custom [Universal Blue](https://universal-blue.org/) image based on
[Bazzite](https://bazzite.gg/) + [MangoWM](https://mangowm.github.io/)
+ [Noctalia v5](https://noctalia.dev/).

- **Base:** `ghcr.io/ublue-os/bazzite-nvidia:stable` (Fedora 44 + NVIDIA)
- **Compositor:** MangoWM (added session alongside the Bazzite default)
- **Shell:** Noctalia v5 `noctalia-git` (added session)

Result: `ghcr.io/patrikhallgren/mazzite:stable` — a Bazzite image that
boots into the default Bazzite desktop, **and** offers a `MangoWM
(Noctalia v5)` option at the SDDM greeter.

## Rebase to Mazzite

On a system already running a Universal Blue / Bazzite image:

```
sudo bootc switch ghcr.io/patrikhallgren/mazzite:stable
systemctl reboot
```

## Build locally

```
sudo dnf install podman buildah
just build
```

## Repository layout

```
Mazzite/
├── Containerfile                          # Multi-stage, FROM bazzite-nvidia
├── build_files/                           # Build-time scripts (run in image)
│   ├── 00-base.sh                         # MangoWM, Noctalia, desktop tools
│   ├── 10-mazzite.sh                      # System file wiring
│   ├── 20-cleanup.sh                      # dnf cleanup + systemd enable
│   └── copr/
│       └── lionheartp-Hyprland.repo.in    # COPR .repo template (%OS_VERSION%)
├── system_files/                          # Files baked into the final image
│   └── usr/
│       ├── lib/systemd/user/
│       │   └── noctalia.service            # Autostart Noctalia in Mango session
│       ├── share/mazzite/
│       │   ├── first-login.sh             # Seeds ~/.config on first Mango login
│       │   ├── mango.conf                 # Default Mango config (Gruvbox)
│       │   └── noctalia.toml              # Default Noctalia v5 config
│       └── share/wayland-sessions/
│           ├── mango-session.sh           # SDDM session wrapper
│           └── mangowm-noctalia.desktop    # SDDM session entry
├── .github/workflows/build.yml            # podman build + sign + push
├── Justfile                               # Local build recipes
├── cosign.pub                             # Public signing key
├── VERIFY.md                              # cosign verification how-to
└── README.md
```

## Session behaviour

| Greeter choice | What starts |
|---|---|
| Bazzite default (KDE/Plasma) | As before. `noctalia.service` does **not** start. |
| **MangoWM (Noctalia v5)** | SDDM runs `mango-session.sh` → seeds user configs → `/usr/bin/mango` → `noctalia.service` user unit fires once the Wayland display is up. |

The `noctalia.service` unit is gated on `XDG_SESSION_DESKTOP=mangowm-noctalia`
(set by SDDM from our custom session entry), so it never starts in the
default Bazzite session.

## Package sources

| Package | Source | Notes |
|---|---|---|
| `mangowm` | [Terra](https://repos.fyralabs.com/terra44) (`terra-extras`) | pre-enabled on Bazzite base |
| `noctalia-git` | [COPR `lionheartp/Hyprland`](https://copr.fedorainfracloud.org/coprs/lionheartp/Hyprland/) for Fedora 44 | rebuilt by the COPR on every upstream commit |
| Everything else | Bazzite's default Fedora + RPM Fusion repos | standard `dnf5 install` |

## nvidia EGL sidecar

We do **not** touch the nvidia EGL / VAAPI / GBM packages in the base
(`libnvidia-egl-wayland`, `libva-nvidia-driver`, `nvidia-vaapi-driver`,
`egl-wayland`, `mesa-vdpau-drivers`, `ublue-os-nvidia-addons`). Stripping
any of these silently kills the MangoWM session on boot — the screen
turns black and `noctalia` exits without an error.

If you see this on a real machine, the diagnostic from a TTY is:

```
ls /usr/lib64/libEGL_nvidia*
```

If that returns empty, the sidecar is gone. Add it back to
`build_files/00-base.sh`.

## Signing

Images are cosign-signed in CI. The `SIGNING_SECRET` GitHub Action
secret is the contents of `cosign.key` (your private signing key).
`cosign.pub` is checked in so verifiers can check signatures.

```
cosign verify --key cosign.pub ghcr.io/patrikhallgren/mazzite:stable
```

The same key pair is used for UBlueOS and Mazzite. See `VERIFY.md` for
the rotation procedure and rationale.
