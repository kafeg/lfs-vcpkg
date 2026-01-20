#!/bin/bash

# Basic Configuration
export REPO_ROOT=`pwd`
export VCPKG_ROOT=$REPO_ROOT/vcpkg
export VCPKG_TAG="2025.12.12"
export VCPKG_DISABLE_METRICS=true
export VCPKG_LFS_OVERLAY_PORTS=$REPO_ROOT/lfs-ports
export VCPKG_FORCE_SYSTEM_BINARIES=1

# Check the architecture of the host system, select HOST triplet
ARCH=$(uname -m)
if [ "$ARCH" == "aarch64" ]; then
    VCPKG_TRIPLET="arm64-linux-release"
else
    VCPKG_TRIPLET="x64-linux-release"
fi
export VCPKG_DEFAULT_TRIPLET="$VCPKG_TRIPLET"
export VCPKG_DEFAULT_HOST_TRIPLET="$VCPKG_TRIPLET"

# Output the selected triplet (optional)
echo "VCPKG_TRIPLET is set to $VCPKG_TRIPLET"

# LFS Configuration
export LC_ALL=POSIX
export LFS_TGT=$(uname -m)-lfs-linux-gnu
export LFS_MNT=/mnt/lfs

# Get vcpkg
if [ ! -d "$VCPKG_ROOT" ]
then
  echo "Clonning vcpkg"
  git clone https://github.com/microsoft/vcpkg.git $VCPKG_ROOT
fi

cd $VCPKG_ROOT
git checkout $VCPKG_TAG

if [ ! -f "$VCPKG_ROOT/vcpkg" ]
then
  ./bootstrap-vcpkg.sh -disableMetrics
fi

# Cleanup if needed
CLEAR=false
if [[ " $* " == *" -c "* ]]; then
  CLEAR=true
fi

if $CLEAR; then
  echo "Cleanup..."
  rm -rf $VCPKG_ROOT/installed
  rm -rf $VCPKG_ROOT/buildtrees
  rm -rf $VCPKG_ROOT/packages
fi

# Build cross-compiler toolchain
./vcpkg --overlay-ports=$VCPKG_LFS_OVERLAY_PORTS --triplet=$VCPKG_TRIPLET install binutils-pass1 # https://www.linuxfromscratch.org/lfs/view/12.4-systemd/chapter05/binutils-pass1.html
./vcpkg --overlay-ports=$VCPKG_LFS_OVERLAY_PORTS --triplet=$VCPKG_TRIPLET install gcc-pass1 # https://www.linuxfromscratch.org/lfs/view/12.4-systemd/chapter05/gcc-pass1.html

#./vcpkg --overlay-ports=$VCPKG_LFS_OVERLAY_PORTS --triplet=$VCPKG_TRIPLET --no-dry-run upgrade

cd $REPO_ROOT
exit 0
