#!/usr/bin/env bash

SKIPUNZIP=1

EXYNOS_DISP64="$WORK_DIR/vendor/lib64/libexynosdisplay.so"
EXYNOS_DISP32="$WORK_DIR/vendor/lib/libexynosdisplay.so"

# 64-bit: 94000037 (tbnz w20, #0, #0x78e0c) -> 04000014 (b #0x78e0c)
HEX_FROM_64="8a010034940000370b2540f96b554539"
HEX_TO_64="8a010034040000140b2540f96b554539"

if [ -f "$EXYNOS_DISP64" ] && xxd -p -c 0 "$EXYNOS_DISP64" | grep -q "$HEX_FROM_64"; then
    LOG "- Patching 64-bit libexynosdisplay.so for DDIScaler boot resolution fix"
    HEX_PATCH "$EXYNOS_DISP64" "$HEX_FROM_64" "$HEX_TO_64" || return 1
fi

# 32-bit: 1db9 (cbnz r5, #0x593ee) -> 03e0 (b.n #0x593ee)
HEX_FROM_32="92b11db98b6b93f86d30"
HEX_TO_32="92b103e08b6b93f86d30"

if [ -f "$EXYNOS_DISP32" ] && xxd -p -c 0 "$EXYNOS_DISP32" | grep -q "$HEX_FROM_32"; then
    LOG "- Patching 32-bit libexynosdisplay.so for DDIScaler boot resolution fix"
    HEX_PATCH "$EXYNOS_DISP32" "$HEX_FROM_32" "$HEX_TO_32" || return 1
fi

unset EXYNOS_DISP64 EXYNOS_DISP32 HEX_FROM_64 HEX_TO_64 HEX_FROM_32 HEX_TO_32

return 0
