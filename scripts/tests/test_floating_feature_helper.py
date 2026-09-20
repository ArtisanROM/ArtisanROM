# SPDX-License-Identifier: GPL-3.0-or-later
"""Run the shared floating-feature helper against isolated XML fixtures."""
from pathlib import Path
import re
import subprocess
import tempfile
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
SOURCE = (ROOT / 'scripts/utils/module_utils.sh').read_text()
FUNCTION = re.search(r'^SET_FLOATING_FEATURE_CONFIG\(\)\n\{\n.*?^\}',
                     SOURCE, re.M | re.S).group(0)


class FloatingFeatureTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.xml = Path(self.tmp.name) / 'system/system/etc/floating_feature.xml'
        self.xml.parent.mkdir(parents=True)

    def run_helper(self, commands):
        script = '''set -euo pipefail
WORK_DIR="$1"
_CHECK_NON_EMPTY_PARAM() { test -n "$2"; }
LOG() { :; }
LOGE() { echo "$*" >&2; }
''' + FUNCTION + '\n' + commands
        return subprocess.run(['bash', '-c', script, 'test', self.tmp.name],
                              capture_output=True, text=True)

    def test_insert_update_delete_preserve_longer_key(self):
        self.xml.write_text('<SecFloatingFeatureSet>\n<TEST_LONG>keep</TEST_LONG>\n</SecFloatingFeatureSet>\n')
        for value in ('first', 'second'):
            result = self.run_helper(f'SET_FLOATING_FEATURE_CONFIG TEST {value}')
            self.assertEqual(result.returncode, 0, result.stderr)
            tree = ET.parse(self.xml)
            self.assertEqual(tree.findtext('TEST'), value)
            self.assertEqual(tree.findtext('TEST_LONG'), 'keep')
        self.assertEqual(self.run_helper('SET_FLOATING_FEATURE_CONFIG TEST --delete').returncode, 0)
        self.assertIsNone(ET.parse(self.xml).find('TEST'))
        before = self.xml.read_bytes()
        self.assertEqual(self.run_helper('SET_FLOATING_FEATURE_CONFIG TEST --delete').returncode, 0)
        self.assertEqual(self.xml.read_bytes(), before)

    def test_duplicate_tags_are_rejected_without_changes(self):
        for separator in ('\n', ''):
            for operation in ('new', '--delete'):
                with self.subTest(separator=separator, operation=operation):
                    self.xml.write_text('<SecFloatingFeatureSet>\n<TEST>a</TEST>' + separator +
                                        '<TEST>b</TEST>\n</SecFloatingFeatureSet>\n')
                    before = self.xml.read_bytes()
                    result = self.run_helper(f'SET_FLOATING_FEATURE_CONFIG TEST {operation}')
                    self.assertNotEqual(result.returncode, 0)
                    self.assertEqual(self.xml.read_bytes(), before)

    def test_missing_file_fails(self):
        self.assertNotEqual(self.run_helper('SET_FLOATING_FEATURE_CONFIG TEST new').returncode, 0)
        self.assertFalse(self.xml.exists())


if __name__ == '__main__':
    unittest.main()
