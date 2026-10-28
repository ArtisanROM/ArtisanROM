# SPDX-License-Identifier: GPL-3.0-or-later

SKIPUNZIP=1

if [[ "$TARGET_CODENAME" != "r8s" || "$SOURCE_PLATFORM_SDK_VERSION" -lt 36 ]]; then
    return 0
fi

R8S_GRAPHICS_SONAME="android.hardware.graphics.common-V6-ndk.so"
R8S_GRAPHICS_DEST="$WORK_DIR/system/system/lib64/$R8S_GRAPHICS_SONAME"

R8S_IS_GRAPHICS_V6_ARM64()
{
    python3 "$SRC_DIR/target/r8s/validate_graphics_dso.py" "$1" "$R8S_GRAPHICS_SONAME" > /dev/null 2>&1
}

if R8S_IS_GRAPHICS_V6_ARM64 "$R8S_GRAPHICS_DEST"; then
    LOG "- Keeping existing ARM64 Graphics Common V6 system library"
else
    # This is the S22 firmware used as the ESSI system source by the working
    # ArtisanROM 3.5.1 r8s release. Import one system DSO, never its vendor,
    # SurfaceFlinger, libui or libgui. A V7 symlink or an ARM32 DSO is not V6.
    R8S_GRAPHICS_DONOR="SM-S901B/EUX/350330051234562"
    # This exact firmware supplied the valid ARM64 V6 in the first r8s build.
    # Do not silently switch the compatibility DSO when Samsung updates FUS.
    R8S_GRAPHICS_DONOR_VERSION="S901BXXSOGZH3/S901BOXMOGZH3/S901BXXSOGZH3/S901BXXSOGZH3"
    R8S_GRAPHICS_FW="$FW_DIR/SM-S901B_EUX"
    R8S_GRAPHICS_SOURCE="$R8S_GRAPHICS_FW/system/system/lib64/$R8S_GRAPHICS_SONAME"

    if [[ ! -f "$R8S_GRAPHICS_FW/.extracted" ]] || \
            [[ "$(cat "$R8S_GRAPHICS_FW/.extracted")" != "$R8S_GRAPHICS_DONOR_VERSION" ]]; then
        LOG "- Preparing Artisan 3.5.1 system donor for r8s ARM64 graphics dependency"
        "$SRC_DIR/scripts/download_fw.sh" --force --version "$R8S_GRAPHICS_DONOR_VERSION" \
            --ignore-source --ignore-target "$R8S_GRAPHICS_DONOR" || return 1
        "$SRC_DIR/scripts/extract_fw.sh" --force --ignore-source --ignore-target "$R8S_GRAPHICS_DONOR" || return 1
    fi
    # Firmware extraction accepts both system-as-root and flat system images.
    if [[ ! -f "$R8S_GRAPHICS_SOURCE" ]]; then
        R8S_GRAPHICS_SOURCE="$R8S_GRAPHICS_FW/system/lib64/$R8S_GRAPHICS_SONAME"
    fi
    if ! R8S_IS_GRAPHICS_V6_ARM64 "$R8S_GRAPHICS_SOURCE"; then
        ABORT "The r8s S22 donor must provide a real AArch64 $R8S_GRAPHICS_SONAME; no ARM32/V7 substitution is compatible"
        return 1
    fi
    ADD_TO_WORK_DIR "$R8S_GRAPHICS_DONOR" "system" "system/lib64/$R8S_GRAPHICS_SONAME" \
        0 0 644 "u:object_r:system_lib_file:s0" || return 1
    LOG "- Installed r8s ARM64 Graphics Common V6; vendor HALs retained"
fi

unset R8S_GRAPHICS_SONAME R8S_GRAPHICS_DEST R8S_GRAPHICS_DONOR R8S_GRAPHICS_DONOR_VERSION R8S_GRAPHICS_FW R8S_GRAPHICS_SOURCE
unset -f R8S_IS_GRAPHICS_V6_ARM64
