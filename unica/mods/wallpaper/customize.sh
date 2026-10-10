#!/usr/bin/env bash
# Copyright (c) 2026 At30c
# SPDX-License-Identifier: GPL-3.0-or-later

# shellcheck disable=SC2034
SKIPUNZIP=1

# Every Exynos 990 target ships its own wallpaper-res.apk inside the matching
# prebuilt (x1s -> x1sxxx, c2s -> c2sxxx, ...). Pull the one that belongs to the
# device being built so the bundled wallpapers match its panel.
#
# The c1s/c2s prebuilts store the APK split into .00/.01/.02 parts; passing the
# file path lets ADD_TO_WORK_DIR stitch them back together.

WALLPAPER_DONOR="${TARGET_CODENAME}xxx"

if [ ! -d "$SRC_DIR/prebuilts/samsung/$WALLPAPER_DONOR" ]; then
    LOG "- No wallpaper-res donor for \"$TARGET_CODENAME\"; skipping"
    return 0
fi

LOG_STEP_IN "- Adding stock wallpapers from $WALLPAPER_DONOR"
ADD_TO_WORK_DIR "$WALLPAPER_DONOR" "system" \
    "system/priv-app/wallpaper-res/wallpaper-res.apk" \
    0 0 644 "u:object_r:system_file:s0" || return 1
LOG_STEP_OUT

unset WALLPAPER_DONOR

return 0
