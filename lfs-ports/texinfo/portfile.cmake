set(VCPKG_POLICY_EMPTY_INCLUDE_FOLDER enabled)

vcpkg_download_distfile(ARCHIVE
    URLS "https://ftp.gnu.org/gnu/texinfo/texinfo-${VERSION}.tar.xz"
    FILENAME "texinfo-${VERSION}.tar.xz"
    SHA512 8e67337ae12a552fc620c43725507a4978710ea6630e98b0f5e98eb3f79a90e191dde5225699aa6217c26f171d277461f76150f0459cd07b40c3234d2f3d89bf
)

vcpkg_extract_source_archive_ex(
    OUT_SOURCE_PATH SOURCE_PATH
    ARCHIVE ${ARCHIVE}
    REF ${VERSION}
)

vcpkg_configure_make(
    #AUTOCONFIG # prevent fail on 'configure.ac:35: error: Please use exactly Autoconf 2.69 instead of 2.71. c'
    SOURCE_PATH ${SOURCE_PATH}
)

vcpkg_install_make()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")
file(INSTALL ${SOURCE_PATH}/COPYING DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug")
