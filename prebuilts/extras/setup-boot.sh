#!/sbin/sh

sleep 0.5

[ -f /tmp/lk3rd.img ] || exit 1
[ -f /tmp/boot.img ] || exit 1

if [ -b /dev/block/bootdevice/by-name/lk3rd ]; then
    echo "Installing lk3rd bootloader..."
    cat /tmp/lk3rd.img > /dev/block/bootdevice/by-name/lk3rd

    # If you made the boot image the full 59mb its gonna error, just ignore
    echo "Installing boot image..."
    cat /tmp/boot.img > /dev/block/bootdevice/by-name/boot
else
    echo "Installing lk3rd bootloader and boot..."

    # It's gonna error, just ignore
    cat /tmp/lk3rd.img /tmp/boot.img > /dev/block/bootdevice/by-name/boot
fi

sync
