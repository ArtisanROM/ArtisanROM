# S24 FE OneUI 7 -> SoundBooster 2000
# S20 Series -> SoundBooster 1050
#
# The S926B Android 16 firmware exposes a 7.1 service. That service is linked
# against symbols which are not available in the y2slte vendor namespace. Use
# the tested HIDL 6.0 wrapper from the older Exynos donor instead. The old
# donor is intentionally discovered by its extracted files so a build remains
# safe when the optional firmware has not been downloaded yet.
AUDIO_DONOR_SOURCE="${AUDIO_LEGACY_DONOR_DIR:-}"
AUDIO_DONOR_LABEL="${AUDIO_LEGACY_DONOR_DIR:-}"
if [ "$AUDIO_DONOR_SOURCE" ] && \
        { [ ! -f "$AUDIO_DONOR_SOURCE/vendor/lib64/hw/android.hardware.audio@6.0-impl.so" ] || \
            [ ! -f "$AUDIO_DONOR_SOURCE/vendor/bin/hw/android.hardware.audio.service" ]; }; then
    LOGW "- AUDIO_LEGACY_DONOR_DIR does not contain a complete HIDL 6.0 HAL; ignoring override"
    AUDIO_DONOR_SOURCE=""
    AUDIO_DONOR_LABEL=""
fi
if [ ! "$AUDIO_DONOR_SOURCE" ]; then
    for AUDIO_CANDIDATE in \
            "$FW_DIR/SM-S901B_EUX" \
            "$FW_DIR/SM-S711B_EUX" \
            "$FW_DIR/SM-S926B_EUX"; do
        [ -d "$AUDIO_CANDIDATE" ] || continue
        if [ -f "$AUDIO_CANDIDATE/vendor/lib64/hw/android.hardware.audio@6.0-impl.so" ] && \
                [ -f "$AUDIO_CANDIDATE/vendor/bin/hw/android.hardware.audio.service" ]; then
            AUDIO_DONOR_SOURCE="$AUDIO_CANDIDATE"
            AUDIO_DONOR_LABEL="${AUDIO_CANDIDATE#$FW_DIR/}"
            break
        fi
    done
fi

AUDIO_DEVICE_FACTORY_VERSION=""
AUDIO_EFFECT_FACTORY_VERSION=""
AUDIO_WRAPPER_LIBS=""
if [ "$AUDIO_DONOR_SOURCE" ]; then
    AUDIO_DEVICE_FACTORY_VERSION="6.0"
    AUDIO_EFFECT_FACTORY_VERSION="6.0"
    AUDIO_WRAPPER_LIBS="
android.hardware.audio.common@6.0.so
android.hardware.audio.common@6.0-util.so
android.hardware.audio.effect@6.0.so
android.hardware.audio.effect@6.0-util.so
android.hardware.audio@6.0.so
android.hardware.audio@6.0-util.so
    "
fi

if [ ! "$AUDIO_DEVICE_FACTORY_VERSION" ]; then
    LOG "- Legacy HIDL 6.0 donor is not extracted; keeping the target audio HAL"
else
    LOG_STEP_IN "- Porting the Audio HAL wrapper from $AUDIO_DONOR_LABEL (HIDL 6.0)"
    # The base Exynos 990 manifest advertises the stock HIDL 5.0 factory.
    # Promote only the two audio HAL entries when a complete 6.0 donor is
    # actually present; this keeps the no-donor path internally consistent.
    AUDIO_MANIFEST="$WORK_DIR/vendor/etc/vintf/manifest.xml"
    if [ -f "$AUDIO_MANIFEST" ]; then
        EVAL "sed -i -e '/<name>android.hardware.audio<\\/name>/,/<\\/hal>/ { s#<version>5.0</version>#<version>6.0</version>#; s#@5.0::IDevicesFactory/default#@6.0::IDevicesFactory/default#; }' -e '/<name>android.hardware.audio.effect<\\/name>/,/<\\/hal>/ { s#<version>5.0</version>#<version>6.0</version>#; s#@5.0::IEffectsFactory/default#@6.0::IEffectsFactory/default#; }' '$AUDIO_MANIFEST'"
    fi
    # Keep the Exynos 990 legacy audio.primary driver, DSP firmware, mixer
    # paths and policy files. Only the generic service/wrapper is taken from
    # the source firmware.
    if [ -f "$AUDIO_DONOR_SOURCE/vendor/bin/hw/android.hardware.audio.service" ]; then
        ADD_TO_WORK_DIR "$AUDIO_DONOR_SOURCE" "vendor" "bin/hw/android.hardware.audio.service" \
            0 2000 755 "u:object_r:hal_audio_default_exec:s0"
    fi

    for ARCH in lib lib64; do
        [ -d "$AUDIO_DONOR_SOURCE/vendor/$ARCH" ] || continue
        while IFS= read -r LIB; do
            [ -f "$AUDIO_DONOR_SOURCE/vendor/$ARCH/$LIB" ] || continue
            ADD_TO_WORK_DIR "$AUDIO_DONOR_SOURCE" "vendor" "$ARCH/$LIB" \
                0 0 644 "u:object_r:vendor_file:s0"
        done < <(printf '%s\n' "$AUDIO_WRAPPER_LIBS" | sed '/^$/d')

        AUDIO_IMPL="$ARCH/hw/android.hardware.audio@${AUDIO_DEVICE_FACTORY_VERSION}-impl.so"
        if [ -f "$AUDIO_DONOR_SOURCE/vendor/$AUDIO_IMPL" ]; then
            ADD_TO_WORK_DIR "$AUDIO_DONOR_SOURCE" "vendor" "$AUDIO_IMPL" \
                0 0 644 "u:object_r:vendor_file:s0"
            AUDIO_IMPL_PATH="$WORK_DIR/vendor/$AUDIO_IMPL"
            if ! readelf -d "$AUDIO_IMPL_PATH" 2>/dev/null | grep -q \
                    "libaudio-hidl-vndk30-compat.so"; then
                EVAL "patchelf --add-needed libaudio-hidl-vndk30-compat.so '$AUDIO_IMPL_PATH'"
            fi
        fi

        AUDIO_EFFECT_IMPL="$ARCH/hw/android.hardware.audio.effect@${AUDIO_EFFECT_FACTORY_VERSION}-impl.so"
        if [ -f "$AUDIO_DONOR_SOURCE/vendor/$AUDIO_EFFECT_IMPL" ]; then
            ADD_TO_WORK_DIR "$AUDIO_DONOR_SOURCE" "vendor" "$AUDIO_EFFECT_IMPL" \
                0 0 644 "u:object_r:vendor_file:s0"
            AUDIO_EFFECT_IMPL_PATH="$WORK_DIR/vendor/$AUDIO_EFFECT_IMPL"
            if ! readelf -d "$AUDIO_EFFECT_IMPL_PATH" 2>/dev/null | grep -q \
                    "libaudio-hidl-vndk30-compat.so"; then
                EVAL "patchelf --add-needed libaudio-hidl-vndk30-compat.so '$AUDIO_EFFECT_IMPL_PATH'"
            fi
        fi
    done

    LOG_STEP_OUT
fi

unset AUDIO_DONOR_SOURCE AUDIO_DONOR_LABEL AUDIO_CANDIDATE AUDIO_MANIFEST AUDIO_DEVICE_FACTORY_VERSION \
    AUDIO_EFFECT_FACTORY_VERSION AUDIO_WRAPPER_LIBS AUDIO_IMPL AUDIO_IMPL_PATH \
    AUDIO_EFFECT_IMPL AUDIO_EFFECT_IMPL_PATH

LOG_STEP_IN "- Replacing SoundBooster"
DELETE_FROM_WORK_DIR "system" "system/lib64/lib_SoundBooster_ver2000.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/lib_SAG_EQ_ver2000.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/libsoundboostereq_legacy.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/lib_SoundBooster_ver1050.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libsamsungSoundbooster_plus_legacy.so" 0 0 644 "u:object_r:system_lib_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Replacing GameDriver"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/priv-app/GameDriver-EX9830/GameDriver-EX9830.apk" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/priv-app/DevGPUDriver-EX9830/DevGPUDriver-EX9830.apk" 0 0 644 "u:object_r:system_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Replacing Hotword"
DELETE_FROM_WORK_DIR "product" "priv-app/HotwordEnrollmentOKGoogleEx4CORTEXM55"
DELETE_FROM_WORK_DIR "product" "priv-app/HotwordEnrollmentXGoogleEx4CORTEXM55"
if [[ "$TARGET_CODENAME" != "r8s" ]]; then
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "product" "priv-app/HotwordEnrollmentOKGoogleEx3CORTEXM4/HotwordEnrollmentOKGoogleEx3CORTEXM4.apk" 0 0 644 "u:object_r:system_file:s0"
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "product" "priv-app/HotwordEnrollmentXGoogleEx3CORTEXM4/HotwordEnrollmentXGoogleEx3CORTEXM4.apk" 0 0 644 "u:object_r:system_file:s0"
elif [[ "$TARGET_CODENAME" == "r8s" ]]; then
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "product" "priv-app/HotwordEnrollmentOKGoogleEx2CORTEXM4/HotwordEnrollmentOKGoogleEx2CORTEXM4.apk" 0 0 644 "u:object_r:system_file:s0"
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "product" "priv-app/HotwordEnrollmentXGoogleEx2CORTEXM4/HotwordEnrollmentXGoogleEx2CORTEXM4.apk" 0 0 644 "u:object_r:system_file:s0"
fi
LOG_STEP_OUT

if [[ "$TARGET_CODENAME" == "c2s" || "$TARGET_CODENAME" == "c1s" ]]; then
    LOG_STEP_IN "- Adding SPen SEC Feature"
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/permissions/com.sec.feature.spen_usp_level40.xml" 0 0 644 "u:object_r:system_file:s0"
    LOG_STEP_OUT
fi

LOG_STEP_IN "- Adding stock NFC Case features"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/permissions/com.sec.feature.cover.clearsideviewcover.xml" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/permissions/com.sec.feature.cover.xml" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/permissions/com.sec.feature.cover.sview.xml" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/permissions/com.sec.feature.nfc_authentication_cover.xml" 0 0 644 "u:object_r:system_file:s0"

if [[ "$TARGET_CODENAME" != "r8s" ]]; then
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/permissions/com.sec.feature.cover.flip.xml" 0 0 644 "u:object_r:system_file:s0"
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/permissions/com.sec.feature.cover.ledbackcover.xml" 0 0 644 "u:object_r:system_file:s0"
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/permissions/com.sec.feature.cover.nfcledcover.xml" 0 0 644 "u:object_r:system_file:s0"
fi

if [[ "$TARGET_CODENAME" == "x1s" || "$TARGET_CODENAME" == "y2s" || "$TARGET_CODENAME" == "z3s" ]]; then
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/priv-app/LedBackCoverAppHubble/LedBackCoverAppHubble.apk" 0 0 644 "u:object_r:system_file:s0"
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/permissions/privapp-permissions-com.samsung.android.app.ledbackcover.xml" 0 0 644 "u:object_r:system_file:s0"
fi
LOG_STEP_OUT
