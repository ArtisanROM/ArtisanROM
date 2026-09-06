if [[ "$SOURCE_PLATFORM_SDK_VERSION" -ge 36 ]]; then
    LOG_STEP_IN "- Preparing unencrypted user storage"
    STORAGE_INIT_RC="$WORK_DIR/system/system/etc/init/hw/init.rc"
    STORAGE_FSTAB="$WORK_DIR/vendor/etc/fstab.exynos990"
    STORAGE_DATA_RULE="mkdir /data/data 0771 system system encryption=None"

    [ -f "$STORAGE_INIT_RC" ] || \
        ABORT "File not found: ${STORAGE_INIT_RC//$WORK_DIR\//}"
    [ -f "$STORAGE_FSTAB" ] || \
        ABORT "File not found: ${STORAGE_FSTAB//$WORK_DIR\//}"

    if grep '^/dev/block/by-name/userdata' "$STORAGE_FSTAB" | grep -q 'fileencryption='; then
        LOG "  - File-based encryption is enabled; no compatibility rule is needed"
    elif grep -q -F -x "    $STORAGE_DATA_RULE" "$STORAGE_INIT_RC"; then
        LOG "  - Legacy /data/data initialization is already present"
    elif grep -q -F -x "    init_user0" "$STORAGE_INIT_RC"; then
        LOG "  - Creating /data/data before init_user0"
        EVAL "sed -i '0,/^    init_user0$/{s|^    init_user0$|    $STORAGE_DATA_RULE\\n\\n    init_user0|}' \"$STORAGE_INIT_RC\""
    else
        ABORT "Unable to locate init_user0 in ${STORAGE_INIT_RC//$WORK_DIR\//}"
    fi

    if ! grep '^/dev/block/by-name/userdata' "$STORAGE_FSTAB" | grep -q 'fileencryption='; then
        grep -q -F -x "    $STORAGE_DATA_RULE" "$STORAGE_INIT_RC" || \
            ABORT "Failed to add the legacy /data/data initialization rule"
    fi

    unset STORAGE_INIT_RC STORAGE_FSTAB STORAGE_DATA_RULE
    LOG_STEP_OUT
fi
