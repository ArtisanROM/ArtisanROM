MODEL=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 1)
REGION=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 2)

if [ -d "$FW_DIR/${MODEL}_${REGION}/system/system/media/audio/pensounds" ]; then
    LOG_STEP_IN "- Adding SPen stack"

    # Platform/device modules are applied before ROM-wide modules. Locate a
    # compatibility package supplied by either layer and make it authoritative
    # again after importing the generic stack below.
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
        AIRCOMMAND_OVERRIDE_ROOT="${AIRCOMMAND_OVERRIDE%/system/priv-app/AirCommand/AirCommand.apk}"
        LOG "- Installing platform/device AirCommand compatibility package as final override"
        ADD_TO_WORK_DIR "$AIRCOMMAND_OVERRIDE_ROOT" "system" \
            "system/priv-app/AirCommand/AirCommand.apk" \
            0 0 644 "u:object_r:system_file:s0"
    else
        ADD_TO_WORK_DIR "dm3qxxx" "system" "system/priv-app/AirCommand"
    fi
    ADD_TO_WORK_DIR "dm3qxxx" "system" "system/priv-app/AirReadingGlass"
    ADD_TO_WORK_DIR "dm3qxxx" "system" "system/priv-app/SmartEye"
    LOG_STEP_OUT
else
    LOG "- SPen support not detected in target device. Ignoring."
fi

unset MODEL REGION AIRCOMMAND_OVERRIDE AIRCOMMAND_OVERRIDE_ROOT
