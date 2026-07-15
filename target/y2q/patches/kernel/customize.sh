LOG "- Replacing kernel binaries"

# Clean old outputs
rm -f "$WORK_DIR/kernel/boot.img"
rm -f "$WORK_DIR/kernel/dtbo.img"

BOOT_PARTS="$SRC_DIR/platform/kernels/y2q/boot.img.part*"
BOOT_FULL="$SRC_DIR/platform/kernels/y2q/boot.img"

# Case 1: Merge boot.img parts if they exist
if ls $BOOT_PARTS >/dev/null 2>&1; then
    LOG "- Found boot.img parts, merging..."
    cat $BOOT_PARTS > "$WORK_DIR/kernel/boot.img"
    LOG "- Merged boot.img parts into $WORK_DIR/kernel/boot.img"

# Case 2: If no parts, but full boot.img exists, copy it
elif [ -f "$BOOT_FULL" ]; then
    LOG "- Found full boot.img, copying..."
    cp -fa "$BOOT_FULL" "$WORK_DIR/kernel/boot.img"

# Case 3: Neither parts nor full boot.img found
else
    LOG "- No boot.img parts or full boot.img found, skipping"
fi

# Always copy dtbo.img if present
if [ -f "$SRC_DIR/platform/kernels/y2q/dtbo.img" ]; then
    cp -fa "$SRC_DIR/platform/kernels/y2q/dtbo.img" "$WORK_DIR/kernel/"
    LOG "- Copied dtbo.img to $WORK_DIR/kernel/"
else
    LOG "- No dtbo.img found, skipping"
fi
