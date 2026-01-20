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

set(ENV{C_INCLUDE_PATH} "/")
set(ENV{MAKEINFO} "${CURRENT_INSTALLED_DIR}/tools/texinfo/bin/makeinfo")

vcpkg_configure_make(
    #AUTOCONFIG # prevent fail on 'configure.ac:35: error: Please use exactly Autoconf 2.69 instead of 2.71. c'
    SOURCE_PATH ${SOURCE_PATH}
    OPTIONS --disable-nls --disable-werror --disable-docs --enable-new-dtags --enable-default-hash-style=gnu
    #--target=$ENV{LFS_TGT}
)

vcpkg_install_make()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")
file(INSTALL ${SOURCE_PATH}/COPYING DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)
