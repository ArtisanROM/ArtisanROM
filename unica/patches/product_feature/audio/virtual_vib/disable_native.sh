# SPDX-License-Identifier: GPL-3.0-or-later
# Disable the unsupported virtual vibration *sound* at its playback boundary.
# Keep actual haptics, Bluetooth routing, constructors, fields and callers intact.

DECODE_APK "system" "system/framework/services.jar"
R8S_VIB_HELPER="$(find "$APKTOOL_DIR/system/framework/services.jar" -type f \
    -path '*/com/android/server/vibrator/VirtualVibSoundHelper.smali' -printf '%P\n')"
if [[ -z "$R8S_VIB_HELPER" || "$R8S_VIB_HELPER" == *$'\n'* ]]; then
    ABORT "Expected one Android 16 VirtualVibSoundHelper for the r8s sound adaptation"
fi

# Method descriptors are stable interfaces; dex splits, registers, labels and
# synthetic lambda numbers are not. Retain the methods so existing callers
# cannot encounter NoSuchMethodError or verifier failures from deleted fields.
SMALI_PATCH "system" "system/framework/services.jar" "$R8S_VIB_HELPER" "null" \
    "playVirtualSoundIfNeeded(Ljava/lang/String;Landroid/os/VibrationAttributes;Z)V"
SMALI_PATCH "system" "system/framework/services.jar" "$R8S_VIB_HELPER" "null" \
    "stopVirtualSound(Ljava/lang/String;)V"

DECODE_APK "system" "system/priv-app/SecSettings/SecSettings.apk"
R8S_VIB_CONTROLLER="$(find "$APKTOOL_DIR/system/priv-app/SecSettings/SecSettings.apk" -type f \
    -path '*/com/samsung/android/settings/asbase/vibration/VirtualVibrationSoundPreferenceController.smali' \
    -printf '%P\n')"
if [[ -z "$R8S_VIB_CONTROLLER" || "$R8S_VIB_CONTROLLER" == *$'\n'* ]]; then
    ABORT "Expected one virtual vibration sound preference controller"
fi
SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" "$R8S_VIB_CONTROLLER" \
    "return" "getAvailabilityStatus()I" "3"

# SettingsProvider's existing key is harmless: both sound entry points above
# are disabled even if a backup restores vibration_sound_enabled=1. Do not
# rewrite its database migration or remove unrelated Settings reset logic.
LOG "- Disabled r8s virtual vibration sound; native haptics and Bluetooth retained"
unset R8S_VIB_HELPER R8S_VIB_CONTROLLER
