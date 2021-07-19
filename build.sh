#!/bin/bash

# Configuration
REPO_ROOT=`pwd`
VCPKG_ROOT=$REPO_ROOT/vcpkg
VCPKG_TRIPLET=x64-linux
VCPKG_TAG="2021.05.12"
VCPKG_DISABLE_METRICS=true
VCPKG_LFS_OVERLAY_PORTS=$REPO_ROOT/lfs-ports

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

./vcpkg --overlay-ports=$VCPKG_LFS_OVERLAY_PORTS --triplet=$VCPKG_TRIPLET install binutils

./vcpkg --overlay-ports=$VCPKG_LFS_OVERLAY_PORTS --triplet=$VCPKG_TRIPLET --no-dry-run upgrade

cd $REPO_ROOT
exit 0
