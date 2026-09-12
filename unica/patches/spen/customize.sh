MODEL=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 1)
REGION=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 2)

if [ -d "$FW_DIR/${MODEL}_${REGION}/system/system/media/audio/pensounds" ]; then
    LOG_STEP_IN "- Adding SPen stack"

    # Platform/device modules are applied before ROM-wide modules. Preserve an
    # AirCommand compatibility package supplied by either layer instead of
    # silently replacing it with the generic dm3q build below.
    AIRCOMMAND_OVERRIDE="$(find \
        "$SRC_DIR/platform/$TARGET_PLATFORM/patches" \
        "$SRC_DIR/target/$TARGET_CODENAME/patches" \
        -type f -path '*/system/priv-app/AirCommand/AirCommand.apk' \
        -print -quit 2> /dev/null)"

    ADD_TO_WORK_DIR "dm3qxxx" "system" "system/app/AirGlance"
    ADD_TO_WORK_DIR "dm3qxxx" "system" "system/app/LiveDrawing"
    ADD_TO_WORK_DIR "dm3qxxx" "system" "system/etc/default-permissions/default-permissions-com.samsung.android.service.aircommand.xml"
    ADD_TO_WORK_DIR "dm3qxxx" "system" "system/etc/permissions/privapp-permissions-com.samsung.android.app.readingglass.xml"
    ADD_TO_WORK_DIR "dm3qxxx" "system" "system/etc/permissions/privapp-permissions-com.samsung.android.service.aircommand.xml"
    ADD_TO_WORK_DIR "dm3qxxx" "system" "system/etc/permissions/privapp-permissions-com.samsung.android.service.airviewdictionary.xml"
    ADD_TO_WORK_DIR "dm3qxxx" "system" "system/etc/public.libraries-smps.samsung.txt"
    ADD_TO_WORK_DIR "dm3qxxx" "system" "system/etc/sysconfig/airviewdictionaryservice.xml"
    ADD_TO_WORK_DIR "dm3qxxx" "system" "system/lib64/libsmpsft.smps.samsung.so"
    ADD_TO_WORK_DIR "dm3qxxx" "system" "system/media/audio/pensounds"
    if [ "$AIRCOMMAND_OVERRIDE" ]; then
        LOG "- Preserving platform/device AirCommand compatibility package"
    else
        ADD_TO_WORK_DIR "dm3qxxx" "system" "system/priv-app/AirCommand"
    fi
    ADD_TO_WORK_DIR "dm3qxxx" "system" "system/priv-app/AirReadingGlass"
    ADD_TO_WORK_DIR "dm3qxxx" "system" "system/priv-app/SmartEye"
    LOG_STEP_OUT
else
    LOG "- SPen support not detected in target device. Ignoring."
fi

unset MODEL REGION AIRCOMMAND_OVERRIDE
