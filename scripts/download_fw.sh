#!/usr/bin/env bash
# Copyright (c) 2025 Salvo Giangreco
# SPDX-License-Identifier: GPL-3.0-or-later

# [
source "$SRC_DIR/scripts/utils/firmware_utils.sh" || exit 1

FORCE=false

FIRMWARES=()
MODEL=""
CSC=""
IMEI=""
SERIAL_NO=""
LATEST_FIRMWARE=""
DOWNLOAD_FIRMWARE=""
REQUESTED_FIRMWARE=""
ZIP_FILE=""

PREPARE_SCRIPT()
{
    local EXTRA_FIRMWARES=()
    local IGNORE_SOURCE=false
    local IGNORE_TARGET=false

    while [ "$#" != 0 ]; do
        if [[ "$1" == "--force" ]] || [[ "$1" == "-f" ]]; then
            FORCE=true
        elif [[ "$1" == "--version" ]]; then
            shift
            if [ -z "$1" ] || [[ "$1" == "-"* ]]; then
                LOGE "--version requires a firmware version"
                PRINT_USAGE
                exit 1
            fi
            REQUESTED_FIRMWARE="$1"
        elif [[ "$1" == "--ignore-source" ]]; then
            IGNORE_SOURCE=true
        elif [[ "$1" == "--ignore-target" ]]; then
            IGNORE_TARGET=true
        elif [[ "$1" == "-"* ]]; then
            LOGE "Unknown option: $1"
            PRINT_USAGE
            exit 1
        else
            EXTRA_FIRMWARES+=("$1")
        fi

        shift
    done

    if ! $IGNORE_SOURCE; then
        _CHECK_NON_EMPTY_PARAM "SOURCE_FIRMWARE" "$SOURCE_FIRMWARE" || exit 1
        FIRMWARES+=("$SOURCE_FIRMWARE")
        IFS=':' read -r -a SOURCE_EXTRA_FIRMWARES <<< "$SOURCE_EXTRA_FIRMWARES"
        if [ "${#SOURCE_EXTRA_FIRMWARES[@]}" -ge 1 ]; then
            FIRMWARES+=("${SOURCE_EXTRA_FIRMWARES[@]}")
        fi
    fi

    if ! $IGNORE_TARGET; then
        _CHECK_NON_EMPTY_PARAM "TARGET_FIRMWARE" "$TARGET_FIRMWARE" || exit 1
        FIRMWARES+=("$TARGET_FIRMWARE")
        IFS=':' read -r -a TARGET_EXTRA_FIRMWARES <<< "$TARGET_EXTRA_FIRMWARES"
        if [ "${#TARGET_EXTRA_FIRMWARES[@]}" -ge 1 ]; then
            FIRMWARES+=("${TARGET_EXTRA_FIRMWARES[@]}")
        fi
    fi

    if [ "${#EXTRA_FIRMWARES[@]}" -ge 1 ]; then
        FIRMWARES+=("${EXTRA_FIRMWARES[@]}")
    fi

    if [ -n "$REQUESTED_FIRMWARE" ] && [ "${#FIRMWARES[@]}" -ne 1 ]; then
        LOGE "--version can only be used when downloading one firmware"
        exit 1
    fi
}

PRINT_USAGE()
{
    echo "Usage: download_fw [options] <firmware>" >&2
    echo " --ignore-source : Skip parsing source firmware flags" >&2
    echo " --ignore-target : Skip parsing target firmware flags" >&2
    echo " -f, --force : Force firmware download" >&2
    echo " --version <PDA/CSC/CP> : Download a specific firmware version" >&2
}

VERIFY_ODIN_PACKAGES()
{
    local FILE_NAME
    local LENGTH
    local STORED_HASH
    local CALCULATED_HASH

    while IFS= read -r f; do
        FILE_NAME="$(basename "$f")"
        LOG_STEP_IN "- Verifying $FILE_NAME..."

        FILE_NAME="${FILE_NAME%.md5}"

        # Samsung stores the output of `md5sum` at the very end of the file
        LENGTH="32" # Length of MD5 hash
        LENGTH="$((LENGTH + 2))" # 2 whitespace chars
        LENGTH="$((LENGTH + ${#FILE_NAME}))" # File name without .md5 extension
        LENGTH="$((LENGTH + 1))" # 1 newline char

        STORED_HASH="$(tail -c "$LENGTH" "$f" | cut -d " " -f 1 -s)"
        if [ ! "$STORED_HASH" ] || [[ "${#STORED_HASH}" != "32" ]]; then
            LOG "\033[0;31m! Expected hash could not be parsed\033[0m"
            exit 1
        fi

        CALCULATED_HASH="$(head -c-$LENGTH "$f" | md5sum | cut -d " " -f 1 -s)"

        if [[ "$STORED_HASH" != "$CALCULATED_HASH" ]]; then
            LOG "\033[0;31m! File is damaged\033[0m"
            exit 1
        fi

        LOG_STEP_OUT
    done < <(find "$ODIN_DIR/${MODEL}_${CSC}" -type f -name "*.md5")
}
# ]

PREPARE_SCRIPT "$@"

for i in "${FIRMWARES[@]}"; do
    PARSE_FIRMWARE_STRING "$i" || exit 1

    CONFIGURED_FIRMWARE=""
    if [ "$i" == "$SOURCE_FIRMWARE" ]; then
        CONFIGURED_FIRMWARE="$SOURCE_FIRMWARE_VERSION"
    elif [ "$i" == "$TARGET_FIRMWARE" ]; then
        CONFIGURED_FIRMWARE="$TARGET_FIRMWARE_VERSION"
    fi

    LATEST_FIRMWARE="$(GET_LATEST_FIRMWARE "$MODEL" "$CSC")"
    if [ ! "$LATEST_FIRMWARE" ] && [ -z "$REQUESTED_FIRMWARE" ] && [ -z "$CONFIGURED_FIRMWARE" ]; then
        LOGE "Latest available firmware could not be fetched"
        exit 1
    fi

    DOWNLOAD_FIRMWARE="${REQUESTED_FIRMWARE:-${CONFIGURED_FIRMWARE:-$LATEST_FIRMWARE}}"

    LOG_STEP_IN "- Processing $MODEL firmware with $CSC CSC"
    LOG "- Downloaded firmware: $(cat "$ODIN_DIR/${MODEL}_${CSC}/.downloaded" 2> /dev/null)"
    LOG "- Extracted firmware: $(cat "$FW_DIR/${MODEL}_${CSC}/.extracted" 2> /dev/null)"
    LOG "- Latest available firmware: $LATEST_FIRMWARE"
    [ -n "$CONFIGURED_FIRMWARE" ] && LOG "- Configured firmware: $CONFIGURED_FIRMWARE"
    [ -n "$REQUESTED_FIRMWARE" ] && LOG "- Requested firmware: $REQUESTED_FIRMWARE"

    LOG_STEP_IN

    if ! $FORCE; then
        # Skip if firmware has been extracted and equal/newer than the one in FUS
        if [ -f "$FW_DIR/${MODEL}_${CSC}/.extracted" ]; then
            if COMPARE_SEC_BUILD_VERSION "$(cat "$FW_DIR/${MODEL}_${CSC}/.extracted")" "$DOWNLOAD_FIRMWARE"; then
                LOG "\033[0;33m! This firmware has already been extracted, skipping\033[0m"
                LOG_STEP_OUT; LOG_STEP_OUT
                continue
            fi
        fi

        # Skip if firmware has already been downloaded
        if [ -f "$ODIN_DIR/${MODEL}_${CSC}/.downloaded" ]; then
            if ! COMPARE_SEC_BUILD_VERSION "$(cat "$ODIN_DIR/${MODEL}_${CSC}/.downloaded")" "$DOWNLOAD_FIRMWARE"; then
                LOG "\033[0;33m! A newer firmware is available for download, use --force flag if you want to overwrite it\033[0m"
            else
                LOG "\033[0;33m! This firmware has already been downloaded\033[0m"
            fi
            LOG_STEP_OUT; LOG_STEP_OUT
            continue
        fi
    fi

    LOG "- Downloading firmware..."
    [ -f "$ODIN_DIR/${MODEL}_${CSC}/.downloaded" ] && rm -rf "$ODIN_DIR/${MODEL}_${CSC}"
    mkdir -p "$ODIN_DIR/${MODEL}_${CSC}"
    find "$ODIN_DIR/${MODEL}_${CSC}" -maxdepth 1 -type f -name "*.zip" -delete

    COUNT=1
    while true; do
        "$TOOLS_DIR/bin/samloader" download \
            --model "$MODEL" \
            --region "$CSC" \
            --version "$DOWNLOAD_FIRMWARE" \
            --out-dir "$ODIN_DIR/${MODEL}_${CSC}" || exit 1

        ZIP_FILE="$(find "$ODIN_DIR/${MODEL}_${CSC}" -maxdepth 1 -type f -name "*.zip" | head -n 1)"
        if [ ! "$ZIP_FILE" ] || [ ! -f "$ZIP_FILE" ]; then
            if [ "$COUNT" -gt 10 ]; then
                LOG "\033[0;31m! Download failed after 10 retries\033[0m"
                exit 1
            fi

            LOG "\033[0;31m! [Attempt: $COUNT] Download failed, retrying in 5 seconds...\033[0m"
            sleep 5
            ((COUNT++))
        else
            break
        fi
    done

    LOG "- Extracting $(basename "$ZIP_FILE")..."
    EVAL "unzip -o \"$ZIP_FILE\" -d \"$ODIN_DIR/${MODEL}_${CSC}\" && rm -rf \"$ZIP_FILE\"" || exit 1

    VERIFY_ODIN_PACKAGES

    echo -n "$DOWNLOAD_FIRMWARE" > "$ODIN_DIR/${MODEL}_${CSC}/.downloaded"

    LOG_STEP_OUT; LOG_STEP_OUT
done

exit 0
