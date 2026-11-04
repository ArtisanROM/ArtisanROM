#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Align the tested ARM64 Mali P010 import with r8s' stock gralloc.

Gralloc uses internal format 0x204 for semiplanar P010. This Mali build maps
it to packed Y210 (DRM fourcc Y210), causing doubled/pink video during GPU
composition. Select its existing P010 table entry instead. No codec, HDR,
overlay, blur, GPU clock or other pixel-format paths are disabled.
"""
import hashlib
import os
from pathlib import Path
import stat
import struct
import sys

ORIGINAL_SHA256 = "9ce9377713c7e25290685ab025db5a898eb29db0d9677ce1ca476d32161d682f"
PATCHED_SHA256 = "8a9ff1d037f62bd68d51d5c311b0a13975ee978be793e35a86c01a65f0d2cd2a"
GRALLOC_SHA256 = "1dd0cd1c9d20b224f63f780bfc647f828203e3fb2b5654172aa6d86aed9b70e7"
INSTRUCTION_OFFSET = 0x81D604


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def patch(gpu, gralloc):
    gpu, gralloc = Path(gpu), Path(gralloc)
    # Guard both ends of the interface; an unknown replacement GPU/gralloc
    # must receive an explicit review, rather than the same numeric offset.
    if sha256(gralloc.read_bytes()) != GRALLOC_SHA256:
        raise ValueError("r8s gralloc differs from the physically validated P010 stack")
    original = gpu.read_bytes()
    digest = sha256(original)
    if digest == PATCHED_SHA256:
        print("r8s Mali P010 mapping already corrected")
        return False
    if digest != ORIGINAL_SHA256:
        raise ValueError("Unknown r8s Mali library; refusing an unverified binary patch")
    if original[:6] != b"\x7fELF\x02\x01" or struct.unpack_from("<H", original, 18)[0] != 183:
        raise ValueError("P010 compatibility fix requires the verified AArch64 ELF")
    data = bytearray(original)
    # android_config_interface::get_buffer_fourcc_format, internal 0x204:
    # mov w10,#16 (Y210 table entry) -> mov w10,#17 (P010 table entry).
    if struct.unpack_from("<I", data, INSTRUCTION_OFFSET)[0] != 0x5280020A:
        raise ValueError("Mali P010 instruction does not match the reviewed function")
    struct.pack_into("<I", data, INSTRUCTION_OFFSET, 0x5280022A)
    if sha256(data) != PATCHED_SHA256:
        raise ValueError("Corrected Mali library failed its complete-file integrity check")
    temporary = gpu.with_name(gpu.name + ".p010-tmp")
    try:
        temporary.write_bytes(data)
        temporary.chmod(stat.S_IMODE(gpu.stat().st_mode))
        os.replace(temporary, gpu)
    finally:
        if temporary.exists():
            temporary.unlink()
    print("Corrected r8s Mali internal P010 import; all other instructions retained")
    return True


if __name__ == "__main__":
    try:
        if len(sys.argv) != 3:
            raise ValueError("Usage: fix_p010_mapping.py libGLES_mali.so gralloc.exynos990.so")
        patch(sys.argv[1], sys.argv[2])
    except (OSError, ValueError) as error:
        sys.exit(str(error))
