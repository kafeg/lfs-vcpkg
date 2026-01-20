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
# LFS preflight checks (early chapters)
# -----------------------------
source $REPO_ROOT/preflight.sh

# Basic sanity checks (fail fast)
if [ ! -d "$LFS" ]; then
  echo "ERROR: LFS mount dir does not exist: $LFS"
  echo "Create/mount it first (e.g. /mnt/lfs)."
  exit 2
fi

mkdir -p "$LFS/sources" "$LFS/tools"

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

# Helper
vcpkg_install_stage() {
  local triplet="$1"
  shift
  echo
  echo "=== vcpkg install (triplet=$triplet) : $* ==="
  ./vcpkg --overlay-ports="$VCPKG_LFS_OVERLAY_PORTS" --overlay-triplets="$VCPKG_LFS_OVERLAY_TRIPLETS" --triplet="$triplet" install "$@"
}

# -----------------------------
# Stage: PASS 1 (Chapter 5)
# -----------------------------
export VCPKG_DEFAULT_TRIPLET="$PASS1_TRIPLET"

#vcpkg_install_stage "$PASS1_TRIPLET" texinfo
vcpkg_install_stage "$PASS1_TRIPLET" binutils-pass1
#vcpkg_install_stage "$PASS1_TRIPLET" gcc-pass1

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
