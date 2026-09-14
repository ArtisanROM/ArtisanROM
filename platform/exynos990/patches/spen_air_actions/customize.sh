#!/usr/bin/env bash
# Copyright (c) 2026 At30c
# SPDX-License-Identifier: GPL-3.0-or-later

SKIPUNZIP=1

TARGET_FIRMWARE_PATH="$(cut -d "/" -f 1 -s <<< "$TARGET_FIRMWARE")_$(cut -d "/" -f 2 -s <<< "$TARGET_FIRMWARE")"
TARGET_AIRCOMMAND="$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/priv-app/AirCommand/AirCommand.apk"
TARGET_PEN_SOUNDS="$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/media/audio/pensounds"

if [ ! -f "$TARGET_AIRCOMMAND" ] || [ ! -d "$TARGET_PEN_SOUNDS" ]; then
    LOG "- Target has no complete S Pen stack; skipping AirCommand compatibility package"
    unset TARGET_FIRMWARE_PATH TARGET_AIRCOMMAND TARGET_PEN_SOUNDS
    return 0
fi

LOG "- Installing One UI 6.0 AirCommand compatibility package for Exynos 990 S Pen target"
ADD_TO_WORK_DIR "$MODPATH" "system" \
    "system/priv-app/AirCommand/AirCommand.apk" \
    0 0 644 "u:object_r:system_file:s0"

# Exynos 990 stock firmware defines this read-only framework property in the
# vendor partition. Android 16 rejects vendor_init setting an unnamespaced
# default_prop, leaving the SMPS/S Pen feature disabled at runtime. Define it
# from the system partition instead and remove the rejected vendor copy.
SET_PROP "vendor" "ro.smps.enable" --delete
SET_PROP "system" "ro.smps.enable" "true"

unset TARGET_FIRMWARE_PATH TARGET_AIRCOMMAND TARGET_PEN_SOUNDS
