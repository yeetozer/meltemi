# iPhone Ad Hoc build (manual only)

The lead must add repository Actions secrets **ASC_KEY_ID**, **ASC_ISSUER_ID**,
**ASC_KEY_P8_BASE64** (base64-encoded Apple .p8 key), **APPLE_TEAM_ID**, and
**MELTEMI_PLAY_TOKEN**. The Apple key needs permission to register devices and
bundle IDs and manage automatic signing (including cloud-managed distribution
certificates). The Pages token needs Contents read/write access to
`yeetozer/meltemi-play`; the source repository GITHUB_TOKEN cannot push there.
Never commit keys or put a token in dispatch inputs.

```sh
gh workflow run ios-adhoc.yml -R yeetozer/meltemi -f udid=YOUR_IPHONE_UDID -f device_name='Yigit iPhone 15'
```

This registers an absent device (consuming an annual Apple device slot), ensures
`com.yeetozer.meltemi` exists without adding capabilities, downloads the official
Godot 4.7.2 editor and matching templates, checks published SHA512 sums when
available, exports an Xcode project, then archives/exports using API-key automatic
signing and Xcode's `release-testing` (Ad Hoc) method. Build numbers are
`1000.<workflow run number>`; marketing version is 0.1.0.

Expected output: an IPA + manifest + signing-report workflow artifact (7 days),
and https://yeetozer.github.io/meltemi-play/ios/ after the existing Pages deployment
finishes. Open in Safari on the registered iPhone and tap **Install Meltemi**.
Developer Mode is not normally needed for Ad Hoc. To add another tester, run the
same command with their UDID/name: previously registered devices remain registered
and automatic signing regenerates the profile. Each rebuild must include the
requested device; the workflow checks the exported profile, not just the archive.
Apple device limits, account agreements, certificate permissions or profile expiry
can require attention in the developer account. Public IPAs contain embedded
provisioning profiles (including registered UDIDs); the install URL is not access
control. Raw signing logs and private keys are not published; keys are deleted
in an always-run cleanup. On signing failure, raw logs stay on the ephemeral runner
rather than leaking device IDs in Actions output.

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
publish that branch/root and the token must be allowed to trigger Pages builds.
An IPA must remain below GitHub's 100 MiB per-file limit. No web build is republished
by this workflow. Re-running the same Actions run retains its build number.

Prepared on Linux only: native export, signing, provisioning and installation
require the first manually dispatched macOS run; preparation does not run it.
