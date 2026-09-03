# Enable Power off lock feature
SMALI_PATCH "system" "system/framework/framework.jar" \
    "smali_classes6/com/samsung/android/globalactions/util/SystemPropertiesWrapper.smali" "return" \
    'isBrazilianCountryISO()Z' 'true'
DECODE_APK "system_ext" "priv-app/SystemUI/SystemUI.apk"
SYSTEMUI_DEVICE_CONTROLLER="$(find "$APKTOOL_DIR/system_ext/priv-app/SystemUI/SystemUI.apk" \
    -path '*/com/android/systemui/bixby2/controller/DeviceController.smali' -printf '%P\n' -quit)"
SMALI_PATCH "system_ext" "priv-app/SystemUI/SystemUI.apk" \
    "$SYSTEMUI_DEVICE_CONTROLLER" "return" \
    'isSupportPowerOffLock()Z' 'true'

# Hide Remote management tile in Settings app
DECODE_APK "system" "system/priv-app/SecSettings/SecSettings.apk"
REMOTE_SUPPORT_CONTROLLER="$(find "$APKTOOL_DIR/system/priv-app/SecSettings/SecSettings.apk" \
    -path '*/com/samsung/android/settings/homepage/TopLevelRemoteSupportPreferenceController.smali' -printf '%P\n' -quit)"
SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
    "$REMOTE_SUPPORT_CONTROLLER" "return" \
    'getAvailabilityStatus()I' '3'

unset SYSTEMUI_DEVICE_CONTROLLER REMOTE_SUPPORT_CONTROLLER
