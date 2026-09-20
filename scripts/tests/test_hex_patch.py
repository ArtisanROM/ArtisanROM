# SPDX-License-Identifier: GPL-3.0-or-later
"""Byte matching, atomic failure handling and shell caller regressions."""
import contextlib
import importlib.util
import io
from pathlib import Path
import re
import subprocess
import tempfile
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location('hex_patch', ROOT / 'scripts/utils/hex_patch.py')
HELPER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(HELPER)


class HexPatchTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.path = Path(self.tmp.name) / 'input.bin'
        self.path.write_bytes(bytes.fromhex('012345'))
        self.path.chmod(0o751)

    def run_helper(self, source, replacement):
        with contextlib.redirect_stderr(io.StringIO()):
            return HELPER.main([str(self.path), source, replacement])

    def assert_preserved(self, data):
        self.assertEqual(self.path.read_bytes(), data)
        self.assertEqual(self.path.stat().st_mode & 0o777, 0o751)
        self.assertEqual(list(self.path.parent.glob('*.patch.*')), [])

    def test_half_byte_match_is_absent(self):
        self.assertEqual(self.run_helper('1234', 'abcd'), 1)
        self.assert_preserved(bytes.fromhex('012345'))

    def test_skips_half_byte_match_and_patches_first_real_match(self):
        self.path.write_bytes(bytes.fromhex('01234512341234'))
        self.assertEqual(self.run_helper('1234', 'ABCD'), 0)
        self.assert_preserved(bytes.fromhex('012345abcd1234'))

    def test_length_changing_and_nul_patterns(self):
        self.path.write_bytes(bytes.fromhex('00110011'))
        self.assertEqual(self.run_helper('0011', 'ff'), 0)
        self.assert_preserved(bytes.fromhex('ff0011'))
        self.assertEqual(self.run_helper('ff', '000102'), 0)
        self.assert_preserved(bytes.fromhex('0001020011'))

    def test_identity_match_succeeds(self):
        self.assertEqual(self.run_helper('0123', '0123'), 0)
        self.assert_preserved(bytes.fromhex('012345'))

    def test_invalid_hex_does_not_touch_original(self):
        for value in ('', '0', 'zz', '01 23', '0x12', '12\n', '.*', '12/34'):
            for source, replacement in ((value, 'abcd'), ('0123', value)):
                with self.subTest(source=source, replacement=replacement):
                    self.assertEqual(self.run_helper(source, replacement), 2)
                    self.assert_preserved(bytes.fromhex('012345'))

    def test_missing_input(self):
        self.path.unlink()
        self.assertEqual(self.run_helper('0123', 'abcd'), 2)
        self.assertFalse(self.path.exists())

    def test_symlink_rejected(self):
        target = self.path.with_name('target.bin')
        self.path.rename(target)
        self.path.symlink_to(target.name)
        self.assertEqual(self.run_helper('0123', 'abcd'), 2)
        self.assertTrue(self.path.is_symlink())
        self.assertEqual(target.read_bytes(), bytes.fromhex('012345'))

    def test_empty_file_is_no_match(self):
        self.path.write_bytes(b'')
        self.assertEqual(self.run_helper('0123', 'abcd'), 1)
        self.assert_preserved(b'')

    def test_io_failures_preserve_original(self):
        for name in ('fchmod', 'fsync', 'replace'):
            with self.subTest(stage=name):
                with mock.patch.object(HELPER.os, name, side_effect=OSError('injected failure')):
                    self.assertEqual(self.run_helper('0123', 'abcd'), 2)
                self.assert_preserved(bytes.fromhex('012345'))

    def test_temporary_file_creation_failure(self):
        with mock.patch.object(HELPER.tempfile, 'NamedTemporaryFile', side_effect=OSError('injected failure')):
            self.assertEqual(self.run_helper('0123', 'abcd'), 2)
        self.assert_preserved(bytes.fromhex('012345'))

    def test_write_failure(self):
        real_factory = HELPER.tempfile.NamedTemporaryFile
        def failing_factory(*args, **kwargs):
            output = real_factory(*args, **kwargs)
            output.write = mock.Mock(side_effect=OSError('injected write failure'))
            return output
        with mock.patch.object(HELPER.tempfile, 'NamedTemporaryFile', side_effect=failing_factory):
            self.assertEqual(self.run_helper('0123', 'abcd'), 2)
        self.assert_preserved(bytes.fromhex('012345'))

    def test_read_failure(self):
        with mock.patch.object(HELPER.Path, 'read_bytes', side_effect=OSError('injected read failure')):
            self.assertEqual(self.run_helper('0123', 'abcd'), 2)
        self.assert_preserved(bytes.fromhex('012345'))

    def test_cli_status_and_shell_wrapper(self):
        source = (ROOT / 'scripts/utils/module_utils.sh').read_text()
        function = re.search(r'^HEX_PATCH\(\)\n\{\n.*?^\}', source, re.M | re.S).group(0)
        script = '''set -e
SRC_DIR="$1"
WORK_DIR="$2"
_CHECK_NON_EMPTY_PARAM() { test -n "$2"; }
LOG() { :; }
LOGE() { :; }
''' + function + '\nHEX_PATCH "$WORK_DIR/input.bin" "$3" "$4"\n'
        for pattern, expected in (('1234', 1), ('invalid', 2), ('0123', 0)):
            result = subprocess.run(['bash', '-c', script, 'test', str(ROOT), self.tmp.name,
                                     pattern, 'abcd'], capture_output=True)
            self.assertEqual(result.returncode, expected, result.stderr)
        self.assert_preserved(bytes.fromhex('abcd45'))

    def test_bluetooth_fallback_only_on_absent_pattern(self):
        source = (ROOT / 'unica/patches/bluetooth/customize.sh').read_text()
        block = source[source.index('BT_HEX_STATUS=0'):source.index('unset BT_HEX_STATUS')]
        for first, calls, status in ((0, 1, 0), (1, 2, 0), (2, 1, 1)):
            with self.subTest(first=first):
                script = f"first_status={first}\n" + '''set -e
TMP_DIR=unused
LOGE() { :; }
calls=0
HEX_PATCH() { calls=$((calls + 1)); if [ "$calls" -eq 1 ]; then return "$first_status"; fi; }
'''
                script += 'apply() {\n' + block + '\n}\nstatus=0\napply || status=$?\nprintf "%s %s" "$calls" "$status"\n'
                result = subprocess.run(['bash', '-c', script], capture_output=True, text=True)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout, f'{calls} {status}')


if __name__ == '__main__':
    unittest.main()
