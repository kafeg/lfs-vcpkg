set(VCPKG_POLICY_EMPTY_INCLUDE_FOLDER enabled)

vcpkg_download_distfile(ARCHIVE
    URLS "https://ftp.gnu.org/gnu/texinfo/texinfo-${VERSION}.tar.xz"
    FILENAME "texinfo-${VERSION}.tar.xz"
    SHA512 ceab03e8422d800b08c7b44e8263b0a1f35bb7758d83a81136df6f3304a14daecda98a12a282afb85406d2ca2f665b2295e10b6f4064156ea1285d80d5d355db
)

vcpkg_extract_source_archive_ex(
    OUT_SOURCE_PATH SOURCE_PATH
    ARCHIVE ${ARCHIVE}
    REF ${VERSION}
)

vcpkg_configure_make(
    #AUTOCONFIG
    SOURCE_PATH ${SOURCE_PATH}
)

vcpkg_install_make()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")
file(INSTALL ${SOURCE_PATH}/COPYING DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug")
