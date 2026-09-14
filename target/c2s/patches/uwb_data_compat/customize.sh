#!/usr/bin/env bash
# Copyright (c) 2026 At30c
# SPDX-License-Identifier: GPL-3.0-or-later

SKIPUNZIP=1

UWB_INIT="system/etc/init/init.system.uwb.rc"
UWB_JAR="system/framework/semuwb-service.jar"
UWB_CALLBACK='smali/com/samsung/android/server/uwb/UwbVendorExtensionWrapper$1.smali'
VENDOR_POLICY="etc/selinux/vendor_sepolicy.cil"

if [ ! -f "$WORK_DIR/vendor/etc/permissions/android.hardware.uwb.xml" ]; then
    LOG "- UWB hardware declaration is not present; skipping c2s UWB compatibility"
    unset UWB_INIT UWB_JAR UWB_CALLBACK VENDOR_POLICY
    return 0
fi

# Samsung's Android 16 framework stores its database and SCPM data in
# /data/uwb. The Android 11 c2s vendor labels that directory as uwb_data_file,
# but only granted access to the old platform_app implementation. The current
# implementation runs inside system_server, so grant the same data access to
# the versioned system_server domain exposed to this vendor policy.
if [ ! -f "$WORK_DIR/vendor/$VENDOR_POLICY" ]; then
    LOGE "File not found: /vendor/$VENDOR_POLICY"
    return 1
fi

if ! grep -q -F '(type uwb_data_file)' "$WORK_DIR/vendor/$VENDOR_POLICY" || \
        ! grep -q -F '(typeattributeset system_server_30_0 (system_server))' \
            "$WORK_DIR/system/system/etc/selinux/mapping/30.0.cil"; then
    LOGE "Required c2s UWB SELinux types are not available"
    return 1
fi

LOG "- Granting system_server access to the legacy c2s UWB data domain"
if ! grep -q -F '(allow system_server_30_0 uwb_data_file (dir ' \
        "$WORK_DIR/vendor/$VENDOR_POLICY"; then
    printf '%s\n' \
        '(allow system_server_30_0 uwb_data_file (dir (ioctl read write create getattr setattr lock rename open watch watch_reads add_name remove_name reparent search rmdir)))' \
        >> "$WORK_DIR/vendor/$VENDOR_POLICY"
fi
if ! grep -q -F '(allow system_server_30_0 uwb_data_file (file ' \
        "$WORK_DIR/vendor/$VENDOR_POLICY"; then
    printf '%s\n' \
        '(allow system_server_30_0 uwb_data_file (file (ioctl read write create getattr setattr lock append map unlink rename open watch watch_reads)))' \
        >> "$WORK_DIR/vendor/$VENDOR_POLICY"
fi

# Both the c2s and current Samsung init scripts refer to /system/etc/uwb_key,
# although the firmware actually ships the key in /vendor/etc. Keep the
# framework-owned /data/uwb layout and source the key from its real location.
if [ ! -f "$WORK_DIR/system/$UWB_INIT" ]; then
    LOGE "File not found: /system/$UWB_INIT"
    return 1
fi

if [ ! -f "$WORK_DIR/vendor/etc/uwb_key" ]; then
    LOGE "File not found: /vendor/etc/uwb_key"
    return 1
fi

if grep -q -F 'copy /system/etc/uwb_key /data/uwb/Key' \
        "$WORK_DIR/system/$UWB_INIT"; then
    LOG "- Correcting the c2s UWB key source"
    sed -i 's|copy /system/etc/uwb_key /data/uwb/Key|copy /vendor/etc/uwb_key /data/uwb/Key|' \
        "$WORK_DIR/system/$UWB_INIT"
fi

if ! grep -q -F 'copy /vendor/etc/uwb_key /data/uwb/Key' \
        "$WORK_DIR/system/$UWB_INIT"; then
    LOGE "Could not configure the c2s UWB key source"
    return 1
fi

if ! grep -q -F 'restorecon_recursive /data/uwb' \
        "$WORK_DIR/system/$UWB_INIT"; then
    sed -i '/mkdir \/data\/uwb\/ 775 system system encryption=None/a\    restorecon_recursive /data/uwb' \
        "$WORK_DIR/system/$UWB_INIT"
fi

# A failed SamsungExtension construction must never leave an unguarded OEM
# callback capable of killing system_server.
if [ ! -f "$WORK_DIR/system/$UWB_JAR" ]; then
    LOGE "File not found: /system/$UWB_JAR"
    return 1
fi

DECODE_APK "system" "$UWB_JAR" || return 1

UWB_CALLBACK_PATH="$APKTOOL_DIR/system/${UWB_JAR//system\//}/$UWB_CALLBACK"
if [ ! -f "$UWB_CALLBACK_PATH" ]; then
    LOGE "Required Samsung UWB smali files were not found in /system/$UWB_JAR"
    return 1
fi

if grep -q -F ':cond_unica_no_device_listener' "$UWB_CALLBACK_PATH"; then
    LOG "- UWB null-listener callback guard is already present; skipping"
else
    LOG "- Guarding c2s UWB notifications received without a device listener"

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
    ' "$UWB_CALLBACK_PATH" > "$UWB_CALLBACK_PATH.tmp"; then
        rm -f "$UWB_CALLBACK_PATH.tmp"
        LOGE "Could not add the UWB callback guard in /system/$UWB_JAR/$UWB_CALLBACK"
        return 1
    fi

    mv -f "$UWB_CALLBACK_PATH.tmp" "$UWB_CALLBACK_PATH"
fi

unset UWB_INIT UWB_JAR UWB_CALLBACK VENDOR_POLICY UWB_CALLBACK_PATH
