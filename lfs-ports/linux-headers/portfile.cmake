# Helper port: installs into $LFS directly (LFS Chapter 5: Linux API Headers).
set(VCPKG_POLICY_CMAKE_HELPER_PORT enabled)

vcpkg_download_distfile(ARCHIVE
    URLS "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${VERSION}.tar.xz"
    FILENAME "linux-${VERSION}.tar.xz"
    SHA512 5b52251283ecf2d55d2700ed831f9f5484f825ca439704d6bb80cc8283833e84e6d5d2c2814316f2c955ebd985ee6d8e3c5ae16db406e1e2c669c730405c4df9
)

vcpkg_extract_source_archive_ex(
    OUT_SOURCE_PATH SOURCE_PATH
    ARCHIVE ${ARCHIVE}
    REF ${VERSION}
)

if(NOT DEFINED ENV{LFS})
    message(FATAL_ERROR "ENV{LFS} is not set. Export LFS=/mnt/lfs before building.")
endif()

if(NOT DEFINED ENV{LFS_TGT})
    message(FATAL_ERROR "ENV{LFS_TGT} is not set. Export LFS_TGT=$(uname -m)-lfs-linux-gnu before building.")
endif()

file(MAKE_DIRECTORY "$ENV{LFS}/usr")

message(STATUS "Installing Linux API headers into $ENV{LFS}/usr ...")

vcpkg_execute_required_process(
    COMMAND /bin/bash -c
        "set -euo pipefail
         cd '${SOURCE_PATH}'
         make mrproper
         make headers
         make headers_install INSTALL_HDR_PATH='$ENV{LFS}/usr'"
    WORKING_DIRECTORY "${SOURCE_PATH}"
    LOGNAME "install-${PORT}"
)

# Minimal vcpkg payload (helper-port marker)
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug")
file(MAKE_DIRECTORY "${CURRENT_PACKAGES_DIR}/share/${PORT}")

file(WRITE "${CURRENT_PACKAGES_DIR}/share/${PORT}/vcpkg-port-config.cmake" "# helper port\n")
file(WRITE "${CURRENT_PACKAGES_DIR}/share/${PORT}/lfs-helper.txt"
"Installed Linux API headers into $ENV{LFS}/usr/include by helper port ${PORT}\n"
)

if(EXISTS "${SOURCE_PATH}/COPYING")
    file(INSTALL "${SOURCE_PATH}/COPYING"
         DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
         RENAME copyright)
else()
    file(WRITE "${CURRENT_PACKAGES_DIR}/share/${PORT}/copyright"
"Linux kernel sources contain various licenses; see source tree.\n"
)
endif()
