# Keep SecSettings' compiled antenna position aligned with the target vendor.
# The RF configuration itself remains target-specific and is never replaced.

NFC_SETTINGS_APK="system/priv-app/SecSettings/SecSettings.apk"
NFC_TARGET_ANTPOS="$(GET_PROP "vendor" "ro.vendor.nfc.info.antpos")"

if [ -z "$NFC_TARGET_ANTPOS" ]; then
    LOG "- Target NFC antenna position is not declared; skipping"
    unset NFC_SETTINGS_APK NFC_TARGET_ANTPOS
    return 0
fi

if ! [[ "$NFC_TARGET_ANTPOS" =~ ^[0-9]+$ ]]; then
    LOGW "Invalid target NFC antenna position: $NFC_TARGET_ANTPOS"
    unset NFC_SETTINGS_APK NFC_TARGET_ANTPOS
    return 0
fi

_GET_COMPILED_NFC_ANTPOS()
{
    local SMALI_FILE="$1"
    local METHOD="$2"

    awk -v FN="$METHOD" '
        /^\.method/ && index($0, FN) {
            inside = 1
            candidate = ""
        }
        inside && /^[[:space:]]*const-string(\/jumbo)?[[:space:]].*"[0-9]+"/ {
            if (match($0, /"[0-9]+"/))
                candidate = substr($0, RSTART + 1, RLENGTH - 2)
        }
        inside && /"ro\.vendor\.nfc\.info\.antpos"/ {
            print candidate
            exit
        }
        inside && /^\.end method/ { inside = 0 }
    ' "$SMALI_FILE"
}

_PATCH_NFC_ANTPOS()
{
    local SMALI_FILE="$1"
    local SMALI_RELATIVE="$2"
    local METHOD="$3"
    local COMPILED_ANTPOS

    COMPILED_ANTPOS="$(_GET_COMPILED_NFC_ANTPOS "$SMALI_FILE" "$METHOD")"

    if [ -z "$COMPILED_ANTPOS" ]; then
        LOGW "Could not find the compiled NFC antenna position in $SMALI_RELATIVE"
        return 0
    elif [ "$COMPILED_ANTPOS" = "$NFC_TARGET_ANTPOS" ]; then
        LOG "- NFC antenna position already matches in $SMALI_RELATIVE"
        return 0
    fi

    SMALI_PATCH "system" "$NFC_SETTINGS_APK" "$SMALI_RELATIVE" \
        "replace" "$METHOD" "$COMPILED_ANTPOS" "$NFC_TARGET_ANTPOS"
}

LOG_STEP_IN "- Matching NFC antenna guide to target position $NFC_TARGET_ANTPOS"

DECODE_APK "system" "$NFC_SETTINGS_APK"
NFC_APKTOOL_PATH="$APKTOOL_DIR/system/${NFC_SETTINGS_APK//system\//}"

NFC_GUIDE_SMALI="$(find "$NFC_APKTOOL_PATH" -type f \
    -path '*/com/samsung/android/settings/nfc/NfcAntennaGuideDialog.smali' -print -quit)"
NFC_SETTINGS_SMALI="$(find "$NFC_APKTOOL_PATH" -type f \
    -path '*/com/samsung/android/settings/nfc/NfcSettings.smali' -print -quit)"

if [ ! -f "$NFC_GUIDE_SMALI" ] || [ ! -f "$NFC_SETTINGS_SMALI" ]; then
    LOGW "SecSettings does not contain the expected NFC antenna guide classes; skipping"
else
    NFC_GUIDE_SMALI="${NFC_GUIDE_SMALI#"$NFC_APKTOOL_PATH/"}"
    NFC_SETTINGS_SMALI="${NFC_SETTINGS_SMALI#"$NFC_APKTOOL_PATH/"}"

    _PATCH_NFC_ANTPOS "$NFC_APKTOOL_PATH/$NFC_GUIDE_SMALI" \
        "$NFC_GUIDE_SMALI" "onCreate(Landroid/os/Bundle;)V"
    _PATCH_NFC_ANTPOS "$NFC_APKTOOL_PATH/$NFC_SETTINGS_SMALI" \
        "$NFC_SETTINGS_SMALI" \
        "populateViewForOrientation(Lcom/android/settingslib/widget/LayoutPreference;)V"
fi

LOG_STEP_OUT

unset NFC_SETTINGS_APK NFC_TARGET_ANTPOS NFC_APKTOOL_PATH
unset NFC_GUIDE_SMALI NFC_SETTINGS_SMALI
unset -f _GET_COMPILED_NFC_ANTPOS _PATCH_NFC_ANTPOS
