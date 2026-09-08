# The source framework and r11s expose the same VaultKeeperService Java/JNI
# contract, but use different native transports. Keep the source AIDL manager
# for APEX clients (notably Bluetooth), and give VaultKeeperService a private,
# renamed copy of the r11s HIDL 2.0 manager.
VK_DONOR="r11sxxx"
VK_TARGET_INTERFACE="$WORK_DIR/vendor/lib64/vendor.samsung.hardware.security.vaultkeeper@2.0.so"
VK_TARGET_DAEMON="$WORK_DIR/vendor/bin/vaultkeeperd"
VK_HIDL_MANAGER="$WORK_DIR/system/system/lib64/libvkmanager-hidl.so"

if [ -f "$VK_TARGET_INTERFACE" ] && [ -f "$VK_TARGET_DAEMON" ]; then
    LOG "- Adding the isolated r11s VaultKeeper HIDL 2.0 system bridge"

    # Restore the source AIDL manager explicitly when a cached work directory
    # still contains an earlier downgrade experiment.
    ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "system" "system/lib64/libvkmanager.so" \
        0 0 644 "u:object_r:system_lib_file:s0"

    ADD_TO_WORK_DIR "$VK_DONOR" "system" "lib64/vendor.samsung.hardware.security.vaultkeeper@2.0.so" \
        0 0 644 "u:object_r:system_lib_file:s0"
    ADD_TO_WORK_DIR "$VK_DONOR" "system" "lib64/libvkjni.so" \
        0 0 644 "u:object_r:system_lib_file:s0"

    cp -a "$SRC_DIR/prebuilts/samsung/$VK_DONOR/system/lib64/libvkmanager.so" \
        "$VK_HIDL_MANAGER"
    SET_METADATA "system" "system/lib64/libvkmanager-hidl.so" \
        0 0 644 "u:object_r:system_lib_file:s0"

    if ! command -v patchelf > /dev/null 2>&1; then
        LOGE "patchelf is required for VaultKeeper HIDL compatibility"
        return 1
    fi
    patchelf --set-soname 'libvkmanager-hidl.so' "$VK_HIDL_MANAGER"
    patchelf --replace-needed 'libvkmanager.so' 'libvkmanager-hidl.so' \
        "$WORK_DIR/system/system/lib64/libvkjni.so"

    # Clean artifacts from the superseded public-library experiment.
    sed -i '\|^vendor\.samsung\.hardware\.security\.vaultkeeper@2\.0\.so 64$|d' \
        "$WORK_DIR/system/system/etc/public.libraries.txt"
else
    LOGW "Legacy VaultKeeper HIDL 2.0 backend not found; keeping source system bridge"
fi

unset VK_DONOR VK_TARGET_INTERFACE VK_TARGET_DAEMON VK_HIDL_MANAGER
