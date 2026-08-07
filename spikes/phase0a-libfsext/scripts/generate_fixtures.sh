#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SPIKE_DIR="$(dirname "$SCRIPT_DIR")"
FIXTURES_DIR="${SPIKE_DIR}/fixtures"
MANIFEST="${SPIKE_DIR}/fixtures-manifest.md"

MKE2FS="/private/tmp/e2fsprogs-build/e2fsprogs/misc/mke2fs"
DEBUGFS="/private/tmp/e2fsprogs-build/e2fsprogs/debugfs/debugfs"
TUNE2FS="/private/tmp/e2fsprogs-build/e2fsprogs/misc/tune2fs"

rm -rf "${FIXTURES_DIR}"
mkdir -p "${FIXTURES_DIR}"

# 1. Create a local tree for mke2fs -d
TREE_DIR="${FIXTURES_DIR}/tree"
mkdir -p "${TREE_DIR}"

# Nested directories & empty dir
mkdir -p "${TREE_DIR}/nested/dir1/dir2"
mkdir -p "${TREE_DIR}/empty_dir"

# Empty file
touch "${TREE_DIR}/empty_file"

# Regular file
echo "hello world" > "${TREE_DIR}/regular_file.txt"

# Unicode filename
echo "unicode" > "${TREE_DIR}/유니코드_파일.txt"

# Case-distinct names
echo "lower" > "${TREE_DIR}/case_file.txt"
echo "Upper" > "${TREE_DIR}/Case_File.txt"

# Symlink & broken symlink
ln -s "regular_file.txt" "${TREE_DIR}/symlink_good"
ln -s "nonexistent" "${TREE_DIR}/symlink_broken"

# Long filename
LONG_NAME="long_$(printf 'a%.0s' {1..240})"
touch "${TREE_DIR}/${LONG_NAME}"

# Sparse file
dd if=/dev/zero of="${TREE_DIR}/sparse_file" bs=1 count=1 seek=1048576 2>/dev/null

# Generate base images
for fs in ext2 ext3 ext4; do
    echo "Creating $fs image..."
    IMG="${FIXTURES_DIR}/valid_${fs}.img"
    
    # 64M image
    dd if=/dev/zero of="$IMG" bs=1M count=64 2>/dev/null
    
    opts=""
    if [ "$fs" = "ext3" ]; then
        opts="-j"
    elif [ "$fs" = "ext4" ]; then
        opts="-t ext4"
    else
        opts="-t ext2"
    fi
    
    $MKE2FS -F $opts -d "${TREE_DIR}" "$IMG" >/dev/null 2>&1
    
    # Add non-UTF-8 filename via debugfs because APFS might reject it
    # \xff\xfe is invalid UTF-8
    $DEBUGFS -w -R "write ${TREE_DIR}/regular_file.txt bad_utf8_$(printf '\xff\xfe')" "$IMG" >/dev/null 2>&1
done

# Encrypted subtree (ext4 only)
echo "Creating encrypted subtree image..."
IMG_ENC="${FIXTURES_DIR}/encrypted_ext4.img"
cp "${FIXTURES_DIR}/valid_ext4.img" "$IMG_ENC"
$TUNE2FS -O encrypt "$IMG_ENC" >/dev/null 2>&1
$DEBUGFS -w -R "mkdir encrypted_dir" "$IMG_ENC" >/dev/null 2>&1
# We can't fully simulate fscrypt offline easily without kernel, but we can set the EXT4_ENCRYPT_FL (0x0800) flag using debugfs
$DEBUGFS -w -R "sif encrypted_dir flags 0x0800" "$IMG_ENC" >/dev/null 2>&1

# Truncated image
echo "Creating truncated image..."
IMG_TRUNC="${FIXTURES_DIR}/truncated_ext4.img"
cp "${FIXTURES_DIR}/valid_ext4.img" "$IMG_TRUNC"
# truncate to 10MB
dd if=/dev/null of="$IMG_TRUNC" bs=1M seek=10 2>/dev/null

# Corrupt metadata image
echo "Creating corrupt image..."
IMG_CORRUPT="${FIXTURES_DIR}/corrupt_ext4.img"
cp "${FIXTURES_DIR}/valid_ext4.img" "$IMG_CORRUPT"
# overwrite some superblock/inode bytes
dd if=/dev/urandom of="$IMG_CORRUPT" bs=4096 count=2 seek=1 conv=notrunc 2>/dev/null

# Partition offset image
echo "Creating partitioned image..."
IMG_PART="${FIXTURES_DIR}/partitioned_ext4.img"
dd if=/dev/zero of="$IMG_PART" bs=1M count=80 2>/dev/null
# write valid ext4 at 10MB offset
dd if="${FIXTURES_DIR}/valid_ext4.img" of="$IMG_PART" bs=1M seek=10 conv=notrunc 2>/dev/null

# Manifest
cat << 'EOF' > "$MANIFEST"
# Fixtures Manifest

- `valid_ext2.img`: valid ext2 filesystem
- `valid_ext3.img`: valid ext3 filesystem
- `valid_ext4.img`: valid ext4 filesystem
- `encrypted_ext4.img`: ext4 with an fscrypt flagged directory
- `truncated_ext4.img`: cut-off ext4 image
- `corrupt_ext4.img`: damaged metadata ext4 image
- `partitioned_ext4.img`: valid ext4 image located at offset 10MB
EOF

echo "Done generating fixtures."
