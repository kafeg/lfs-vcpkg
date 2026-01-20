set(VCPKG_POLICY_CMAKE_HELPER_PORT enabled)

# =============================================================================
# Config
# =============================================================================
set(_strict OFF)
if("strict" IN_LIST FEATURES)
    set(_strict ON)
endif()

set(_howto [==[
How to prepare LFS disk (manual steps):

1) Create a partition (fdisk/parted).
2) Create filesystem:
   sudo mkfs.ext4 /dev/<partition>
3) Mount:
   sudo mkdir -p /mnt/lfs
   sudo mount /dev/<partition> /mnt/lfs
4) Make writable for your user:
   sudo chown -R $USER:$USER /mnt/lfs

Verify:
   mountpoint /mnt/lfs
   df -h /mnt/lfs
]==])

# =============================================================================
# Logging helpers
# =============================================================================
function(_lfs_status msg)
    message(STATUS "[lfs-preflight] ${msg}")
endfunction()

function(_lfs_warn msg)
    message(WARNING "[lfs-preflight] ${msg}")
endfunction()

function(_lfs_fail msg)
    if(_strict)
        message(FATAL_ERROR
            "[lfs-preflight] ${msg}\n\n${_howto}"
        )
    else()
        message(WARNING "[lfs-preflight] ${msg} (soft mode)")
    endif()
endfunction()

# Executes a command. In strict mode: fail on non-zero exit.
# In soft mode: warn on non-zero exit.
function(_lfs_run label)
    # remaining args are the command
    set(options)
    set(oneValueArgs)
    set(multiValueArgs COMMAND)
    cmake_parse_arguments(R "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(NOT R_COMMAND)
        message(FATAL_ERROR "[lfs-preflight] _lfs_run(${label}) missing COMMAND")
    endif()

    execute_process(
        COMMAND ${R_COMMAND}
        RESULT_VARIABLE _rc
        OUTPUT_VARIABLE _out
        ERROR_VARIABLE  _err
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_STRIP_TRAILING_WHITESPACE
    )

    if(_rc EQUAL 0)
        if(NOT _out STREQUAL "")
            _lfs_status("${label}: ${_out}")
        else()
            _lfs_status("${label}: OK")
        endif()
    else()
        # Keep error concise, but useful
        set(_msg "${label} failed (exit=${_rc})")
        if(NOT _err STREQUAL "")
            set(_msg "${_msg}\n${_err}")
        endif()
        _lfs_fail("${_msg}")
    endif()

    # export outputs to parent if caller wants them (optional pattern)
    set(LFS_RUN_RC  "${_rc}"  PARENT_SCOPE)
    set(LFS_RUN_OUT "${_out}" PARENT_SCOPE)
    set(LFS_RUN_ERR "${_err}" PARENT_SCOPE)
endfunction()

# =============================================================================
# Read env
# =============================================================================
set(LFS "$ENV{LFS}")
if(LFS STREQUAL "")
    _lfs_fail("LFS env var is not set (expected e.g. /mnt/lfs)")
else()
    _lfs_status("LFS = ${LFS}")
endif()

if(NOT LFS MATCHES "^/")
    _lfs_fail("LFS must be an absolute path, got: ${LFS}")
endif()

if(LFS STREQUAL "/")
    _lfs_fail("Refusing to use LFS=/")
endif()

if(NOT IS_DIRECTORY "${LFS}")
    _lfs_fail("LFS directory does not exist: ${LFS}")
endif()

# =============================================================================
# Check: locale UTF-8
# =============================================================================
message(STATUS "[lfs-preflight] Checking host locale...")
find_program(_locale_exe locale)
if(_locale_exe)
    execute_process(
        COMMAND "${_locale_exe}" charmap
        RESULT_VARIABLE _lc_rc
        OUTPUT_VARIABLE _charmap
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET
    )
    if(_lc_rc EQUAL 0)
        if(NOT _charmap STREQUAL "UTF-8")
            _lfs_fail("Host locale charmap is '${_charmap}', expected UTF-8.
Fix: export LANG=C.UTF-8 and LC_ALL=C.UTF-8 before running build.sh.")
        else()
            _lfs_status("Locale: UTF-8")
        endif()
    else()
        _lfs_warn("Could not run 'locale charmap'; skipping locale check")
    endif()
else()
    _lfs_warn("locale(1) not found; skipping locale check")
endif()

# =============================================================================
# Check: writable (pure CMake technique via cmake -P)
# =============================================================================
message(STATUS "[lfs-preflight] Checking LFS writability...")
set(_probe_src "${CURRENT_BUILDTREES_DIR}/_probe.txt")
file(WRITE "${_probe_src}" "probe\n")

set(_probe_dst "${LFS}/.lfs_write_test")
set(_probe_script "${CURRENT_BUILDTREES_DIR}/probe_write.cmake")
file(WRITE "${_probe_script}" "
file(COPY_FILE \"${_probe_src}\" \"${_probe_dst}\")
file(REMOVE \"${_probe_dst}\")
")

execute_process(
    COMMAND "${CMAKE_COMMAND}" -P "${_probe_script}"
    RESULT_VARIABLE _probe_rc
    OUTPUT_VARIABLE _probe_out
    ERROR_VARIABLE  _probe_err
)
if(NOT _probe_rc EQUAL 0)
    _lfs_fail("LFS is not writable: ${LFS}\n${_probe_err}")
else()
    _lfs_status("Writable: OK")
endif()

# =============================================================================
# Check: mountpoint (strict recommended)
# =============================================================================
message(STATUS "[lfs-preflight] Checking LFS mountpoint...")
find_program(_mountpoint_exe mountpoint)
if(_mountpoint_exe)
    if(_strict)
        # strict: must be a mountpoint
        _lfs_run("Mountpoint" COMMAND "${_mountpoint_exe}" -q "${LFS}")
    else()
        # soft: warn if not a mountpoint (don’t fail)
        execute_process(
            COMMAND "${_mountpoint_exe}" -q "${LFS}"
            RESULT_VARIABLE _mp_rc
        )
        if(NOT _mp_rc EQUAL 0)
            _lfs_warn("LFS is not a mountpoint: ${LFS}")
        else()
            _lfs_status("Mountpoint: OK")
        endif()
    endif()
else()
    _lfs_warn("mountpoint(1) not found; skipping mountpoint check")
endif()

# =============================================================================
# Info: disk space (never hard-fail, just show; you can make strict later)
# =============================================================================
message(STATUS "[lfs-preflight] Checking LFS disk space...")
find_program(_df_exe df)
if(_df_exe)
    execute_process(
        COMMAND "${_df_exe}" -h "${LFS}"
        RESULT_VARIABLE _df_rc
        OUTPUT_VARIABLE _df_out
        ERROR_VARIABLE  _df_err
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_STRIP_TRAILING_WHITESPACE
    )
    if(_df_rc EQUAL 0 AND NOT _df_out STREQUAL "")
        _lfs_status("Disk:\n${_df_out}")
    else()
        _lfs_warn("df(1) failed; skipping disk info")
    endif()
endif()

# =============================================================================
# Prepare directories required for current phase
# =============================================================================
message(STATUS "[lfs-preflight] Preparing LFS directories...")
file(MAKE_DIRECTORY "${LFS}/sources" "${LFS}/tools")
_lfs_status("Ensured dirs: ${LFS}/sources, ${LFS}/tools")

# Try to set recommended perms on sources: a+wt (best-effort)
find_program(_chmod_exe chmod)
if(_chmod_exe)
    execute_process(
        COMMAND "${_chmod_exe}" a+wt "${LFS}/sources"
        RESULT_VARIABLE _chmod_rc
        ERROR_VARIABLE _chmod_err
        ERROR_STRIP_TRAILING_WHITESPACE
    )
    if(NOT _chmod_rc EQUAL 0)
        _lfs_warn("Could not chmod a+wt ${LFS}/sources (continuing). ${_chmod_err}")
    else()
        _lfs_status("Perms: chmod a+wt ${LFS}/sources")
    endif()
else()
    _lfs_warn("chmod(1) not found; skipping perms on sources")
endif()

# =============================================================================
# Done
# =============================================================================
_lfs_status("Preflight OK (mode: $<IF:$<BOOL:${_strict}>,strict,soft>)")

# Minimal payload for vcpkg
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug")
file(MAKE_DIRECTORY "${CURRENT_PACKAGES_DIR}/share/${PORT}")
file(WRITE "${CURRENT_PACKAGES_DIR}/share/${PORT}/vcpkg-port-config.cmake" "# helper port\n")
file(WRITE "${CURRENT_PACKAGES_DIR}/share/${PORT}/lfs-preflight.txt"
"Mode: ${_strict}\nValidated: env LFS, path, dir exists, writable; mountpoint check if available.\n")
