# One UI 8.5 ships framework classes3.dex at the 65,535 method-reference
# limit. Keybox/PIF add cross-dex hook references to classes in this dex, so
# leave some headroom by relocating an unrelated framework class to classes6.
# The class descriptor is unchanged; only its dex container is different.
if [ "$SOURCE_PLATFORM_SDK_VERSION" -ge 36 ] && \
        [ -f "$APKTOOL_DIR/system/framework/framework.jar/smali_classes3/android/os/BaseBundle.smali" ]; then
    LOG "- Rebalancing framework multidex for Keybox/PIF hooks"
    EVAL "mkdir -p \"$APKTOOL_DIR/system/framework/framework.jar/smali_classes6/android/os\""
    EVAL "mv \"$APKTOOL_DIR/system/framework/framework.jar/smali_classes3/android/os/BaseBundle.smali\" \"$APKTOOL_DIR/system/framework/framework.jar/smali_classes6/android/os/BaseBundle.smali\""
fi
