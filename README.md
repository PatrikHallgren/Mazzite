# Mazzite

A custom [Universal Blue](https://universal-blue.org/) / [Bazzite](https://bazzite.gg/) image:

- **Base:** `ghcr.io/ublue-os/bazzite-nvidia:stable` (Fedora 44 + NVIDIA)
- **Compositor:** [MangoWM](https://mangowm.github.io/) (added session)
- **Shell:** [Noctalia v5](https://noctalia.dev/) `noctalia-git` (added session)

Result: `ghcr.io/patrikhallgren/mazzite:stable` — a Bazzite image that boots into
the default Bazzite desktop, **and** offers a `MangoWM (Noctalia v5)` option at
the SDDM greeter.

## Rebase to Mazzite

On a system already running a Universal Blue / Bazzite image:

```
sudo bootc switch ghcr.io/patrikhallgren/mazzite:stable
systemctl reboot
```

## Build locally

Requires `podman` and the `bluebuild` CLI:

```
sudo dnf install bluebuild
just build
```

## Repository layout

```
Mazzite/
├── recipe.yml                              # main recipe (root: /recipes/recipe.yml)
├── .github/workflows/build.yml             # GitHub Actions CI
├── files/
│   ├── scripts/post-install-cleanup.sh     # final dnf/bootc cleanup
│   └── system/
│       ├── usr/lib/systemd/user/
│       │   └── noctalia.service            # autostart noctalia in MangoWM
│       ├── usr/share/mango/
│       │   └── config.conf                 # default MangoWM keybinds
│       └── usr/share/wayland-sessions/
│           ├── mangowm-noctalia.desktop    # SDDM session entry
│           └── mango-session.sh            # session wrapper
├── Justfile                                # local build recipes
├── VERIFY.md                               # cosign verification how-to
├── cosign.pub                              # public signing key (NOT a secret)
└── README.md
```

## Session behaviour

| Greeter choice | What starts |
|---|---|
| `Bazzite GNOME` (default) | Bazzite's default session. Noctalia does **not** start. |
| `MangoWM (Noctalia v5)`   | SDDM runs `mango-session.sh` → `/usr/bin/mango` → once the Wayland display is up, the `noctalia.service` user unit starts `noctalia`. |

## Package sources

| Package | Source | Notes |
|---|---|---|
| `mangowm` | [Terra](https://repos.fyralabs.com/terra44) (`terra-extras`) | pre-enabled on Bazzite base |
| `noctalia-git` | [COPR `lionheartp/Hyprland`](https://copr.fedorainfracloud.org/coprs/lionheartp/Hyprland/) for Fedora 44 | rebuilds on every upstream commit |

## nvidia EGL sidecar

We do **not** touch the nvidia EGL / VAAPI / GBM packages in the base
(`libnvidia-egl-wayland`, `libva-nvidia-driver`, `nvidia-vaapi-driver`,
`egl-wayland`, `mesa-vdpau-drivers`, `ublue-os-nvidia-addons`). Stripping any
of these silently kills the MangoWM session on boot — the screen turns black
and `noctalia` exits without an error. See `references/nvidia-egl-debug.md`
from the `ublue-custom-images` skill for the diagnostic transcript.

## Signing

Images are cosign-signed. The CI consumes the `SIGNING_SECRET` GitHub
Action secret. To verify locally:

```
cosign verify --key cosign.pub ghcr.io/patrikhallgren/mazzite:stable
```

The same key pair is used for UBlueOS and Mazzite. See `VERIFY.md` for
the rotation procedure and rationale.
