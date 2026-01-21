# Helper port: installs into $LFS directly (LFS Chapter 5.6: Target Libstdc++).
set(VCPKG_POLICY_CMAKE_HELPER_PORT enabled)

vcpkg_download_distfile(ARCHIVE
    URLS "http://ftp.gnu.org/gnu/gcc/gcc-${VERSION}/gcc-${VERSION}.tar.xz"
    FILENAME "gcc-${VERSION}.tar.xz"
    SHA512 89047a2e07bd9da265b507b516ed3635adb17491c7f4f67cf090f0bd5b3fc7f2ee6e4cc4008beef7ca884b6b71dffe2bb652b21f01a702e17b468cca2d10b2de
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

# Ensure we use the just-built cross tools in $LFS/tools
set(ENV{PATH} "$ENV{LFS}/tools/bin:/usr/bin:/bin")

# Dedicated build dir (as in the book: mkdir build; cd build)
set(_build_dir "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel")
file(REMOVE_RECURSE "${_build_dir}")
file(MAKE_DIRECTORY "${_build_dir}")

message(STATUS "Configuring ${PORT} (libstdc++-v3)...")
vcpkg_execute_required_process(
    COMMAND /bin/bash -c
        "set -euo pipefail
         cd '${SOURCE_PATH}'
         mkdir -p build
         cd build

         BUILD_TRIPLET=\"$(../config.guess)\"

         ../libstdc++-v3/configure \
           --host='$ENV{LFS_TGT}' \
           --build=\"${BUILD_TRIPLET}\" \
           --prefix=/usr \
           --disable-multilib \
           --disable-nls \
           --disable-libstdcxx-pch \
           --with-gxx-include-dir=/tools/$ENV{LFS_TGT}/include/c++/${VERSION}"
    WORKING_DIRECTORY "${SOURCE_PATH}"
    LOGNAME "configure-${PORT}"
)

message(STATUS "Building ${PORT}...")
vcpkg_execute_required_process(
    COMMAND /bin/bash -c
        "set -euo pipefail
         cd '${SOURCE_PATH}/build'
         make"
    WORKING_DIRECTORY "${SOURCE_PATH}"
    LOGNAME "build-${PORT}"
)

message(STATUS "Installing ${PORT} into $ENV{LFS} (DESTDIR)...")
vcpkg_execute_required_process(
    COMMAND /bin/bash -c
        "set -euo pipefail
         cd '${SOURCE_PATH}/build'
         make DESTDIR='$ENV{LFS}' install"
    WORKING_DIRECTORY "${SOURCE_PATH}"
    LOGNAME "install-${PORT}"
)

# Remove .la files as LFS says they are harmful for cross-compilation
message(STATUS "Removing libtool .la archives (LFS recommendation)...")
vcpkg_execute_required_process(
    COMMAND /bin/bash -c
        "set -euo pipefail
         rm -vf '$ENV{LFS}/usr/lib/libstdc++.la' \
                '$ENV{LFS}/usr/lib/libstdc++exp.la' \
                '$ENV{LFS}/usr/lib/libstdc++fs.la' \
                '$ENV{LFS}/usr/lib/libsupc++.la' || true"
    WORKING_DIRECTORY "${SOURCE_PATH}"
    LOGNAME "cleanup-${PORT}"
)

# Minimal vcpkg payload (helper-port marker)
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug")
file(MAKE_DIRECTORY "${CURRENT_PACKAGES_DIR}/share/${PORT}")
file(WRITE "${CURRENT_PACKAGES_DIR}/share/${PORT}/vcpkg-port-config.cmake" "# helper port\n")
file(WRITE "${CURRENT_PACKAGES_DIR}/share/${PORT}/lfs-helper.txt"
"Installed target libstdc++ into $ENV{LFS}/usr (DESTDIR) and headers into $ENV{LFS}/tools/$ENV{LFS_TGT}/include/c++/${VERSION} by helper port ${PORT}\n"
)

if(EXISTS "${SOURCE_PATH}/COPYING")
    file(INSTALL "${SOURCE_PATH}/COPYING"
         DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
         RENAME copyright)
else()
    file(WRITE "${CURRENT_PACKAGES_DIR}/share/${PORT}/copyright"
"GCC licensing: see source tree.\n")
endif()
