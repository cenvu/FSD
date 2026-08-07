#!/bin/bash
set -e

mkdir -p fixtures/malformed
cd fixtures

declare -a IMG_TYPES=("apfs" "hfs")

for vol in "${IMG_TYPES[@]}"; do
    img_name="${vol}.dmg"
    malformed_name="malformed/${vol}_truncated.dmg"
    
    echo "Creating truncated malformed image for $vol..."
    dd if="$img_name" of="$malformed_name" bs=1m count=1 2>/dev/null
done

echo "Malformed images generated."
