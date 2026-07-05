# Add KernelSU-Next Manager APK only for ESSI target
if [ "$TARGET_OS_SINGLE_SYSTEM_IMAGE" = "essi" ]; then
    KERNELSU_MANAGER_APK="https://github.com/KernelSU-Next/KernelSU-Next/releases/download/v3.2.0/KernelSU_Next_v3.2.0_33129-release.apk"
    APK_PATH="system/preload/KernelSU-Next/com.rifsxd.ksunext-mesa==/base.apk"

    LOG "- Adding KernelSU-Next APK v3.2.0 to preload apps"
    mkdir -p "$WORK_DIR/system/$(dirname "$APK_PATH")"
    DOWNLOAD_FILE "$KERNELSU_MANAGER_APK" "$WORK_DIR/system/$APK_PATH"

    while IFS= read -r i; do
        i="${i//$WORK_DIR\/system\//}"

        if [ -d "$WORK_DIR/system/$i" ]; then
            SET_METADATA "system" "$i" 0 0 755 "u:object_r:system_file:s0"
        else
            SET_METADATA "system" "$i" 0 0 644 "u:object_r:system_file:s0"
        fi

        if [[ "$i" == *".apk" ]] && \
                ! grep -q "$i" "$WORK_DIR/system/system/etc/vpl_apks_count_list.txt"; then
            LOG "- Adding \"$i\" to /system/system/etc/vpl_apks_count_list.txt"
            EVAL "echo \"$i\" >> \"$WORK_DIR/system/system/etc/vpl_apks_count_list.txt\""
        fi
    done <<< "$(find "$WORK_DIR/system/system/preload")"
fi

# Add KernelSU-Next Manager APK only for QSSI target
if [ "$TARGET_OS_SINGLE_SYSTEM_IMAGE" = "qssi" ]; then
    KERNELSU_MANAGER_APK="https://github.com/KernelSU-Next/KernelSU-Next/releases/download/v3.1.0/KernelSU_Next_v3.1.0_33024-release.apk"
    APK_PATH="system/preload/KernelSU-Next/com.rifsxd.ksunext-mesa==/base.apk"

    LOG "- Adding KernelSU-Next APK v3.1.0 to preload apps"
    mkdir -p "$WORK_DIR/system/$(dirname "$APK_PATH")"
    DOWNLOAD_FILE "$KERNELSU_MANAGER_APK" "$WORK_DIR/system/$APK_PATH"

    while IFS= read -r i; do
        i="${i//$WORK_DIR\/system\//}"

        if [ -d "$WORK_DIR/system/$i" ]; then
            SET_METADATA "system" "$i" 0 0 755 "u:object_r:system_file:s0"
        else
            SET_METADATA "system" "$i" 0 0 644 "u:object_r:system_file:s0"
        fi

        if [[ "$i" == *".apk" ]] && \
                ! grep -q "$i" "$WORK_DIR/system/system/etc/vpl_apks_count_list.txt"; then
            LOG "- Adding \"$i\" to /system/system/etc/vpl_apks_count_list.txt"
            EVAL "echo \"$i\" >> \"$WORK_DIR/system/system/etc/vpl_apks_count_list.txt\""
        fi
    done <<< "$(find "$WORK_DIR/system/system/preload")"
fi
