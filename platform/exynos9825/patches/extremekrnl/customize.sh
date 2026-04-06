# [
EXTREMEKRNL_REPO="https://github.com/Ocin4ever/ExtremeKernel/releases"

REPLACE_KERNEL_BINARIES()
{
    [ -d "$TMP_DIR" ] && rm -rf "$TMP_DIR"
    mkdir -p "$TMP_DIR"

    ZIP_LINK="$EXTREMEKRNL_REPO/latest/download/ExtremeKRNL-Nexus-${TARGET_CODENAME}.zip"
    # if ! $DEBUG; then
    #     ZIP_LINK="$EXTREMEKRNL_REPO/latest/download/ExtremeKRNL-Nexus-${TARGET_CODENAME}.zip"
    # else
    #     ZIP_LINK="$EXTREMEKRNL_REPO/download/debug/ExtremeKRNL-Nexus-${TARGET_CODENAME}.zip"
    # fi
    LOG "Downloading $(basename "$ZIP_LINK")"
    curl -L -s -o "$TMP_DIR/krnl.zip" "$ZIP_LINK"

    LOG "Extracting kernel binaries"
    echo $WORK_DIR
    rm -f "$WORK_DIR/kernel/"*.img
    unzip -q -j "$TMP_DIR/krnl.zip" \
        "files/boot.img" "files/dtbo.img" "files/dtb.img" \
        -d "$WORK_DIR/kernel"

    rm -rf "$TMP_DIR"
}

REPLACE_KERNEL_BINARIES