DECODE_APK "system" "system/priv-app/SecSettings/SecSettings.apk"
SEC_DISPLAY_UTILS="$(find "$APKTOOL_DIR/system/priv-app/SecSettings/SecSettings.apk" \
    -type f -path '*/com/samsung/android/settings/display/SecDisplayUtils.smali' -printf '%P\n' -quit)"
[ "$SEC_DISPLAY_UTILS" ] || ABORT "SecDisplayUtils.smali not found"
SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
    "$SEC_DISPLAY_UTILS" "return" \
    'isInvalidFont(Landroid/content/Context;Ljava/lang/String;)Z' \
    'false'
unset SEC_DISPLAY_UTILS
