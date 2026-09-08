LOG_STEP_IN "- Updating Vibrator/RIL/Face/WPA HALs"
# Delete hermes to get rid of weaver encryption blobs
BLOBS_LIST="
bin/hw/vendor.samsung.hardware.vibrator@2.2-service
etc/init/vendor.samsung.hardware.vibrator@2.2-service.rc
lib64/vendor.samsung.hardware.vibrator@2.0.so
lib64/vendor.samsung.hardware.vibrator@2.1.so
lib64/vendor.samsung.hardware.vibrator@2.2.so
bin/hw/vendor.samsung.hardware.biometrics.face@2.0-service
etc/init/vendor.samsung.hardware.biometrics.face@2.0-service.rc
bin/hermesd
etc/init/hermesd.rc
lib/liboemcrypto.so
"
for blob in $BLOBS_LIST
do
    DELETE_FROM_WORK_DIR "vendor" "$blob"
done

ADD_TO_WORK_DIR "p3sxxx" "vendor" "bin/hw/vendor.samsung.hardware.biometrics.face@3.0-service"
ADD_TO_WORK_DIR "p3sxxx" "vendor" "bin/hw/vendor.samsung.hardware.vibrator-service"
# Keep the existing non-audio p3s HAL support explicit.  Do not copy the
# whole directory: p3sxxx also contains the experimental audio @6.0 blobs,
# which are handled later by platform/exynos990/patches/zz_p3s_audio_hal.
P3S_VENDOR_LIBS="
lib64/android.hardware.light-V1-ndk_platform.so
lib64/vendor.samsung.hardware.light-V1-ndk_platform.so
lib64/vendor.samsung.hardware.vibrator-V3-ndk_platform.so
lib64/vendor.samsung.hardware.biometrics.face@2.0.so
lib64/vendor.samsung.hardware.biometrics.face@3.0.so
lib64/uwb_uci.hal.so
"
for blob in $P3S_VENDOR_LIBS; do
    ADD_TO_WORK_DIR "p3sxxx" "vendor" "$blob" \
        0 0 644 "u:object_r:vendor_file:s0"
done
ADD_TO_WORK_DIR "p3sxxx" "vendor" "etc/init"
ADD_TO_WORK_DIR "p3sxxx" "vendor" \
    "etc/vintf/manifest/vendor.samsung.hardware.vibrator-default.xml" \
    0 0 644 "u:object_r:vendor_configs_file:s0"

# WPA Supplicant HAL
if [[ "$TARGET_CODENAME" != "r8s" ]]; then
    ADD_TO_WORK_DIR "p3sxxx" "vendor" "bin/hw/wpa_supplicant"
fi

# Light HAL
if [[ "$TARGET_CODENAME" != "r8s" ]]; then
    ADD_TO_WORK_DIR "p3sxxx" "vendor" "bin/hw/vendor.samsung.hardware.light-service"
    ADD_TO_WORK_DIR "p3sxxx" "vendor" "lib64/android.hardware.light-V1-ndk_platform.so"
    ADD_TO_WORK_DIR "p3sxxx" "vendor" "lib64/vendor.samsung.hardware.light-V1-ndk_platform.so"
else
    ADD_TO_WORK_DIR "a73xqxx" "vendor" "bin/hw/vendor.samsung.hardware.light-service"
    ADD_TO_WORK_DIR "a73xqxx" "vendor" "lib64/android.hardware.light-V1-ndk_platform.so"
    ADD_TO_WORK_DIR "a73xqxx" "vendor" "lib64/vendor.samsung.hardware.light-V1-ndk_platform.so"
fi
LOG_STEP_OUT
unset BLOBS_LIST P3S_VENDOR_LIBS blob
