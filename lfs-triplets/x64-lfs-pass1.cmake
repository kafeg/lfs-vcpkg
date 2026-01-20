# x64-lfs-pass1.cmake
# Host build (Ubuntu) that produces LFS pass1 toolchain pieces.
# Goal: keep environment deterministic and avoid host pollution.

set(VCPKG_TARGET_ARCHITECTURE x64)
set(VCPKG_CMAKE_SYSTEM_NAME Linux)

# LFS passes don't want vcpkg's Debug/Release dual layout.
set(VCPKG_BUILD_TYPE release)

# Avoid accidental shared deps from host; LFS toolchain stage is typically static where possible.
set(VCPKG_LIBRARY_LINKAGE static)
set(VCPKG_CRT_LINKAGE dynamic)

# ---------------------------
# Derive/normalize LFS env
# ---------------------------

# If LFS is still not set, default to /mnt/lfs (LFS book default).
if(NOT DEFINED ENV{LFS})
    message( FATAL_ERROR "ERROR: LFS mount dir env var must be set" )
endif()

# Ensure LFS_TGT exists (some ports assume it even if commented now).
if(NOT DEFINED ENV{LFS_TGT})
    execute_process(
        COMMAND uname -m
        OUTPUT_VARIABLE _lfs_arch
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    set(ENV{LFS_TGT} "${_lfs_arch}-lfs-linux-gnu")
endif()

# Locale: keep deterministic behavior (POSIX) but preserve UTF-8 encoding for tools like cmake/libarchive.
# DO NOT set LC_ALL=POSIX: it forces non-UTF8 C locale and breaks extraction of some tarballs.
unset(ENV{LC_ALL})

set(ENV{LANG} "C.UTF-8")
set(ENV{LC_CTYPE} "C.UTF-8")     # encoding

# Determinism-friendly categories (POSIX == C)
set(ENV{LC_COLLATE}  "POSIX")
set(ENV{LC_NUMERIC}  "POSIX")
set(ENV{LC_TIME}     "POSIX")
set(ENV{LC_MONETARY} "POSIX")
set(ENV{LC_MESSAGES} "POSIX")

# ---------------------------
# Clean host-polluting env
# ---------------------------

# LFS explicitly warns about env overriding default optimization flags (GCC notes). :contentReference[oaicite:4]{index=4}
foreach(v
    CFLAGS CXXFLAGS CPPFLAGS LDFLAGS
    CMAKE_PREFIX_PATH CMAKE_LIBRARY_PATH CMAKE_INCLUDE_PATH
    LD_LIBRARY_PATH LIBRARY_PATH CPATH C_INCLUDE_PATH CPLUS_INCLUDE_PATH
    PKG_CONFIG_PATH PKG_CONFIG_LIBDIR PKG_CONFIG_SYSROOT_DIR
    CC CXX AR AS LD NM OBJDUMP OBJCOPY RANLIB READELF STRIP
)
    if(DEFINED ENV{${v}})
        unset(ENV{${v}})
    endif()
endforeach()

# Keep PATH sane; pass1 uses host tools, not yet $LFS/tools toolchain.
# (Ports themselves can still call $LFS_TGT-* once they exist.)
set(ENV{PATH} "/usr/bin:/bin")

# Make sure we don't accidentally use ccache etc.
set(ENV{CCACHE_DISABLE} "1")

# Make builds reproducible-ish
set(ENV{TZ} "UTC")

# vcpkg make helper sometimes injects extra flags; keep them empty by default.
set(VCPKG_C_FLAGS "")
set(VCPKG_CXX_FLAGS "")
set(VCPKG_LINKER_FLAGS "")

# Prefer system tools on host (you already export VCPKG_FORCE_SYSTEM_BINARIES=1 in build.sh). :contentReference[oaicite:5]{index=5}
