#!/bin/bash
set -euo pipefail

# -----------------------------
# LFS preflight checks (early chapters)
# -----------------------------
if [[ " $* " == *" --howto-disk "* ]]; then
  cat <<'EOF'
Suggested (manual) steps to prepare an LFS partition:

1) Create a partition (example with fdisk/parted).
2) Make a filesystem:
   sudo mkfs.ext4 /dev/<partition>
3) Mount it:
   sudo mkdir -p /mnt/lfs
   sudo mount /dev/<partition> /mnt/lfs
4) Make it writable for your user:
   sudo chown -R $USER:$USER /mnt/lfs

Verify:
   mountpoint /mnt/lfs
   df -h /mnt/lfs
EOF
  exit 0
fi

fatal() { echo "ERROR: $*" >&2; exit 2; }
warn()  { echo "WARN:  $*" >&2; }

STRICT_MOUNT=false
if [[ " $* " == *" --strict-mount "* ]]; then
  STRICT_MOUNT=true
fi

echo "LFS = $LFS"
$STRICT_MOUNT && echo "Mount check: strict" || echo "Mount check: skipped"

# Must be absolute and must not be /
[[ "$LFS" = /* ]] || fatal "LFS must be an absolute path, got: $LFS"
[[ "$LFS" != "/" ]] || fatal "Refusing to use LFS=/"

# Directory must exist
[ -d "$LFS" ] || fatal "LFS directory does not exist: $LFS"

# Optional mountpoint check (only in strict mode)
if $STRICT_MOUNT && command -v mountpoint >/dev/null 2>&1; then
  mountpoint -q "$LFS" || fatal "$LFS is not a mountpoint (strict mode).
Mount a filesystem there, e.g.:
  sudo mount /dev/<partition> $LFS"
fi

# Writable check
touch "$LFS/.lfs_write_test" 2>/dev/null || fatal "LFS is not writable: $LFS
Fix permissions or mount options, e.g.:
  sudo chown -R \$USER:\$USER $LFS"
rm -f "$LFS/.lfs_write_test" || true

# Create required dirs for current stage
mkdir -p "$LFS/sources" "$LFS/tools"

# Nice-to-have: sources sticky (won't fail the build if not permitted)
chmod a+wt "$LFS/sources" 2>/dev/null || true
