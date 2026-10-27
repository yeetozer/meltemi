# iPhone Ad Hoc build (manual only)

The lead must add repository Actions secrets **ASC_KEY_ID**, **ASC_ISSUER_ID**,
**ASC_KEY_P8_BASE64** (base64-encoded Apple .p8 key), **APPLE_TEAM_ID**, and
**MELTEMI_PLAY_DEPLOY_KEY**. The Apple key needs permission to register devices and
bundle IDs and read existing provisioning profiles. Signing uses a persistent local
identity, not automatic certificate creation. The deploy key is an SSH private key whose public half is a write-enabled
deploy key on `yeetozer/meltemi-play` only; the source GITHUB_TOKEN cannot push there.
Never commit keys or put a token in dispatch inputs.

```sh
gh workflow run ios-adhoc.yml -R yeetozer/meltemi   # uses the IPHONE_UDID secret
```

This registers an absent device (consuming an annual Apple device slot), ensures
`com.yeetozer.meltemi` exists without adding capabilities, downloads the official
Godot 4.7.2 editor and matching templates, checks published SHA512 sums when
available, exports an Xcode project, then archives/exports using the same imported
distribution identity, manual signing, and Xcode's `release-testing` (Ad Hoc) method. Build numbers are
`1000.<workflow run number>`; marketing version is 0.1.0.

Expected output: an IPA + manifest + signing-report workflow artifact (7 days),
and https://yeetozer.github.io/meltemi-play/ios/ after the existing Pages deployment
finishes. Open in Safari on the registered iPhone and tap **Install Meltemi**.
Developer Mode is not normally needed for Ad Hoc. To add another tester, run the
same command with their UDID/name: previously registered devices remain registered
and the lead must update the existing Ad Hoc profile in the developer portal to
include the new device before rebuilding. CI deliberately never creates or updates
certificates/profiles. Each rebuild must include the
requested device; the workflow checks the exported profile, not just the archive.
Apple device limits, account agreements, certificate permissions or profile expiry
can require attention in the developer account. Public IPAs contain embedded
provisioning profiles (including registered UDIDs); the install URL is not access
control. Raw signing logs and private keys are not published; keys are deleted
in an always-run cleanup. On signing failure, raw logs stay on the ephemeral runner
rather than leaking device IDs in Actions output.

## Reusable signing setup (lead action required before merging/running)

Add these repository Actions secrets, without putting their values in chat or logs:

- `IOS_DISTRIBUTION_P12_BASE64`: base64 of a password-protected PKCS#12 containing
  ONE existing Apple Distribution (or compatible iOS Distribution) certificate AND
  its private key. Export from the machine/password manager that owns that key.
  The inventory's existing iOS distribution identity may be reusable only if its
  private key is available; the ASC API cannot recover private keys. Do not create
  or revoke any certificate as part of this investigation.
- `IOS_DISTRIBUTION_P12_PASSWORD`: the PKCS#12 export password.
- `IOS_ADHOC_PROFILE_NAME`: exact name of one existing active iOS Ad Hoc profile for
  `com.yeetozer.meltemi`, containing that distribution certificate and the tester.
  The read-only inventory currently found no such profile: a lead must separately
  arrange provisioning in the developer portal before enabling this branch. This
  patch intentionally fails closed rather than creating a profile or certificate.

`tools/ios_signing.py` imports the identity into a temporary unlocked keychain,
fetches the exact named active profile with GET requests only, checks team, bundle,
expiry, device membership, Ad Hoc entitlements and certificate/private-key match,
and installs it locally. Archive and export both use manual signing; neither has
`-allowProvisioningUpdates` or API credentials, so Xcode cannot create signing
assets. The existing device/bundle registration step is unchanged. An always-run
cleanup restores the keychain search list and removes the temporary keychain,
profile and PKCS#12. Native execution remains untested until the lead authorizes
an iOS build; no iOS workflow was dispatched during this preparation.

### Why not unsigned archive + cloud signing?

Apple documents cloud-signing reuse and automatic rotation, with the newest
certificate used across signing requests:
https://developer.apple.com/help/account/certificates/cloud-managed-certificates/
Apple's WWDC21 session documents command-line export with API credentials:
https://developer.apple.com/videos/play/wwdc2021/10204/
However, that session explicitly describes an archive as a developer-signed release
build. These sources do not establish that this Godot unsigned archive can be
exported with cloud signing, nor explicitly establish exemption from certificate
quotas. A successful GET of certificates/profiles proves read access, NOT that the
key is Admin or has cloud-signing privileges. Therefore option 2 is the conservative
fix: reuse an existing local identity, with no speculative automatic-signing fallback.

### Read-only diagnosis, 2026-10-27

Inventory: https://github.com/yeetozer/meltemi/actions/runs/40498432543
It returned 11 DEVELOPMENT certificates (10 named Created via API), one
IOS_DISTRIBUTION certificate, and one active Ad Hoc profile for another app.
Certificate creation timestamps are not exposed by the requested certificate
schema; expiration timestamps are not proof of creation time. The failure is at
archive, which previously demanded Apple Development on a fresh runner. Repeated
API-created development certificates strongly support keychain churn exhausting
the development quota, not distribution-certificate exhaustion. ComicPort's Ad Hoc
and TestFlight workflows also automatically sign archives on fresh macOS runners
with API credentials; do not attribute every certificate solely to Meltemi.
No certificate can be labeled safe to revoke from this metadata alone. Developer
cert revocation affects development profiles/builds, not already distribution-signed
Ad Hoc apps; distribution revocation can break Ad Hoc installs/running apps and
profiles across this shared team. No revocations were performed.

## Preset and deployment

The existing GL Compatibility renderer is retained: Godot supports it on iOS,
and this 2D game already uses it. iPhone only, portrait (existing project setting),
iOS 15+, cream launch screen; Game Center/push disabled. `ios_icon.png` is the
existing `art/src/icon.svg` artwork (via `game/assets/ui/icon.png`), converted to
1024×1024 RGB PNG with no alpha. CI replaces the non-secret Team ID placeholder
and build version in its checkout only. No iOS templates or Mac are required locally.

The deploy checkout targets the existing `meltemi-play` main branch and stages
only `ios/Meltemi.ipa`, `ios/manifest.plist`, `ios/index.html`; it rebases on concurrent
web publications and never force-pushes. The existing Pages configuration must
publish that branch/root and a deploy-key push must trigger a Pages build (otherwise request one via the Pages API).
An IPA must remain below GitHub's 100 MiB per-file limit. No web build is republished
by this workflow. Re-running the same Actions run retains its build number.

Prepared on Linux only: native export, signing, provisioning and installation
require the first manually dispatched macOS run; preparation does not run it.
