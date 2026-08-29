#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later

source "$SRC_DIR/scripts/utils/build_utils.sh" || exit 1

ZIP_FILE="$1"

WAIT_FOR_CONFIRMATION()
{
    if [ ! -t 0 ]; then
        LOGE "Interactive confirmation is required, but stdin is not a terminal"
        exit 1
    fi

    read -r -p "Pressione Enter para tentar novamente... "
}

WAIT_FOR_ADB_DEVICE()
{
    while true; do
        mapfile -t DEVICES < <(adb devices | awk 'NR > 1 && $2 == "device" { print $1 }')
        if [ "${#DEVICES[@]}" -eq 1 ]; then
            LOG "- ADB device connected: ${DEVICES[0]}"
            return 0
        fi

        LOGW "No single authorized ADB device was found"
        adb devices -l >&2
        echo "Conecte apenas o aparelho que será instalado, desbloqueie a tela," >&2
        echo "ative a Depuração USB e aceite a chave RSA deste computador." >&2
        WAIT_FOR_CONFIRMATION
    done
}

WAIT_FOR_ROOT_SHELL()
{
    local ROOT_UID

    while true; do
        # Besides checking access, this call triggers the KernelSU permission
        # dialog when Shell has not been authorized yet.
        ROOT_UID="$(adb shell su -c 'id -u' 2> /dev/null | tr -d '\r' | tail -n 1)"
        if [ "$ROOT_UID" = "0" ]; then
            LOG "- Root shell access confirmed"
            return 0
        fi

        LOGW "ADB is connected, but Shell does not have root access"
        echo "Abra o gerenciador KernelSU, conceda root ao aplicativo Shell" >&2
        echo "e mantenha o aparelho conectado e desbloqueado." >&2
        WAIT_FOR_CONFIRMATION

        # The device may have been disconnected while the user was granting
        # access. Return to the ADB connection check before retrying su.
        WAIT_FOR_ADB_DEVICE
    done
}

if ! $DEBUG; then
    LOGE "Debug ZIP installation requires: source buildenv.sh --debug <target>"
    exit 1
elif [ ! -f "$ZIP_FILE" ]; then
    LOGE "File not found: ${ZIP_FILE//$SRC_DIR\//}"
    exit 1
elif ! command -v adb &> /dev/null; then
    LOGE "adb was not found in PATH"
    exit 1
fi

WAIT_FOR_ADB_DEVICE
WAIT_FOR_ROOT_SHELL

ZIP_NAME="$(basename "$ZIP_FILE")"
if [[ ! "$ZIP_NAME" =~ ^[A-Za-z0-9._+-]+$ ]]; then
    LOGE "ZIP name contains characters unsupported by the debug installer: $ZIP_NAME"
    exit 1
fi

REMOTE_ZIP="/sdcard/$ZIP_NAME"
LOCAL_SHA256="$(sha256sum "$ZIP_FILE" | cut -d " " -f 1)"

LOG "- Uploading $ZIP_NAME to internal storage"
adb push "$ZIP_FILE" "$REMOTE_ZIP" || exit 1

REMOTE_SHA256="$(adb shell "toybox sha256sum '$REMOTE_ZIP'" 2> /dev/null | tr -d '\r' | cut -d " " -f 1)"
if [ "$LOCAL_SHA256" != "$REMOTE_SHA256" ]; then
    LOGE "Uploaded ZIP checksum does not match"
    exit 1
fi

LOG "- Scheduling ZIP installation through OpenRecoveryScript"
ORS_LOCAL="$(mktemp)" || exit 1
trap 'rm -f "$ORS_LOCAL"' EXIT
printf 'install %s\nwipe cache\nwipe dalvik\nreboot\n' "$REMOTE_ZIP" > "$ORS_LOCAL"

# Do not pipe the file through `adb shell su -c`. Some KernelSU versions only
# keep the first part of a compound remote command under su, so the redirect or
# verification is performed as the unprivileged shell user. Push to a staging
# path first, then run the whole install transaction in one quoted root shell.
ORS_STAGING="/data/local/tmp/unica-openrecoveryscript"
adb push "$ORS_LOCAL" "$ORS_STAGING" || exit 1
adb shell "su -c 'mkdir -p /cache/recovery && install -m 600 $ORS_STAGING /cache/recovery/openrecoveryscript && chown system:cache /cache/recovery/openrecoveryscript && sync /cache/recovery/openrecoveryscript'" || {
    LOGE "Could not write /cache/recovery/openrecoveryscript as root"
    exit 1
}

EXPECTED_ORS="$(printf 'install %s\nwipe cache\nwipe dalvik\nreboot' "$REMOTE_ZIP")"
ACTUAL_ORS="$(adb shell "su -c 'cat /cache/recovery/openrecoveryscript'" 2> /dev/null | tr -d '\r')"
if [ "$EXPECTED_ORS" != "$ACTUAL_ORS" ]; then
    LOGE "Could not verify /cache/recovery/openrecoveryscript"
    LOGE "Expected: $(printf %q "$EXPECTED_ORS")"
    LOGE "Actual:   $(printf %q "$ACTUAL_ORS")"
    exit 1
fi

LOG "- Rebooting device into recovery"
adb reboot recovery || exit 1
