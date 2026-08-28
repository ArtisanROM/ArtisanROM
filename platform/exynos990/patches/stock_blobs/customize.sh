# S24 FE OneUI 7 -> SoundBooster 2000
# S20 Series -> SoundBooster 1050
LOG_STEP_IN "- Porting the Audio HAL wrapper from HIDL 5.0 to 6.0"
# Keep the Exynos 990 legacy audio.primary driver, DSP firmware, mixer paths
# and policy files. Only replace the generic binder service and HIDL wrapper
# with the Android 16 source firmware's 6.0 implementation.
ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "vendor" "bin/hw/android.hardware.audio.service" 0 2000 755 "u:object_r:hal_audio_default_exec:s0"
for ARCH in lib lib64; do
    for LIB in \
        android.hardware.audio.common@6.0.so \
        android.hardware.audio.common@6.0-util.so \
        android.hardware.audio.effect@6.0.so \
        android.hardware.audio.effect@6.0-util.so \
        android.hardware.audio@6.0.so \
        android.hardware.audio@6.0-util.so; do
        ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "vendor" "$ARCH/$LIB" 0 0 644 "u:object_r:vendor_file:s0"
    done
    ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "vendor" "$ARCH/hw/android.hardware.audio@6.0-impl.so" 0 0 644 "u:object_r:vendor_file:s0"
    ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "vendor" "$ARCH/hw/android.hardware.audio.effect@6.0-impl.so" 0 0 644 "u:object_r:vendor_file:s0"
    EVAL "patchelf --add-needed libaudio-hidl-vndk30-compat.so '$WORK_DIR/vendor/$ARCH/hw/android.hardware.audio@6.0-impl.so'"
    EVAL "patchelf --add-needed libaudio-hidl-vndk30-compat.so '$WORK_DIR/vendor/$ARCH/hw/android.hardware.audio.effect@6.0-impl.so'"
done
LOG_STEP_OUT

LOG_STEP_IN "- Replacing SoundBooster"
DELETE_FROM_WORK_DIR "system" "system/lib64/lib_SoundBooster_ver2000.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/lib_SAG_EQ_ver2000.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/libsoundboostereq_legacy.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/lib_SoundBooster_ver1050.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libsamsungSoundbooster_plus_legacy.so" 0 0 644 "u:object_r:system_lib_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Replacing GameDriver"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/priv-app/GameDriver-EX9830/GameDriver-EX9830.apk" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/priv-app/DevGPUDriver-EX9830/DevGPUDriver-EX9830.apk" 0 0 644 "u:object_r:system_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Replacing Hotword"
DELETE_FROM_WORK_DIR "product" "priv-app/HotwordEnrollmentOKGoogleEx4CORTEXM55"
DELETE_FROM_WORK_DIR "product" "priv-app/HotwordEnrollmentXGoogleEx4CORTEXM55"
if [[ "$TARGET_CODENAME" != "r8s" ]]; then
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "product" "priv-app/HotwordEnrollmentOKGoogleEx3CORTEXM4/HotwordEnrollmentOKGoogleEx3CORTEXM4.apk" 0 0 644 "u:object_r:system_file:s0"
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "product" "priv-app/HotwordEnrollmentXGoogleEx3CORTEXM4/HotwordEnrollmentXGoogleEx3CORTEXM4.apk" 0 0 644 "u:object_r:system_file:s0"
elif [[ "$TARGET_CODENAME" == "r8s" ]]; then
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "product" "priv-app/HotwordEnrollmentOKGoogleEx2CORTEXM4/HotwordEnrollmentOKGoogleEx2CORTEXM4.apk" 0 0 644 "u:object_r:system_file:s0"
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "product" "priv-app/HotwordEnrollmentXGoogleEx2CORTEXM4/HotwordEnrollmentXGoogleEx2CORTEXM4.apk" 0 0 644 "u:object_r:system_file:s0"
fi
LOG_STEP_OUT

if [[ "$TARGET_CODENAME" == "c2s" || "$TARGET_CODENAME" == "c1s" ]]; then
    LOG_STEP_IN "- Adding SPen SEC Feature"
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/permissions/com.sec.feature.spen_usp_level40.xml" 0 0 644 "u:object_r:system_file:s0"
    LOG_STEP_OUT
fi

LOG_STEP_IN "- Adding 32-Bit WFD blobs from S21 (p3sxxx)"
ADD_TO_WORK_DIR "p3sxxx" "system" "system/bin/remotedisplay" 0 2000 755 "u:object_r:remotedisplay_exec:s0"
ADD_TO_WORK_DIR "p3sxxx" "system" "system/lib" 0 0 644 "u:object_r:system_lib_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Adding stock NFC Case features"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/permissions/com.sec.feature.cover.clearsideviewcover.xml" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/permissions/com.sec.feature.cover.xml" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/permissions/com.sec.feature.cover.sview.xml" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/permissions/com.sec.feature.nfc_authentication_cover.xml" 0 0 644 "u:object_r:system_file:s0"

if [[ "$TARGET_CODENAME" != "r8s" ]]; then
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/permissions/com.sec.feature.cover.flip.xml" 0 0 644 "u:object_r:system_file:s0"
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/permissions/com.sec.feature.cover.ledbackcover.xml" 0 0 644 "u:object_r:system_file:s0"
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/permissions/com.sec.feature.cover.nfcledcover.xml" 0 0 644 "u:object_r:system_file:s0"
fi

if [[ "$TARGET_CODENAME" == "x1s" || "$TARGET_CODENAME" == "y2s" || "$TARGET_CODENAME" == "z3s" ]]; then
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/priv-app/LedBackCoverAppHubble/LedBackCoverAppHubble.apk" 0 0 644 "u:object_r:system_file:s0"
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/permissions/privapp-permissions-com.samsung.android.app.ledbackcover.xml" 0 0 644 "u:object_r:system_file:s0"
fi
LOG_STEP_OUT
