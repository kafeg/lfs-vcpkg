set(VCPKG_POLICY_CMAKE_HELPER_PORT enabled)

if(NOT DEFINED ENV{LFS})
    message(FATAL_ERROR "ENV{LFS} is not set. Export LFS=/mnt/lfs before building.")
endif()
if(NOT DEFINED ENV{LFS_TGT})
    message(FATAL_ERROR "ENV{LFS_TGT} is not set. Export LFS_TGT=$(uname -m)-lfs-linux-gnu before building.")
endif()

# For checks we want cross tools first
set(ENV{PATH} "$ENV{LFS}/tools/bin:/usr/bin:/bin")

# -----------------------------------------------------------------------------
# Run a bash script with strict checks
# -----------------------------------------------------------------------------
vcpkg_execute_required_process(
    COMMAND /bin/bash -c
        "set -euo pipefail

         LFS='$ENV{LFS}'
         TGT='$ENV{LFS_TGT}'

         fail(){ echo \"[lfs-ch5-sanity] ERROR: $*\" >&2; exit 1; }
         ok(){ echo \"[lfs-ch5-sanity] OK: $*\"; }

         # --- 1) cross tools exist
         test -x \"$LFS/tools/bin/$TGT-gcc\"     || fail \"missing cross gcc: $LFS/tools/bin/$TGT-gcc\"
         test -x \"$LFS/tools/bin/$TGT-ld\"      || fail \"missing cross ld:  $LFS/tools/bin/$TGT-ld\"
         test -x \"$LFS/tools/bin/$TGT-as\"      || fail \"missing cross as:  $LFS/tools/bin/$TGT-as\"
         test -x \"$LFS/tools/bin/$TGT-readelf\" || fail \"missing cross readelf: $LFS/tools/bin/$TGT-readelf\"
         ok \"cross toolchain present in $LFS/tools/bin\"

         # --- 2) linux headers installed
         test -d \"$LFS/usr/include/linux\" || fail \"missing linux headers dir: $LFS/usr/include/linux\"
         test -d \"$LFS/usr/include/asm\"   || fail \"missing asm headers dir: $LFS/usr/include/asm\"
         ok \"linux API headers present in $LFS/usr/include\"

         # --- 3) glibc installed
         test -x \"$LFS/usr/lib/ld-linux-x86-64.so.2\" || fail \"missing dynamic linker: $LFS/usr/lib/ld-linux-x86-64.so.2\"
         test -r \"$LFS/usr/lib/libc.so.6\"            || fail \"missing libc: $LFS/usr/lib/libc.so.6\"
         ok \"glibc runtime present\"

         # --- 4) libstdc++ installed (accept /usr/lib or /usr/lib64)
         if test -r \"$LFS/usr/lib/libstdc++.so\" || test -r \"$LFS/usr/lib/libstdc++.so.6\"; then
           ok \"libstdc++ found in $LFS/usr/lib\"
         elif test -r \"$LFS/usr/lib64/libstdc++.so\" || test -r \"$LFS/usr/lib64/libstdc++.so.6\"; then
           ok \"libstdc++ found in $LFS/usr/lib64\"
         else
           fail \"missing libstdc++ in $LFS/usr/lib or $LFS/usr/lib64\"
         fi

         # --- 4b) libstdc++ headers under /tools/$TGT/include/c++/<ver>
         CXXINC_BASE=\"$LFS/tools/$TGT/include/c++\"
         test -d \"$CXXINC_BASE\" || fail \"missing c++ include base: $CXXINC_BASE\"

         GCCVER_DIR=\"\"
         for d in \"$CXXINC_BASE\"/*; do
           if test -d \"$d\"; then GCCVER_DIR=\"$d\"; break; fi
         done
         test -n \"$GCCVER_DIR\" || fail \"no versioned dir under $CXXINC_BASE (expected e.g. .../15.2.0)\"
         test -d \"$GCCVER_DIR/bits\" || fail \"missing bits/ under $GCCVER_DIR\"
         ok \"libstdc++ headers present in $GCCVER_DIR\"

         # --- 5) compile+readelf check
         work=\"$(mktemp -d)\"
         trap 'rm -rf \"$work\"' EXIT
         cd \"$work\"
         echo 'int main(){return 0;}' > dummy.c

         \"$TGT-gcc\" dummy.c -o a.out
         \"$TGT-readelf\" -l a.out > phdr.txt
         \"$TGT-readelf\" -d a.out > dyn.txt

         grep -q \"Requesting program interpreter\" phdr.txt || fail \"ELF has no PT_INTERP\"
         ! grep -q \"$LFS\" phdr.txt || fail \"PT_INTERP contains host path ($LFS)\"
         grep -Eq \"/lib(64)?/ld-linux\" phdr.txt || fail \"PT_INTERP doesn't look like /lib(64)?/ld-linux...\"
         grep -q \"NEEDED.*libc.so.6\" dyn.txt || fail \"binary doesn't NEEDED libc.so.6\"
         ok \"toolchain sanity compile+readelf checks passed\"

         # --- 6) warn on .la (do not fail)
         found_la=0
         for f in \"$LFS/usr/lib\"/*.la \"$LFS/usr/lib64\"/*.la; do
           if test -e \"$f\"; then
             echo \"[lfs-ch5-sanity] WARN: found libtool archive: $f\"
             found_la=1
           fi
         done
         if test \"$found_la\" -eq 0; then
           ok \"no .la files found in /usr/lib or /usr/lib64\"
         fi

         ok \"Chapter 5 sanity: READY for Chapter 6\""
    WORKING_DIRECTORY "${CURRENT_BUILDTREES_DIR}"
    LOGNAME "ch5-sanity"
)

# Minimal payload for vcpkg
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug")
file(MAKE_DIRECTORY "${CURRENT_PACKAGES_DIR}/share/${PORT}")
file(WRITE "${CURRENT_PACKAGES_DIR}/share/${PORT}/vcpkg-port-config.cmake" "# helper port\n")
file(WRITE "${CURRENT_PACKAGES_DIR}/share/${PORT}/result.txt"
"Chapter 5 sanity checks passed. Ready for Chapter 6.\n"
)

file(WRITE "${CURRENT_PACKAGES_DIR}/share/${PORT}/copyright"
"Sanity-check helper port (no upstream sources).\n"
)
