# Layered rider rig

The approved SVGs are copied byte-for-byte into `art/src`: two boards, two upper bodies, tail spray and four kite colourways. Do not regenerate/redraw these sources with the legacy drawing functions. `art/build_assets.py` preserves them, supersamples rider layers at 4× and records actual output dimensions in the manifest. The legacy `rider.png` remains for historical offline art composites only; gameplay has no reference to it.

`game/resources/rider_rig.json` is the original approved specification. `rider_visual.gd` ports `layers.py`'s hip interpolation, rotated strap endpoints, knee bend (convert length to design units first), outline/fill ordering and rotated foot ellipses. All coordinates are logical pixels before the rider parent's 1.5× gameplay scale. The visual child owns mirroring, procedural legs and trick squash/tuck; the parent retains heading/spin/air transforms. Board angle exponentially blends 15–45° with lateral speed. Mirror changes require >35 px/s and use an interruptible 0.12-second tween; Reduce Motion applies the side instantly. Spray follows the rotated tail, not an unrelated world point. The menu wake ends at that same transformed tail.

Four solid kite lines transform the approved bar and kite anchors through the complete scene transforms every frame. Kite gameplay scale is 1.45×; airborne scaling remains unchanged.

## Independent skins

`rider_skins.gd` registers `classic` / `seaglass` boards and `navy` / `terra` upper bodies, including procedural leg suit colours. Only classic/navy have `visible=true`; there is no player-facing board/character purchase UI. Call `rider_visual.set_skins(board_id, character_id)` independently. Unknown IDs fall back safely. Saves persist `selected_board` and `selected_character`; version 1/2 saves without those fields default to classic/navy.

## Verification and evidence

- `tools/run_smoke.sh` includes model, steering, fidelity, hold-still, gameplay/menu, all skin combinations and normal-play flip/grab tests.
- Skin tests compare foot endpoints and bar anchors against the original JSON at both board-angle endpoints in both mirror states, verify real texture paths and old-save migration/independent selection persistence.
- Pose tests exercise the real main-loop trick transforms, grab release, hysteresis, a timed mirror reversal and Reduce Motion.
- `python3 art/audit_assets.py` checks 41 manifest images.
- `tools/export_web.sh` uses the unchanged Web preset.

Ignored real-engine evidence lives in `art/qa/rider-v3/`. Still captures use the editor-only `--capture=` path, deterministic default saves and 1179×2556 output under Xvfb (`-screen 0 1400x2800x24`). Modes: returning, first_launch, missions, shop, riding, left_carve, right_carve, airborne, airborne_flip, airborne_grab. Wait for the `CAPTURE ... 0` message.

`tests/rider_evidence.gd` is editor-only: `--qa-mode=skins` captures four real rig combinations; `menu` records 180 frames and `play` records 600 frames at fixed 30 FPS using actual model drag input. The gameplay harness asserts both sides and the full blend range without suppressing crashes or removing hazards. For Movie Maker, temporarily use a 720×1562 project viewport (Movie Maker initializes before script-side resizing), record with `--write-movie`, and restore 720×1280 immediately afterwards. The committed project viewport and Web export preset are unchanged. Movies are encoded to H.264 without stretching. Compare-sheet and 3× crop are derived only from the real captured frames; the approved reference remains untouched.

Linux dummy-audio shutdown can report retained AudioStreamWAV/playback objects after tests/captures; these are separate from assertions and rendering, not a claim of iPhone audio/performance validation. A physical iPhone touch/feel pass remains human QA.
