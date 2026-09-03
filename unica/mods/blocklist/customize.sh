DELETE_FROM_WORK_DIR "system" "system/etc/ldu_blocklist.xml"

APPLY_PATCH "system" "system/framework/services.jar" \
    "$MODPATH/services.jar/0001-Allow-custom-PackageBlockListPolicy.patch"
