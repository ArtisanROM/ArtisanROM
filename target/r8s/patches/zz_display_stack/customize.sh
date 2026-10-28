# SPDX-License-Identifier: GPL-3.0-or-later
SKIPUNZIP=1

if [[ "$TARGET_CODENAME" != "r8s" || "$SOURCE_PLATFORM_SDK_VERSION" -lt 36 ]]; then
    return 0
fi

R8S_DISPLAY_BLOBS="$SRC_DIR/target/r8s/blobs/display/system"
# Check the exact source GUI ABI and all immediate native dependencies before
# overwriting anything. A newer source must receive an explicit compatibility
# review, rather than silently mixing different BufferQueue object layouts.
python3 "$SRC_DIR/target/r8s/validate_display_stack.py" \
    "$R8S_DISPLAY_BLOBS" "$WORK_DIR/system/system" || return 1

ADD_TO_WORK_DIR "$SRC_DIR/target/r8s/blobs/display" "system" "system/bin/surfaceflinger" \
    0 2000 755 "u:object_r:surfaceflinger_exec:s0" || return 1
for R8S_DISPLAY_DSO in libgui.so libui.so; do
    ADD_TO_WORK_DIR "$SRC_DIR/target/r8s/blobs/display" "system" "system/lib64/$R8S_DISPLAY_DSO" \
        0 0 644 "u:object_r:system_lib_file:s0" || return 1
done

unset R8S_DISPLAY_BLOBS R8S_DISPLAY_DSO
