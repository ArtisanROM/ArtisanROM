# Hide Remote management tile in Settings app
SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
    "smali_classes3/com/samsung/android/settings/homepage/TopLevelRemoteSupportPreferenceController.smali" "return" \
    'getAvailabilityStatus()I' '3'
