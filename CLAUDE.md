# Instructions for Claude: build the CB1 Dolby Vision packages for CachyOS

Goal: build 7 pacman packages in `out/` and give the user the install command.
The Dolby Vision work is by CroqueMr (https://github.com/CroqueMr/libreelec-x86-dv).
This repository contains only packaging, three kernel patches and scripts.

## Rules

- Do not change a patch file. Do not change a pin in `pins.env`, unless the user tells you to.
- Do not put a patch from the fork into this repository. The scripts get the patches at build time.
- Do not use `-march=native`. The packages must run on a different computer.
- Do not post to the CroqueMr repository (issues, pull requests or comments).
- Do not install packages on the build computer, unless the user tells you to.
- Run the build in the background. The kernel takes approximately 70 minutes with 10 threads.
- If a step fails, stop and read the log. Do not try the same command again without a change.

## Procedure

1. Make sure that `podman`, `git`, `curl` and `python3` are available.
   Make sure that rootless podman works: `podman run --rm docker.io/cachyos/cachyos:latest true`.
2. Make sure that 40 GB of disk space is free in this directory.
3. Run `scripts/fetch-sources.sh`.
   - The script clones the fork at `FORK_COMMIT` and runs the fork's own CB1 checks
     (`CB1/tools/verify.py`, `scripts/cb1-stage.py`).
   - The script gets the linux-cachyos PKGBUILD at `LC_COMMIT` and applies
     `packaging/linux-cachyos-cb1/PKGBUILD.patch`.
   - The script copies the 73 patches in `sources.map` to `build/pkgs/<package>/`.
   - Expected last lines: `Copied 73 patches.` and `Done.`
4. Run `scripts/build-all.sh` in the background (for example, in `tmux`).
   Set `JOBS` to the number of CPU threads if you must use fewer threads.
   - The logs are in `build/logs/<package>.log`.
   - To build one package again: `scripts/build-all.sh <package>`.
5. Do the checks in "Verification".
6. Tell the user the install procedure in `docs/INSTALL.md`.
   Tell the user that the packages are in `out/` and that `out/SHA256SUMS` is available.

## Verification

Run `scripts/verify.sh`. Report each line of the output to the user.
Expected result: 6 lines with `PASS` and the line `All checks passed.`

The script makes sure that:
- there are 7 packages and `out/SHA256SUMS` is correct,
- `amdgpu.ko` contains the DVBridge code and the kernel version is `7.2.8-1-cachyos-cb1`,
- `kodi.bin` contains the DV connector property and loads its libraries from `/opt/cb1/lib`.

If a check fails, do not tell the user that the build is good.

## Known problems and fixes

| Symptom | Cause | Fix |
| --- | --- | --- |
| `fetch-sources.sh` stops with `Source mismatch` or `Integration mismatch` | The fork checkout is not at `FORK_COMMIT`, or it has changes | Remove `build/libreelec-x86-dv` and run the script again |
| A patch does not apply after a failed build | `src/` contains old files | `build-all.sh` uses `makepkg -C`. Make sure that you did not remove `-C` |
| FFmpeg assembler errors | LTO | The PKGBUILD has `options=('!lto')`. Do not remove it |
| Kodi link error about `pack-relative-relocs` | The gold linker | The PKGBUILD sets `-DENABLE_GOLD=OFF`. Do not remove it |
| Kodi stops with a hash error for libdvd*, crossguid, fstrcmp or udfread | Kodi expects its own mirror files | The PKGBUILD gives `*_HASH=SHA256=...` for the upstream files. Do not remove these |
| Kodi cannot find `cta-vic.h` | Old libdisplay-info | Build `cb1-libdisplay-info` before `kodi-cb1` |
| Kernel: `unknown public key` | The kernel signature key is not in the container | `build-all.sh` uses `--skippgpcheck` for the kernel only. The b2sum is still checked |
| `pacman -U` on the target: `duplicate target` | The glob includes a package two times | Use `sudo pacman -U ./*.pkg.tar.zst` in the `out/` directory |

## To change a version

If the user wants a newer fork commit or a newer kernel, tell the user that the result is not
tested. Then:

1. Change the pin in `pins.env`. For the fork, also change `_cb1rev` in
   `packaging/kodi-cb1/PKGBUILD`.
2. Run `scripts/fetch-sources.sh`. If a file in `sources.map` is missing, find the new name
   in the fork and update `sources.map` and the `source=()` array of the PKGBUILD.
3. Run `updpkgsums` in the container for each changed PKGBUILD. Copy the new sums back to
   `packaging/`. For the kernel, update the `b2sums+=()` block in `PKGBUILD.patch`.
4. Kernel 7.3 and later: the fork patches do not apply, because `amdgpu_dm.c` is split.
   This needs a port. Tell the user before you start a port.
