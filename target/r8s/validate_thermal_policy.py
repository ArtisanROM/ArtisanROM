#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Check policy names against the exact decoded service, before repacking it."""
from pathlib import Path
import re
import sys
import xml.etree.ElementTree as ET


def validate(policy, decoded):
    suffix = 'com/sec/android/sdhms/thermal/overheatcontrol/overheatcomplex/OverheatComplexType.smali'
    classes = list(Path(decoded).glob('smali*/' + suffix))
    if len(classes) != 1:
        raise ValueError('Cannot locate the exact OverheatComplexType enum')
    text = classes[0].read_text()
    match = re.search(r'^\.method[^\n]* <clinit>\(\)V\n(.*?)^\.end method', text, re.M | re.S)
    if not match:
        raise ValueError('Cannot inspect OverheatComplexType initialization')
    supported = set(re.findall(r'const-string(?:/jumbo)?\s+\w+,\s+"([A-Z][A-Z0-9_]*)"', match[1]))
    names = {node.tag for node in ET.parse(policy).findall('./overheatcontrol/complex/*')}
    if not supported or names - supported:
        raise ValueError('Unsupported overheat policy names: ' + ', '.join(sorted(names - supported)))


if __name__ == '__main__':
    try:
        validate(sys.argv[1], sys.argv[2])
    except (ValueError, OSError, IndexError, ET.ParseError) as error:
        print('Invalid r8s thermal policy: ' + str(error), file=sys.stderr)
        sys.exit(1)
