SKIPUNZIP=1

ADD_TO_WORK_DIR "$MODPATH" "system" "."

DECODE_APK "system" "system/priv-app/SamsungCamera/SamsungCamera.apk"

APPLY_PATCH "system" "system/priv-app/SamsungCamera/SamsungCamera.apk" \
    "$MODPATH/smali/system/priv-app/SamsungCamera/SamsungCamera.apk/0001-Fix-camera-crash-make-LlHdrNodeChainComposer.configure-a-no-op.patch"
