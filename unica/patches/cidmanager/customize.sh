# The source framework and the target firmware expose the same
# VaultKeeperService Java/JNI contract, but use different native transports.
# Keep the source AIDL manager for APEX clients (notably Bluetooth), and give
# VaultKeeperService a private copy of the target's matching HIDL 2.0 manager.
VK_CURRENT_MANAGER="$WORK_DIR/system/system/lib64/libvkmanager.so"
VK_STACK_MARKER="$WORK_DIR/configs/vaultkeeper_system_stack.path"

IS_VAULTKEEPER_HIDL_2_MANAGER()
{
    local VK_NEEDED

    [ -f "$1" ] || return 1
    while IFS= read -r VK_NEEDED; do
        if [ "$VK_NEEDED" = "vendor.samsung.hardware.security.vaultkeeper@2.0.so" ]; then
            return 0
        fi
    done < <(patchelf --print-needed "$1" 2> /dev/null)

    return 1
}

if [ -s "$VK_STACK_MARKER" ]; then
    VK_STACK_PATH="$(head -n 1 "$VK_STACK_MARKER")"
    if [ ! -d "$VK_STACK_PATH/system" ]; then
        ABORT "VaultKeeper stack module not found: ${VK_STACK_PATH#$SRC_DIR/}"
    fi

    LOG "- Reapplying the authoritative Bluetooth/VaultKeeper stack from ${VK_STACK_PATH#$SRC_DIR/}"
    ADD_TO_WORK_DIR "$VK_STACK_PATH" "system" "." \
        0 0 755 "u:object_r:system_file:s0"

    for VK_RELATIVE_FILE in \
        "system/apex/com.android.bt.apex" \
        "system/lib64/libbt-iopdb.so" \
        "system/lib64/libbt-iopdb_mod.so" \
        "system/lib64/libvkmanager.so" \
        "system/lib64/libvkjni.so" \
        "system/lib64/vendor.samsung.hardware.security.vaultkeeper@2.0.so"; do
        if ! cmp -s \
                "$VK_STACK_PATH/system/$VK_RELATIVE_FILE" \
                "$WORK_DIR/system/$VK_RELATIVE_FILE"; then
            ABORT "VaultKeeper stack file was not installed correctly: /$VK_RELATIVE_FILE"
        fi
    done

    if ! IS_VAULTKEEPER_HIDL_2_MANAGER "$VK_CURRENT_MANAGER"; then
        ABORT "Selected VaultKeeper stack does not provide a HIDL 2.0 libvkmanager.so"
    fi
fi

if IS_VAULTKEEPER_HIDL_2_MANAGER "$VK_CURRENT_MANAGER"; then
    LOG "- Keeping the coherent Bluetooth/VaultKeeper HIDL 2.0 stack"

    for VK_FILE in \
        "$WORK_DIR/system/system/apex/com.android.bt.apex" \
        "$WORK_DIR/system/system/lib64/libvkmanager.so" \
        "$WORK_DIR/system/system/lib64/libvkjni.so" \
        "$WORK_DIR/system/system/lib64/vendor.samsung.hardware.security.vaultkeeper@2.0.so"; do
        if [ ! -f "$VK_FILE" ]; then
            ABORT "Incomplete VaultKeeper HIDL 2.0 stack: ${VK_FILE#$WORK_DIR}"
        fi
    done

    unset VK_CURRENT_MANAGER VK_FILE VK_RELATIVE_FILE VK_STACK_MARKER VK_STACK_PATH
    unset -f IS_VAULTKEEPER_HIDL_2_MANAGER
    return 0
fi

unset VK_CURRENT_MANAGER VK_STACK_MARKER VK_STACK_PATH
unset -f IS_VAULTKEEPER_HIDL_2_MANAGER

VK_DONOR="$TARGET_FIRMWARE"
VK_DONOR_PATH="$(cut -d "/" -f 1 -s <<< "$VK_DONOR")_$(cut -d "/" -f 2 -s <<< "$VK_DONOR")"
VK_TARGET_INTERFACE="$WORK_DIR/vendor/lib64/vendor.samsung.hardware.security.vaultkeeper@2.0.so"
VK_TARGET_DAEMON="$WORK_DIR/vendor/bin/vaultkeeperd"
VK_HIDL_MANAGER="$WORK_DIR/system/system/lib64/libvkmanager-hidl.so"

if [ -f "$VK_TARGET_INTERFACE" ] && [ -f "$VK_TARGET_DAEMON" ]; then
    LOG "- Adding the isolated target VaultKeeper HIDL 2.0 system bridge"

    # Restore the source AIDL manager explicitly when a cached work directory
    # still contains an earlier downgrade experiment.
    ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "system" "system/lib64/libvkmanager.so" \
        0 0 644 "u:object_r:system_lib_file:s0"

    ADD_TO_WORK_DIR "$VK_DONOR" "system" "system/lib64/vendor.samsung.hardware.security.vaultkeeper@2.0.so" \
        0 0 644 "u:object_r:system_lib_file:s0"
    ADD_TO_WORK_DIR "$VK_DONOR" "system" "system/lib64/libvkjni.so" \
        0 0 644 "u:object_r:system_lib_file:s0"

    cp -a "$FW_DIR/$VK_DONOR_PATH/system/system/lib64/libvkmanager.so" \
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

unset VK_DONOR VK_DONOR_PATH VK_TARGET_INTERFACE VK_TARGET_DAEMON VK_HIDL_MANAGER
