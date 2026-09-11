# [
_LOG() { if $DEBUG; then LOGW "$1"; else ABORT "$1"; fi }

_IMPORT_LEGACY_NXP_JNI()
{
    local ABI_DIR="$1"
    local NXP_VARIANT="$2"
    local JNI_PATH="system/$ABI_DIR/libnfc_${NXP_VARIANT}_jni.so"
    local CORE_PATH="system/$ABI_DIR/libnfc-${NXP_VARIANT}.so"
    local GENERIC_PATH="system/$ABI_DIR/libnfc_nci_jni.so"

    if [ ! -f "$FW_DIR/$TARGET_FIRMWARE_PATH/system/$CORE_PATH" ]; then
        _LOG "Missing direct NFC dependency in target firmware: $CORE_PATH"
        return 1
    fi

    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "$JNI_PATH" \
        0 0 644 "u:object_r:system_lib_file:s0"
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "$CORE_PATH" \
        0 0 644 "u:object_r:system_lib_file:s0"

    # Samsung's pre-U NFC JNI uses the old Java method capitalization.
    if [ "$TARGET_PLATFORM_SDK_VERSION" -lt 34 ]; then
        sed -i "s/\<CoverAttached\>/coverAttached/g" "$WORK_DIR/system/$JNI_PATH"
        sed -i "s/\<StartLedCover\>/startLedCover/g" "$WORK_DIR/system/$JNI_PATH"
        sed -i "s/\<StopLedCover\>/stopLedCover/g" "$WORK_DIR/system/$JNI_PATH"
        sed -i "s/\<TransceiveLedCover\>/transceiveLedCover/g" "$WORK_DIR/system/$JNI_PATH"
    fi

    # API 36 unified the NXP JNI filename. Preserve the original filename and
    # expose a copy under the name requested by System.loadLibrary().
    cp -f "$WORK_DIR/system/$JNI_PATH" "$WORK_DIR/system/$GENERIC_PATH"
    SET_METADATA "system" "$GENERIC_PATH" \
        0 0 644 "u:object_r:system_lib_file:s0"
}
# ]

TARGET_FIRMWARE_PATH="$(cut -d "/" -f 1 -s <<< "$TARGET_FIRMWARE")_$(cut -d "/" -f 2 -s <<< "$TARGET_FIRMWARE")"

if [ -f "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/etc/libnfc-nci.conf" ]; then
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/libnfc-nci.conf" 0 0 644 "u:object_r:system_file:s0"
else
    DELETE_FROM_WORK_DIR "system" "system/etc/libnfc-nci.conf"
fi
if [ -f "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/etc/libnfc-nci_temp.conf" ]; then
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/libnfc-nci_temp.conf" 0 0 644 "u:object_r:system_file:s0"
else
    DELETE_FROM_WORK_DIR "system" "system/etc/libnfc-nci_temp.conf"
fi
if [ -f "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/etc/libnfc-nci-NXP_SN100U.conf" ]; then
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/libnfc-nci-NXP_SN100U.conf" 0 0 644 "u:object_r:system_file:s0"
fi
if [ -f "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/etc/libnfc-nci-NXP_PN553.conf" ]; then
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/libnfc-nci-NXP_PN553.conf" 0 0 644 "u:object_r:system_file:s0"
fi
if [ -f "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/etc/libnfc-nci-SLSI.conf" ]; then
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/libnfc-nci-SLSI.conf" 0 0 644 "u:object_r:system_file:s0"
fi
if [ -f "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/etc/libnfc-nci-STM_ST21.conf" ]; then
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/libnfc-nci-STM_ST21.conf" 0 0 644 "u:object_r:system_file:s0"
fi

if [ "$(GET_PROP "vendor" "ro.vendor.nfc.feature.chipname")" ]; then
    if [[ "$(GET_PROP "vendor" "ro.vendor.nfc.feature.chipname")" == "NXP_PN553" ]]; then
        SET_PROP "vendor" "ro.vendor.nfc.feature.chipname" "NXP_SN100U"
    fi
    if ! [[ "$(GET_PROP "vendor" "ro.vendor.nfc.feature.chipname")" =~ NXP_SN100U|SLSI|STM_ST21 ]]; then
        _LOG "Unknown NFC chip name: $(GET_PROP "vendor" "ro.vendor.nfc.feature.chipname")"
        return 0
    fi
fi

# If the target device uses the same NXP SN100U chip as the Note 20 Ultra,
# pull libnfc_nci_jni.so from its stock firmware so the source API 36
# NFC app can find the JNI library.
if [[ "$(GET_PROP "vendor" "ro.vendor.nfc.feature.chipname")" == "NXP_SN100U" ]]; then
    if [ -f "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/lib/libnfc_nci_jni.so" ]; then
        ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib/libnfc_nci_jni.so" 0 0 644 "u:object_r:system_lib_file:s0"
    fi
    if [ -f "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/lib64/libnfc_nci_jni.so" ]; then
        ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libnfc_nci_jni.so" 0 0 644 "u:object_r:system_lib_file:s0"
    fi
fi

# SEC_PRODUCT_FEATURE_NFC_CHIP_NAME:=NXP_SN100U/NXP_PN553
# - API 35 and below: libnfc_nxpsn_jni.so/libnfc_nxppn_jni.so
# - API 36: libnfc_nci_jni.so
#
# Use NXP_SN100U blobs for devices with legacy NXP_PN553 impl.
if [ -f "$WORK_DIR/system/system/lib/libnfc_nci_jni.so" ]; then
    if [ ! -f "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/lib/libnfc_nci_jni.so" ] && \
            [ ! -f "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/lib/libnfc_nxppn_jni.so" ] && \
            [ ! -f "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/lib/libnfc_nxpsn_jni.so" ] && \
            [ ! -f "$WORK_DIR/vendor/lib/nfc_nci_nxpsn.so" ] && \
            [ ! -f "$WORK_DIR/vendor/lib/nfc_nci_nxp.so" ] && \
            [ ! -f "$WORK_DIR/vendor/lib64/nfc_nci_nxpsn.so" ] && \
            [ ! -f "$WORK_DIR/vendor/lib64/nfc_nci_nxp.so" ]; then
        DELETE_FROM_WORK_DIR "system" "system/lib/libnfc_nci_jni.so"
        DELETE_FROM_WORK_DIR "system" "system/lib/libnfc_prop_extn.so"
        DELETE_FROM_WORK_DIR "system" "system/lib/libnfc_vendor_extn.so"
    fi
elif [ -f "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/lib/libnfc_nci_jni.so" ]; then
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib/libnfc_nci_jni.so" 0 0 644 "u:object_r:system_lib_file:s0"
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib/libnfc_prop_extn.so" 0 0 644 "u:object_r:system_lib_file:s0"
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib/libnfc_vendor_extn.so" 0 0 644 "u:object_r:system_lib_file:s0"
elif [ -f "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/lib/libnfc_nxpsn_jni.so" ]; then
    _IMPORT_LEGACY_NXP_JNI "lib" "nxpsn"
elif [ -f "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/lib/libnfc_nxppn_jni.so" ]; then
    _IMPORT_LEGACY_NXP_JNI "lib" "nxppn"
fi
if [ -f "$WORK_DIR/system/system/lib64/libnfc_nci_jni.so" ]; then
    if [ ! -f "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/lib64/libnfc_nci_jni.so" ] && \
            [ ! -f "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/lib64/libnfc_nxppn_jni.so" ] && \
            [ ! -f "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/lib64/libnfc_nxpsn_jni.so" ] && \
            [ ! -f "$WORK_DIR/vendor/lib64/nfc_nci_nxpsn.so" ] && \
            [ ! -f "$WORK_DIR/vendor/lib64/nfc_nci_nxp.so" ]; then
        DELETE_FROM_WORK_DIR "system" "system/lib64/libnfc_nci_jni.so"
        DELETE_FROM_WORK_DIR "system" "system/lib64/libnfc_prop_extn.so"
        DELETE_FROM_WORK_DIR "system" "system/lib64/libnfc_vendor_extn.so"
    fi
elif [ -f "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/lib64/libnfc_nci_jni.so" ]; then
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libnfc_nci_jni.so" 0 0 644 "u:object_r:system_lib_file:s0"
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libnfc_prop_extn.so" 0 0 644 "u:object_r:system_lib_file:s0"
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libnfc_vendor_extn.so" 0 0 644 "u:object_r:system_lib_file:s0"
elif [ -f "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/lib64/libnfc_nxpsn_jni.so" ]; then
    _IMPORT_LEGACY_NXP_JNI "lib64" "nxpsn"
elif [ -f "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/lib64/libnfc_nxppn_jni.so" ]; then
    _IMPORT_LEGACY_NXP_JNI "lib64" "nxppn"
fi

# SEC_PRODUCT_FEATURE_NFC_CHIP_NAME:=STM_ST21
# - API 35 and below: libnfc_st_jni.so
# - API 36: libstnfc_nci_jni.so
if [ -f "$WORK_DIR/system/system/lib/libstnfc_nci_jni.so" ]; then
    if [ ! -f "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/lib/libstnfc_nci_jni.so" ] && \
            [ ! -f "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/lib64/libnfc_st_jni.so" ]; then
        DELETE_FROM_WORK_DIR "system" "system/lib/libnfc_vendor_extn_st.so"
        DELETE_FROM_WORK_DIR "system" "system/lib/libstnfc_nci_jni.so"
    fi
elif [ -f "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/lib/libstnfc_nci_jni.so" ]; then
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib/libnfc_vendor_extn_st.so" 0 0 644 "u:object_r:system_lib_file:s0"
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib/libstnfc_nci_jni.so" 0 0 644 "u:object_r:system_lib_file:s0"
elif [ -f "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/lib64/libnfc_st_jni.so" ]; then
    ADD_TO_WORK_DIR "a17xxx" "system" "system/lib/libnfc_vendor_extn_st.so" 0 0 644 "u:object_r:system_lib_file:s0"
    ADD_TO_WORK_DIR "a17xxx" "system" "system/lib/libstnfc_nci_jni.so" 0 0 644 "u:object_r:system_lib_file:s0"
fi
if [ -f "$WORK_DIR/system/system/lib64/libstnfc_nci_jni.so" ]; then
    if [ ! -f "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/lib64/libstnfc_nci_jni.so" ] && \
            [ ! -f "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/lib64/libnfc_st_jni.so" ]; then
        DELETE_FROM_WORK_DIR "system" "system/lib64/libnfc_vendor_extn_st.so"
        DELETE_FROM_WORK_DIR "system" "system/lib64/libstnfc_nci_jni.so"
    fi
elif [ -f "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/lib64/libstnfc_nci_jni.so" ]; then
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libnfc_vendor_extn_st.so" 0 0 644 "u:object_r:system_lib_file:s0"
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libstnfc_nci_jni.so" 0 0 644 "u:object_r:system_lib_file:s0"
elif [ -f "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/lib64/libnfc_st_jni.so" ]; then
    ADD_TO_WORK_DIR "a17xxx" "system" "system/lib64/libnfc_vendor_extn_st.so" 0 0 644 "u:object_r:system_lib_file:s0"
    ADD_TO_WORK_DIR "a17xxx" "system" "system/lib64/libstnfc_nci_jni.so" 0 0 644 "u:object_r:system_lib_file:s0"
fi

# SEC_PRODUCT_FEATURE_NFC_CHIP_NAME:=SLSI
# - Same lib name as before, check for TARGET_PLATFORM_SDK_VERSION instead
if [ -f "$WORK_DIR/system/system/lib/libnfc_sec_jni.so" ]; then
    if [ ! -f "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/lib/libnfc_sec_jni.so" ] && \
            [ ! -f "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/lib64/libnfc_sec_jni.so" ] && \
            [ ! -f "$WORK_DIR/vendor/lib/nfc_nci_sec.so" ] && \
            [ ! -f "$WORK_DIR/vendor/lib64/nfc_nci_sec.so" ]; then
        DELETE_FROM_WORK_DIR "system" "system/lib/libnfc_sec_jni.so"
    fi
elif [ -f "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/lib/libnfc_sec_jni.so" ] || \
        [ -f "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/lib64/libnfc_sec_jni.so" ]; then
    if [ "$TARGET_PLATFORM_SDK_VERSION" -ge "36" ]; then
        ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib/libnfc_sec_jni.so" 0 0 644 "u:object_r:system_lib_file:s0"
    else
        ADD_TO_WORK_DIR "r11sxxx" "system" "system/lib/libnfc_sec_jni.so" 0 0 644 "u:object_r:system_lib_file:s0"
    fi
fi
if [ -f "$WORK_DIR/system/system/lib64/libnfc_sec_jni.so" ]; then
    if [ ! -f "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/lib64/libnfc_sec_jni.so" ] && \
            [ ! -f "$WORK_DIR/vendor/lib64/nfc_nci_sec.so" ]; then
        DELETE_FROM_WORK_DIR "system" "system/lib64/libnfc_sec_jni.so"
    fi
elif [ -f "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/lib64/libnfc_sec_jni.so" ]; then
    if [ "$TARGET_PLATFORM_SDK_VERSION" -ge "36" ]; then
        ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libnfc_sec_jni.so" 0 0 644 "u:object_r:system_lib_file:s0"
    else
        ADD_TO_WORK_DIR "r11sxxx" "system" "system/lib64/libnfc_sec_jni.so" 0 0 644 "u:object_r:system_lib_file:s0"
    fi
fi

unset TARGET_FIRMWARE_PATH
unset -f _IMPORT_LEGACY_NXP_JNI _LOG
