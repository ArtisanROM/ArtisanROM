LOG_STEP_IN "- Fixing Reboot on call hang up"
DECODE_APK "system" "system/priv-app/Telecom/Telecom.apk"
# APPLY_PATCH "system" "system/priv-app/Telecom/Telecom.apk" "$SRC_DIR/unica/patches/telecom/0001-Modify-SamsungBluetoothRouteManager.patch"
    true
LOG_STEP_OUT
