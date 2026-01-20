# Helper port: installs into $LFS/tools directly (LFS Chapter 5 pass1).
set(VCPKG_POLICY_CMAKE_HELPER_PORT enabled)

vcpkg_download_distfile(ARCHIVE
    URLS "http://ftp.gnu.org/gnu/binutils/binutils-${VERSION}.tar.xz"
    FILENAME "binutils-${VERSION}.tar.xz"
    SHA512 c7b10a7466d9fd398d7a0b3f2a43318432668d714f2ec70069a31bdc93c86d28e0fe83792195727167743707fbae45337c0873a0786416db53bbf22860c16ce7
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

file(MAKE_DIRECTORY "$ENV{LFS}/tools")
file(MAKE_DIRECTORY "$ENV{LFS}/tools/bin")

# Ensure makeinfo is found (texinfo is a vcpkg dep)
set(ENV{MAKEINFO} "${CURRENT_INSTALLED_DIR}/tools/texinfo/bin/makeinfo")

# Dedicated build directory (as in the book)
set(_build_dir "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel")
file(REMOVE_RECURSE "${_build_dir}")
file(MAKE_DIRECTORY "${_build_dir}")

# Run configure manually (DO NOT use vcpkg_configure_make: it injects --prefix=${CURRENT_INSTALLED_DIR})
vcpkg_execute_required_process(
    COMMAND /bin/bash -c
            "cd '${_build_dir}' && '${SOURCE_PATH}/configure' \
              --prefix='$ENV{LFS}/tools' \
              --with-sysroot='$ENV{LFS}' \
              --target='$ENV{LFS_TGT}' \
              --disable-nls \
              --enable-gprofng=no \
              --disable-werror \
              --enable-new-dtags \
              --enable-default-hash-style=gnu"
    WORKING_DIRECTORY "${_build_dir}"
    LOGNAME "configure-${PORT}"
)

# Build & install (no DESTDIR!)
vcpkg_execute_required_process(
    COMMAND make
    WORKING_DIRECTORY "${_build_dir}"
    LOGNAME "build-${PORT}"
)

vcpkg_execute_required_process(
    COMMAND make install
    WORKING_DIRECTORY "${_build_dir}"
    LOGNAME "install-${PORT}"
)

# Minimal vcpkg payload
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug")
file(MAKE_DIRECTORY "${CURRENT_PACKAGES_DIR}/share/${PORT}")

file(INSTALL "${SOURCE_PATH}/COPYING"
     DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
     RENAME copyright)

# Required marker for helper ports to silence vcpkg warning
file(WRITE "${CURRENT_PACKAGES_DIR}/share/${PORT}/vcpkg-port-config.cmake" "# helper port\n")

file(WRITE "${CURRENT_PACKAGES_DIR}/share/${PORT}/lfs-helper.txt"
"Installed into $ENV{LFS}/tools by helper port ${PORT}\n")
