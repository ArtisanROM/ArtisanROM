# [
EXTREMEKRNL_REPO="https://github.com/Ocin4ever/ExtremeKernel/releases"

REPLACE_KERNEL_BINARIES()
{
    [ -d "$TMP_DIR" ] && rm -rf "$TMP_DIR"
    mkdir -p "$TMP_DIR"
    # ​This kernel actually won't boot. You need to flash Creeeeger/9820_kernel from the OneUI8Stable branch instead: https://github.com/Creeeeger/9820_kernel
    # Changed from /latest/download/ to /download/v1.0/ 
    # This ensures it grabs the d1xks kernel from the initial release
    ZIP_LINK="https://github.com/Ocin4ever/ExtremeKernel/releases/download/v1.0/ExtremeKRNL-Nexus-${TARGET_CODENAME}.zip"

    LOG "Downloading $(basename "$ZIP_LINK")"
    
    # Added -f to curl so it fails immediately if the link is 404
    if ! curl -L -f -s -o "$TMP_DIR/krnl.zip" "$ZIP_LINK"; then
        LOG "ERROR: Failed to download kernel! Check if the link is correct."
        exit 1
    fi

    LOG "Extracting kernel binaries"
    echo "$WORK_DIR"
    rm -f "$WORK_DIR/kernel/"*.img
    
    # Unzip the necessary kernel components
    unzip -q -j "$TMP_DIR/krnl.zip" \
        "files/boot.img" "files/dtbo.img" "files/dtb.img" \
        -d "$WORK_DIR/kernel"

    rm -rf "$TMP_DIR"
}


REPLACE_KERNEL_BINARIES
