# x64-lfs-temp.cmake
# For Chapter 6: cross-compiling temporary tools, using the toolchain in $LFS/tools.
# Goal: force usage of $LFS_TGT-* tools from $LFS/tools/bin and keep env clean.

set(VCPKG_TARGET_ARCHITECTURE x64)
set(VCPKG_CMAKE_SYSTEM_NAME Linux)
set(VCPKG_BUILD_TYPE release)

set(VCPKG_LIBRARY_LINKAGE static)
set(VCPKG_CRT_LINKAGE dynamic)

# ---------------------------
# Derive/normalize LFS env
# ---------------------------

# If LFS is still not set, default to /mnt/lfs (LFS book default).
if(NOT DEFINED ENV{LFS})
    message( FATAL_ERROR "ERROR: LFS mount dir env var must be set" )
endif()

if(NOT DEFINED ENV{LFS_TGT})
    execute_process(
        COMMAND uname -m
        OUTPUT_VARIABLE _lfs_arch
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    set(ENV{LFS_TGT} "${_lfs_arch}-lfs-linux-gnu")
endif()

set(ENV{LC_ALL} "POSIX")

# ---------------------------
# Clean host-polluting env
# ---------------------------

foreach(v
    CFLAGS CXXFLAGS CPPFLAGS LDFLAGS
    CMAKE_PREFIX_PATH CMAKE_LIBRARY_PATH CMAKE_INCLUDE_PATH
    LD_LIBRARY_PATH LIBRARY_PATH CPATH C_INCLUDE_PATH CPLUS_INCLUDE_PATH
    PKG_CONFIG_PATH PKG_CONFIG_LIBDIR PKG_CONFIG_SYSROOT_DIR
)
    if(DEFINED ENV{${v}})
        unset(ENV{${v}})
    endif()
endforeach()

# ---------------------------
# Force toolchain from $LFS/tools
# ---------------------------

# Put LFS cross-tools first in PATH (critical for Chapter 6 cross-compile discipline). :contentReference[oaicite:6]{index=6}
set(ENV{PATH} "$ENV{LFS}/tools/bin:/usr/bin:/bin")

# Prefer the cross tools explicitly. Many Autoconf projects respect these vars.
set(ENV{CC}      "$ENV{LFS_TGT}-gcc")
set(ENV{CXX}     "$ENV{LFS_TGT}-g++")
set(ENV{AR}      "$ENV{LFS_TGT}-ar")
set(ENV{AS}      "$ENV{LFS_TGT}-as")
set(ENV{LD}      "$ENV{LFS_TGT}-ld")
set(ENV{NM}      "$ENV{LFS_TGT}-nm")
set(ENV{RANLIB}  "$ENV{LFS_TGT}-ranlib")
set(ENV{READELF} "$ENV{LFS_TGT}-readelf")
set(ENV{STRIP}   "$ENV{LFS_TGT}-strip")
set(ENV{OBJCOPY} "$ENV{LFS_TGT}-objcopy")
set(ENV{OBJDUMP} "$ENV{LFS_TGT}-objdump")

# Make sure pkg-config doesn't “подсасывать” хостовые .pc
# (для temporary tools это часто принципиально; sysroot/pc-path обычно задаются в портах при необходимости)
set(ENV{PKG_CONFIG} "pkg-config")
set(ENV{PKG_CONFIG_PATH} "")
set(ENV{PKG_CONFIG_LIBDIR} "")
set(ENV{PKG_CONFIG_SYSROOT_DIR} "$ENV{LFS}")

set(ENV{CCACHE_DISABLE} "1")
set(ENV{TZ} "UTC")

set(VCPKG_C_FLAGS "")
set(VCPKG_CXX_FLAGS "")
set(VCPKG_LINKER_FLAGS "")
