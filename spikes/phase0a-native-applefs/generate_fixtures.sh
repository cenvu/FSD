#!/bin/bash
set -e

mkdir -p fixtures
cd fixtures

VOLS=("apfs" "apfsx" "hfs" "hfsx")
FSS=("APFS" "Case-sensitive APFS" "Journaled HFS+" "Case-sensitive Journaled HFS+")

for i in "${!VOLS[@]}"; do
    vol="${VOLS[$i]}"
    fs="${FSS[$i]}"
    img_name="${vol}.dmg"
    vol_name="${vol}_vol"
    
    echo "Creating $img_name with $fs..."
    rm -f "$img_name"
    hdiutil create -size 50m -fs "$fs" -volname "$vol_name" "$img_name" > /dev/null
    
    mount_point="/Volumes/$vol_name"
    hdiutil attach "$img_name" -mountpoint "$mount_point" > /dev/null
    
    echo "Populating $vol_name..."
    mkdir -p "$mount_point/deep/a/b/c"
    touch "$mount_point/empty_file"
    mkdir "$mount_point/empty_dir"
    echo "hello world" > "$mount_point/regular_file.txt"
    echo "hidden" > "$mount_point/.hidden_file"
    mkdir "$mount_point/app.app"
    touch "$mount_point/app.app/Contents"
    ln -s "regular_file.txt" "$mount_point/symlink_valid"
    ln -s "does_not_exist" "$mount_point/symlink_broken"
    
    python3 -c "import unicodedata; open('$mount_point/' + unicodedata.normalize('NFC', 'café_NFC.txt'), 'w').write('nfc')"
    python3 -c "import unicodedata; open('$mount_point/' + unicodedata.normalize('NFD', 'café_NFD.txt'), 'w').write('nfd')"

    long_name=$(python3 -c "print('a' * 250 + '.txt')")
    touch "$mount_point/$long_name"
    
    dd if=/dev/zero of="$mount_point/sparse.bin" bs=1 count=0 seek=1048576 2>/dev/null
    
    touch -t 202607251200 "$mount_point/regular_file.txt"
    
    if [[ "$vol" == "apfsx" || "$vol" == "hfsx" ]]; then
        echo "case1" > "$mount_point/Report.txt"
        echo "case2" > "$mount_point/REPORT.TXT"
    fi
    
    hdiutil detach "$mount_point" > /dev/null
    
    echo "--- Baseline for $img_name ---" >> baseline_state.txt
    shasum -a 256 "$img_name" >> baseline_state.txt
    ls -l "$img_name" >> baseline_state.txt
    stat -x "$img_name" >> baseline_state.txt
    echo "" >> baseline_state.txt
done

echo "Fixtures generated."
