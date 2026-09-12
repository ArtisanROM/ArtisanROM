#!/usr/bin/env bash
# Copyright (c) 2026 At30c
# SPDX-License-Identifier: GPL-3.0-or-later

SKIPUNZIP=1

TARGET_FIRMWARE_PATH="$(cut -d "/" -f 1 -s <<< "$TARGET_FIRMWARE")_$(cut -d "/" -f 2 -s <<< "$TARGET_FIRMWARE")"
TARGET_UWB_PERMISSION="$FW_DIR/$TARGET_FIRMWARE_PATH/vendor/etc/permissions/android.hardware.uwb.xml"

if [ ! -f "$TARGET_UWB_PERMISSION" ]; then
    LOG "- Target has no UWB hardware declaration; skipping Samsung UWB framework patch"
    unset TARGET_FIRMWARE_PATH TARGET_UWB_PERMISSION
    return 0
fi

PARTITION="system"
JAR="system/framework/semuwb-service.jar"
SMALI="smali/com/samsung/android/server/uwb/SamsungExtension.smali"
CALLBACK_SMALI="smali/com/samsung/android/server/uwb/UwbVendorExtensionWrapper\$1.smali"

if [ ! -f "$WORK_DIR/$PARTITION/$JAR" ]; then
    LOG "- Samsung UWB framework is not present; skipping"
    unset TARGET_FIRMWARE_PATH TARGET_UWB_PERMISSION PARTITION JAR SMALI \
        CALLBACK_SMALI
    return 0
fi

DECODE_APK "$PARTITION" "$JAR" || return 1

SMALI_PATH="$APKTOOL_DIR/$PARTITION/${JAR//system\//}/$SMALI"
CALLBACK_PATH="$APKTOOL_DIR/$PARTITION/${JAR//system\//}/$CALLBACK_SMALI"
LISTENER_CALL='invoke-virtual {v0, p0}, Lcom/samsung/android/server/uwb/UwbVendorExtensionWrapper;->setDeviceListener(Lcom/samsung/android/server/uwb/IVendorExtension$DeviceNotification;)V'
DEFERRED_CALL='invoke-virtual {v1, p0}, Lcom/samsung/android/server/uwb/UwbVendorExtensionWrapper;->setDeviceListener(Lcom/samsung/android/server/uwb/IVendorExtension$DeviceNotification;)V'
ENABLE_ASSIGN='iput-object v1, p0, Lcom/samsung/android/server/uwb/SamsungExtension;->mEnableTask:Lcom/samsung/android/server/uwb/SamsungUwbEnableTask;'

if [ ! -f "$SMALI_PATH" ] || [ ! -f "$CALLBACK_PATH" ]; then
    LOGE "Smali not found: /$PARTITION/$JAR/$SMALI"
    return 1
fi

# Cached or previously patched trees are safe to reuse only when registration
# is already located after mEnableTask has been initialized.
if awk -v ENABLE="$ENABLE_ASSIGN" -v CALL="$DEFERRED_CALL" '
    {
        line = $0
        gsub(/^[ \t]+|[ \t]+$/, "", line)
        if (line == ENABLE) initialized = 1
        if (line == CALL && initialized) found = 1
    }
    END { exit(found ? 0 : 1) }
' "$SMALI_PATH"; then
    LOG "- UWB listener registration is already deferred; skipping"
else
    LOG "- Moving UWB listener registration after framework initialization"

    if ! awk -v OLD_CALL="$LISTENER_CALL" -v ENABLE="$ENABLE_ASSIGN" -v NEW_CALL="$DEFERRED_CALL" '
    {
        line = $0
        gsub(/^[ \t]+|[ \t]+$/, "", line)

        if (line == OLD_CALL && !removed) {
            removed = 1
            next
        }

        print

        if (line == ENABLE && !inserted) {
            print ""
            print "    iget-object v1, p0, Lcom/samsung/android/server/uwb/SamsungExtension;->mVendorExtensionWrapper:Lcom/samsung/android/server/uwb/UwbVendorExtensionWrapper;"
            print ""
            print "    " NEW_CALL
            inserted = 1
        }
    }
        END {
            if (!removed || !inserted) exit 42
        }
    ' "$SMALI_PATH" > "$SMALI_PATH.tmp"; then
        rm -f "$SMALI_PATH.tmp"
        LOGE "Could not relocate UWB listener registration in /$PARTITION/$JAR/$SMALI"
        return 1
    fi

    mv -f "$SMALI_PATH.tmp" "$SMALI_PATH"
fi

# Some UWB HALs send the initial device-state callback synchronously. Even
# with deferred registration, that callback can win the race and reach the
# wrapper while mDeviceNotification is still null, crashing system_server.
if grep -q ':cond_unica_no_device_listener' "$CALLBACK_PATH"; then
    LOG "- UWB early-callback guard is already present; skipping"
else
    LOG "- Guarding UWB device notifications received before listener setup"

    if ! awk '
        /^\.method public onDeviceStatusNotificationReceived\(Landroid\/os\/PersistableBundle;\)V$/ {
            in_method = 1
        }

        in_method && /-\$\$Nest\$fgetmDeviceNotification/ {
            waiting_result = 1
        }

        in_method && waiting_result && /^[ \t]*move-result-object v1[ \t]*$/ {
            print
            print ""
            print "    if-eqz v1, :cond_unica_no_device_listener"
            waiting_result = 0
            inserted_guard = 1
            next
        }

        in_method && inserted_guard && /^[ \t]*return-void[ \t]*$/ && !inserted_label {
            print "    :cond_unica_no_device_listener"
            inserted_label = 1
        }

        { print }

        in_method && /^\.end method$/ {
            in_method = 0
        }

        END {
            if (!inserted_guard || !inserted_label) exit 42
        }
    ' "$CALLBACK_PATH" > "$CALLBACK_PATH.tmp"; then
        rm -f "$CALLBACK_PATH.tmp"
        LOGE "Could not add the early-callback guard in /$PARTITION/$JAR/$CALLBACK_SMALI"
        return 1
    fi

    mv -f "$CALLBACK_PATH.tmp" "$CALLBACK_PATH"
fi

unset TARGET_FIRMWARE_PATH TARGET_UWB_PERMISSION PARTITION JAR SMALI \
    CALLBACK_SMALI SMALI_PATH CALLBACK_PATH LISTENER_CALL DEFERRED_CALL \
    ENABLE_ASSIGN
