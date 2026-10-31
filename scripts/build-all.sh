#!/bin/bash
# Build all packages in a rootless podman CachyOS container. Output: out/*.pkg.tar.zst + SHA256SUMS.
# Usage: scripts/build-all.sh [package...]   (default: all, in dependency order)
# Env:   JOBS=<n> (default: nproc)
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
B=$ROOT/build
OUT=$ROOT/out
JOBS=${JOBS:-$(nproc)}
mkdir -p "$OUT" "$B/logs"
[ -d "$B/pkgs" ] || { echo "Run scripts/fetch-sources.sh first." >&2; exit 1; }

# The libraries come before kodi-cb1; the kernel is independent of them.
pkgs=("$@")
[ ${#pkgs[@]} -gt 0 ] || pkgs=(linux-cachyos-cb1 cb1-libdisplay-info cb1-lightgbm cb1-libplacebo cb1-ffmpeg kodi-cb1)

podman build -t localhost/cb1-builder "$ROOT/builder"

for p in "${pkgs[@]}"; do
  log=$B/logs/$p.log
  echo "== $p (log: $log)"
  # The kernel tarball's .asc key is not in the container keyring; its b2sum is still checked.
  extra=
  [ "$p" = linux-cachyos-cb1 ] && extra=--skippgpcheck
  podman run --rm --userns=keep-id -e MAKEFLAGS="-j$JOBS" -e EXTRA="$extra" \
    -v "$B/pkgs/$p:/build:Z" -v "$OUT:/repo:Z" localhost/cb1-builder bash -c '
      set -e
      # Packages built earlier in this run satisfy the cb1-* dependencies.
      if ls /repo/cb1-*.pkg.tar.zst >/dev/null 2>&1; then
        sudo pacman -U --noconfirm --needed /repo/cb1-*.pkg.tar.zst
      fi
      PKGDEST=/repo makepkg -Cfs --noconfirm $EXTRA' > "$log" 2>&1 \
    || { echo "FAILED: $p. Read the end of $log." >&2; exit 1; }
  echo "   ok"
done

(cd "$OUT" && sha256sum *.pkg.tar.zst > SHA256SUMS)
echo "Done. Packages and SHA256SUMS are in $OUT"
