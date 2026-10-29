# Keep the Android 16 camera, manifest and native ABI. Add the legacy r8s
# resolutions/controls and derive seamless lens stops from its declared roles.
if [[ "$TARGET_CODENAME" == "r8s" && "$SOURCE_PLATFORM_SDK_VERSION" -ge 36 ]]; then
    # The source firmware has no FoodDetector, although its camera requests
    # food.samsung.v1. The target's ARM64 detector implements the same init/
    # deinit ABI and uses OpenCV symbols already supplied by the source.
    if [ ! -f "$WORK_DIR/system/system/lib64/libFoodDetector.camera.samsung.so" ]; then
        ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" \
            "system/lib64/libFoodDetector.camera.samsung.so" \
            0 0 644 "u:object_r:system_lib_file:s0" || return 1
    fi
    APPLY_PATCH "system" "system/priv-app/SamsungCamera/SamsungCamera.apk" \
        "$MODPATH/r8s-legacy-camera.patch" || return 1

    # Match the on-device fix: the camera's native loader must also find the
    # target detector inside its own APK namespace, not only /system/lib64.
    EVAL "mkdir -p \"$APKTOOL_DIR/system/priv-app/SamsungCamera/SamsungCamera.apk/lib/arm64-v8a\"" || return 1
    EVAL "cp -a \"$WORK_DIR/system/system/lib64/libFoodDetector.camera.samsung.so\" \"$APKTOOL_DIR/system/priv-app/SamsungCamera/SamsungCamera.apk/lib/arm64-v8a/\"" || return 1
fi
