# Delete ringtones to stop duplicates
rm -rf "$WORK_DIR/system/system/media/audio"

ADD_TO_WORK_DIR "$MODPATH" "system" "."

LOG_STEP_OUT
