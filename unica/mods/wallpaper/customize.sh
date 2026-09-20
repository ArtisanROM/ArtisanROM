if $DEBUG; then
    LOG "\033[0;33m! Debug build detected. Skipping\033[0m"
    return 0
fi

# [
COMPRESS_WEBP()
{
    local FILE="$1"
    local FILE_PATH
    local FILE_NAME
    local RES="2400"
    local CMD

    FILE_PATH="$(dirname "$FILE")"
    FILE_NAME="$(basename "$FILE")"

    if $TARGET_COMMON_SUPPORT_DYN_RESOLUTION_CONTROL; then
        if [ "$TARGET_PRODUCT_SHIPPING_API_LEVEL" -gt "30" ] && \
                [ "$TARGET_PRODUCT_SHIPPING_API_LEVEL" -lt "34" ]; then
            RES="3088"
        else
            RES="3120"
        fi
    fi

    LOG "- Compressing $FILE_NAME"

    CMD="cwebp"
    CMD+=" -q 100"
    CMD+=" -resize $RES $RES"
    CMD+=" \"$FILE_PATH/$FILE_NAME\""
    CMD+=" -o \"$FILE_PATH/temp.webp\""

    EVAL "$CMD" || return 1
    EVAL "mv -f \"$FILE_PATH/temp.webp\" \"$FILE_PATH/$FILE_NAME\"" || return 1
}

ENCODE_MP4()
{
    local FILE="$1"
    local FILE_PATH
    local FILE_NAME
    local RES="-1:2400"
    local CMD

    FILE_PATH="$(dirname "$FILE")"
    FILE_NAME="$(basename "$FILE")"

    if $TARGET_COMMON_SUPPORT_DYN_RESOLUTION_CONTROL; then
        RES="1440:-1"
    fi

    LOG "- Encoding $FILE_NAME"

    CMD="ffmpeg"
    CMD+=" -i \"$FILE_PATH/$FILE_NAME\""
    CMD+=" -c:v libx264 -c:a copy"
    CMD+=" -pix_fmt yuv420p -crf 18 -g 1"
    CMD+=" -preset veryslow -tune zerolatency"
    CMD+=" -movflags use_metadata_tags -map_metadata 0"
    CMD+=" -vf \"fps=60,scale=$RES,setsar=1:1\""
    CMD+=" -video_track_timescale 360000 -movie_timescale 90000"
    CMD+=" \"$FILE_PATH/temp.mp4\""

    EVAL "$CMD" || return 1
    EVAL "mv -f \"$FILE_PATH/temp.mp4\" \"$FILE_PATH/$FILE_NAME\"" || return 1
}
# ]

ADD_TO_WORK_DIR "m2sxxx" "system" \
    "system/priv-app/wallpaper-res/wallpaper-res.apk" 0 0 644 "u:object_r:system_file:s0"
DECODE_APK "system" "system/priv-app/wallpaper-res/wallpaper-res.apk"
for f in "$APKTOOL_DIR/system/priv-app/wallpaper-res/wallpaper-res.apk/res/drawable-nodpi/dex_wallpaper_"*.webp; do
    COMPRESS_WEBP "$f"
done
for f in "$APKTOOL_DIR/system/priv-app/wallpaper-res/wallpaper-res.apk/res/drawable-nodpi/wallpaper_"*.webp; do
    COMPRESS_WEBP "$f"
done
for f in "$APKTOOL_DIR/system/priv-app/wallpaper-res/wallpaper-res.apk/res/raw/video_"*.mp4; do
    ENCODE_MP4 "$f"
done
ADD_TO_WORK_DIR "m2sxxx" "system" \
    "system/priv-app/SpriteWallpaper/SpriteWallpaper.apk" 0 0 644 "u:object_r:system_file:s0"
LOG "- Halving wallpaper transition timings in SpriteWallpaper"
DECODE_APK "system" "system/priv-app/SpriteWallpaper/SpriteWallpaper.apk"
local _SW="$APKTOOL_DIR/system/priv-app/SpriteWallpaper/SpriteWallpaper.apk"
local _SF
_SF="$(grep -rl 'AOD AOD 0' "$_SW/smali"* | head -n 1)"
if [ "$_SF" ]; then
    # Pre-SDK35 variant (720/2952)
    sed -i 's/AOD LOCK 0 720 1800/AOD LOCK 0 360 900/g;s/AOD HOME 0 2952 2500/AOD HOME 0 1476 2500/g;s/LOCK HOME 720 2952 1200/LOCK HOME 360 1476 1200/g;s/LOCK TOUCH 720 1800 1000/LOCK TOUCH 360 900 1000/g' "$_SF"
    # SDK35+ variant (700/2040)
    sed -i 's/AOD LOCK 0 700 1000/AOD LOCK 0 350 1000/g;s/AOD HOME 0 2040 2500/AOD HOME 0 1020 2500/g;s/LOCK HOME 700 2040 1500/LOCK HOME 350 1020 1500/g;s/LOCK TOUCH 700 1750 1500/LOCK TOUCH 350 875 1500/g' "$_SF"
    # S26+ directional variant (270/719/1169/1619)
    sed -i 's/AOD LOCK 0 269 1500/AOD LOCK 0 538 1500/g;s/AOD HOME 0 719 3000/AOD HOME 0 1438 3000/g;s/LOCK HOME_LEFT 270 719/LOCK HOME_LEFT 540 1438/g;s/LOCK HOME_UP 720 1169/LOCK HOME_UP 1440 2338/g;s/LOCK HOME_RIGHT 1170 1619/LOCK HOME_RIGHT 2340 3238/g;s/LOCK TOUCH_LEFT 270 519/LOCK TOUCH_LEFT 540 1038/g;s/LOCK TOUCH_UP 720 969/LOCK TOUCH_UP 1440 1938/g;s/LOCK TOUCH_RIGHT 1170 1419/LOCK TOUCH_RIGHT 2340 2838/g' "$_SF"
else
    LOGW "SpriteWallpaper timing string not found, skipping"
fi
APPLY_PATCH "system" "system/priv-app/wallpaper-res/wallpaper-res.apk" \
    "$MODPATH/wallpaper-res.apk/0001-Adjust-metadata-for-60fps-video-files.patch"

unset -f ENCODE_MP4 COMPRESS_WEBP
