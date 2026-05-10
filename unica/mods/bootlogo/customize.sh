if [[ $TARGET_OS_SINGLE_SYSTEM_IMAGE == "essi" ]]; then
    LOG_STEP_IN "- Exynos device detected. Selecting custom up_param."

    # 1. Determine Firmware Path
    TARGET_FIRMWARE_PATH="$(cut -d "/" -f 1 -s <<< "$TARGET_FIRMWARE")_$(cut -d "/" -f 2 -s <<< "$TARGET_FIRMWARE")"
    
    # 2. Path to system QMG for resolution detection
    BOOT_QMG="$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/media/bootsamsung.qmg"

    if [ -f "$BOOT_QMG" ]; then
        # Read Width at offset 6 (2 bytes)
        W_HEX=$(READ_BYTES_AT "$BOOT_QMG" "6" "2")
        WIDTH=$(printf "%d" "0x$W_HEX")
        
        # Read Height at offset 8 (2 bytes)
        H_HEX=$(READ_BYTES_AT "$BOOT_QMG" "8" "2")
        HEIGHT=$(printf "%d" "0x$H_HEX")

        # 3. Exact Match Logic
        if [ "$WIDTH" -eq 1440 ]; then
            LOG " Exact QHD (1440p) match. Applying bootlogo."
            cp -a "$SRC_DIR/unica/mods/bootlogo/up_param_1440p.bin" "$WORK_DIR/up_param.bin"
        elif [ "$WIDTH" -eq 1080 ]; then
            LOG " Exact FHD (1080p) match. Applying bootlogo."
            cp -a "$SRC_DIR/unica/mods/bootlogo/up_param_1080p.bin" "$WORK_DIR/up_param.bin"
        else
            LOGW "  ! Detected resolution ${WIDTH}x${HEIGHT} is non-standard. Skipping custom up_param."
        fi
    else
        LOGW "  ! Resolution reference (bootsamsung.qmg) missing. Skipping up_param."
    fi

    # Cleanup variables
    unset TARGET_FIRMWARE_PATH W_HEX H_HEX WIDTH HEIGHT BOOT_QMG
    LOG_STEP_OUT
    LOG_STEP_IN "- Applying Boot Animation patches"
    ADD_TO_WORK_DIR "e2sxxx" "system" "system/media/bootsamsung.qmg"
    ADD_TO_WORK_DIR "e2sxxx" "system" "system/media/bootsamsungloop.qmg"
    ADD_TO_WORK_DIR "e2sxxx" "system" "system/media/shutdown.qmg"
    LOG_STEP_OUT
else
    LOG "- Non-Exynos device detected. Skipping custom up_param."
fi
