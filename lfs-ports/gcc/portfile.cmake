vcpkg_download_distfile(ARCHIVE
    URLS "http://ftp.gnu.org/gnu/gcc/gcc-${VERSION}/gcc-${VERSION}.tar.xz"
    FILENAME "gcc-${VERSION}.tar.xz"
    SHA512 932bdef0cda94bacedf452ab17f103c0cb511ff2cec55e9112fc0328cbf1d803b42595728ea7b200e0a057c03e85626f937012e49a7515bc5dd256b2bf4bc396
)

vcpkg_extract_source_archive_ex(
    OUT_SOURCE_PATH SOURCE_PATH
    ARCHIVE ${ARCHIVE}
    REF ${VERSION}
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
