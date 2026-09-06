# P3S audio HAL test. The prebuilt contains the complete tree copied from
# Downloads/p3s for reference, but the build imports only audio HAL blobs;
# unrelated UWB, biometrics, SAIV and model files remain prebuilt-only.

P3S_PREBUILT="$SRC_DIR/prebuilts/samsung/p3sxxx"
P3S_SOURCE_MANIFEST="$P3S_PREBUILT/vendor/etc/vintf/manifest.xml"
P3S_TARGET_MANIFEST="$WORK_DIR/vendor/etc/vintf/manifest.xml"
[ -f "$P3S_SOURCE_MANIFEST" ] || {
    ABORT "P3S source VINTF manifest is missing"
    return 1
}
[ -f "$P3S_TARGET_MANIFEST" ] || {
    ABORT "Target vendor VINTF manifest is missing"
    return 1
}

grep -q -F '<fqname>@6.0::IDevicesFactory/default</fqname>' \
    "$P3S_SOURCE_MANIFEST" || {
    ABORT "P3S manifest has no android.hardware.audio@6.0 factory"
    return 1
}
grep -q -F '<fqname>@6.0::IEffectsFactory/default</fqname>' \
    "$P3S_SOURCE_MANIFEST" || {
    ABORT "P3S manifest has no android.hardware.audio.effect@6.0 factory"
    return 1
}

P3S_AUDIO_FILES_IMPORTED=0
while IFS= read -r P3S_FILE; do
    [ "$P3S_FILE" ] || continue
    # This module merges only the audio entries from the P3S manifest below;
    # copying the complete donor manifest or unrelated donor files would
    # remove/replace target HAL declarations and services.
    case "$P3S_FILE" in
        bin/hw/android.hardware.audio.service|\
        lib/android.hardware.audio*.so|\
        lib/hw/android.hardware.audio*.so|\
        lib64/android.hardware.audio*.so|\
        lib64/hw/android.hardware.audio*.so)
            ;;
        *)
            continue
            ;;
    esac

    case "$P3S_FILE" in
        bin/*)
            ADD_TO_WORK_DIR "p3sxxx" "vendor" "$P3S_FILE" \
                0 2000 755 "u:object_r:hal_audio_default_exec:s0" || return 1
            ;;
        *)
            ADD_TO_WORK_DIR "p3sxxx" "vendor" "$P3S_FILE" \
                0 0 644 "u:object_r:vendor_file:s0" || return 1
            ;;
    esac
    ((P3S_AUDIO_FILES_IMPORTED+=1))
done < <(find "$P3S_PREBUILT/vendor" -type f -printf '%P\n' | LC_ALL=C sort)

# Port only the two generic audio declarations from the P3S manifest.
EVAL "sed -i \
    -e '/<name>android.hardware.audio<\\/name>/,/<\\/hal>/ { \
        s#<version>[0-9.]*</version>#<version>6.0</version>#; \
        /<version>/! s#<transport>hwbinder</transport>#&\\n        <version>6.0</version>#; \
        s#@[0-9.]*::IDevicesFactory/default#@6.0::IDevicesFactory/default#; \
    }' \
    -e '/<name>android.hardware.audio.effect<\\/name>/,/<\\/hal>/ { \
        s#<version>[0-9.]*</version>#<version>6.0</version>#; \
        /<version>/! s#<transport>hwbinder</transport>#&\\n        <version>6.0</version>#; \
        s#@[0-9.]*::IEffectsFactory/default#@6.0::IEffectsFactory/default#; \
    }' \
    '$P3S_TARGET_MANIFEST'"

grep -q -F '<fqname>@6.0::IDevicesFactory/default</fqname>' \
    "$P3S_TARGET_MANIFEST" || {
    ABORT "Failed to declare android.hardware.audio@6.0 in target VINTF"
    return 1
}
grep -q -F '<fqname>@6.0::IEffectsFactory/default</fqname>' \
    "$P3S_TARGET_MANIFEST" || {
    ABORT "Failed to declare android.hardware.audio.effect@6.0 in target VINTF"
    return 1
}

LOG "  - Imported $P3S_AUDIO_FILES_IMPORTED P3S vendor files"
LOG "  - Updated generic audio factories to HIDL 6.0"
unset P3S_PREBUILT P3S_SOURCE_MANIFEST P3S_TARGET_MANIFEST P3S_FILE \
    P3S_AUDIO_FILES_IMPORTED
