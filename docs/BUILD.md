# Build

## Requirements

- An x86-64 Linux computer. The build computer can be different from the TV computer.
- Rootless `podman`, `git`, `curl` and `python3`.
- 40 GB of free disk space and 12 GB of RAM or more.
- Internet access. The scripts get the sources from GitHub, ffmpeg.org, VideoLAN, SourceForge
  and Apache.

The build runs in a CachyOS container. You do not need CachyOS on the build computer.

## Procedure

1. Clone this repository:

   ```sh
   git clone https://github.com/snrgarb/kodi-standalone-dv-patch.git
   cd kodi-standalone-dv-patch
   ```

2. Get the sources:

   ```sh
   scripts/fetch-sources.sh
   ```

   The script does these steps:
   - It clones [CroqueMr/libreelec-x86-dv](https://github.com/CroqueMr/libreelec-x86-dv) at the
     commit in `pins.env`.
   - It runs the fork's checks and its staging script. These verify the CB1 sources and patches.
   - It gets the linux-cachyos PKGBUILD and config at the commit in `pins.env`. Then it applies
     `packaging/linux-cachyos-cb1/PKGBUILD.patch`.
   - It copies each patch in `sources.map` into `build/pkgs/<package>/`.

   Make sure that the output ends with `Copied 74 patches.` and `Done.`

3. Build the packages:

   ```sh
   tmux new -s cb1 scripts/build-all.sh
   ```

   The script builds the container image `localhost/cb1-builder`. Then it builds the packages in
   this sequence: kernel, libdisplay-info, LightGBM, libplacebo, FFmpeg, Kodi.
   The kernel takes approximately 70 minutes with 10 threads.
   To use fewer threads, set `JOBS`, for example `JOBS=4 scripts/build-all.sh`.

   The logs are in `build/logs/`. If a package fails, read the end of its log.
   To build one package again, give its name: `scripts/build-all.sh kodi-cb1`.

4. Verify the packages:

   ```sh
   scripts/verify.sh
   ```

   Make sure that each line shows `PASS`.

5. Copy the `out/` directory to the TV computer. Then refer to [INSTALL.md](INSTALL.md).

## Compiler flags

The container uses `-march=x86-64 -O2`, as LibreELEC does. Thus, the packages run on all
x86-64 CPUs. Do not use `-march=native`, unless the build computer and the TV computer have
the same CPU.

## Pinned versions

| Input | Version | Pin |
| --- | --- | --- |
| CroqueMr/libreelec-x86-dv | `c7317cab38` | `pins.env` |
| CachyOS/linux-cachyos PKGBUILD | `41605bd4ab` (kernel 7.2.8-1) | `pins.env` |
| Kodi | `28ea2eac1e` | `packaging/kodi-cb1/PKGBUILD` |
| FFmpeg | 9.0 | `packaging/cb1-ffmpeg/PKGBUILD` |
| libplacebo | `e2972fdd09` | `packaging/cb1-libplacebo/PKGBUILD` |

The PKGBUILDs contain a checksum for each source file. The CB1 tarball for Kodi has no
checksum in the PKGBUILD. The fork's `cb1-stage.py` verifies its contents in step 2.

A newer fork commit can work, but it is not tested. Kernel 7.3 and later needs a port of the
kernel patches, because `amdgpu_dm.c` is split in 7.3.
