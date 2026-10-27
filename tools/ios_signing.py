#!/usr/bin/env python3
"""Reuse an existing identity and existing Ad Hoc profile; never create either."""
import base64
import datetime
import hashlib
import json
import os
from pathlib import Path
import plistlib
import secrets
import subprocess
import sys
import time
import urllib.parse
import urllib.request


def command(*args):
    return subprocess.run(args, check=True, capture_output=True).stdout


def install():
    import jwt
    root = Path(os.environ['RUNNER_TEMP'])
    for key in ('IOS_DISTRIBUTION_P12_BASE64', 'IOS_DISTRIBUTION_P12_PASSWORD', 'IOS_ADHOC_PROFILE_NAME'):
        if not os.environ.get(key):
            raise RuntimeError('Missing required secret: ' + key)
    original = command('security', 'list-keychains', '-d', 'user').decode()
    # JSON array avoids interpreting shell quoting when restoring the search list.
    import shlex
    (root / 'original-keychains.json').write_text(json.dumps(shlex.split(original)))
    keychain = str(root / 'meltemi-signing.keychain-db')
    password = secrets.token_urlsafe(32)
    p12 = root / 'distribution.p12'
    p12.write_bytes(base64.b64decode(os.environ['IOS_DISTRIBUTION_P12_BASE64'], validate=True))
    p12.chmod(0o600)
    try:
        command('security', 'create-keychain', '-p', password, keychain)
        command('security', 'set-keychain-settings', '-lut', '21600', keychain)
        command('security', 'unlock-keychain', '-p', password, keychain)
        command('security', 'import', str(p12), '-k', keychain, '-P', os.environ['IOS_DISTRIBUTION_P12_PASSWORD'],
                '-T', '/usr/bin/codesign', '-T', '/usr/bin/security')
        command('security', 'set-key-partition-list', '-S', 'apple-tool:,apple:,codesign:', '-s', '-k', password, keychain)
        command('security', 'list-keychains', '-d', 'user', '-s', keychain, *shlex.split(original))
    finally:
        p12.unlink(missing_ok=True)
    now = int(time.time())
    key = root / 'private_keys' / ('AuthKey_' + os.environ['ASC_KEY_ID'] + '.p8')
    token = jwt.encode({'iss': os.environ['ASC_ISSUER_ID'], 'iat': now, 'exp': now + 600,
                        'aud': 'appstoreconnect-v1'}, key.read_bytes(), algorithm='ES256',
                       headers={'kid': os.environ['ASC_KEY_ID'], 'typ': 'JWT'})
    params = {'filter[name]': os.environ['IOS_ADHOC_PROFILE_NAME'], 'filter[profileState]': 'ACTIVE',
              'filter[profileType]': 'IOS_APP_ADHOC', 'fields[profiles]': 'name,profileContent', 'limit': '200'}
    url = 'https://api.appstoreconnect.apple.com/v1/profiles?' + urllib.parse.urlencode(params)
    profiles = []
    while url:
        if not url.startswith('https://api.appstoreconnect.apple.com/v1/'):
            raise RuntimeError('Unexpected pagination origin')
        request = urllib.request.Request(url, headers={'Authorization': 'Bearer ' + token}, method='GET')
        with urllib.request.urlopen(request, timeout=60) as response:
            payload = json.load(response)
        profiles.extend(p for p in payload['data'] if p['attributes']['name'] == os.environ['IOS_ADHOC_PROFILE_NAME'])
        url = payload.get('links', {}).get('next')
    if len(profiles) != 1:
        raise RuntimeError('Need exactly one existing active named Ad Hoc profile; lead must provision it outside CI')
    temporary = root / 'adhoc.mobileprovision'
    temporary.write_bytes(base64.b64decode(profiles[0]['attributes']['profileContent'], validate=True))
    temporary.chmod(0o600)
    profile = plistlib.loads(command('security', 'cms', '-D', '-i', str(temporary)))
    entitlements = profile['Entitlements']
    team = os.environ['APPLE_TEAM_ID']
    assert profile['TeamIdentifier'] == [team], 'Profile team mismatch'
    assert entitlements['application-identifier'].split('.', 1)[1] == 'com.yeetozer.meltemi', 'Profile bundle mismatch'
    assert not entitlements.get('get-task-allow') and not profile.get('ProvisionsAllDevices'), 'Not Ad Hoc'
    assert os.environ['DEVICE_UDID'].lower() in {d.lower() for d in profile.get('ProvisionedDevices', [])}, 'Device absent: lead must update existing profile'
    assert profile['ExpirationDate'] > datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None), 'Profile expired'
    identities = command('security', 'find-identity', '-v', '-p', 'codesigning', keychain).decode()
    matches = [hashlib.sha1(cert).hexdigest().upper() for cert in profile['DeveloperCertificates']
               if hashlib.sha1(cert).hexdigest().upper() in identities]
    if len(matches) != 1:
        raise RuntimeError('Existing profile must contain the imported valid distribution identity')
    directory = Path.home() / 'Library/MobileDevice/Provisioning Profiles'
    directory.mkdir(parents=True, exist_ok=True)
    installed = directory / (profile['UUID'] + '.mobileprovision')
    installed.write_bytes(temporary.read_bytes())
    installed.chmod(0o600)
    (root / 'installed-profile-path').write_text(str(installed))
    print('::add-mask::' + matches[0])
    print('::add-mask::' + profile['UUID'])
    print('::add-mask::' + profile['Name'])
    with open(os.environ['GITHUB_ENV'], 'a') as env:
        env.write('SIGNING_IDENTITY=' + matches[0] + '\n')
        env.write('SIGNING_PROFILE_UUID=' + profile['UUID'] + '\n')
    with (root / 'ExportOptions.plist').open('wb') as output:
        plistlib.dump({'method': 'release-testing', 'destination': 'export', 'teamID': team,
                      'signingStyle': 'manual', 'signingCertificate': matches[0],
                      'provisioningProfiles': {'com.yeetozer.meltemi': profile['UUID']},
                      'manageAppVersionAndBuildNumber': False, 'stripSwiftSymbols': True, 'thinning': '<none>'}, output)
    print('Existing signing identity and existing Ad Hoc profile validated (identifiers withheld)')


def cleanup():
    root = Path(os.environ['RUNNER_TEMP'])
    original = root / 'original-keychains.json'
    if original.exists():
        command('security', 'list-keychains', '-d', 'user', '-s', *json.loads(original.read_text()))
    keychain = root / 'meltemi-signing.keychain-db'
    if keychain.exists():
        command('security', 'delete-keychain', str(keychain))
    installed = root / 'installed-profile-path'
    if installed.exists():
        Path(installed.read_text()).unlink(missing_ok=True)
    for name in ('distribution.p12', 'adhoc.mobileprovision', 'installed-profile-path', 'original-keychains.json'):
        (root / name).unlink(missing_ok=True)


if __name__ == '__main__':
    try:
        {'install': install, 'cleanup': cleanup}[sys.argv[1]]()
    except Exception:
        # API/security errors can embed full identifiers or private response bodies.
        raise SystemExit('Signing setup/cleanup failed; verify secrets, identity validity and existing profile/device coverage (details withheld)') from None
