TWOTHREE_TARGETS=""
TWOFOUR_TARGETS="a52sxq a51 a53x a73xq m52xq r8q r9q r9q2"
TWOFIVE_TARGETS="x1q y2q c1q c2q z3q"

if echo "$TWOTHREE_TARGETS" | grep -q -w "$TARGET_CODENAME"; then
    cp -a --preserve=all "$SRC_DIR/unica/mods/bootanim/2340x1080/"* "$WORK_DIR/system/system/media"
elif echo "$TWOFOUR_TARGETS" | grep -q -w "$TARGET_CODENAME"; then
    cp -a --preserve=all "$SRC_DIR/unica/mods/bootanim/2400x1080/"* "$WORK_DIR/system/system/media"
elif echo "$TWOFIVE_TARGETS" | grep -q -w "$TARGET_CODENAME"; then
    cp -a --preserve=all "$SRC_DIR/unica/mods/bootanim/3200x1440/"* "$WORK_DIR/system/system/media"	
else
    echo "Unknown boot animation resolution for \"$TARGET_CODENAME\""
fi

