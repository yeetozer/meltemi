#!/usr/bin/env python3
"""Actions-only iOS helpers. No Apple requests occur unless `register` is invoked."""
import base64
import json
import os
from pathlib import Path
import plistlib
import re
import shutil
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parents[1]
BUNDLE = 'com.yeetozer.meltemi'
BASE = 'https://yeetozer.github.io/meltemi-play/ios'


def prepare():
    for name in ('ASC_KEY_ID', 'ASC_ISSUER_ID', 'ASC_KEY_P8_BASE64', 'APPLE_TEAM_ID', 'MELTEMI_PLAY_DEPLOY_KEY'):
        if not os.environ.get(name):
            raise SystemExit('Missing required secret: ' + name)
    udid = os.environ['DEVICE_UDID']
    if not re.fullmatch(r'(?:[0-9A-Fa-f]{8}-[0-9A-Fa-f]{16}|[0-9A-Fa-f]{40})', udid):
        raise SystemExit('Invalid UDID format (value withheld)')
    print('::add-mask::' + udid)
    team = os.environ['APPLE_TEAM_ID']
    if not re.fullmatch(r'[A-Z0-9]{10}', team):
        raise SystemExit('Invalid Apple Team ID')
    key_dir = Path(os.environ['RUNNER_TEMP']) / 'private_keys'
    key_dir.mkdir(mode=0o700, exist_ok=True)
    key = key_dir / ('AuthKey_' + os.environ['ASC_KEY_ID'] + '.p8')
    key.write_bytes(base64.b64decode(os.environ['ASC_KEY_P8_BASE64'], validate=True))
    key.chmod(0o600)
    preset = ROOT / 'game/export_presets.cfg'
    text = preset.read_text().replace('APPLE_TEAM_ID_PLACEHOLDER', team)
    text = text.replace('application/version="0.1.0"', 'application/version="' + os.environ['BUILD_NUMBER'] + '"')
    preset.write_text(text)


def register():
    import jwt  # Installed only on the macOS runner.
    key = Path(os.environ['RUNNER_TEMP']) / 'private_keys' / ('AuthKey_' + os.environ['ASC_KEY_ID'] + '.p8')
    now = int(time.time())
    token = jwt.encode({'iss': os.environ['ASC_ISSUER_ID'], 'iat': now, 'exp': now + 600,
                        'aud': 'appstoreconnect-v1'}, key.read_bytes(), algorithm='ES256',
                       headers={'kid': os.environ['ASC_KEY_ID'], 'typ': 'JWT'})
    print('::add-mask::' + token)

    def request(path, data=None):
        req = urllib.request.Request('https://api.appstoreconnect.apple.com/v1/' + path,
            data=None if data is None else json.dumps(data).encode(),
            headers={'Authorization': 'Bearer ' + token, 'Content-Type': 'application/json'},
            method='GET' if data is None else 'POST')
        try:
            with urllib.request.urlopen(req, timeout=60) as response:
                return json.load(response)
        except urllib.error.HTTPError as error:
            raise SystemExit(f'ASC HTTP {error.code}; response withheld to protect identifiers') from None

    udid = os.environ['DEVICE_UDID']
    path = 'devices?' + urllib.parse.urlencode({'filter[udid]': udid})
    devices = request(path)['data']
    if not devices:
        request('devices', {'data': {'type': 'devices', 'attributes': {
            'udid': udid, 'platform': 'IOS', 'name': os.environ['DEVICE_NAME'] or 'Yigit iPhone 15'}}})
        devices = request(path)['data']
        print('Device registered')
    else:
        print('Device already registered')
    if not devices or any(d['attributes']['status'] != 'ENABLED' for d in devices):
        raise SystemExit('Device read-back failed or device disabled')
    path = 'bundleIds?' + urllib.parse.urlencode({'filter[identifier]': BUNDLE})
    bundles = request(path)['data']
    if not bundles:
        request('bundleIds', {'data': {'type': 'bundleIds', 'attributes': {
            'identifier': BUNDLE, 'name': 'Meltemi', 'platform': 'IOS'}}})
        bundles = request(path)['data']
    if not bundles or any(b['attributes']['identifier'] != BUNDLE for b in bundles):
        raise SystemExit('Bundle ID read-back failed')
    print('Bundle ID ready (no capabilities requested)')


def export_options():
    # Only ios_signing.install may generate options from a validated existing profile.
    raise SystemExit('Use ios_signing.py install for manual signing export options')


def package():
    root = Path(os.environ['RUNNER_TEMP'])
    packages = list((root / 'export-adhoc').glob('*.ipa'))
    if len(packages) != 1:
        raise SystemExit('Expected exactly one IPA')
    if packages[0].stat().st_size >= 100 * 1024 * 1024:
        raise SystemExit('IPA exceeds GitHub per-file limit; use a different HTTPS artifact host')
    out = root / 'ios-publish'
    out.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(dir=root) as tmp:
        with zipfile.ZipFile(packages[0]) as archive:
            archive.extractall(tmp)
        apps = list((Path(tmp) / 'Payload').glob('*.app'))
        if len(apps) != 1:
            raise SystemExit('Expected exactly one app')
        app = apps[0]
        info = plistlib.loads((app / 'Info.plist').read_bytes())
        assert info['CFBundleIdentifier'] == BUNDLE, 'Bundle ID mismatch'
        assert info['CFBundleVersion'] == os.environ['BUILD_NUMBER'], 'Build number mismatch'
        assert info['CFBundleShortVersionString'] == '0.1.0', 'Version mismatch'
        assert info['UIDeviceFamily'] == [1], 'Expected iPhone only'
        assert info['UISupportedInterfaceOrientations'] == ['UIInterfaceOrientationPortrait'], 'Expected portrait only'
        assert float(info['MinimumOSVersion']) >= 15, 'Minimum iOS must be 15+'
        decoded = subprocess.run(['security', 'cms', '-D', '-i', str(app / 'embedded.mobileprovision')],
                                 capture_output=True, check=True)
        profile = plistlib.loads(decoded.stdout)
        devices = profile.get('ProvisionedDevices', [])
        entitlements = profile.get('Entitlements', {})
        assert devices and not profile.get('ProvisionsAllDevices') and not entitlements.get('get-task-allow'), 'Not Ad Hoc'
        assert os.environ['DEVICE_UDID'].lower() in {d.lower() for d in devices}, 'Device missing from profile'
        assert entitlements.get('application-identifier', '').endswith('.' + BUNDLE), 'Profile bundle mismatch'
        assert not entitlements.get('aps-environment') and not entitlements.get('com.apple.developer.game-center'), 'Unexpected capability'
        subprocess.run(['codesign', '--verify', '--deep', '--strict', str(app)], check=True)
        signature = subprocess.run(['codesign', '-dv', '--verbose=4', str(app)], capture_output=True, text=True, check=True)
        report = ('Profile name: ' + profile['Name'] + '\nProfile type: Ad Hoc\nProvisionedDevices count: ' +
                  str(len(devices)) + '\nExpires: ' + str(profile['ExpirationDate']) + '\n' + signature.stderr)
        (out / 'signing-report.txt').write_text(report)
        print(report)
        shutil.copy2(packages[0], out / 'Meltemi.ipa')
        manifest = {'items': [{'assets': [{'kind': 'software-package', 'url': BASE + '/Meltemi.ipa'}],
                    'metadata': {'bundle-identifier': BUNDLE, 'bundle-version': info['CFBundleVersion'],
                                 'kind': 'software', 'title': 'Meltemi'}}]}
        with (out / 'manifest.plist').open('wb') as f:
            plistlib.dump(manifest, f)
        link = 'itms-services://?action=download-manifest&url=' + urllib.parse.quote(BASE + '/manifest.plist', safe='')
        page = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Install Meltemi</title><style>body{background:#F4EBDD;color:#493d34;font:18px system-ui;margin:0;padding:48px 24px}main{max-width:460px;margin:auto}a{display:block;background:#b75c43;color:white;padding:22px;text-align:center;border-radius:16px;text-decoration:none;font-weight:700;margin:32px 0}p{line-height:1.6}</style>
<main><h1>Meltemi</h1><p>A little Mediterranean escape.</p><p>Version 0.1.0 · Build BUILD</p>
<a href="LINK">Install Meltemi</a><p>Open this page in Safari on your registered iPhone. Tap Install Meltemi, confirm Install, then look on your Home Screen.</p>
<p>If it says Unable to install, the device is not registered. Ask for your UDID to be added and a new build, then retry. An expired provisioning profile also needs a new build.</p>
<p>Ad Hoc distribution: Developer Mode is not normally required. This signed build is only for registered testers.</p></main></html>'''
        (out / 'index.html').write_text(page.replace('BUILD', info['CFBundleVersion']).replace('LINK', link.replace('&', '&amp;')))
        with open(os.environ['GITHUB_STEP_SUMMARY'], 'a') as f:
            f.write('## Meltemi iPhone Ad Hoc\nVersion 0.1.0 / build ' + info['CFBundleVersion'] +
                    '\n\nInstall after the Pages deployment finishes: ' + BASE + '/\n\nSigning report and IPA are attached as an artifact.\n')


if __name__ == '__main__':
    {'prepare': prepare, 'register': register, 'export-options': export_options, 'package': package}[sys.argv[1]]()
