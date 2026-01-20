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

set(ENV{C_INCLUDE_PATH} "/")
set(ENV{MAKEINFO} "${CURRENT_INSTALLED_DIR}/tools/texinfo/bin/makeinfo")

vcpkg_configure_make(
    #AUTOCONFIG
    SOURCE_PATH ${SOURCE_PATH}
    OPTIONS 
    #--target=$LFS_TGT         
    #--prefix=$LFS/tools       
    --with-glibc-version=2.42
    --with-sysroot=$LFS
    --with-newlib
    --without-headers
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

vcpkg_install_make()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")
file(INSTALL ${SOURCE_PATH}/COPYING DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)
