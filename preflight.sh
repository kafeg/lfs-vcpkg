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

echo "LFS = $LFS"

# Must be absolute and must not be /
[[ "$LFS" = /* ]] || fatal "LFS must be an absolute path, got: $LFS"
[[ "$LFS" != "/" ]] || fatal "Refusing to use LFS=/"

# Ensure mountpoint exists
if [ ! -d "$LFS" ]; then
  fatal "LFS directory does not exist: $LFS
Create it and mount a filesystem there (recommended), e.g.:
  sudo mkdir -p /mnt/lfs
  sudo mount /dev/<your-partition> /mnt/lfs"
fi

# Check it's a mountpoint (recommended in LFS). If not, warn but continue (useful for dev mode).
if command -v mountpoint >/dev/null 2>&1; then
  if ! mountpoint -q "$LFS"; then
    warn "$LFS is not a mountpoint.
This is OK for a dev sandbox, but LFS usually expects a dedicated filesystem.
To mount:
  sudo mount /dev/<your-partition> $LFS"
  fi
fi

# Writable check
touch "$LFS/.lfs_write_test" 2>/dev/null || fatal "LFS is not writable: $LFS
Fix permissions or mount options. Example:
  sudo chown -R \$USER:\$USER $LFS"
rm -f "$LFS/.lfs_write_test" || true

# Disk space check (rough; adjust threshold if you want)
if command -v df >/dev/null 2>&1; then
  avail_kb="$(df -Pk "$LFS" | awk 'NR==2 {print $4}')"
  # 10 GB = 10*1024*1024 KB
  if [ "${avail_kb:-0}" -lt $((10*1024*1024)) ]; then
    warn "Low free space on $LFS: $(df -Ph "$LFS" | awk 'NR==2 {print $4}') available.
LFS builds can require 10–20GB+ depending on what you keep."
  fi
fi

# Create required dirs (book uses $LFS/sources, $LFS/tools early)
mkdir -p "$LFS/sources" "$LFS/tools"

# Helpful permissions (book commonly sets sources sticky + writable)
chmod a+wt "$LFS/sources" 2>/dev/null || true

# If you want to enforce running as non-root (LFS builds are done as user 'lfs' for a while)
if [ "$(id -u)" -eq 0 ]; then
  warn "You are running as root. LFS typically builds toolchain as an unprivileged user."
fi

echo "Preflight OK."
