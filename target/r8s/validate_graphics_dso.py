#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Validate a real AArch64 shared object's SONAME without executing it."""
from pathlib import Path
import struct
import sys


def validate(path, expected_soname):
    data = Path(path).read_bytes()
    if len(data) < 64 or data[:6] != b"\x7fELF\x02\x01":
        raise ValueError("Expected an ELF64 little-endian shared library")
    kind, machine = struct.unpack_from("<HH", data, 16)
    if kind != 3 or machine != 183:
        raise ValueError("Expected an AArch64 ET_DYN shared library")
    phoff = struct.unpack_from("<Q", data, 32)[0]
    phsize, count = struct.unpack_from("<HH", data, 54)
    if phsize < 56 or not 0 < count <= 1024 or phoff + count * phsize > len(data):
        raise ValueError("Invalid ELF program-header table")
    loads, dynamic = [], None
    for index in range(count):
        segment = struct.unpack_from("<IIQQQQQQ", data, phoff + index * phsize)
        tag, _, offset, virtual, _, size, _, _ = segment
        if offset + size > len(data):
            raise ValueError("ELF segment extends beyond file")
        if tag == 1:
            loads.append((virtual, offset, size))
        elif tag == 2:
            dynamic = (offset, size)
    if dynamic is None:
        raise ValueError("Missing dynamic table")
    strings, string_size, soname = None, None, None
    for offset in range(dynamic[0], dynamic[0] + dynamic[1] - 15, 16):
        tag, value = struct.unpack_from("<qQ", data, offset)
        if tag == 0:
            break
        if tag == 5:
            strings = value
        elif tag == 10:
            string_size = value
        elif tag == 14:
            soname = value
    if strings is None or string_size is None or soname is None or not 0 <= soname < string_size:
        raise ValueError("Missing or invalid DT_STRTAB/DT_STRSZ/DT_SONAME")
    for virtual, offset, size in loads:
        if virtual <= strings and strings + string_size <= virtual + size:
            table = offset + strings - virtual
            end = data.find(b"\0", table + soname, table + string_size)
            if end == -1:
                raise ValueError("Unterminated SONAME")
            actual = data[table + soname:end].decode("ascii")
            if actual != expected_soname:
                raise ValueError("SONAME mismatch: " + actual)
            return actual
    raise ValueError("Dynamic string table is not backed by a file segment")


if __name__ == "__main__":
    try:
        print(validate(sys.argv[1], sys.argv[2]))
    except (ValueError, OSError, IndexError, struct.error) as failure:
        print("Invalid r8s graphics library: " + str(failure), file=sys.stderr)
        sys.exit(1)
