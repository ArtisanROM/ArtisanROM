# [
_LOG() { if $DEBUG; then LOGW "$1"; else ABORT "$1"; fi }

_IMPORT_LEGACY_NXP_JNI()
{
    local ABI_DIR="$1"
    local NXP_VARIANT="$2"
    local NFC_INTERFACE_LIB
    local NFC_INTERFACE_SOURCE
    local JNI_PATH="system/$ABI_DIR/libnfc_${NXP_VARIANT}_jni.so"
    local CORE_PATH="system/$ABI_DIR/libnfc-${NXP_VARIANT}.so"
    local GENERIC_PATH="system/$ABI_DIR/libnfc_nci_jni.so"
    local MODERN_JNI="$SRC_DIR/prebuilts/samsung/pa3qzcx/system/lib64/libnfc_nci_jni.so"

    if [ ! -f "$FW_DIR/$TARGET_FIRMWARE_PATH/system/$CORE_PATH" ]; then
        _LOG "Missing direct NFC dependency in target firmware: $CORE_PATH"
        return 1
    fi

    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "$JNI_PATH" \
        0 0 644 "u:object_r:system_lib_file:s0"
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "$CORE_PATH" \
        0 0 644 "u:object_r:system_lib_file:s0"

    if [ "$ABI_DIR" = "lib64" ]; then
        # Replacing the source vendor with an older target vendor also removes
        # its Android 16 NFC interface libraries.  Both the legacy NXP HAL and
        # libnfc-nxpsn.so list these sonames in DT_NEEDED, so the HAL exits
        # before NfcService can publish an NfcAdapter when they are absent.
        # Prefer the source Android 16 implementations, while retaining the
        # target's chip-specific HAL, firmware, configuration and Samsung ABI.
        for NFC_INTERFACE_LIB in \
            "android.hardware.nfc@1.0.so" \
            "android.hardware.nfc@1.1.so" \
            "android.hardware.nfc@1.2.so" \
            "android.hardware.nfc-V1-ndk.so"; do
            NFC_INTERFACE_SOURCE="$FW_DIR/$SOURCE_FIRMWARE_PATH/vendor/lib64/$NFC_INTERFACE_LIB"

            if [ -f "$NFC_INTERFACE_SOURCE" ]; then
                ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "vendor" "lib64/$NFC_INTERFACE_LIB" \
                    0 0 644 "u:object_r:vendor_file:s0"
                cp -f "$WORK_DIR/vendor/lib64/$NFC_INTERFACE_LIB" \
                    "$WORK_DIR/system/system/lib64/$NFC_INTERFACE_LIB"
                SET_METADATA "system" "system/lib64/$NFC_INTERFACE_LIB" \
                    0 0 644 "u:object_r:system_lib_file:s0"
            elif [ -f "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/lib64/$NFC_INTERFACE_LIB" ]; then
                ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/$NFC_INTERFACE_LIB" \
                    0 0 644 "u:object_r:system_lib_file:s0"
                cp -f "$WORK_DIR/system/system/lib64/$NFC_INTERFACE_LIB" \
                    "$WORK_DIR/vendor/lib64/$NFC_INTERFACE_LIB"
                SET_METADATA "vendor" "vendor/lib64/$NFC_INTERFACE_LIB" \
                    0 0 644 "u:object_r:vendor_file:s0"
            else
                _LOG "Missing NFC interface dependency: $NFC_INTERFACE_LIB"
                return 1
            fi
        done

        if [ -f "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/lib64/vendor.samsung.hardware.nfc@2.0.so" ]; then
            ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" \
                "system/lib64/vendor.samsung.hardware.nfc@2.0.so" \
                0 0 644 "u:object_r:system_lib_file:s0"
        fi
    fi

    # Samsung's pre-U NFC JNI uses the old Java method capitalization.
    if [ "$TARGET_PLATFORM_SDK_VERSION" -lt 34 ]; then
        sed -i "s/\<CoverAttached\>/coverAttached/g" "$WORK_DIR/system/$JNI_PATH"
        sed -i "s/\<StartLedCover\>/startLedCover/g" "$WORK_DIR/system/$JNI_PATH"
        sed -i "s/\<StopLedCover\>/stopLedCover/g" "$WORK_DIR/system/$JNI_PATH"
        sed -i "s/\<TransceiveLedCover\>/transceiveLedCover/g" "$WORK_DIR/system/$JNI_PATH"
    fi

    # API 36 uses a vendor-neutral JNI that can talk to both AIDL and legacy
    # HIDL NFC HALs. Prefer the native API 36 implementation for arm64 while
    # retaining the target's own NXP HAL, firmware and configuration.
    if [ "$ABI_DIR" = "lib64" ] && [ -f "$MODERN_JNI" ]; then
        ADD_TO_WORK_DIR "pa3qzcx" "system" "$GENERIC_PATH" \
            0 0 644 "u:object_r:system_lib_file:s0"
    else
        # Fallback for 32-bit targets or trees without the modern prebuilt.
        cp -f "$WORK_DIR/system/$JNI_PATH" "$WORK_DIR/system/$GENERIC_PATH"
        SET_METADATA "system" "$GENERIC_PATH" \
            0 0 644 "u:object_r:system_lib_file:s0"
    fi
}
# ]

TARGET_FIRMWARE_PATH="$(cut -d "/" -f 1 -s <<< "$TARGET_FIRMWARE")_$(cut -d "/" -f 2 -s <<< "$TARGET_FIRMWARE")"
SOURCE_FIRMWARE_PATH="$(cut -d "/" -f 1 -s <<< "$SOURCE_FIRMWARE")_$(cut -d "/" -f 2 -s <<< "$SOURCE_FIRMWARE")"

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

unset SOURCE_FIRMWARE_PATH TARGET_FIRMWARE_PATH
unset -f _IMPORT_LEGACY_NXP_JNI _LOG

# Keep SecSettings' compiled antenna position aligned with the target vendor.
# The RF configuration itself remains target-specific and is never replaced.
NFC_SETTINGS_APK="system/priv-app/SecSettings/SecSettings.apk"
NFC_TARGET_ANTPOS="$(GET_PROP "vendor" "ro.vendor.nfc.info.antpos")"

if [ -z "$NFC_TARGET_ANTPOS" ]; then
    LOG "- Target NFC antenna position is not declared; skipping antenna guide patch"
    unset NFC_SETTINGS_APK NFC_TARGET_ANTPOS
    return 0
fi

if ! [[ "$NFC_TARGET_ANTPOS" =~ ^[0-9]+$ ]]; then
    LOGW "Invalid target NFC antenna position: $NFC_TARGET_ANTPOS"
    unset NFC_SETTINGS_APK NFC_TARGET_ANTPOS
    return 0
fi

_GET_COMPILED_NFC_ANTPOS()
{
    local SMALI_FILE="$1"
    local METHOD="$2"

    awk -v FN="$METHOD" '
        /^\.method/ && index($0, FN) {
            inside = 1
            candidate = ""
        }
        inside && /^[[:space:]]*const-string(\/jumbo)?[[:space:]].*"[0-9]+"/ {
            if (match($0, /"[0-9]+"/))
                candidate = substr($0, RSTART + 1, RLENGTH - 2)
        }
        inside && /"ro\.vendor\.nfc\.info\.antpos"/ {
            print candidate
            exit
        }
        inside && /^\.end method/ { inside = 0 }
    ' "$SMALI_FILE"
}

_PATCH_NFC_ANTPOS()
{
    local SMALI_FILE="$1"
    local SMALI_RELATIVE="$2"
    local METHOD="$3"
    local COMPILED_ANTPOS

    COMPILED_ANTPOS="$(_GET_COMPILED_NFC_ANTPOS "$SMALI_FILE" "$METHOD")"

    if [ -z "$COMPILED_ANTPOS" ]; then
        LOGW "Could not find the compiled NFC antenna position in $SMALI_RELATIVE"
        return 0
    elif [ "$COMPILED_ANTPOS" = "$NFC_TARGET_ANTPOS" ]; then
        LOG "- NFC antenna position already matches in $SMALI_RELATIVE"
        return 0
    fi

    SMALI_PATCH "system" "$NFC_SETTINGS_APK" "$SMALI_RELATIVE" \
        "replace" "$METHOD" "$COMPILED_ANTPOS" "$NFC_TARGET_ANTPOS"
}

LOG_STEP_IN "- Matching NFC antenna guide to target position $NFC_TARGET_ANTPOS"

DECODE_APK "system" "$NFC_SETTINGS_APK" || return 1
NFC_APKTOOL_PATH="$APKTOOL_DIR/system/${NFC_SETTINGS_APK//system\//}"

NFC_GUIDE_SMALI="$(find "$NFC_APKTOOL_PATH" -type f \
    -path '*/com/samsung/android/settings/nfc/NfcAntennaGuideDialog.smali' -print -quit)"
NFC_SETTINGS_SMALI="$(find "$NFC_APKTOOL_PATH" -type f \
    -path '*/com/samsung/android/settings/nfc/NfcSettings.smali' -print -quit)"

if [ ! -f "$NFC_GUIDE_SMALI" ] || [ ! -f "$NFC_SETTINGS_SMALI" ]; then
    LOGW "SecSettings does not contain the expected NFC antenna guide classes; skipping"
else
    NFC_GUIDE_SMALI="${NFC_GUIDE_SMALI#"$NFC_APKTOOL_PATH/"}"
    NFC_SETTINGS_SMALI="${NFC_SETTINGS_SMALI#"$NFC_APKTOOL_PATH/"}"

    _PATCH_NFC_ANTPOS "$NFC_APKTOOL_PATH/$NFC_GUIDE_SMALI" \
        "$NFC_GUIDE_SMALI" "onCreate(Landroid/os/Bundle;)V"
    _PATCH_NFC_ANTPOS "$NFC_APKTOOL_PATH/$NFC_SETTINGS_SMALI" \
        "$NFC_SETTINGS_SMALI" \
        "populateViewForOrientation(Lcom/android/settingslib/widget/LayoutPreference;)V"
fi

LOG_STEP_OUT

unset NFC_SETTINGS_APK NFC_TARGET_ANTPOS NFC_APKTOOL_PATH
unset NFC_GUIDE_SMALI NFC_SETTINGS_SMALI
unset -f _GET_COMPILED_NFC_ANTPOS _PATCH_NFC_ANTPOS
