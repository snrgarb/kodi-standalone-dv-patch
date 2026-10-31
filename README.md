# kodi-standalone-dv-patch

Native Dolby Vision in a standalone Kodi on CachyOS with Plasma Bigscreen.
Tested on an AMD Radeon RX 9070 XT (DCN 4.01).

This repository does not contain the Dolby Vision work. It contains build instructions and
packaging only. The scripts get the patches from the original project at build time.

## Credit

All Dolby Vision, CB1 and DVBridge work is by **CroqueMr**:
**[CroqueMr/libreelec-x86-dv](https://github.com/CroqueMr/libreelec-x86-dv)**.
That project is a LibreELEC fork. It gives native Dolby Vision output on x86 GPUs.
Go to that project for the design, the documentation and the supported hardware.
Do not send problems with this port to CroqueMr. Open an issue here.

Other upstream projects:
[LibreELEC](https://libreelec.tv), [Kodi](https://kodi.tv),
[CachyOS linux-cachyos](https://github.com/CachyOS/linux-cachyos), [FFmpeg](https://ffmpeg.org),
[libplacebo](https://github.com/haasn/libplacebo).

## Status

| Item | Result |
| --- | --- |
| RX 9070 XT, Profile 8.1, DV Standard | Works (LibreELEC and CachyOS) |
| RX 9070 XT, Profile 7 FEL, DV Master Reference | Works (LibreELEC) |
| Kodi start from Plasma Bigscreen, return to Plasma | Works (CachyOS) |
| Profile 5, kernel 7.3, PipeWire audio passthrough, CEC | Not tested |

This is experimental. CroqueMr does not list RX 9000 GPUs as supported. Use it at your own risk.

## Breakdown

The system has two parts: a patched kernel and a patched Kodi. Kodi does not run inside the
desktop. Kodi gets its own login session on tty7 and controls the display directly (KMS).
Dolby Vision needs this, because Kodi sets the DV HDMI properties on the display connector.
Plasma Bigscreen continues to run on its own VT. When you exit Kodi, the display goes back to
Plasma.

| Package | Contents |
| --- | --- |
| `linux-cachyos-cb1` (+ `-headers`) | CachyOS kernel 7.2.8 + 22 kernel patches from the fork + 3 patches from this repo |
| `cb1-ffmpeg` | FFmpeg 9.0 + the LibreELEC and fork patches |
| `cb1-libplacebo` | libplacebo `e2972fd` + 20 fork patches |
| `cb1-libdisplay-info` | libdisplay-info 0.4.0 (CachyOS has 0.3.0) |
| `cb1-lightgbm` | LightGBM 4.7.0 (for the CB1 HDR10 AI modes) |
| `kodi-cb1` | Kodi `28ea2ea` + 17 patches + CB1 from the fork, GBM/GLES, and the Bigscreen hand-off |

All packages except the kernel install in `/opt/cb1`. They do not replace the CachyOS Kodi,
FFmpeg or libplacebo. The kernel is a separate package. The stock `linux-cachyos` stays
installed as a fallback.

### Patches in this repository

| File | Function |
| --- | --- |
| `patches/linux/linux-9926-amd-dcn401-dv.patch` | Adds DCN 4.01 (RX 9000) to the AMD DV allowlist. Rejects a DV commit if the DCN 4.01 scaler or colour blocks can change pixels. |
| `patches/linux/linux-9927-cachyos-dv-exclusive-vsif.patch` | CachyOS 7.2 sends the HDMI 1.4 VSIF from a different slot. This patch disables that slot while DV is on, so the TV gets only the Dolby VSIF. |
| `patches/linux/linux-9930-amd-3d.patch` | The fork's 3D patch with one change: it uses `hfvsif_infopacket`, as CachyOS 7.2 does. |

`sources.map` lists the origin of each of the 73 patches. `pins.env` gives the tested commits.

## Build with Claude Code

You need: an x86-64 Linux computer with rootless `podman`, `git`, `curl` and `python3`.
Make sure that you have 40 GB of free disk space and 12 GB of RAM or more.
The kernel takes approximately 70 minutes with 10 threads.

1. Clone this repository and go into it.
2. Start Claude Code in the repository directory.
3. Give this prompt:

   > Read CLAUDE.md and follow it. Build all packages, verify them, and tell me the install command.

Claude reads `CLAUDE.md`. That file gives the procedure, the checks and the known problems.

## Build manually

```sh
scripts/fetch-sources.sh     # gets the fork and linux-cachyos at the pinned commits
scripts/build-all.sh         # builds in a CachyOS container; output goes to out/
```

Refer to [docs/BUILD.md](docs/BUILD.md) for more information.
Refer to [docs/INSTALL.md](docs/INSTALL.md) to install and test the packages.

## Licence

The kernel patches are GPL-2.0-only, as the Linux kernel is.
All other files in this repository are GPL-2.0-or-later (refer to `LICENSE`).
The patches that the scripts get from the fork keep their own licences.
