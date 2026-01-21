# Helper port: installs into $LFS directly (LFS Chapter 5: Glibc).
set(VCPKG_POLICY_CMAKE_HELPER_PORT enabled)

vcpkg_download_distfile(ARCHIVE
    URLS "https://ftp.gnu.org/gnu/glibc/glibc-${VERSION}.tar.xz"
    FILENAME "glibc-${VERSION}.tar.xz"
    SHA512 73a617db8e0f0958c0575f7a1c5a35b72b7e070b6cbdd02a9bb134995ca7ca0909f1e50d7362c53d2572d72f1879bb201a61d5275bac16136895d9a34ef0c068
)

# LFS patch: glibc-2.42-fhs-1.patch
vcpkg_download_distfile(FHS_PATCH
    URLS "https://www.linuxfromscratch.org/patches/lfs/12.4/glibc-${VERSION}-fhs-1.patch"
    FILENAME "glibc-${VERSION}-fhs-1.patch"
    SHA512 5b24f292cc87a133f45d743a95a8e706884e05ccf68024a0a88c0605c437928e111498feebca0259581da12d1ddb8e24726a67428e590240a1cbae48f7c2cc35
)

vcpkg_extract_source_archive_ex(
    OUT_SOURCE_PATH SOURCE_PATH
    ARCHIVE ${ARCHIVE}
    REF ${VERSION}
)

# --- Validate env ---
if(NOT DEFINED ENV{LFS})
    message(FATAL_ERROR "ENV{LFS} is not set. Export LFS=/mnt/lfs before building.")
endif()
if(NOT DEFINED ENV{LFS_TGT})
    message(FATAL_ERROR "ENV{LFS_TGT} is not set. Export LFS_TGT=$(uname -m)-lfs-linux-gnu before building.")
endif()

# Glibc build must find $LFS/tools/bin/$LFS_TGT-* tools
set(ENV{PATH} "$ENV{LFS}/tools/bin:/usr/bin:/bin")

# Apply FHS patch (per LFS)
message(STATUS "Patching ${PORT} with FHS patch...")
vcpkg_execute_required_process(
    COMMAND /bin/bash -c
        "set -euo pipefail
         cd '${SOURCE_PATH}'
         patch -Np1 -i '${FHS_PATCH}'"
    WORKING_DIRECTORY "${SOURCE_PATH}"
    LOGNAME "patch-${PORT}"
)

# Dedicated build dir
set(_build_dir "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel")
file(REMOVE_RECURSE "${_build_dir}")
file(MAKE_DIRECTORY "${_build_dir}")

# Ensure needed dirs exist in $LFS
file(MAKE_DIRECTORY "$ENV{LFS}/usr" "$ENV{LFS}/lib" "$ENV{LFS}/etc")

# Configure + build + install (DESTDIR=$LFS)
message(STATUS "Configuring ${PORT}...")
vcpkg_execute_required_process(
    COMMAND /bin/bash -c
        "set -euo pipefail
         cd '${_build_dir}'

         # LFS requires rootsbindir=/usr/sbin for ldconfig/sln
         echo 'rootsbindir=/usr/sbin' > configparms

         BUILD_TRIPLET=\"$('${SOURCE_PATH}/scripts/config.guess')\"

         '${SOURCE_PATH}/configure' \
           --prefix=/usr \
           --host='$ENV{LFS_TGT}' \
           --build=\"${BUILD_TRIPLET}\" \
           --disable-nscd \
           libc_cv_slibdir=/usr/lib \
           --enable-kernel=5.4"
    WORKING_DIRECTORY "${_build_dir}"
    LOGNAME "configure-${PORT}"
)

message(STATUS "Building ${PORT}...")
vcpkg_execute_required_process(
    COMMAND make
    WORKING_DIRECTORY "${_build_dir}"
    LOGNAME "build-${PORT}"
)

message(STATUS "Installing ${PORT} into $ENV{LFS} (DESTDIR)...")
vcpkg_execute_required_process(
    COMMAND /bin/bash -c
        "set -euo pipefail
         cd '${_build_dir}'
         make DESTDIR='$ENV{LFS}' install"
    WORKING_DIRECTORY "${_build_dir}"
    LOGNAME "install-${PORT}"
)

# --- Toolchain sanity check (LFS-style) ---
# Verify the dynamic linker and libc are coming from $LFS/usr/lib
message(STATUS "Sanity-checking toolchain after ${PORT} install...")
vcpkg_execute_required_process(
    COMMAND /bin/bash -c
        "set -euo pipefail
         cd '${_build_dir}'

         echo 'int main(){}' > dummy.c

         # Ensure we are using the cross tools from $LFS/tools
         export PATH='$ENV{LFS}/tools/bin:/usr/bin:/bin'

         '$ENV{LFS_TGT}-gcc' dummy.c

         '$ENV{LFS_TGT}-readelf' -l a.out > dummy.phdr
         '$ENV{LFS_TGT}-readelf' -d a.out > dummy.dyn

         # 1) Must have an interpreter (PT_INTERP)
         grep -q \"Requesting program interpreter\" dummy.phdr

         # 2) Interpreter path must be within the target FS namespace (no /mnt/lfs)
         grep -Eq \"/lib(64)?/ld-linux\" dummy.phdr
         ! grep -q \"$ENV{LFS}\" dummy.phdr

         # 3) Must depend on libc.so.6
         grep -q \"NEEDED.*libc.so.6\" dummy.dyn

         rm -f a.out dummy.c dummy.phdr dummy.dyn"
    WORKING_DIRECTORY "${_build_dir}"
    LOGNAME "check-${PORT}"
)

# Minimal vcpkg payload (helper-port marker)
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug")
file(MAKE_DIRECTORY "${CURRENT_PACKAGES_DIR}/share/${PORT}")
file(WRITE "${CURRENT_PACKAGES_DIR}/share/${PORT}/vcpkg-port-config.cmake" "# helper port\n")
file(WRITE "${CURRENT_PACKAGES_DIR}/share/${PORT}/lfs-helper.txt"
"Installed Glibc into $ENV{LFS}/usr via DESTDIR by helper port ${PORT}\n")

if(EXISTS "${SOURCE_PATH}/COPYING")
    file(INSTALL "${SOURCE_PATH}/COPYING"
         DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
         RENAME copyright)
else()
    file(WRITE "${CURRENT_PACKAGES_DIR}/share/${PORT}/copyright"
"Glibc licensing: see source tree.\n")
endif()
