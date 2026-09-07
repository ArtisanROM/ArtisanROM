#!/usr/bin/env bash
# Copyright (c) 2025 Salvo Giangreco
# SPDX-License-Identifier: GPL-3.0-or-later

# [
source "$SRC_DIR/scripts/utils/build_utils.sh" || exit 1

FORCE=false
USE_APK_CACHE=false
BUILD_ROM=false
BUILD_TARGET_FILES=true
BUILD_FLASHABLE_ZIP=false
SKIP_DEBUG_INSTALL=false

START_TIME="$(date +%s)"

SOURCE_FIRMWARE_PATH="$(cut -d "/" -f 1 -s <<< "$SOURCE_FIRMWARE")_$(cut -d "/" -f 2 -s <<< "$SOURCE_FIRMWARE")"
TARGET_FIRMWARE_PATH="$(cut -d "/" -f 1 -s <<< "$TARGET_FIRMWARE")_$(cut -d "/" -f 2 -s <<< "$TARGET_FIRMWARE")"
APK_CACHE_DIR="$OUT_DIR/target/$TARGET_CODENAME/apk_cache"
APK_DECODE_CACHE_DIR="$OUT_DIR/target/$TARGET_CODENAME/apk_decode_cache"

GET_PATCHED_APK_TREE_HASH()
{
    [ -d "$APKTOOL_DIR" ] || return 1

    find "$APKTOOL_DIR" -type f -print0 | sort -z | \
        xargs -0 sha256sum | sha256sum | cut -d " " -f 1
}

GET_BUILT_APK_PATH()
{
    local RELATIVE_PATH="$1"
    local PARTITION
    local FILE

    PARTITION="$(cut -d "/" -f 1 -s <<< "$RELATIVE_PATH")"
    FILE="$(cut -d "/" -f 2- -s <<< "$RELATIVE_PATH")"

    case "$PARTITION" in
        "system")
            echo "$WORK_DIR/system/system/$FILE"
            ;;
        "system_ext")
            if $TARGET_OS_BUILD_SYSTEM_EXT_PARTITION; then
                echo "$WORK_DIR/system_ext/$FILE"
            else
                echo "$WORK_DIR/system/system/system_ext/$FILE"
            fi
            ;;
        *)
            echo "$WORK_DIR/$PARTITION/$FILE"
            ;;
    esac
}

RESTORE_APK_CACHE()
{
    local TREE_HASH
    local RELATIVE_PATH
    local OUTPUT_FILE

    TREE_HASH="$(GET_PATCHED_APK_TREE_HASH)" || return 1
    [ -f "$APK_CACHE_DIR/.tree_hash" ] || return 1
    [ "$(cat "$APK_CACHE_DIR/.tree_hash")" = "$TREE_HASH" ] || return 1

    while IFS= read -r -d '' f; do
        RELATIVE_PATH="${f/$APKTOOL_DIR\//}"
        OUTPUT_FILE="$(GET_BUILT_APK_PATH "$RELATIVE_PATH")"
        [ -f "$APK_CACHE_DIR/files/$RELATIVE_PATH" ] || return 1
        mkdir -p "$(dirname "$OUTPUT_FILE")"
        cp -a "$APK_CACHE_DIR/files/$RELATIVE_PATH" "$OUTPUT_FILE"
    done < <(find "$APKTOOL_DIR" -type d \( -name "*.apk" -o -name "*.jar" \) -print0)

    LOG "- Reused APK/JAR cache ($TREE_HASH)"
    return 0
}

UPDATE_APK_CACHE()
{
    local TREE_HASH
    local RELATIVE_PATH
    local OUTPUT_FILE

    [ -d "$APKTOOL_DIR" ] || return 0
    TREE_HASH="$(GET_PATCHED_APK_TREE_HASH)" || return 1

    rm -rf "$APK_CACHE_DIR"
    mkdir -p "$APK_CACHE_DIR/files"

    while IFS= read -r -d '' f; do
        RELATIVE_PATH="${f/$APKTOOL_DIR\//}"
        OUTPUT_FILE="$(GET_BUILT_APK_PATH "$RELATIVE_PATH")"
        [ -f "$OUTPUT_FILE" ] || return 1
        mkdir -p "$APK_CACHE_DIR/files/$(dirname "$RELATIVE_PATH")"
        cp -a "$OUTPUT_FILE" "$APK_CACHE_DIR/files/$RELATIVE_PATH"
    done < <(find "$APKTOOL_DIR" -type d \( -name "*.apk" -o -name "*.jar" \) -print0)

    printf '%s' "$TREE_HASH" > "$APK_CACHE_DIR/.tree_hash"
    LOG "- Updated APK/JAR cache ($TREE_HASH)"
}

BUILD_APKS()
{
    local MAX_JOBS
    MAX_JOBS="$(nproc)"
    [ "$MAX_JOBS" -gt "8" ] && MAX_JOBS="8"

    if [ -d "$APKTOOL_DIR" ]; then
        LOG_STEP_IN true "Building APKs/JARs"

        # shellcheck disable=SC2016
        find "$APKTOOL_DIR" -type d \( -name "*.apk" -o -name "*.jar" \) -print0 | xargs -0 -I "{}" -P "$MAX_JOBS" \
            bash -c '
                FILE="${1/$APKTOOL_DIR\//}"
                PARTITION="$(cut -d "/" -f 1 -s <<< "$FILE")"
                [[ "$PARTITION" != "system" ]] && FILE="$(cut -d "/" -f 2- -s <<< "$FILE")"
                "$SRC_DIR/scripts/apktool.sh" b -j "$2" "$PARTITION" "$FILE"
            ' "bash" "{}" "$MAX_JOBS" || exit 1

        LOG_STEP_OUT
    fi
}

GET_WORK_DIR_HASH()
{
    if [ "${TARGET_PLATFORM//none/}" ] && [ -d "$SRC_DIR/platform/$TARGET_PLATFORM" ]; then
        # Some device codenames are aliases (for example target/y2s points to
        # target/y2slte). Follow command-line symlinks so device patches are
        # part of the incremental-build fingerprint as well.
        find -H "$SRC_DIR/scripts" "$SRC_DIR/unica" "$SRC_DIR/platform/$TARGET_PLATFORM" \
            "$SRC_DIR/target/$TARGET_CODENAME" -type f -print0 | \
            sort -z | xargs -0 sha1sum | sha1sum | cut -d " " -f 1
    else
        find -H "$SRC_DIR/scripts" "$SRC_DIR/unica" "$SRC_DIR/target/$TARGET_CODENAME" \
            -type f -print0 | \
            sort -z | xargs -0 sha1sum | sha1sum | cut -d " " -f 1
    fi
}

PREPARE_SCRIPT()
{
    while [[ "$#" != 0 ]]; do
        if [[ "$1" == "--force" ]] || [[ "$1" == "-f" ]]; then
            FORCE=true
        elif [[ "$1" == "--use-apk-cache" ]] || [[ "$1" == "-c" ]]; then
            USE_APK_CACHE=true
        elif [[ "$1" == "--no-target-files" ]] || [[ "$1" == "-x" ]]; then
            BUILD_TARGET_FILES=false
            BUILD_FLASHABLE_ZIP=false
        elif [[ "$1" == "--build-rom-zip" ]] || [[ "$1" == "-z" ]]; then
            BUILD_TARGET_FILES=true
            BUILD_FLASHABLE_ZIP=true
        elif [[ "$1" == "--no-debug-install" ]]; then
            SKIP_DEBUG_INSTALL=true
        else
            if [[ "$1" == "-"* ]]; then
                LOGE "Unknown option: $1"
            fi
            PRINT_USAGE
            exit 1
        fi

        shift
    done
}

# shellcheck disable=SC2317,SC2329
PRINT_BUILD_OUTCOME()
{
    local EXIT_CODE="$?"
    local END_TIME
    local ESTIMATED

    END_TIME="$(date +%s)"
    ESTIMATED="$((END_TIME - START_TIME))"

    if [[ "$EXIT_CODE" != "0" ]]; then
        echo -n -e '\n\033[1;31m'"Build failed "
    else
        echo -n -e '\n\033[1;32m'"Build completed "
    fi
    echo -e "in $((ESTIMATED / 3600))hrs $(((ESTIMATED / 60) % 60))min $((ESTIMATED % 60))sec."'\033[0m\n'
}

PRINT_USAGE()
{
    echo "Usage: make_rom [options]" >&2
    echo " -f, --force : Force ROM build" >&2
    echo " -c, --use-apk-cache : Reuse decoded and compiled APKs/JARs when sources match" >&2
    echo " -x, --no-target-files : Do not build target-files zip" >&2
    echo " -z, --build-rom-zip : Build flashable zip" >&2
    echo " --no-debug-install : Do not install a debug ZIP after building it" >&2
}
# ]

PREPARE_SCRIPT "$@"

# apktool.sh is also invoked indirectly by patch modules. Exporting the cache
# policy here lets every decode participate without changing module scripts.
export APK_DECODE_CACHE_DIR
if $USE_APK_CACHE; then
    export APK_DECODE_CACHE_MODE="reuse"
else
    export APK_DECODE_CACHE_MODE="refresh"
    rm -rf "$APK_DECODE_CACHE_DIR"
fi

if $FORCE || ! $USE_APK_CACHE; then
    # A regular invocation intentionally performs a clean ROM rebuild and
    # refreshes the APK/JAR cache. Cache reuse is opt-in with -c.
    BUILD_ROM=true
else
    if [ -f "$WORK_DIR/.completed" ]; then
        if [[ "$(cat "$WORK_DIR/.completed")" == "$(GET_WORK_DIR_HASH)" ]]; then
            LOGW "No changes have been detected in the build environment"
            BUILD_ROM=false
        else
            LOGW "Changes detected in the build environment"
            BUILD_ROM=true
        fi
    else
        BUILD_ROM=true
    fi
fi

trap 'PRINT_BUILD_OUTCOME' EXIT
trap 'echo' INT

if $BUILD_ROM; then
    [ -d "$APKTOOL_DIR" ] && rm -rf "$APKTOOL_DIR"
    [ -f "$WORK_DIR/.completed" ] && rm -f "$WORK_DIR/.completed"

    if [ ! -f "$FW_DIR/$SOURCE_FIRMWARE_PATH/.extracted" ] || [ ! -f "$FW_DIR/$TARGET_FIRMWARE_PATH/.extracted" ]; then
        if [ ! -f "$ODIN_DIR/$SOURCE_FIRMWARE_PATH/.downloaded" ] || [ ! -f "$ODIN_DIR/$TARGET_FIRMWARE_PATH/.downloaded" ]; then
            LOG_STEP_IN true "Downloading required firmwares"
            "$SRC_DIR/scripts/download_fw.sh" || exit 1
            LOG_STEP_OUT
        fi
        LOG_STEP_IN true "Extracting required firmwares"
        "$SRC_DIR/scripts/extract_fw.sh" || exit 1
        LOG_STEP_OUT
    fi

    LOG_STEP_IN true "Creating work dir"
    "$SRC_DIR/scripts/internal/create_work_dir.sh" || exit 1
    LOG_STEP_OUT

    if [ -d "$SRC_DIR/platform/$TARGET_PLATFORM/patches" ]; then
        LOG_STEP_IN true "Applying platform patches"
        "$SRC_DIR/scripts/internal/apply_modules.sh" "$SRC_DIR/platform/$TARGET_PLATFORM/patches" || exit 1
        LOG_STEP_OUT
    fi
    if [ -d "$SRC_DIR/target/$TARGET_CODENAME/patches" ]; then
        LOG_STEP_IN true "Applying device patches"
        "$SRC_DIR/scripts/internal/apply_modules.sh" "$SRC_DIR/target/$TARGET_CODENAME/patches" || exit 1
        LOG_STEP_OUT
    fi
    if [ -d "$SRC_DIR/unica/patches" ]; then
        LOG_STEP_IN true "Applying ROM patches"
        "$SRC_DIR/scripts/internal/apply_modules.sh" "$SRC_DIR/unica/patches" || exit 1
        LOG_STEP_OUT
    fi

    if [ -d "$SRC_DIR/unica/mods" ]; then
        LOG_STEP_IN true "Applying ROM mods"
        "$SRC_DIR/scripts/internal/apply_modules.sh" "$SRC_DIR/unica/mods" || exit 1
        LOG_STEP_OUT
    fi

    if $USE_APK_CACHE && RESTORE_APK_CACHE; then
        LOG "Skipping APK/JAR compilation"
    else
        if $USE_APK_CACHE; then
            LOGW "APK/JAR cache is missing or stale. Rebuilding it."
        fi
        BUILD_APKS
        UPDATE_APK_CACHE || exit 1
    fi

    echo -n "$(GET_WORK_DIR_HASH)" > "$WORK_DIR/.completed"
fi

if $BUILD_TARGET_FILES || $BUILD_FLASHABLE_ZIP; then
    ZIP_FILE_NAME="${TARGET_CODENAME}_"
    if [ "$(GET_PROP "system" "ro.unica.version")" ]; then
        ZIP_FILE_NAME+="$(GET_PROP "system" "ro.unica.version")"
    else
        ZIP_FILE_NAME+="$ROM_VERSION"
    fi
    ZIP_FILE_NAME+="-target_files.zip"

    # A rebuilt work dir must never be packaged through a stale target-files
    # archive left by a previous build with the same ROM version.
    if $BUILD_ROM || [ ! -f "$OUT_DIR/$ZIP_FILE_NAME" ]; then
        rm -f "$OUT_DIR/$ZIP_FILE_NAME"
        LOG_STEP_IN true "Creating target-files zip"
        "$SRC_DIR/scripts/internal/create_target_files_zip.sh" "$OUT_DIR/$ZIP_FILE_NAME" || exit 1
        LOG_STEP_OUT
    else
        LOGW "File already exists: ${OUT_DIR//$SRC_DIR\//}/$ZIP_FILE_NAME"
    fi

    if $BUILD_FLASHABLE_ZIP; then
        FLASHABLE_ZIP="$OUT_DIR/UN1CA_"
        BUILD_INFO="$(unzip -p "$OUT_DIR/$ZIP_FILE_NAME" "build_info.txt")" || exit 1
        FLASHABLE_ZIP+="$(grep "^version" <<< "$BUILD_INFO" | cut -d "=" -f 2 -s)_"
        FLASHABLE_ZIP+="$(date -d "@$(grep "^timestamp" <<< "$BUILD_INFO" | cut -d "=" -f 2 -s)" "+%Y%m%d")_"
        FLASHABLE_ZIP+="$(grep "^device" <<< "$BUILD_INFO" | cut -d "=" -f 2 -s)"
        if ! $DEBUG || $ROM_IS_OFFICIAL; then
            FLASHABLE_ZIP+="-sign"
        fi
        FLASHABLE_ZIP+=".zip"

        LOG_STEP_IN true "Creating flashable zip"
        "$SRC_DIR/scripts/build_flashable_zip.sh" -o "$FLASHABLE_ZIP" "$OUT_DIR/$ZIP_FILE_NAME" || exit 1
        LOG_STEP_OUT

        if $DEBUG && ! $SKIP_DEBUG_INSTALL; then
            LOG_STEP_IN true "Installing debug zip"
            "$SRC_DIR/scripts/install_debug_zip.sh" "$FLASHABLE_ZIP" || exit 1
            LOG_STEP_OUT
        fi
    fi
fi

exit 0
