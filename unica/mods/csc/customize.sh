# SET_CSC_FEATURE_CONFIG "<config>" "<value>"
# Sets the supplied config to the desidered value.
# "-d" or "--delete" can be passed as value to delete the config.
SET_CSC_FEATURE_CONFIG()
{
    local CONFIG="$1"
    local VALUE="$2"

    if grep -q "$CONFIG" "$FILE"; then
        if [[ "$VALUE" == "-d" ]] || [[ "$VALUE" == "--delete" ]]; then
            sed -i "/$CONFIG/d" "$FILE"
        else
            sed -i "/$CONFIG/c\    <$CONFIG>$VALUE<\/$CONFIG>" "$FILE"
        fi
    elif [[ "$VALUE" != "-d" ]] && [[ "$VALUE" != "--delete" ]]; then
        if ! grep -q "Added by " "$FILE"; then
            sed -i "/<\/FeatureSet>/i \    <!-- Added by unica/mods/csc/customize.sh -->" "$FILE"
        fi
        sed -i "/<\/FeatureSet>/i \    <$CONFIG>$VALUE</$CONFIG>" "$FILE"
    fi

    return 0
}

LOG "- Patching CSC model"
SOURCE_MODEL=$(echo -n "$SOURCE_FIRMWARE" | cut -d "/" -f 1)
TARGET_MODEL=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 1)
find "$WORK_DIR/optics" -type f -exec sed -i "s/SAOMC_SM-S938B/SAOMC_${TARGET_MODEL}/g" {} +

LOG_STEP_IN "- Patching CSC Features"
while read -r FILE; do
    (
        LOG "- Decoding $FILE"
        ! grep -q 'CscFeature' "$FILE" && EVAL "$TOOLS_DIR/bin/cscdecoder --decode --in-place \"$FILE\""

        LOG_STEP_IN "- Applying CSC Tweaks"
        if $SOURCE_IS_ESIM_SUPPORTED && ! $TARGET_IS_ESIM_SUPPORTED; then
            SET_CSC_FEATURE_CONFIG "CscFeature_RIL_SupportEsim" "FALSE"
            SET_CSC_FEATURE_CONFIG "CscFeature_SetupWizard_SupportEsimAsPrimary" --delete
        fi

        SET_CSC_FEATURE_CONFIG "CscFeature_VoiceCall_ConfigRecording" "RecordingAllowed"
        SET_CSC_FEATURE_CONFIG "CscFeature_Setting_SupportRealTimeNetworkSpeed" "TRUE"
        SET_CSC_FEATURE_CONFIG "CscFeature_Setting_EnableHwVersionDisplay" "TRUE"
        SET_CSC_FEATURE_CONFIG "CscFeature_Setting_SupportMenuSmartTutor" "FALSE"
        SET_CSC_FEATURE_CONFIG "CscFeature_Setting_ConfigLongPressType" 1
        SET_CSC_FEATURE_CONFIG "CscFeature_Common_DisableBixby" --delete
        SET_CSC_FEATURE_CONFIG "CscFeature_Contact_EnableSmartCall" "TRUE"
        SET_CSC_FEATURE_CONFIG "CscFeature_Setting_ConfigOperatorCallService" "TRUE"
        SET_CSC_FEATURE_CONFIG "CscFeature_Common_ConfigHiyaService" "TRUE"
        LOG_STEP_OUT

        LOG "- Encoding $FILE"
        EVAL "$TOOLS_DIR/bin/cscdecoder --encode --in-place \"$FILE\""
    ) &
done <<< "$(find "$WORK_DIR/optics" -type f -name "cscfeature.xml")"

# shellcheck disable=SC2046
wait $(jobs -p) || exit 1
LOG_STEP_OUT

LOG_STEP_IN "- Patching APKs for network speed monitoring"

DECODE_APK "system" "system/priv-app/SecSettings/SecSettings.apk"
DECODE_APK "system_ext" "priv-app/SystemUI/SystemUI.apk"

FTP="
system/priv-app/SecSettings/SecSettings.apk/smali_classes4/com/samsung/android/settings/eternal/provider/items/NotificationsItem.smali
system/priv-app/SecSettings/SecSettings.apk/smali_classes3/com/samsung/android/settings/notification/ConfigureNotificationMoreSettings\$1.smali
system/priv-app/SecSettings/SecSettings.apk/smali_classes3/com/samsung/android/settings/notification/StatusBarNetworkSpeedController.smali
system_ext/priv-app/SystemUI/SystemUI.apk/smali/com/android/systemui/Rune.smali
system_ext/priv-app/SystemUI/SystemUI.apk/smali/com/android/systemui/QpRune.smali
"
for f in $FTP; do
    sed -i "s/CscFeature_Common_SupportZProjectFunctionInGlobal/CscFeature_Setting_SupportRealTimeNetworkSpeed/g" "$APKTOOL_DIR/$f"
done
LOG_STEP_OUT
