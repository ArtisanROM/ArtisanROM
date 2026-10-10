#!/usr/bin/env bash
# Copyright (c) 2026 At30c
# SPDX-License-Identifier: GPL-3.0-or-later

SKIPUNZIP=1

# The Android 16 SurfaceFlinger binary pairs an AOSP RenderEngine (Skia/Ganesh
# on top of the stock Exynos 990 Mali/EGL driver) with vendor gralloc buffers.
# When a video decoder (AV1 via Dav1d in Instagram/TikTok) hands SurfaceFlinger
# a 10-bit HDR YCBCR_P010 (format 0x36) AHardwareBuffer, the vendor EGL image
# creation fails with EGL_BAD_ALLOC. GaneshBackendTexture then ends up invalid
# and its constructor treats that as unrecoverable:
#
#   LOG_ALWAYS_FATAL("Failed to create a valid texture. ...")
#
# __android_log_assert() calls abort(), so the SIGABRT in the RenderEngine
# thread takes SurfaceFlinger down and the platform recovers with a soft reboot.
#
# Redirect the three texture validation branches (isValid / width / height)
# from the LOG_ALWAYS_FATAL block to the constructor epilogue. The invalid
# texture is then returned to the caller, which already handles the
# !isValid() case, instead of killing the process.

SF="$WORK_DIR/system/system/bin/surfaceflinger"

if [ ! -f "$SF" ]; then
    LOG "- SurfaceFlinger binary not found; skipping RenderEngine P010 compatibility patch"
    return 0
fi

# <from> <to> for each known Android 16 SurfaceFlinger build. The first pattern
# matches e2sxxx/b0sxxx/r9sxxx, the second b0qxxx/r9qxxx.
SF_PATCHES="
410300542403003405030034 2102005404020034e5010034
810200546402003445020034 610100544401003425010034
"

SF_PATCHED=false
while read -r SF_FROM SF_TO; do
    [ "$SF_FROM" ] || continue

    if xxd -p -c 0 "$SF" | grep -q "$SF_FROM"; then
        LOG "- Letting SurfaceFlinger RenderEngine reject un-importable video textures"
        HEX_PATCH "$SF" "$SF_FROM" "$SF_TO" || return 1
        SF_PATCHED=true
    fi
done <<< "$SF_PATCHES"

if ! $SF_PATCHED; then
    LOG "- SurfaceFlinger is not a known Android 16 build; skipping RenderEngine P010 compatibility patch"
fi

unset SF SF_PATCHES SF_FROM SF_TO SF_PATCHED

return 0
