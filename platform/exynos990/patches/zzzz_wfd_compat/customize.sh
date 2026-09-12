#!/usr/bin/env bash
# Copyright (c) 2026 At30c
# SPDX-License-Identifier: GPL-3.0-or-later

SKIPUNZIP=1

if [[ "$SOURCE_PLATFORM_SDK_VERSION" -lt 36 ]]; then
    LOG "- Source is not Android 16; skipping Exynos 990 WFD compatibility"
    return 0
fi

LOG_STEP_IN "- Adding Android 16 ARM32 wireless DeX/Smart View stack"

# Exynos 990 retains a 32-bit OMX service. R9s supplies an Android 16 ARM32
# RemoteDisplay stack that uses the same metadata ABI as the legacy encoder.
ADD_TO_WORK_DIR "r9sxxx" "system" "system/bin/insthk" \
    0 2000 755 "u:object_r:insthk_exec:s0" || return 1
ADD_TO_WORK_DIR "r9sxxx" "system" "system/bin/remotedisplay" \
    0 2000 755 "u:object_r:remotedisplay_exec:s0" || return 1

R9S_WFD_LIBS="
android.hardware.graphics.common-V6-ndk.so
android.hardware.graphics.composer3-V4-ndk.so
android.hardware.graphics.extension.composer3-V1-ndk.so
libhdcp2.so
libhdcp_client_aidl.so
libremotedisplay.so
libremotedisplay_wfd.so
libremotedisplayservice.so
librepeater.so
libsecuibc.so
libstagefright_hdcp.so
libtsmux.so
vendor.samsung.hardware.security.hdcp.wifidisplay-V2-ndk.so
vendor.samsung_slsi.hardware.ExynosHWCServiceTW@1.0.so
vendor.samsung_slsi.hardware.graphics.extension.composer3-V4-ndk.so
wfd_log.so
"
while IFS= read -r R9S_WFD_LIB; do
    [ "$R9S_WFD_LIB" ] || continue
    ADD_TO_WORK_DIR "r9sxxx" "system" "system/lib/$R9S_WFD_LIB" \
        0 0 644 "u:object_r:system_lib_file:s0" || return 1
done <<< "$R9S_WFD_LIBS"

# R9s advertises WFD R2/HEVC, while the target encoder uses the legacy native
# metadata layout. Skip the R2 capability fields in sendM3().
HEX_PATCH "$WORK_DIR/system/system/lib/libremotedisplay_wfd.so" \
    "94f81d0318b994f8241301290ed1" \
    "00f00fb818b994f8241301290ed1" || return 1

# Fix the ARM32 __fread_chk overflow observed when RemoteDisplay configures
# the legacy encoder. ACodec::reconfigEncoder4OtherApps reads 512 bytes into a
# 255-byte stack buffer and immediately aborts under FORTIFY. Limit the read
# to 254 bytes so the following NUL terminator remains inside the buffer. The
# surrounding Thumb instructions make this call site unique.
HEX_PATCH "$WORK_DIR/system/system/lib/libstagefright.so" \
    "01214ff4007230462b460097" \
    "01214ff0fe0230462b460097" || return 1

# Do not leave an alternative ARM64 graph that can be selected by stale
# processes in preference to the matching ARM32 stack.
R9S_WFD_64_REMOVE="
android.hardware.graphics.extension.composer3-V1-ndk.so
libhdcp2.so
libhdcp_client_aidl.so
libremotedisplay_wfd.so
libremotedisplayservice.so
librepeater.so
libsecuibc.so
libstagefright_hdcp.so
libtsmux.so
vendor.samsung.hardware.security.hdcp.wifidisplay-V2-ndk.so
wfd_log.so
"
while IFS= read -r R9S_WFD_64_LIB; do
    [ "$R9S_WFD_64_LIB" ] || continue
    DELETE_FROM_WORK_DIR "system" "system/lib64/$R9S_WFD_64_LIB"
done <<< "$R9S_WFD_64_REMOVE"

# Resolve the framework-side WFD roots recursively from the Android 16 r11s
# multilib donor. Libraries already supplied by runtime32_compat are reused.
declare -A R11S_WFD_IMPORTED=()

ADD_R11S_WFD_LIB()
{
    local LIB_NAME="$1"
    local DONOR_LIB="$SRC_DIR/prebuilts/samsung/r11sxxx/system/lib/$LIB_NAME"
    local NEEDED_LIB

    [ "${R11S_WFD_IMPORTED[$LIB_NAME]+set}" ] && return 0
    R11S_WFD_IMPORTED["$LIB_NAME"]=1
    [ -e "$WORK_DIR/system/system/lib/$LIB_NAME" ] && return 0

    if [ ! -f "$DONOR_LIB" ]; then
        ABORT "Missing r11s ARM32 WFD dependency: system/lib/$LIB_NAME"
        return 1
    fi
    ADD_TO_WORK_DIR "r11sxxx" "system" "system/lib/$LIB_NAME" \
        0 0 644 "u:object_r:system_lib_file:s0" || return 1

    while read -r NEEDED_LIB; do
        case "$NEEDED_LIB" in
            libc.so|libdl.so|libdl_android.so|libm.so|libandroidicu.so)
                continue
                ;;
        esac
        ADD_R11S_WFD_LIB "$NEEDED_LIB" || return 1
    done < <(readelf -d "$DONOR_LIB" 2>/dev/null | \
        sed -n 's/.*(NEEDED).*\[\(.*\)\].*/\1/p')
}

for WFD_RUNTIME_ROOT in libsfextcp.so libinput.so libmemunreachable.so; do
    ADD_R11S_WFD_LIB "$WFD_RUNTIME_ROOT" || return 1
done

# Reject incomplete or mixed-architecture dependency graphs during the build.
declare -A ARM32_WFD_VALIDATED=()

VALIDATE_ARM32_WFD_ELF()
{
    local ELF_PATH="$1"
    local ELF_NAME="${ELF_PATH##*/}"
    local NEEDED_LIB
    local NEEDED_PATH

    [ "${ARM32_WFD_VALIDATED[$ELF_NAME]+set}" ] && return 0
    ARM32_WFD_VALIDATED["$ELF_NAME"]=1

    if [ ! -f "$ELF_PATH" ]; then
        ABORT "Missing ARM32 WFD dependency: $ELF_NAME"
        return 1
    fi
    if ! LC_ALL=C readelf -h "$ELF_PATH" 2>/dev/null | grep -q 'ELF32'; then
        ABORT "ARM32 WFD dependency is not ELF32: $ELF_NAME"
        return 1
    fi

    while read -r NEEDED_LIB; do
        case "$NEEDED_LIB" in
            libc.so|libdl.so|libdl_android.so|libm.so|libandroidicu.so)
                continue
                ;;
        esac
        NEEDED_PATH="$WORK_DIR/system/system/lib/$NEEDED_LIB"
        if [ ! -f "$NEEDED_PATH" ]; then
            ABORT "$ELF_NAME requires missing ARM32 library: $NEEDED_LIB"
            return 1
        fi
        VALIDATE_ARM32_WFD_ELF "$NEEDED_PATH" || return 1
    done < <(readelf -d "$ELF_PATH" 2>/dev/null | \
        sed -n 's/.*(NEEDED).*\[\(.*\)\].*/\1/p')
}

VALIDATE_ARM32_WFD_ELF \
    "$WORK_DIR/system/system/bin/remotedisplay" || return 1
LOG "  - ARM32 RemoteDisplay dependency graph validated"

unset R9S_WFD_LIBS R9S_WFD_LIB R9S_WFD_64_REMOVE R9S_WFD_64_LIB \
    WFD_RUNTIME_ROOT R11S_WFD_IMPORTED ARM32_WFD_VALIDATED
unset -f ADD_R11S_WFD_LIB VALIDATE_ARM32_WFD_ELF

LOG_STEP_OUT
