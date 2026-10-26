# Meltemi original asset production

Run from `/home/yigit/projects`:

```sh
python meltemi/art/build_assets.py
python meltemi/art/build_audio.py
python meltemi/art/build_font.py
python meltemi/art/audit_assets.py
```

Artwork build and audio use Python standard library only. Artwork rasterization calls installed system `librsvg-2` and `libcairo` using ctypes (no Python Cairo/Pillow dependency). Font fetch uses official Google Fonts GitHub; optional installed fontTools generates the static weight-600 SemiBold face. The official variable face is retained too. No paid generators, downloaded art or sound samples used.

`build_assets.py` contains the handwritten vector geometry, regenerates individually editable `src/*.svg`, and rasterizes each at its exact contract dimensions. Edit geometry in the script for persistent rebuild changes; standalone SVGs are also editable in any vector editor. There are no @2x exports. The font-independent logo wordmark uses original geometric path lettering.

`build_audio.py` uses seeded filtered noise, damped sine/FM tones, low thumps, and plucked harmonic synthesis. Ambience is 8 seconds; optional A-phrygian-dominant modal music is 19.2 seconds. Loop ends are cross-blended and all endpoints have short cosine fades to digital zero. All files peak at -1.1 dBFS, mono PCM16, 44100Hz. Numerical verification is in `qa/audio_check.json`; listening QA has not been performed.

## QA evidence

- `qa/contact_sheet.png`: every sprite/UI PNG at 1x on both #4FB3BF lagoon and #E8D3A8 sand. This is intentionally tall to preserve 1x sizes, including the 1024px icon.
- `qa/overview.png`: compact supplementary view of small assets.
- `qa/tiled_tests.png`: 3x horizontal wave/gold-wave and 3x vertical shore repeats.
- `qa/mock_gameplay.png`: 720x1280 gameplay art composite (not an engine screenshot).
- `qa/asset_audit.json`: exact dimensions and alpha audit; source coverage and audio validated by audit script.
- `qa/visual_review.md`: final vision review and repair history.

Godot import/runtime integration and phone performance are owned by the game-code worker; the PNG/WAV files themselves were rasterized/synthesized and audited here. Original art and synthesis are CC0-1.0; Fredoka is OFL 1.1, see `game/assets/LICENSES.md`.
