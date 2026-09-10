#!/usr/bin/env bash
# Copyright (c) 2026 At30c
# SPDX-License-Identifier: GPL-3.0-or-later

SKIPUNZIP=1

PARTITION="system"
JAR="system/framework/semuwb-service.jar"
SMALI="smali/com/samsung/android/server/uwb/SamsungExtension.smali"

DECODE_APK "$PARTITION" "$JAR" || return 1

SMALI_PATH="$APKTOOL_DIR/$PARTITION/${JAR//system\//}/$SMALI"
LISTENER_CALL='invoke-virtual {v0, p0}, Lcom/samsung/android/server/uwb/UwbVendorExtensionWrapper;->setDeviceListener(Lcom/samsung/android/server/uwb/IVendorExtension$DeviceNotification;)V'
DEFERRED_CALL='invoke-virtual {v1, p0}, Lcom/samsung/android/server/uwb/UwbVendorExtensionWrapper;->setDeviceListener(Lcom/samsung/android/server/uwb/IVendorExtension$DeviceNotification;)V'
ENABLE_ASSIGN='iput-object v1, p0, Lcom/samsung/android/server/uwb/SamsungExtension;->mEnableTask:Lcom/samsung/android/server/uwb/SamsungUwbEnableTask;'

if [ ! -f "$SMALI_PATH" ]; then
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
    return 0
fi

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

unset PARTITION JAR SMALI SMALI_PATH LISTENER_CALL DEFERRED_CALL ENABLE_ASSIGN
