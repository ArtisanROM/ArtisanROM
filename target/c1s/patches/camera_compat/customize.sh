LOG_STEP_IN "- Fixing Galaxy Note 20 LLHDR camera node"

LLHDR_LIB="$WORK_DIR/system/system/lib64/liblow_light_hdr.arcsoft.so"
CAMERA_VENDOR_LIB_INFO="$(GET_FLOATING_FEATURE_CONFIG \
    "SEC_FLOATING_FEATURE_CAMERA_CONFIG_VENDOR_LIB_INFO")"

if [ ! -f "$LLHDR_LIB" ]; then
    ABORT "Required LLHDR implementation is missing: system/lib64/liblow_light_hdr.arcsoft.so"
    return 1
fi

if [[ "$CAMERA_VENDOR_LIB_INFO" == *"llhdr.mpi.v1"* ]]; then
    CAMERA_VENDOR_LIB_INFO="${CAMERA_VENDOR_LIB_INFO//llhdr.mpi.v1/llhdr.arcsoft.v4}"
elif [[ "$CAMERA_VENDOR_LIB_INFO" != *"llhdr.arcsoft.v4"* ]]; then
    if [ "$CAMERA_VENDOR_LIB_INFO" ]; then
        CAMERA_VENDOR_LIB_INFO+=",llhdr.arcsoft.v4"
    else
        CAMERA_VENDOR_LIB_INFO="llhdr.arcsoft.v4"
    fi
fi

SET_FLOATING_FEATURE_CONFIG \
    "SEC_FLOATING_FEATURE_CAMERA_CONFIG_VENDOR_LIB_INFO" \
    "$CAMERA_VENDOR_LIB_INFO"

unset LLHDR_LIB CAMERA_VENDOR_LIB_INFO

LOG_STEP_OUT
