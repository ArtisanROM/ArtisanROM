# The platform camera module has already decoded and patched the source APK.
# Copying the 3.5.1 APK now leaves that decoded tree active; BUILD_APKS later
# overwrites the copied APK with the source version. Keep one consistent
# Android 16 camera pipeline, including upstream ArcSoft EV/recording fixes.
# The old APK and its precompiled ART files remain available for older bases.
SKIPUNZIP=1

if [ "$SOURCE_PLATFORM_SDK_VERSION" -ge 36 ]; then
    LOG "- Keeping the source camera and its Exynos 990 compatibility patches"
else
    ADD_TO_WORK_DIR "$MODPATH" "system" "." 0 0 755 "u:object_r:system_file:s0"
fi
