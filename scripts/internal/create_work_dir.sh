#!/usr/bin/env bash
#
# Copyright (C) 2025 Salvo Giangreco
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

# [
source "$SRC_DIR/scripts/utils/build_utils.sh" || exit 1

SOURCE_FIRMWARE_PATH="$(cut -d "/" -f 1 -s <<< "$SOURCE_FIRMWARE")_$(cut -d "/" -f 2 -s <<< "$SOURCE_FIRMWARE")"
TARGET_FIRMWARE_PATH="$(cut -d "/" -f 1 -s <<< "$TARGET_FIRMWARE")_$(cut -d "/" -f 2 -s <<< "$TARGET_FIRMWARE")"

COPY_SOURCE_FIRMWARE()
{
    local SOURCE_FOLDERS="odm product system prism optics"
    for f in $SOURCE_FOLDERS; do
        if [ -d "$FW_DIR/$SOURCE_FIRMWARE_PATH/$f" ]; then
            LOG "- Copying /$f from source firmware"
            EVAL "rsync -a --mkpath --delete --exclude=\"*system_ext*\" \"$FW_DIR/$SOURCE_FIRMWARE_PATH/$f\" \"$WORK_DIR\"" || exit 1
            sed "/system_ext/d" "$FW_DIR/$SOURCE_FIRMWARE_PATH/file_context-$f" > "$WORK_DIR/configs/file_context-$f"
            sed "/system_ext/d" "$FW_DIR/$SOURCE_FIRMWARE_PATH/fs_config-$f" > "$WORK_DIR/configs/fs_config-$f"
        else
            [ -d "$WORK_DIR/$f" ] && rm -rf "$WORK_DIR/$f"
            [ -f "$WORK_DIR/configs/file_context-$f" ] && rm -f "$WORK_DIR/configs/file_context-$f"
            [ -f "$WORK_DIR/configs/fs_config-$f" ] && rm -f "$WORK_DIR/configs/fs_config-$f"
        fi
    done

    if [ -d "$FW_DIR/$SOURCE_FIRMWARE_PATH/system_ext" ]; then
        if $TARGET_HAS_SYSTEM_EXT; then
            LOG_STEP_IN "- Copying /system_ext from source firmware"

            [ -L "$WORK_DIR/system/system_ext" ] && rm -f "$WORK_DIR/system/system_ext"
            [ -d "$WORK_DIR/system/system/system_ext" ] && rm -rf "$WORK_DIR/system/system/system_ext"

            EVAL "rsync -a --mkpath --delete \"$FW_DIR/$SOURCE_FIRMWARE_PATH/system_ext\" \"$WORK_DIR\"" || exit 1
            mkdir -p "$WORK_DIR/system/system_ext"
            EVAL "ln -sf \"/system_ext\" \"$WORK_DIR/system/system/system_ext\"" || exit 1
            SET_METADATA "system" "system_ext" 0 0 755 "u:object_r:system_file:s0"
            SET_METADATA "system" "system/system_ext" 0 0 644 "u:object_r:system_file:s0"
            EVAL "cp -a \"$FW_DIR/$SOURCE_FIRMWARE_PATH/file_context-system_ext\" \"$WORK_DIR/configs/file_context-system_ext\"" || exit 1
            EVAL "cp -a \"$FW_DIR/$SOURCE_FIRMWARE_PATH/fs_config-system_ext\" \"$WORK_DIR/configs/fs_config-system_ext\"" || exit 1

            LOG_STEP_OUT
        else
            LOG_STEP_IN "- Copying /system/system/system_ext from source firmware"

            [ -d "$WORK_DIR/system/system_ext" ] && rm -rf "$WORK_DIR/system/system_ext"
            [ -L "$WORK_DIR/system/system/system_ext" ] && rm -f "$WORK_DIR/system/system/system_ext"
            [ -d "$WORK_DIR/system_ext" ] && rm -rf "$WORK_DIR/system_ext"
            [ -f "$WORK_DIR/configs/file_context-system_ext" ] && rm -f "$WORK_DIR/configs/file_context-system_ext"
            [ -f "$WORK_DIR/configs/fs_config-system_ext" ] && rm -f "$WORK_DIR/configs/fs_config-system_ext"

            EVAL "rsync -a --mkpath --delete \"$FW_DIR/$SOURCE_FIRMWARE_PATH/system_ext\" \"$WORK_DIR/system/system\"" || exit 1
            EVAL "ln -sf \"/system/system_ext\" \"$WORK_DIR/system/system_ext\"" || exit 1
            SET_METADATA "system" "system_ext" 0 0 644 "u:object_r:system_file:s0"
            sed "s/^\/system_ext/\/system\/system_ext/g" "$FW_DIR/$SOURCE_FIRMWARE_PATH/file_context-system_ext" >> "$WORK_DIR/configs/file_context-system"
            sed "s/^system_ext/system\/system_ext/g" "$FW_DIR/$SOURCE_FIRMWARE_PATH/fs_config-system_ext" >> "$WORK_DIR/configs/fs_config-system"

            DELETE_FROM_WORK_DIR "system" "system/system_ext/etc/NOTICE.xml.gz"
            DELETE_FROM_WORK_DIR "system" "system/system_ext/etc/fs_config_dirs"
            DELETE_FROM_WORK_DIR "system" "system/system_ext/etc/fs_config_files"

            LOG_STEP_OUT
        fi
    elif [ -d "$FW_DIR/$SOURCE_FIRMWARE_PATH/system/system/system_ext" ]; then
        if $TARGET_HAS_SYSTEM_EXT; then
            LOG_STEP_IN "- Copying /system_ext from source firmware"

            [ -L "$WORK_DIR/system/system_ext" ] && rm -f "$WORK_DIR/system/system_ext"
            [ -d "$WORK_DIR/system/system/system_ext" ] && rm -rf "$WORK_DIR/system/system/system_ext"

            EVAL "rsync -a --mkpath --delete \"$FW_DIR/$SOURCE_FIRMWARE_PATH/system/system/system_ext\" \"$WORK_DIR\"" || exit 1
            mkdir -p "$WORK_DIR/system/system_ext"
            EVAL "ln -sf \"/system_ext\" \"$WORK_DIR/system/system/system_ext\"" || exit 1
            SET_METADATA "system" "system_ext" 0 0 755 "u:object_r:system_file:s0"
            SET_METADATA "system" "system/system_ext" 0 0 644 "u:object_r:system_file:s0"
            grep -F "system/system_ext" "$FW_DIR/$SOURCE_FIRMWARE_PATH/file_context-system" | sed "s/^\/system//" > "$WORK_DIR/configs/file_context-system_ext"
            grep -F "system/system_ext" "$FW_DIR/$SOURCE_FIRMWARE_PATH/fs_config-system" | sed "s/^system\///" > "$WORK_DIR/configs/fs_config-system_ext"

            ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "etc/NOTICE.xml.gz"
            ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "etc/fs_config_dirs"
            ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "etc/fs_config_files"

            LOG_STEP_OUT
        else
            LOG_STEP_IN "- Copying /system/system/system_ext from source firmware"

            [ -d "$WORK_DIR/system/system_ext" ] && rm -rf "$WORK_DIR/system/system_ext"
            [ -L "$WORK_DIR/system/system/system_ext" ] && rm -f "$WORK_DIR/system/system/system_ext"
            [ -d "$WORK_DIR/system_ext" ] && rm -rf "$WORK_DIR/system_ext"
            [ -f "$WORK_DIR/configs/file_context-system_ext" ] && rm -f "$WORK_DIR/configs/file_context-system_ext"
            [ -f "$WORK_DIR/configs/fs_config-system_ext" ] && rm -f "$WORK_DIR/configs/fs_config-system_ext"

            EVAL "rsync -a --mkpath --delete \"$FW_DIR/$SOURCE_FIRMWARE_PATH/system/system/system_ext\" \"$WORK_DIR/system/system\"" || exit 1
            EVAL "ln -sf \"/system/system_ext\" \"$WORK_DIR/system/system_ext\"" || exit 1
            grep -F "system_ext" "$FW_DIR/$SOURCE_FIRMWARE_PATH/file_context-system" >> "$WORK_DIR/configs/file_context-system"
            grep -F "system_ext" "$FW_DIR/$SOURCE_FIRMWARE_PATH/fs_config-system" >> "$WORK_DIR/configs/fs_config-system"

            LOG_STEP_OUT
        fi
    fi
}

COPY_TARGET_FIRMWARE()
{
    local TARGET_FOLDERS="odm_dlkm system_dlkm vendor vendor_dlkm"
    for f in $TARGET_FOLDERS; do
        if [ -d "$FW_DIR/$TARGET_FIRMWARE_PATH/$f" ]; then
            LOG "- Copying /$f from target firmware"
            EVAL "rsync -a --mkpath --delete \"$FW_DIR/$TARGET_FIRMWARE_PATH/$f\" \"$WORK_DIR\"" || exit 1
            EVAL "cp -a \"$FW_DIR/$TARGET_FIRMWARE_PATH/file_context-$f\" \"$WORK_DIR/configs/file_context-$f\"" || exit 1
            EVAL "cp -a \"$FW_DIR/$TARGET_FIRMWARE_PATH/fs_config-$f\" \"$WORK_DIR/configs/fs_config-$f\"" || exit 1
        else
            [ -d "$WORK_DIR/$f" ] && rm -rf "$WORK_DIR/$f"
            [ -f "$WORK_DIR/configs/file_context-$f" ] && rm -f "$WORK_DIR/configs/file_context-$f"
            [ -f "$WORK_DIR/configs/fs_config-$f" ] && rm -f "$WORK_DIR/configs/fs_config-$f"
        fi
    done
}

COPY_TARGET_KERNEL()
{
    if [ -d "$FW_DIR/$TARGET_FIRMWARE_PATH/kernel" ]; then
        LOG_STEP_IN "- Copying target firmware kernel images"
        EVAL "rsync -a --mkpath --delete \"$FW_DIR/$TARGET_FIRMWARE_PATH/kernel\" \"$WORK_DIR\"" || exit 1
        $TARGET_KEEP_ORIGINAL_SIGN || find "$WORK_DIR/kernel" -mindepth 1 -exec "$SRC_DIR/scripts/unsign_bin.sh" {} \;
        LOG_STEP_OUT
    else
        [ -d "$WORK_DIR/kernel" ] && rm -rf "$WORK_DIR/kernel"
    fi
    if $TARGET_INCLUDE_PATCHED_VBMETA; then
        LOG "- Copying vbmeta.img from target firmware"
        mkdir -p "$WORK_DIR/kernel"
        EVAL "cp -a \"$FW_DIR/$TARGET_FIRMWARE_PATH/vbmeta_patched.img\" \"$WORK_DIR/kernel/vbmeta.img\"" || exit 1
    else
        [ -f "$WORK_DIR/kernel/vbmeta.img" ] && rm -f "$WORK_DIR/kernel/vbmeta.img"
        [ -d "$WORK_DIR/kernel" ] && [ -n "$(find "$WORK_DIR/kernel" -maxdepth 0 -empty)" ] && rm -rf "$WORK_DIR/kernel"
    fi
}

# PATCH: REPLACE & MAP INCOMPATIBLE APEX by @Devandroid-bit
REPLACE_BROKEN_APEX()
{
    LOG_STEP_IN "- Replacing APEX files in Nested System (System-in-System)"
    
    if [ -d "$SRC_DIR/prebuilts/apex_fixes" ]; then
        # Ensure the nested destination directory exists
        mkdir -p "$WORK_DIR/system/system/apex"

        LOG "  > Cleaning specific files from BOTH locations to prevent conflicts..."
        # 1. Remove from top-level /system/apex (The ones you don't want)
        rm -f "$WORK_DIR/system/apex/com."*"tethering"*
        rm -f "$WORK_DIR/system/apex/com."*"bt"*

        # 2. Remove from nested /system/system/apex (To prepare for the new ones)
        rm -f "$WORK_DIR/system/system/apex/com."*"tethering"*
        rm -f "$WORK_DIR/system/system/apex/com."*"bt"*
        
        LOG "  > Copying OneUI 7 fixes to nested system/system/apex/..."
        # We only copy the fixes to the nested folder as requested
        cp -f "$SRC_DIR/prebuilts/apex_fixes/"*.apex "$WORK_DIR/system/system/apex/"
        chmod 644 "$WORK_DIR/system/system/apex/"*.apex
        
        LOG "  > Updating configurations with exact nested paths..."
        
        local FS_CONF="$WORK_DIR/configs/fs_config-system"
        local FL_CONT="$WORK_DIR/configs/file_context-system"

        if [ -f "$FS_CONF" ]; then
            # Path relative to the image root ($WORK_DIR/system)
            # Physical: $WORK_DIR/system/system/apex/file.apex -> Relative: system/apex/file.apex
            echo "system/apex/com.android.bt.apex 0 0 0644" >> "$FS_CONF"
            echo "system/apex/com.google.android.tethering_compressed.apex 0 0 0644" >> "$FS_CONF"
        fi

        if [ -f "$FL_CONT" ]; then
            # Full path for SELinux labeling in the running OS
            echo "/system/system/apex/com\.android\.bt\.apex u:object_r:system_file:s0" >> "$FL_CONT"
            echo "/system/system/apex/com\.google\.android\.tethering_compressed\.apex u:object_r:system_file:s0" >> "$FL_CONT"
        fi

        LOG "  [OK] Nested APEX replacement complete. Root apex folder was preserved."
    else
        LOG "  [!] No fixes found in prebuilts/apex_fixes. Skipping."
    fi
    
    LOG_STEP_OUT
}

# ]

mkdir -p "$WORK_DIR"
mkdir -p "$WORK_DIR/configs"
COPY_SOURCE_FIRMWARE
COPY_TARGET_FIRMWARE
COPY_TARGET_KERNEL
REPLACE_BROKEN_APEX

exit 0
