# SPDX-License-Identifier: GPL-3.0-or-later
SKIPUNZIP=1

if [[ "$TARGET_CODENAME" != "r8s" || "$SOURCE_PLATFORM_SDK_VERSION" -lt 36 ]]; then
    return 0
fi

# Keep the donor APK, resources, native libraries and existing hardware fixes.
# BUILD_APKS rebuilds and signs this same decoded APK after all target patches.
DECODE_APK "system_ext" "priv-app/SystemUI/SystemUI.apk" || return 1
python3 "$SRC_DIR/target/r8s/optimize_systemui_diagnostics.py" \
    "$APKTOOL_DIR/system_ext/priv-app/SystemUI/SystemUI.apk" || return 1
