#!/bin/bash

cd fixtures

echo "Compiling spike..."
swiftc ../spike.swift -o spike
echo ""

VOLS=("apfs" "apfsx" "hfs" "hfsx")
VOL_NAMES=("apfs_vol" "apfsx_vol" "hfs_vol" "hfsx_vol")

for i in "${!VOLS[@]}"; do
    vol="${VOLS[$i]}"
    vol_name="${VOL_NAMES[$i]}"
    img_name="${vol}.dmg"
    mount_point="/Volumes/$vol_name"
    
    echo "======================================"
    echo "Testing $img_name"
    echo "======================================"
    
    echo "[1] Checking pre-mount hash..."
    hash_before=$(shasum -a 256 "$img_name" | awk '{print $1}')
    size_before=$(stat -f %z "$img_name")
    mod_before=$(stat -f %m "$img_name")
    
    echo "[2] Attaching read-only..."
    hdiutil attach "$img_name" -readonly -mountpoint "$mount_point" > /dev/null
    
    echo "[3] Confirming read-only mount..."
    mount | grep "$vol_name" || true
    
    echo "[4] Running Ground Truth (find + stat)..."
    find "$mount_point" -type f -o -type d -o -type l | wc -l > "${vol}_ground_truth_count.txt"
    find "$mount_point" -ls > "${vol}_ground_truth.txt"
    
    echo "[5] Running Spike (3 times for determinism)..."
    for i in 1 2 3; do
        echo "Run $i..."
        time ./spike "$mount_point" > "${vol}_run${i}.txt"
    done
    
    echo "[6] Detaching..."
    hdiutil detach "$mount_point" > /dev/null
    
    echo "[7] Checking post-mount hash..."
    hash_after=$(shasum -a 256 "$img_name" | awk '{print $1}')
    size_after=$(stat -f %z "$img_name")
    mod_after=$(stat -f %m "$img_name")
    
    if [[ "$hash_before" == "$hash_after" && "$size_before" == "$size_after" && "$mod_before" == "$mod_after" ]]; then
        echo "-> Hash check PASSED: Image is completely unmodified."
    else
        echo "-> Hash check FAILED!"
        echo "Before: $hash_before, size: $size_before, mod: $mod_before"
        echo "After : $hash_after, size: $size_after, mod: $mod_after"
    fi
    echo ""
done

echo "======================================"
echo "Testing Malformed Images"
echo "======================================"
for vol in "apfs" "hfs"; do
    img_name="malformed/${vol}_truncated.dmg"
    mount_point="/Volumes/malformed_${vol}"
    
    echo "Attempting to attach truncated $vol..."
    hdiutil attach "$img_name" -readonly -mountpoint "$mount_point"
    attach_status=$?
    
    if [ $attach_status -eq 0 ]; then
        echo "Attach succeeded! Running spike..."
        ./spike "$mount_point"
        hdiutil detach "$mount_point" > /dev/null || true
    else
        echo "Attach failed with status $attach_status as expected."
    fi
    echo ""
done
