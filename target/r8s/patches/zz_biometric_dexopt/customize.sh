# SPDX-License-Identifier: GPL-3.0-or-later
SKIPUNZIP=1

if [[ "$TARGET_CODENAME" != "r8s" || "$SOURCE_PLATFORM_SDK_VERSION" -lt 36 ]]; then
    return 0
fi

DECODE_APK "system" "system/framework/services.jar" || return 1
python3 "$SRC_DIR/target/r8s/optimize_biometric_dexopt.py" \
    "$APKTOOL_DIR/system/framework/services.jar" || return 1
