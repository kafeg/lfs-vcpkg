vcpkg_fail_port_install(ON_TARGET "OSX" "Windows" "UWP")

set(TARGET_VERSION 10.2.0)
vcpkg_download_distfile(ARCHIVE
    URLS "http://ftp.gnu.org/gnu/gcc/gcc-${TARGET_VERSION}/gcc-${TARGET_VERSION}.tar.xz"
    FILENAME "gcc-${TARGET_VERSION}.tar.xz"
    SHA512 42ae38928bd2e8183af445da34220964eb690b675b1892bbeb7cd5bb62be499011ec9a93397dba5e2fb681afadfc6f2767d03b9035b44ba9be807187ae6dc65e
)

vcpkg_extract_source_archive_ex(
    OUT_SOURCE_PATH SOURCE_PATH
    ARCHIVE ${ARCHIVE}
    REF ${TARGET_VERSION}
)

set(ENV{C_INCLUDE_PATH} "/")
set(ENV{MAKEINFO} "${CURRENT_INSTALLED_DIR}/tools/texinfo/bin/makeinfo")

vcpkg_configure_make(
    AUTOCONFIG
    SOURCE_PATH ${SOURCE_PATH}
    OPTIONS --disable-werror --disable-docs --with-glibc-version=2.11
           #--prefix=$$ENV{LFS_MNT}/tools --with-sysroot=$$ENV{LFS_MNT}
           --with-newlib --without-headers --enable-initfini-array
           --disable-nls --disable-shared --disable-multilib
           --disable-decimal-float --disable-threads --disable-libatomic
           --disable-libgomp --disable-libquadmath --disable-libssp
           --disable-libvtv --disable-libstdcxx --enable-languages=c,c++
)

vcpkg_install_make()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")
file(INSTALL ${SOURCE_PATH}/COPYING DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)
