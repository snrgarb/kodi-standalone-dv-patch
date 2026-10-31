#!/bin/bash
# Check the built packages in out/ (runs in the builder container, which has bsdtar/zstd/readelf).
# Usage: scripts/verify.sh [dir]   (default: out/)
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
DIR=$(cd "${1:-$ROOT/out}" && pwd)
podman run --rm --userns=keep-id -v "$DIR:/repo:ro,Z" localhost/cb1-builder bash -c '
  cd /repo; fail=0
  check() { if [ "$2" = ok ]; then echo "PASS  $1"; else echo "FAIL  $1 ($2)"; fail=1; fi; }
  n=$(ls *.pkg.tar.zst | wc -l); [ "$n" = 7 ] && check "7 packages" ok || check "7 packages" "found $n"
  sha256sum -c --quiet SHA256SUMS && check "SHA256SUMS" ok || check "SHA256SUMS" mismatch
  k=$(ls linux-cachyos-cb1-[0-9]*.pkg.tar.zst)
  ko=$(bsdtar -xOf "$k" --include="*/amdgpu.ko.zst" | zstd -dc | strings)
  c=$(grep -c DVBRIDGE <<<"$ko" || true); [ "$c" -gt 0 ] && check "amdgpu.ko has DVBridge" ok || check "amdgpu.ko has DVBridge" "0 strings"
  v=$(grep -m1 -o "vermagic=[^ ]*" <<<"$ko"); [[ $v == *-cachyos-cb1 ]] && check "kernel $v" ok || check "vermagic" "$v"
  t=$(mktemp -d); bsdtar -xf kodi-cb1-*.pkg.tar.zst -C "$t" opt/cb1/lib/kodi/kodi.bin
  c=$(strings "$t/opt/cb1/lib/kodi/kodi.bin" | grep -c DVBRIDGE_DV_STANDARD_LAB || true)
  [ "$c" -gt 0 ] && check "kodi.bin has the DV connector property" ok || check "kodi.bin DV property" "0 strings"
  readelf -d "$t/opt/cb1/lib/kodi/kodi.bin" | grep -q "R.*PATH.*/opt/cb1/lib" && check "kodi.bin runpath /opt/cb1/lib" ok || check "kodi.bin runpath" missing
  [ $fail = 0 ] && echo "All checks passed." || { echo "Some checks failed."; exit 1; }'
