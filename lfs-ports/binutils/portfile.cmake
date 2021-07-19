vcpkg_fail_port_install(ON_TARGET "OSX" "Windows" "UWP")

set(TARGET_VERSION 2.36.1)
vcpkg_download_distfile(ARCHIVE
    URLS "http://ftp.gnu.org/gnu/binutils/binutils-${TARGET_VERSION}.tar.xz"
    FILENAME "binutils-${TARGET_VERSION}.tar.xz"
    SHA512 cc24590bcead10b90763386b6f96bb027d7594c659c2d95174a6352e8b98465a50ec3e4088d0da038428abe059bbc4ae5f37b269f31a40fc048072c8a234f4e9
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
    OPTIONS --disable-nls --disable-werror --disable-docs
)

vcpkg_install_make()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")
file(INSTALL ${SOURCE_PATH}/COPYING DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)
