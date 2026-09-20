#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Replace the first byte match atomically: 0 success, 1 absent, 2 error."""
import os
from pathlib import Path
import re
import stat
import sys
import tempfile


def parse_hex(value):
    if not re.fullmatch(r'(?:[0-9a-fA-F]{2})+', value):
        raise ValueError('patterns must contain nonempty hexadecimal byte pairs')
    return bytes.fromhex(value)


def patch_file(path, source, replacement):
    path = Path(path)
    info = path.lstat()
    if not stat.S_ISREG(info.st_mode):
        raise ValueError('input must be a regular file, not a symlink')
    data = path.read_bytes()
    offset = data.find(source)
    if offset < 0:
        return 1
    patched = data[:offset] + replacement + data[offset + len(source):]
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(dir=path.parent, prefix=path.name + '.patch.',
                                         delete=False) as output:
            temporary = Path(output.name)
            output.write(patched)
            output.flush()
            os.fchmod(output.fileno(), stat.S_IMODE(info.st_mode))
            os.fsync(output.fileno())
        os.replace(temporary, path)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)
    return 0


def main(argv=None):
    args = sys.argv[1:] if argv is None else argv
    if len(args) != 3:
        print('Usage: hex_patch.py FILE FROM_HEX TO_HEX', file=sys.stderr)
        return 2
    try:
        source, replacement = (parse_hex(value) for value in args[1:])
        status = patch_file(args[0], source, replacement)
        if status == 1:
            print('HEX_PATCH: byte pattern not found', file=sys.stderr)
        return status
    except (OSError, ValueError) as error:
        print(f'HEX_PATCH: {error}', file=sys.stderr)
        return 2


if __name__ == '__main__':
    sys.exit(main())
