# https://github.com/WSTxda/ViPERFX_RE/blob/github-actions/module/post-fs-data.sh
# https://github.com/WSTxda/ViPERFX_RE/blob/github-actions/module/common/install.sh

LOG_STEP_IN "- Adding Viper4AndroidFX-RE"

ADD_TO_WORK_DIR "$SRC_DIR/unica/mods/v4a" "vendor" "lib/soundfx/libv4a_re.so" 0 0 644 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "$SRC_DIR/unica/mods/v4a" "vendor" "lib64/soundfx/libv4a_re.so" 0 0 644 "u:object_r:vendor_file:s0"

CFGS="$(find "$WORK_DIR/system" "$WORK_DIR/vendor" -type f -name "*audio_effects*.conf" -o -name "*audio_effects*.xml")"

for f in ${CFGS}; do
    case "$f" in
        *.conf)
            sed -i "/v4a_standard_re {/,/}/d" "$f"
            sed -i "/v4a_re {/,/}/d" "$f"
            sed -i "s/^effects {/effects {\n  v4a_standard_re {\n    library v4a_re\n    uuid 90380da3-8536-4744-a6a3-5731970e640f\n  }/g" "$f"
            sed -i "s/^libraries {/libraries {\n  v4a_re {\n    path \/vendor\/lib\/soundfx\/libv4a_re.so\n  }/g" "$f"
            ;;
        *.xml) 
            sed -i "/v4a_standard_re/d" "$f"
            sed -i "/v4a_re/d" "$f"
            sed -i "/<libraries>/ a\        <library name=\"v4a_re\" path=\"libv4a_re.so\"\/>" "$f"
            sed -i "/<effects>/ a\        <effect name=\"v4a_standard_re\" library=\"v4a_re\" uuid=\"90380da3-8536-4744-a6a3-5731970e640f\"\/>" "$f"
            ;;
    esac
done


V4A_APK="https://github.com/WSTxda/ViperFX-RE-Releases/releases/download/8.0/viperfx-release.apk"
APK_PATH="system/preload/Viper4AndroidFX-RE/com.wstxda.viper4android==/base.apk"

DOWNLOAD_FILE "$V4A_APK" "$WORK_DIR/system/$APK_PATH"

sed -i "/system\/preload/d" "$WORK_DIR/configs/fs_config-system"
sed -i "/system\/preload/d" "$WORK_DIR/configs/file_context-system"

while read -r i; do
    FILE="$(echo -n "$i"| sed "s.$WORK_DIR/system/..")"
    [ -d "$i" ] && echo "$FILE 0 0 755 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-system"
    [ -f "$i" ] && echo "$FILE 0 0 644 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-system"
    FILE="$(echo -n "$FILE" | sed 's/\./\\./g')"
    echo "/$FILE u:object_r:system_file:s0" >> "$WORK_DIR/configs/file_context-system"
done <<< "$(find "$WORK_DIR/system/system/preload")"

rm -f "$WORK_DIR/system/system/etc/vpl_apks_count_list.txt"
while read -r i; do
    FILE="$(echo "$i" | sed "s.$WORK_DIR/system..")"
    echo "$FILE" >> "$WORK_DIR/system/system/etc/vpl_apks_count_list.txt"
done <<< "$(find "$WORK_DIR/system/system/preload" -name "*.apk" | sort)"

LOG_STEP_OUT
