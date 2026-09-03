DECODE_APK "system" "system/priv-app/SecSettings/SecSettings.apk"
OUTDOOR_CONTROLLER="$(find "$APKTOOL_DIR/system/priv-app/SecSettings/SecSettings.apk" \
    -type f -path '*/com/samsung/android/settings/display/controller/SecOutDoorModePreferenceController.smali' -printf '%P\n' -quit)"
[ "$OUTDOOR_CONTROLLER" ] || ABORT "SecOutDoorModePreferenceController.smali not found"
SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
    "$OUTDOOR_CONTROLLER" "return" \
    'isAvailable()Z' \
    'true'
unset OUTDOOR_CONTROLLER
