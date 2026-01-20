# Helper port: installs into $LFS/tools directly, not into vcpkg sandbox.
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

# Ensure LFS dirs exist (otherwise configure --prefix=$LFS/tools will fail later).
if(NOT DEFINED ENV{LFS})
    message(FATAL_ERROR "ENV{LFS} is not set. Export LFS=/mnt/lfs (or your path) before building.")
endif()
if(NOT DEFINED ENV{LFS_TGT})
    message(FATAL_ERROR "ENV{LFS_TGT} is not set. Export LFS_TGT=$(uname -m)-lfs-linux-gnu before building.")
endif()

file(MAKE_DIRECTORY "$ENV{LFS}/tools")
file(MAKE_DIRECTORY "$ENV{LFS}/tools/bin")

# Prevent some headers probing weirdness + ensure makeinfo is found
set(ENV{C_INCLUDE_PATH} "/")
set(ENV{MAKEINFO} "${CURRENT_INSTALLED_DIR}/tools/texinfo/bin/makeinfo")

vcpkg_configure_make(
    SOURCE_PATH ${SOURCE_PATH}
    OPTIONS
        --prefix=$ENV{LFS}/tools
        --with-sysroot=$ENV{LFS}
        --target=$ENV{LFS_TGT}
        --disable-nls
        --enable-gprofng=no
        --disable-werror
        --enable-new-dtags
        --enable-default-hash-style=gnu
)

# Build normally inside vcpkg buildtrees
vcpkg_build_make()

# IMPORTANT:
# Install directly into $LFS/tools (NO DESTDIR), otherwise vcpkg will redirect into ${CURRENT_PACKAGES_DIR}
set(_build_dir "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel")
vcpkg_execute_required_process(
    COMMAND ${MAKE} install
    WORKING_DIRECTORY "${_build_dir}"
    LOGNAME "install-${PORT}"
)

# The "package" part: keep only minimal metadata in vcpkg.
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug")
file(MAKE_DIRECTORY "${CURRENT_PACKAGES_DIR}/share/${PORT}")
file(INSTALL "${SOURCE_PATH}/COPYING"
     DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
     RENAME copyright)

# Optional marker so it's obvious this port is a helper
file(WRITE "${CURRENT_PACKAGES_DIR}/share/${PORT}/lfs-helper.txt"
"Installed into $ENV{LFS}/tools by helper port ${PORT}\n")
