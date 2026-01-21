#!/bin/bash
set -euo pipefail

# -----------------------------
# Repo / vcpkg basics
# -----------------------------
export REPO_ROOT="$(pwd)"
export VCPKG_ROOT="$REPO_ROOT/vcpkg"
export VCPKG_TAG="2025.12.12"
export VCPKG_DISABLE_METRICS=true
export VCPKG_FORCE_SYSTEM_BINARIES=1
export VCPKG_LFS_OVERLAY_PORTS="$REPO_ROOT/lfs-ports"
export VCPKG_LFS_OVERLAY_TRIPLETS="$REPO_ROOT/lfs-triplets"

# -----------------------------
# LFS Configuration
# -----------------------------
export LC_ALL=POSIX
export LFS="/mnt/lfs"
export LFS_TGT="$(uname -m)-lfs-linux-gnu"

# -----------------------------
# Triplets (stage-specific)
# -----------------------------
PASS1_TRIPLET="x64-lfs-pass1"
TEMP_TRIPLET="x64-lfs-temp"
HOST_TRIPLET="x64-linux-release"

# IMPORTANT:
# - do NOT set VCPKG_DEFAULT_TRIPLET to host triplet
# - default should be whichever stage we are currently building
export VCPKG_DEFAULT_HOST_TRIPLET="$HOST_TRIPLET"

echo "HOST_TRIPLET = $HOST_TRIPLET"
echo "PASS1_TRIPLET = $PASS1_TRIPLET"
echo "TEMP_TRIPLET  = $TEMP_TRIPLET"
echo "LFS = $LFS"
echo "LFS_TGT = $LFS_TGT"

# -----------------------------
# Get vcpkg
# -----------------------------
if [ ! -d "$VCPKG_ROOT" ]; then
  echo "Cloning vcpkg..."
  git clone https://github.com/microsoft/vcpkg.git "$VCPKG_ROOT"
fi

cd "$VCPKG_ROOT"
git checkout "$VCPKG_TAG"

if [ ! -f "$VCPKG_ROOT/vcpkg" ]; then
  ./bootstrap-vcpkg.sh -disableMetrics
fi

# -----------------------------
# Cleanup if needed (-c)
# -----------------------------
CLEAR=false
if [[ " $* " == *" -c "* ]]; then
  CLEAR=true
fi

if $CLEAR; then
  echo "Cleanup vcpkg build dirs..."
  rm -rf "$VCPKG_ROOT/installed" \
         "$VCPKG_ROOT/buildtrees" \
         "$VCPKG_ROOT/packages"
fi

# -----------------------------
# Strict mode check
# -----------------------------
STRICT=false
if [[ " $* " == *" --strict "* ]] || [[ " $* " == *" -s "* ]]; then
  STRICT=true
fi

# -----------------------------
# Helpers
# -----------------------------
vcpkg_remove_stage() {
  local triplet="$1"
  shift
  echo
  echo "=== vcpkg remove (triplet=$triplet) : $* ==="
  ./vcpkg --overlay-ports="$VCPKG_LFS_OVERLAY_PORTS" --overlay-triplets="$VCPKG_LFS_OVERLAY_TRIPLETS" --triplet="$triplet" remove "$@"
}

vcpkg_install_stage() {
  local triplet="$1"
  shift
  echo
  echo "=== vcpkg install (triplet=$triplet) : $* ==="
  ./vcpkg --overlay-ports="$VCPKG_LFS_OVERLAY_PORTS" --overlay-triplets="$VCPKG_LFS_OVERLAY_TRIPLETS" --triplet="$triplet" install "$@"
}

# -----------------------------
# Preflight (as a vcpkg port)
# -----------------------------
vcpkg_remove_stage "$PASS1_TRIPLET" --binarysource=clear "lfs-preflight" # always recheck all pre-flight tests by reinstall this port
if $STRICT; then
  vcpkg_install_stage "$PASS1_TRIPLET" --binarysource=clear "lfs-preflight[strict]"
else
  vcpkg_install_stage "$PASS1_TRIPLET" --binarysource=clear "lfs-preflight"
fi

# -----------------------------
# Stage: PASS 1 (Chapter 5)
# -----------------------------
export VCPKG_DEFAULT_TRIPLET="$PASS1_TRIPLET"

#vcpkg_install_stage "$PASS1_TRIPLET" texinfo
vcpkg_install_stage "$PASS1_TRIPLET" binutils-pass1
vcpkg_install_stage "$PASS1_TRIPLET" gcc-pass1
vcpkg_install_stage "$PASS1_TRIPLET" linux-headers
vcpkg_install_stage "$PASS1_TRIPLET" glibc

# -----------------------------
# Stage: TEMP (Chapter 6) - later
# -----------------------------
# When you add temp ports (m4, ncurses, bash, coreutils, ...),
# switch default triplet and install them here:
#
# export VCPKG_DEFAULT_TRIPLET="$TEMP_TRIPLET"
# vcpkg_install_stage "$TEMP_TRIPLET" m4
# vcpkg_install_stage "$TEMP_TRIPLET" ncurses
# ...

cd "$REPO_ROOT"
echo "Done."
