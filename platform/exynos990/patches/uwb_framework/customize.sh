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

if [ ! -f "$WORK_DIR/$PARTITION/$JAR" ]; then
    LOG "- Samsung UWB framework is not present; skipping"
    unset TARGET_FIRMWARE_PATH TARGET_UWB_PERMISSION PARTITION JAR SMALI
    return 0
fi

DECODE_APK "$PARTITION" "$JAR" || return 1

SMALI_PATH="$APKTOOL_DIR/$PARTITION/${JAR//system\//}/$SMALI"
LISTENER_SIGNATURE='Lcom/samsung/android/server/uwb/UwbVendorExtensionWrapper;->setDeviceListener(Lcom/samsung/android/server/uwb/IVendorExtension$DeviceNotification;)V'
FINAL_LISTENER_CALL='invoke-virtual {v1, p0}, Lcom/samsung/android/server/uwb/UwbVendorExtensionWrapper;->setDeviceListener(Lcom/samsung/android/server/uwb/IVendorExtension$DeviceNotification;)V'

if [ ! -f "$SMALI_PATH" ]; then
    LOGE "Smali not found: /$PARTITION/$JAR/$SMALI"
    return 1
fi

# Some vendor HALs invoke the device callback synchronously from
# setDeviceListener(). Do not expose SamsungExtension until every constructor
# branch has finished initializing its fields and receivers. The patch is
# considered applied only when every constructor return is immediately
# preceded by listener registration.
if awk -v CALL="$FINAL_LISTENER_CALL" '
    /^\.method public constructor <init>\(Landroid\/content\/Context;\)V$/ {
        in_constructor = 1
    }

    in_constructor {
        line = $0
        gsub(/^[ \t]+|[ \t]+$/, "", line)

        if (line == "return-void") {
            returns++
            if (last_instruction == CALL) safe_returns++
        }

        if (line != "" && line !~ /^:/ && line !~ /^\./ && line !~ /^#/) {
            last_instruction = line
        }
    }

    in_constructor && /^\.end method$/ {
        in_constructor = 0
    }

    END { exit(returns > 0 && safe_returns == returns ? 0 : 1) }
' "$SMALI_PATH"; then
    LOG "- UWB listener registration is already at constructor exits; skipping"
else
    LOG "- Moving UWB listener registration to the end of each constructor branch"

    if ! awk -v SIGNATURE="$LISTENER_SIGNATURE" -v NEW_CALL="$FINAL_LISTENER_CALL" '
        /^\.method public constructor <init>\(Landroid\/content\/Context;\)V$/ {
            in_constructor = 1
        }

        in_constructor {
            line = $0
            gsub(/^[ \t]+|[ \t]+$/, "", line)

            if (index(line, SIGNATURE) != 0) {
                removed++
                next
            }

            if (line == "return-void") {
                print ""
                print "    iget-object v1, p0, Lcom/samsung/android/server/uwb/SamsungExtension;->mVendorExtensionWrapper:Lcom/samsung/android/server/uwb/UwbVendorExtensionWrapper;"
                print ""
                print "    " NEW_CALL
                print ""
                inserted++
            }
        }

        { print }

        in_constructor && /^\.end method$/ {
            in_constructor = 0
        }

        END {
            if (removed < 1 || inserted < 1) exit 42
        }
    ' "$SMALI_PATH" > "$SMALI_PATH.tmp"; then
        rm -f "$SMALI_PATH.tmp"
        LOGE "Could not relocate UWB listener registration in /$PARTITION/$JAR/$SMALI"
        return 1
    fi

    mv -f "$SMALI_PATH.tmp" "$SMALI_PATH"
fi

unset TARGET_FIRMWARE_PATH TARGET_UWB_PERMISSION PARTITION JAR SMALI SMALI_PATH \
    LISTENER_SIGNATURE FINAL_LISTENER_CALL
