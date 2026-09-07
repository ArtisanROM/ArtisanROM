# Keep SecSettings' product-feature antenna value aligned with the target
# vendor.  Newer donor builds compile this value into SecSettings, and the
# activity intentionally crashes when it differs from ro.vendor.nfc.info.antpos.

NFC_ANTPOS="$(GET_PROP "vendor" "ro.vendor.nfc.info.antpos")"

if [ -z "$NFC_ANTPOS" ]; then
    LOG "- Target NFC antenna position is not declared; skipping"
    return 0
fi

LOG_STEP_IN "- Matching NFC antenna guide to target position $NFC_ANTPOS"

SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
    "smali_classes5/com/samsung/android/settings/nfc/NfcAntennaGuideDialog.smali" \
    "replace" "onCreate(Landroid/os/Bundle;)V" \
    "4" "$NFC_ANTPOS"

SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
    "smali_classes5/com/samsung/android/settings/nfc/NfcSettings.smali" \
    "replace" "populateViewForOrientation(Lcom/android/settingslib/widget/LayoutPreference;)V" \
    "4" "$NFC_ANTPOS"

LOG_STEP_OUT

unset NFC_ANTPOS
