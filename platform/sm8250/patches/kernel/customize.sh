LOG "- Replacing kernel binaries"
rm -f "$WORK_DIR/kernel/boot.img"
cp -fa "$SRC_DIR/prebuilts/kernels/y2q/"*.img "$WORK_DIR/kernel/"