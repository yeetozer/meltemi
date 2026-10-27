"""Offline fixture tests: no Apple requests or actual keychain operations."""
import base64
import contextlib
import datetime
import hashlib
import importlib.util
import io
import json
import os
from pathlib import Path
import plistlib
import sys
import tempfile
import types
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('ios_signing', Path(__file__).with_name('ios_signing.py'))
assert spec is not None and spec.loader is not None
signing = importlib.util.module_from_spec(spec)
spec.loader.exec_module(signing)


class SigningTests(unittest.TestCase):
    def exercise(self, missing_device=False, wrong_cert=False, expired=False):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'private_keys').mkdir()
            (root / 'private_keys/AuthKey_fixture.p8').write_bytes(b'fixture-not-a-key')
            certificate = b'fixture-not-a-certificate'
            fingerprint = hashlib.sha1(certificate).hexdigest().upper()
            profile = {'UUID': 'fixture-profile', 'Name': 'Fixture Ad Hoc', 'TeamIdentifier': ['FIXTURE123'],
                       'Entitlements': {'application-identifier': 'FIXTURE123.com.yeetozer.meltemi', 'get-task-allow': False},
                       'ProvisionedDevices': [] if missing_device else ['fixture-device'],
                       'ExpirationDate': datetime.datetime(2000 if expired else 2099, 1, 1),
                       'DeveloperCertificates': [certificate]}
            payload = {'data': [{'attributes': {'name': 'Fixture Ad Hoc',
                        'profileContent': base64.b64encode(b'fixture-profile-content').decode()}}], 'links': {'next': None}}
            requests, commands = [], []
            def request(req, **kwargs):
                requests.append(req)
                return io.BytesIO(json.dumps(payload).encode())
            def command(*args):
                commands.append(args)
                if args[1] == 'list-keychains' and '-s' not in args:
                    return b'"/fixture/login.keychain-db"\n'
                if args[1] == 'cms':
                    return plistlib.dumps(profile)
                if args[1] == 'find-identity':
                    return ('NO MATCH' if wrong_cert else fingerprint + ' "Apple Distribution: Fixture"').encode()
                return b''
            env = {'RUNNER_TEMP': directory, 'ASC_KEY_ID': 'fixture', 'ASC_ISSUER_ID': 'fixture',
                   'APPLE_TEAM_ID': 'FIXTURE123', 'DEVICE_UDID': 'fixture-device',
                   'IOS_DISTRIBUTION_P12_BASE64': base64.b64encode(b'fixture-p12').decode(),
                   'IOS_DISTRIBUTION_P12_PASSWORD': 'fixture-password',
                   'IOS_ADHOC_PROFILE_NAME': 'Fixture Ad Hoc', 'GITHUB_ENV': str(root / 'env')}
            fake_jwt = types.SimpleNamespace(encode=lambda *args, **kwargs: 'fixture-jwt')
            with patch.dict(os.environ, env), patch.dict(sys.modules, {'jwt': fake_jwt}), \
                 patch.object(signing, 'command', command), patch.object(signing.Path, 'home', return_value=root), \
                 patch.object(signing.urllib.request, 'urlopen', request), contextlib.redirect_stdout(io.StringIO()):
                try:
                    signing.install()
                    options = plistlib.loads((root / 'ExportOptions.plist').read_bytes())
                    self.assertEqual(options['signingStyle'], 'manual')
                    self.assertEqual(options['signingCertificate'], fingerprint)
                    self.assertEqual(options['provisioningProfiles'], {'com.yeetozer.meltemi': 'fixture-profile'})
                    self.assertTrue(all(req.get_method() == 'GET' for req in requests))
                    self.assertFalse((root / 'distribution.p12').exists())
                finally:
                    signing.cleanup()
                self.assertFalse((root / 'Library/MobileDevice/Provisioning Profiles/fixture-profile.mobileprovision').exists())
                self.assertIn(('security', 'list-keychains', '-d', 'user', '-s', '/fixture/login.keychain-db'), commands)

    def test_registered_device_is_get_only(self):
        ci_spec = importlib.util.spec_from_file_location('ios_ci', Path(__file__).with_name('ios_ci.py'))
        assert ci_spec is not None and ci_spec.loader is not None
        ci = importlib.util.module_from_spec(ci_spec)
        ci_spec.loader.exec_module(ci)
        replies = [
            {'data': [{'attributes': {'status': 'ENABLED'}}]},
            {'data': [{'attributes': {'identifier': 'com.yeetozer.meltemi'}}]},
        ]
        requests = []
        def request(req, **kwargs):
            requests.append(req)
            return io.BytesIO(json.dumps(replies.pop(0)).encode())
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'private_keys').mkdir()
            (root / 'private_keys/AuthKey_fixture.p8').write_bytes(b'fixture')
            env = {'RUNNER_TEMP': directory, 'ASC_KEY_ID': 'fixture',
                   'ASC_ISSUER_ID': 'fixture', 'DEVICE_UDID': 'fixture-device'}
            with patch.dict(os.environ, env), \
                 patch.dict(sys.modules, {'jwt': types.SimpleNamespace(encode=lambda *a, **kw: 'fixture')}), \
                 patch.object(ci.urllib.request, 'urlopen', request), contextlib.redirect_stdout(io.StringIO()):
                ci.register()
        self.assertEqual(len(requests), 2)
        self.assertTrue(all(req.get_method() == 'GET' for req in requests))

    def test_valid_existing_identity_and_profile(self):
        self.exercise()

    def test_missing_device_fails_closed(self):
        with self.assertRaisesRegex(AssertionError, 'Device absent'):
            self.exercise(missing_device=True)

    def test_certificate_mismatch_fails_closed(self):
        with self.assertRaisesRegex(RuntimeError, 'imported valid'):
            self.exercise(wrong_cert=True)

    def test_expired_profile_fails_closed(self):
        with self.assertRaisesRegex(AssertionError, 'expired'):
            self.exercise(expired=True)


if __name__ == '__main__':
    unittest.main()
