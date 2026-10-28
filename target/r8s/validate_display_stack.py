#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Reject corrupt/potentially mixed native display ABIs before staging them."""
from pathlib import Path
import hashlib
import os
import struct
import sys

EXPECTED = {
    'bin/surfaceflinger': '3a7b061c2e23455f354c4174264afeca626b62e13524d596d8c2780b419b3b99',
    'lib64/libgui.so': '6cc12b84636fa08318f3d69c9ef48f2c4beb0e79f755b7062da6beb344fdddee',
    'lib64/libui.so': '66cf7bc7ef40bda9ab6b08cc9a2a05610cd37f753ff89a377e946a1beebd4942',
}


def elf_contract(path):
    data = Path(path).read_bytes()
    if data[:6] != b'\x7fELF\x02\x01' or struct.unpack_from('<HH', data, 16) != (3, 183):
        raise ValueError('Expected an AArch64 ELF64 ET_DYN: ' + str(path))
    phoff = struct.unpack_from('<Q', data, 32)[0]
    phsize, phnum = struct.unpack_from('<HH', data, 54)
    shoff = struct.unpack_from('<Q', data, 40)[0]
    shsize, shnum = struct.unpack_from('<HH', data, 58)
    if phsize < 56 or phoff + phsize * phnum > len(data) or shsize != 64 or shoff + shsize * shnum > len(data):
        raise ValueError('Truncated ELF header table: ' + str(path))
    for index in range(phnum):
        fields = struct.unpack_from('<IIQQQQQQ', data, phoff + index * phsize)
        if fields[2] + fields[5] > len(data):
            raise ValueError('ELF segment outside file: ' + str(path))
    sections = [struct.unpack_from('<IIQQQQIIQQ', data, shoff + index * shsize) for index in range(shnum)]
    def string(table, offset):
        start, size = table[4], table[5]
        if offset >= size:
            raise ValueError('ELF string offset outside table')
        end = data.find(b'\0', start + offset, start + size)
        if end < 0:
            raise ValueError('Unterminated ELF string')
        return data[start + offset:end].decode('ascii')
    exports, needed = set(), []
    for section in sections:
        if section[4] + section[5] > len(data):
            raise ValueError('ELF section outside file: ' + str(path))
        if section[1] == 11:
            if section[9] != 24 or section[6] >= shnum:
                raise ValueError('Invalid dynamic symbol table')
            for offset in range(section[4], section[4] + section[5], 24):
                name, info, _, index, _, _ = struct.unpack_from('<IBBHQQ', data, offset)
                if name and index and info >> 4 in (1, 2):
                    exports.add(string(sections[section[6]], name))
        elif section[1] == 6:
            for offset in range(section[4], section[4] + section[5], 16):
                tag, value = struct.unpack_from('<qQ', data, offset)
                if tag == 0:
                    break
                if tag == 1:
                    needed.append(string(sections[section[6]], value))
    return exports, needed


def validate(blobs, source=None):
    blobs = Path(blobs)
    for relative, expected in EXPECTED.items():
        path = blobs / relative
        if hashlib.sha256(path.read_bytes()).hexdigest() != expected:
            raise ValueError('Native display blob changed; review its ABI before use: ' + relative)
        _, needed = elf_contract(path)
        if source:
            for name in needed:
                if not os.path.lexists(Path(source) / 'lib64' / name):
                    raise ValueError(relative + ' requires missing source DSO ' + name)
    if source:
        original, _ = elf_contract(Path(source) / 'lib64/libgui.so')
        pinned, _ = elf_contract(blobs / 'lib64/libgui.so')
        if pinned != original:
            raise ValueError('Source libgui ABI differs from the physically tested r8s stack')


if __name__ == '__main__':
    try:
        validate(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else None)
    except (ValueError, OSError, IndexError, struct.error) as error:
        print('Invalid r8s native display stack: ' + str(error), file=sys.stderr)
        sys.exit(1)
