# The test7 recovery change passed the former LIVE_FOCUS_LITE shortcut crash.
# Keep this separate from the pending resolution-enum camera fix.
if [[ "$TARGET_CODENAME" == "r8s" && "$SOURCE_PLATFORM_SDK_VERSION" -ge 36 ]]; then
    python3 "$SRC_DIR/target/r8s/normalize_camera_modes.py" \
        "$WORK_DIR/system/system/cameradata/camera-feature.xml" || return 1
fi
