# Helper port: installs into $LFS/tools directly.
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
    message(FATAL_ERROR "ENV{LFS} is not set. Export LFS=/mnt/lfs (or your path) before building.")
endif()
if(NOT DEFINED ENV{LFS_TGT})
    message(FATAL_ERROR "ENV{LFS_TGT} is not set. Export LFS_TGT=$(uname -m)-lfs-linux-gnu before building.")
endif()

file(MAKE_DIRECTORY "$ENV{LFS}/tools")
file(MAKE_DIRECTORY "$ENV{LFS}/tools/bin")

# Ensure makeinfo is available (you already do this) :contentReference[oaicite:2]{index=2}
set(ENV{C_INCLUDE_PATH} "/")
set(ENV{MAKEINFO} "${CURRENT_INSTALLED_DIR}/tools/texinfo/bin/makeinfo")

# NOTE:
# In your current portfile, --target and --prefix are commented out. That makes it NOT LFS pass1. :contentReference[oaicite:3]{index=3}
# Re-enable them. Also point GCC to vcpkg-built gmp/mpfr/mpc explicitly.
vcpkg_configure_make(
    SOURCE_PATH ${SOURCE_PATH}
    OPTIONS
        --target=$ENV{LFS_TGT}
        --prefix=$ENV{LFS}/tools

        --with-glibc-version=2.42
        --with-sysroot=$ENV{LFS}
        --with-newlib
        --without-headers

        --with-gmp=${CURRENT_INSTALLED_DIR}
        --with-mpfr=${CURRENT_INSTALLED_DIR}
        --with-mpc=${CURRENT_INSTALLED_DIR}

        --enable-default-pie
        --enable-default-ssp

        --disable-nls
        --disable-shared
        --disable-multilib
        --disable-threads

        --disable-libatomic
        --disable-libgomp
        --disable-libquadmath
        --disable-libssp
        --disable-libvtv
        --disable-libstdcxx

        --enable-languages=c,c++
)

vcpkg_build_make()

# Install directly into $LFS/tools (NO DESTDIR)
set(_build_dir "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel")
vcpkg_execute_required_process(
    COMMAND ${MAKE} install
    WORKING_DIRECTORY "${_build_dir}"
    LOGNAME "install-${PORT}"
)

# Minimal vcpkg package payload (metadata only)
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug")
file(MAKE_DIRECTORY "${CURRENT_PACKAGES_DIR}/share/${PORT}")
file(INSTALL "${SOURCE_PATH}/COPYING"
     DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
     RENAME copyright)

file(WRITE "${CURRENT_PACKAGES_DIR}/share/${PORT}/lfs-helper.txt"
"Installed into $ENV{LFS}/tools by helper port ${PORT}\n")
