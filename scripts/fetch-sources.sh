#!/bin/bash
# Fetch the pinned upstream inputs and assemble one makepkg directory per package in build/pkgs/.
# Patches come from CroqueMr/libreelec-x86-dv (see sources.map); this repo adds only packaging
# and three kernel patches.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
. "$ROOT/pins.env"
B=$ROOT/build
FORK=$B/libreelec-x86-dv
mkdir -p "$B/pkgs"

echo "== Fork: $FORK_URL @ ${FORK_COMMIT:0:10}"
[ -d "$FORK/.git" ] || git clone --filter=blob:none --no-checkout "$FORK_URL" "$FORK"
git -C "$FORK" cat-file -e "$FORK_COMMIT^{commit}" 2>/dev/null || git -C "$FORK" fetch origin
git -C "$FORK" checkout --quiet --detach "$FORK_COMMIT"
# The fork's own tools verify CB1 and copy its matched sources and patches into place.
(cd "$FORK" && python3 CB1/tools/verify.py && python3 scripts/cb1-stage.py)

echo "== Packaging"
for d in "$ROOT"/packaging/*/; do
  p=$(basename "$d")
  rm -rf "$B/pkgs/$p"
  mkdir -p "$B/pkgs/$p"
  cp -a "$d". "$B/pkgs/$p/"
done

echo "== Kernel PKGBUILD: linux-cachyos @ ${LC_COMMIT:0:10}"
K=$B/pkgs/linux-cachyos-cb1
for f in PKGBUILD config; do
  curl -fsSL -o "$K/$f" "https://raw.githubusercontent.com/CachyOS/linux-cachyos/$LC_COMMIT/linux-cachyos/$f"
done
patch -d "$K" -p1 --no-backup-if-mismatch < "$K/PKGBUILD.patch"
rm "$K/PKGBUILD.patch"

echo "== Patches and CB1 media (sources.map)"
n=0
while read -r dest origin; do
  case $dest in ''|'#'*) continue ;; esac
  case $origin in
    fork:*)  src=$FORK/${origin#fork:} ;;
    local:*) src=$ROOT/${origin#local:} ;;
    *) echo "Bad origin: $origin" >&2; exit 1 ;;
  esac
  [ -f "$src" ] || { echo "Missing: $src" >&2; exit 1; }
  cp "$src" "$B/pkgs/$dest"
  n=$((n + 1))
done < "$ROOT/sources.map"
echo "Copied $n files."

echo "== CB1 tree for Kodi"
rev=$(grep -oP '^_cb1rev=\K[0-9a-f]+' "$B/pkgs/kodi-cb1/PKGBUILD")
[ "${FORK_COMMIT:0:${#rev}}" = "$rev" ] || { echo "kodi-cb1 _cb1rev=$rev does not match FORK_COMMIT" >&2; exit 1; }
tar -C "$FORK/packages/mediacenter/kodi" --sort=name --mtime=@0 --owner=0 --group=0 --numeric-owner \
  -czf "$B/pkgs/kodi-cb1/cb1-$rev.tar.gz" cb1 cb1-model

echo "Done. Next: scripts/build-all.sh"
