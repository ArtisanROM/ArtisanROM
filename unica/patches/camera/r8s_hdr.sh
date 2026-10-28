# Adapt Artisan's c1s/c2s HDR-node fix to r8s without copying another
# device's complete VENDOR_LIB_INFO list. See upstream 6d1ee81e841a0958:
# the Android 16 camera has ArcSoft v4 LLHDR/MFHDR, not the old MPI v1 nodes.
# This runs after __floating_feature has restored the r8s hardware features.
R8S_MATCH_HDR_NODES()
{
    [[ "$TARGET_CODENAME" == "r8s" && "$SOURCE_PLATFORM_SDK_VERSION" -ge 36 ]] || return 0

    local FEATURE="SEC_FLOATING_FEATURE_CAMERA_CONFIG_VENDOR_LIB_INFO"
    local VALUE
    VALUE="$(GET_FLOATING_FEATURE_CONFIG "$FEATURE")"
    [ "$VALUE" ] || { ABORT "r8s camera node configuration is missing"; return 1; }

    DECODE_APK "system" "system/priv-app/SamsungCamera/SamsungCamera.apk" || return 1
    local CAMERA="$APKTOOL_DIR/system/priv-app/SamsungCamera/SamsungCamera.apk"
    local NODE
    for NODE in \
        "com/samsung/android/camera/core2/node/llhdr/arcsoft/ArcLlHdrNodeBase.smali" \
        "com/samsung/android/camera/core2/node/mfhdr/arcsoft/v4/ArcMfHdrNode.smali"; do
        [ "$(find "$CAMERA" -type f -path "*/$NODE" -print -quit)" ] || {
            ABORT "r8s source camera does not implement $NODE"
            return 1
        }
    done

    local NODES=()
    local UPDATED=()
    local LLHDR=0 MFHDR=0
    IFS=',' read -r -a NODES <<< "$VALUE"
    for NODE in "${NODES[@]}"; do
        case "$NODE" in
            llhdr.mpi.v1|llhdr.arcsoft.v4) NODE="llhdr.arcsoft.v4"; LLHDR=$((LLHDR + 1));;
            mfhdr.mpi.v1|mfhdr.arcsoft.v4) NODE="mfhdr.arcsoft.v4"; MFHDR=$((MFHDR + 1));;
        esac
        UPDATED+=("$NODE")
    done
    if [[ "$LLHDR" != 1 || "$MFHDR" != 1 ]]; then
        ABORT "Unsupported or duplicate r8s HDR nodes: $VALUE"
        return 1
    fi

    local RESULT
    RESULT="$(IFS=','; printf '%s' "${UPDATED[*]}")"
    if [[ "$RESULT" != "$VALUE" ]]; then
        LOG "- Matching r8s LLHDR/MFHDR nodes to the patched Android 16 camera"
        SET_FLOATING_FEATURE_CONFIG "$FEATURE" "$RESULT" || return 1
    fi
}

R8S_MATCH_HDR_NODES || return 1
unset -f R8S_MATCH_HDR_NODES
