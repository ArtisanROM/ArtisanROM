# Show battery regulatory info in Settings
# Requires SEM_BATTERY_PROPERTY_IC_AUTHENTICATION_RESULT support
if [ "$(GET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_BATTERY_SUPPORT_BSOH_SETTINGS")" ]; then
    SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_BATTERY_SUPPORT_BSOH_SETTINGS" --delete
fi
SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_SETTINGS_ENABLE_EU_BATTERY_REGULATORY" "TRUE"

SMALI_PATCH "system" "system/framework/framework.jar" \
    "smali/android/app/Instrumentation.smali" "replace" \
    'newApplication(Ljava/lang/Class;Landroid/content/Context;)Landroid/app/Application;' \
    'invoke-virtual {p0, p1}, Landroid/app/Application;->attach(Landroid/content/Context;)V' \
    '    invoke-virtual {p0, p1}, Landroid/app/Application;->attach(Landroid/content/Context;)V\n\n    invoke-static {p1}, Lio/mesalabs/unica/SamsungPropsHooks;->init(Landroid/content/Context;)V' \
    > /dev/null
SMALI_PATCH "system" "system/framework/framework.jar" \
    "smali/android/app/Instrumentation.smali" "replace" \
    'newApplication(Ljava/lang/ClassLoader;Ljava/lang/String;Landroid/content/Context;)Landroid/app/Application;' \
    'invoke-virtual {p0, p3}, Landroid/app/Application;->attach(Landroid/content/Context;)V' \
    '    invoke-virtual {p0, p3}, Landroid/app/Application;->attach(Landroid/content/Context;)V\n\n    invoke-static {p3}, Lio/mesalabs/unica/SamsungPropsHooks;->init(Landroid/content/Context;)V' \
    > /dev/null

DECODE_APK "system" "system/priv-app/SecSettings/SecSettings.apk"
SECSETTINGS_APK="$APKTOOL_DIR/system/priv-app/SecSettings/SecSettings.apk"

# Disable stock OTA references
if [ ! -f "$WORK_DIR/system/system/priv-app/ChoiDujour/ChoiDujour.apk" ]; then
    SOFTWARE_UPDATE_UTILS="$(find "$SECSETTINGS_APK" \
        -type f -path '*/com/samsung/android/settings/softwareupdate/SoftwareUpdateUtils.smali' -printf '%P\n' -quit)"
    [ "$SOFTWARE_UPDATE_UTILS" ] || ABORT "SoftwareUpdateUtils.smali not found"
    SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
        "$SOFTWARE_UPDATE_UTILS" "return" \
        'isOTAUpgradeAllowed(Landroid/content/Context;)Z' \
        'false'
    unset SOFTWARE_UPDATE_UTILS
fi

# Always show One UI minor version
ONEUI_VERSION_CONTROLLER="$(find "$SECSETTINGS_APK" -type f \
    -path '*/com/samsung/android/settings/deviceinfo/softwareinfo/OneUIVersionPreferenceController.smali' \
    -printf '%P\n' -quit)"
[ "$ONEUI_VERSION_CONTROLLER" ] || ABORT "OneUIVersionPreferenceController.smali not found"
SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
    "$ONEUI_VERSION_CONTROLLER" "replace" \
    'isDeviceWithMicroVersion()Z' \
    'move-result p0' \
    'const/4 p0, 0x1'

# Show real device model number
MODEL_NAME_GETTER="$(find "$SECSETTINGS_APK" -type f \
    -path '*/com/samsung/android/settings/deviceinfo/aboutphone/ModelNameGetter.smali' \
    -printf '%P\n' -quit)"
[ "$MODEL_NAME_GETTER" ] || ABORT "ModelNameGetter.smali not found"
SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
    "$MODEL_NAME_GETTER" "replace" \
    'getModelName()Ljava/lang/String;' \
    'ro.product.model' \
    'ro.boot.em.model'

LOG_STEP_IN "- Adding UN1CA Settings"

# Dynamically patch SecSettings
# - Add missing/non-xml files in place
# - Patch existing files
#   - Use the first line of the file to tell sed how to apply the rest of the content
#   - Exception made for files under *res/values* where the "resources" tag gets nuked
while IFS= read -r f; do
    f="${f//$MODPATH\/SecSettings.apk\//}"

    if [ ! -f "$APKTOOL_DIR/system/priv-app/SecSettings/SecSettings.apk/$f" ] || \
            [[ "$f" != *".xml" ]]; then
        LOG "- Adding \"$f\" to /system/system/priv-app/SecSettings.apk"
        EVAL "mkdir -p \"$(dirname "$APKTOOL_DIR/system/priv-app/SecSettings/SecSettings.apk/$f")\""
        EVAL "cp -a \"$MODPATH/SecSettings.apk/${f//\$/\\$}\" \"$APKTOOL_DIR/system/priv-app/SecSettings/SecSettings.apk/${f//\$/\\$}\""
    else
        LOG "- Patching \"$f\" in /system/system/priv-app/SecSettings.apk"
        if [[ "$f" == *"res/values"* ]]; then
            PATCH_INST="/<\/resources>/i"
            CONTENT="$(sed -e "/?xml/d" -e "/resources>/d" "$MODPATH/SecSettings.apk/$f")"
        else
            PATCH_INST="$(head -n 1 "$MODPATH/SecSettings.apk/$f")"
            CONTENT="$(tail -n +2 "$MODPATH/SecSettings.apk/$f")"
        fi
        CONTENT="$(sed -e "s/\"/\\\\\"/g" -e "s/\\$/\\\\$/g" -e "s/ /\\\ /g" -e "s/\\\\n/\\\\\\\\\n/g" <<< "$CONTENT")"
        CONTENT="$(sed -E ':a;N;$!ba;s/\r{0,1}\n/\\n/g' <<< "$CONTENT")"
        EVAL "sed -i \"$PATCH_INST $CONTENT\" \"$APKTOOL_DIR/system/priv-app/SecSettings/SecSettings.apk/$f\""
    fi
done < <(find "$MODPATH/SecSettings.apk" -type f)

# Add UN1CA Settings SearchIndexableData registrations
SEARCH_INDEXABLE_RESOURCES="$(find "$SECSETTINGS_APK" -type f \
    -path '*/com/android/settingslib/search/SearchIndexableResourcesMobile.smali' -printf '%P\n' -quit)"
SEARCH_FEATURE_PROVIDER="$(find "$SECSETTINGS_APK" -type f \
    -path '*/com/android/settings/search/SearchFeatureProviderImpl$$ExternalSyntheticLambda0.smali' \
    -printf '%P\n' -quit)"
[ "$SEARCH_INDEXABLE_RESOURCES" ] || ABORT "SearchIndexableResourcesMobile.smali not found"
[ "$SEARCH_FEATURE_PROVIDER" ] || ABORT "SearchFeatureProviderImpl lambda not found"
LOG "- Patching \"$SEARCH_INDEXABLE_RESOURCES\" in /system/system/priv-app/SecSettings.apk"
SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
    "$SEARCH_INDEXABLE_RESOURCES" "replaceall" \
    '.class public final Lcom/android/settingslib/search/SearchIndexableResourcesMobile;' \
    '.class public Lcom/android/settingslib/search/SearchIndexableResourcesMobile;' \
    > /dev/null
LOG "- Patching \"$SEARCH_FEATURE_PROVIDER\" in /system/system/priv-app/SecSettings.apk"
SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
    "$SEARCH_FEATURE_PROVIDER" "replace" \
    'invoke()Ljava/lang/Object;' \
    'return-object p0' \
    '    invoke-static {p0}, Lio/mesalabs/unica/search/UnicaSearchIndexableResources;->addIndexes(Lcom/android/settingslib/search/SearchIndexableResourcesBase;)V\n\n    return-object p0' \
    > /dev/null

DECODE_APK "system" "system/priv-app/SecSettingsIntelligence/SecSettingsIntelligence.apk"
TOP_LEVEL_KEYS_COLLECTOR="$(find "$APKTOOL_DIR/system/priv-app/SecSettingsIntelligence/SecSettingsIntelligence.apk" \
    -type f -path '*/com/samsung/android/settings/intelligence/search/categorizing/TopLevelKeysCollector.smali' \
    -printf '%P\n' -quit)"
[ "$TOP_LEVEL_KEYS_COLLECTOR" ] || ABORT "TopLevelKeysCollector.smali not found"
LOG "- Patching \"$TOP_LEVEL_KEYS_COLLECTOR\" in /system/system/priv-app/SecSettingsIntelligence/SecSettingsIntelligence.apk"
SMALI_PATCH "system" "system/priv-app/SecSettingsIntelligence/SecSettingsIntelligence.apk" \
    "$TOP_LEVEL_KEYS_COLLECTOR" "replace" \
    '<init>(Landroid/content/Context;)V' \
    '.locals 36' \
    '.locals 37' \
    > /dev/null
SMALI_PATCH "system" "system/priv-app/SecSettingsIntelligence/SecSettingsIntelligence.apk" \
    "$TOP_LEVEL_KEYS_COLLECTOR" "replace" \
    '<init>(Landroid/content/Context;)V' \
    'filled-new-array/range {v1 .. v35}, [Ljava/lang/String;' \
    '    const-string v36, "top_level_unica"\n\n    filled-new-array/range {v1 .. v36}, [Ljava/lang/String;' \
    > /dev/null

# Show Vulkan renderer toggle if required
if [[ "$(GET_PROP "ro.hwui.use_vulkan")" != "true" ]]; then
    SET_PROP "system" "persist.sys.unica.vulkan" "false"
fi

unset PATCH_INST CONTENT SECSETTINGS_APK SOFTWARE_UPDATE_UTILS
unset ONEUI_VERSION_CONTROLLER MODEL_NAME_GETTER SEARCH_INDEXABLE_RESOURCES SEARCH_FEATURE_PROVIDER
unset TOP_LEVEL_KEYS_COLLECTOR

LOG_STEP_OUT
