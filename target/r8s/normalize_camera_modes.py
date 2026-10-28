"""Match the stock r8s front portrait name to the Android 16 camera enum."""
from pathlib import Path
import re
import sys
import xml.etree.ElementTree as ET


def normalize(source):
    root = ET.fromstring(source)
    modes = [node for node in root.iter('local')
             if node.get('name') == 'SHOOTING_MODE_LIVE_FOCUS']
    if len(modes) != 1:
        raise ValueError('Expected exactly one r8s portrait mode')
    front = modes[0].get('front')
    if front == 'SELFIE_FOCUS':
        return source
    if front != 'LIVE_FOCUS_LITE':
        raise ValueError('Unsupported r8s front portrait mode: ' + str(front))
    pattern = r'<local\b[^>]*\bname=[\"\']SHOOTING_MODE_LIVE_FOCUS[\"\'][^>]*>'
    tags = list(re.finditer(pattern, source))
    if len(tags) != 1:
        raise ValueError('Ambiguous r8s portrait XML tag')
    tag = tags[0]
    updated, count = re.subn(r'\bfront=([\"\'])LIVE_FOCUS_LITE\1',
                             r'front=\g<1>SELFIE_FOCUS\g<1>', tag[0])
    if count != 1:
        raise ValueError('Missing exact front portrait attribute')
    return source[:tag.start()] + updated + source[tag.end():]


if __name__ == '__main__':
    path = Path(sys.argv[1])
    old = path.read_text(encoding='utf-8')
    new = normalize(old)
    if new != old:
        path.write_text(new, encoding='utf-8', newline='\n')
