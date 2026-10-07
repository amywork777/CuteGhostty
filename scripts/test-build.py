import json
import os
from pathlib import Path
import plistlib
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
MOCK = """#!/usr/bin/env python3
import json
import os
from pathlib import Path
import plistlib
import sys

tool = Path(sys.argv[0]).name
args = sys.argv[1:]
with open(os.environ['BUILD_LOG'], 'a') as log:
    log.write(json.dumps([tool, *args]) + '\\n')
if tool == 'uname':
    print(os.environ.get('BUILD_OS', 'Darwin'))
elif tool == 'plutil':
    path = Path(args[-1])
    with path.open('rb') as source:
        data = plistlib.load(source)
    action, key = args[:2]
    if action == '-extract':
        if key not in data:
            sys.exit(1)
        print(data[key])
        sys.exit(0)
    if action == '-remove':
        del data[key]
    elif action == '-replace':
        data[key] = args[3] == 'YES' if args[2] == '-bool' else args[3]
    else:
        sys.exit(2)
    with path.open('wb') as output:
        plistlib.dump(data, output)
elif tool == 'codesign':
    if os.environ.get('FAIL_CODESIGN') in args:
        sys.exit(1)
"""


class BuildTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.repo = self.root / 'repo'
        self.repo.mkdir()
        shutil.copy2(ROOT / 'build.sh', self.repo)
        shutil.copytree(ROOT / 'assets', self.repo / 'assets')
        self.source = self.root / 'Stock Ghostty.app'
        for directory in ['MacOS', 'Resources', 'PlugIns/DockTilePlugin.plugin', 'Frameworks']:
            (self.source / 'Contents' / directory).mkdir(parents=True)
        (self.source / 'Contents/MacOS/ghostty').write_bytes(b'upstream executable')
        (self.source / 'Contents/Frameworks/untouched').write_bytes(b'nested signed component')
        self.plist = {
            'CFBundleIdentifier': 'com.mitchellh.ghostty',
            'CFBundleShortVersionString': '1.3.0',
            'CFBundleVersion': '12345',
            'GhosttyCommit': 'upstream-commit',
            'NSMicrophoneUsageDescription': 'Microphone access',
            'NSDockTilePlugIn': 'DockTilePlugin.plugin',
            'SUEnableAutomaticChecks': True,
        }
        with (self.source / 'Contents/Info.plist').open('wb') as output:
            plistlib.dump(self.plist, output)
        self.bin = self.root / 'bin'
        self.bin.mkdir()
        for name in ['uname', 'plutil', 'codesign', 'security', 'create-dmg']:
            path = self.bin / name
            path.write_text(MOCK)
            path.chmod(0o755)
        self.log = self.root / 'commands.jsonl'
        self.env = {
            **os.environ,
            'PATH': f'{self.bin}:{os.environ["PATH"]}',
            'BUILD_LOG': str(self.log),
            'CODESIGN_IDENTITY': 'Test Developer ID',
            'SKIP_DMG': '1',
            'SKIP_NOTARIZE': '1',
        }
        self.output = self.repo / 'Cute Ghostty.app'

    def run_build(self, **env):
        return subprocess.run(
            ['bash', str(self.repo / 'build.sh'), str(self.source)],
            env={**self.env, **env}, capture_output=True, text=True, timeout=30,
        )

    def commands(self):
        return [json.loads(line) for line in self.log.read_text().splitlines()]

    def test_signed_build_preserves_metadata_and_nested_components(self):
        result = self.run_build()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        with (self.output / 'Contents/Info.plist').open('rb') as source:
            actual = plistlib.load(source)
        for key in ['CFBundleShortVersionString', 'CFBundleVersion', 'GhosttyCommit', 'NSMicrophoneUsageDescription']:
            self.assertEqual(actual[key], self.plist[key])
        self.assertEqual(actual['CFBundleIdentifier'], 'com.amy.cute-ghostty')
        self.assertEqual(actual['CFBundleDisplayName'], 'Cute Ghostty')
        self.assertFalse(actual['SUEnableAutomaticChecks'])
        self.assertNotIn('NSDockTilePlugIn', actual)
        self.assertFalse((self.output / 'Contents/PlugIns/DockTilePlugin.plugin').exists())
        self.assertTrue((self.source / 'Contents/PlugIns/DockTilePlugin.plugin').exists())
        self.assertEqual((self.output / 'Contents/Frameworks/untouched').read_bytes(), b'nested signed component')
        calls = [call for call in self.commands() if call[0] == 'codesign']
        self.assertEqual(calls[0], [
            'codesign', '--force', '--deep', '--sign', 'Test Developer ID', '--options', 'runtime',
            '--entitlements', str(self.repo / 'assets/Ghostty.entitlements'), str(self.output),
        ])
        self.assertEqual(calls[1], ['codesign', '--verify', '--deep', '--strict', str(self.output)])
        self.assertEqual(self.run_build().returncode, 0)

    def test_ad_hoc_build_also_uses_entitlements(self):
        result = self.run_build(CODESIGN_IDENTITY='')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        signing = next(call for call in self.commands() if call[0] == 'codesign')
        self.assertEqual(signing[signing.index('--sign') + 1], '-')
        self.assertIn('--entitlements', signing)

    def test_signing_and_verification_failures_are_fatal(self):
        for identity in ['', 'Test Developer ID']:
            for failure in ['--force', '--verify']:
                with self.subTest(identity=identity, failure=failure):
                    result = self.run_build(CODESIGN_IDENTITY=identity, FAIL_CODESIGN=failure)
                    self.assertNotEqual(result.returncode, 0)
                    self.assertNotIn('Cute Ghostty.app is ready', result.stdout)

    def test_non_macos_build_leaves_existing_output_untouched(self):
        self.output.mkdir()
        marker = self.output / 'keep'
        marker.touch()
        result = self.run_build(BUILD_OS='Linux')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('requires macOS', result.stdout)
        self.assertTrue(marker.exists())

    def test_source_cannot_be_the_output(self):
        shutil.copytree(self.source, self.output)
        self.source = self.output
        result = self.run_build()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('source app cannot be the build output', result.stdout)
        self.assertTrue((self.source / 'Contents/MacOS/ghostty').exists())

    def test_dmg_build_uses_create_dmg(self):
        result = self.run_build(SKIP_DMG='0')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        calls = [call for call in self.commands() if call[0] == 'create-dmg']
        self.assertEqual(len(calls), 1)
        self.assertEqual(calls[0][-2:], [str(self.repo / 'site/CuteGhostty.dmg'), str(self.output)])

    def test_entitlements_include_upstream_permissions(self):
        with (ROOT / 'assets/Ghostty.entitlements').open('rb') as source:
            entitlements = plistlib.load(source)
        self.assertEqual(entitlements, {
            f'com.apple.security.{permission}': True for permission in [
                'automation.apple-events', 'device.audio-input', 'device.camera',
                'personal-information.addressbook', 'personal-information.calendars',
                'personal-information.location', 'personal-information.photos-library',
            ]
        })


if __name__ == '__main__':
    unittest.main()
