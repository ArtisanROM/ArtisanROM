# Encryption
LINE="$(sed -n "/^\/dev\/block\/by-name\/userdata/=" "$WORK_DIR/vendor/etc/fstab.exynos990")"
LOG "- Switching to FBE v2"
FBE_V1="fileencryption=ice"
FBE_V2="fileencryption=aes-256-xts:aes-256-cts:v2+inlinecrypt_optimized,metadata_encryption=aes-256-xts,keydirectory=/metadata/vold/metadata_encryption"
sed -i "${LINE}s|resgid=5678|resgid=5678,inlinecrypt|g" "$WORK_DIR/vendor/etc/fstab.exynos990" \
    && sed -i "${LINE}s|$FBE_V1|$FBE_V2|g" "$WORK_DIR/vendor/etc/fstab.exynos990"

# Samsung ODE
ENTRIES="
ODE
keydata
keyrefuge
"
for e in $ENTRIES; do
    sed -i "/${e}/d" "$WORK_DIR/vendor/etc/fstab.exynos990"
done

# For some reason we are missing 2 permissions here: android.hardware.security.model.compatible and android.software.controls
# First one is related to encryption and second one to SmartThings Device Control
LOG "- Patching vendor permissions"
sed -i '$d' "$WORK_DIR/vendor/etc/permissions/handheld_core_hardware.xml"
{
    echo ""
    echo "    <!-- Indicate support for the Android security model per the CDD. -->"
    echo "    <feature name=\"android.hardware.security.model.compatible\"/>"
    echo ""
    echo "    <!--  Feature to specify if the device supports controls.  -->"
    echo "    <feature name=\"android.software.controls\"/>"
    echo "</permissions>"
} >> "$WORK_DIR/vendor/etc/permissions/handheld_core_hardware.xml"

SET_PROP "vendor" "ro.crypto.allow_encrypt_override" --delete
SET_PROP "vendor" "ro.crypto.metadata_init_delete_all_keys.enabled" "true"
SET_PROP "vendor" "ro.crypto.dm_default_key.options_format.version" "2"
SET_PROP "vendor" "ro.crypto.volume.metadata.method" "dm-default-key"
SET_PROP "vendor" "ro.crypto.volume.options" "::v2"

SET_PROP "vendor" "external_storage.projid.enabled" "1"
SET_PROP "vendor" "external_storage.casefold.enabled" "1"
SET_PROP "vendor" "external_storage.sdcardfs.enabled" "0"
SET_PROP "vendor" "persist.sys.fuse.passthrough.enable" "true"
LOG_STEP_OUT

LOG_STEP_IN "- Enabling IncrementalFS"
SET_PROP "vendor" "ro.incremental.enable" "yes"
LOG_STEP_OUT

LOG_STEP_IN "- Enabling FS Verity"
SET_PROP "vendor" "ro.apk_verity.mode" "2"
LOG_STEP_OUT