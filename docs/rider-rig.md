# Layered rider rig

The approved SVGs are copied byte-for-byte into `art/src`: two boards, two upper bodies, tail spray and four kite colourways. Do not regenerate/redraw these sources with the legacy drawing functions. `art/build_assets.py` preserves them, supersamples rider layers at 4× and records actual output dimensions in the manifest. The legacy `rider.png` remains for historical offline art composites only; gameplay has no reference to it.

`game/resources/rider_rig.json` records the approved layer anchors plus the phone-readability placement/scale adjustment. `rider_visual.gd` ports `layers.py`'s hip interpolation, rotated strap endpoints, knee bend (convert length to design units first), outline/fill ordering and rotated foot ellipses. All coordinates are logical pixels before the rider parent's 1.5× gameplay scale. The visual child owns mirroring, procedural legs and trick squash/tuck; the parent retains heading/spin/air transforms. Board angle exponentially blends 15–45° with lateral speed. Mirror changes require >35 px/s and use an interruptible 0.12-second tween; Reduce Motion applies the side instantly. Spray follows the rotated tail, not an unrelated world point. The menu wake ends at that same transformed tail.

Four solid kite lines transform the approved bar and kite anchors through the complete scene transforms every frame. Kite gameplay scale is 1.45×; airborne scaling remains unchanged.

## Independent skins

`rider_skins.gd` registers `classic` / `seaglass` boards and `navy` / `terra` upper bodies, including procedural leg suit colours. Only classic/navy have `visible=true`; there is no player-facing board/character purchase UI. Call `rider_visual.set_skins(board_id, character_id)` independently. Unknown IDs fall back safely. Saves persist `selected_board` and `selected_character`; version 1/2 saves without those fields default to classic/navy.

## Verification and evidence

- `tools/run_smoke.sh` includes model, steering, fidelity, hold-still, gameplay/menu, all skin combinations and normal-play flip/grab tests.
- Skin tests compare foot endpoints and bar anchors against the original JSON at both board-angle endpoints in both mirror states, verify real texture paths and old-save migration/independent selection persistence.
- Pose tests exercise the real main-loop trick transforms, grab release, hysteresis, a timed mirror reversal and Reduce Motion.
- `python3 art/audit_assets.py` checks 41 manifest images.
- `tools/export_web.sh` uses the unchanged Web preset.

Ignored real-engine evidence lives in `art/qa/rider-v4/`. Still captures use the editor-only `--capture=` path, deterministic default saves and 1179×2556 output under Xvfb (`-screen 0 1400x2800x24`). Modes: returning, first_launch, missions, shop, riding, left_carve, right_carve, airborne, airborne_flip, airborne_grab. Wait for the `CAPTURE ... 0` message.

`tests/rider_evidence.gd` is editor-only: `--qa-mode=skins` captures four real rig combinations; `menu` records 180 frames and `play` records 600 frames at fixed 30 FPS using actual model drag input. The gameplay harness asserts both sides and the full blend range without suppressing crashes or removing hazards. For Movie Maker, temporarily use a 720×1562 project viewport (Movie Maker initializes before script-side resizing), record with `--write-movie`, and restore 720×1280 immediately afterwards. The committed project viewport and Web export preset are unchanged. Movies are encoded to H.264 without stretching. Compare-sheet and 3× crop are derived only from the real captured frames; the approved reference remains untouched.

Linux dummy-audio shutdown can report retained AudioStreamWAV/playback objects after tests/captures; these are separate from assertions and rendering, not a claim of iPhone audio/performance validation. A physical iPhone touch/feel pass remains human QA.

## Final phone-size polish (v5)

Each leg now draws outline then fill, back before front, so the front white contour remains visible across the back leg. The back suit uses `suit.lightened(0.18)` for every skin. Straight hips widen from ±5 to ±6.5 design units (±4.68 logical px), blending to unchanged carve hips; knees re-solve and strap endpoints remain exact. Tests sample five blend positions on both mirror sides and all skins.

Spray uses the approved SVG attachment (-6,-2), relative to viewBox centre (-8,5), rather than an arbitrary leftward offset. Both sprite and attachment offset rotate with the board; a regression checks the transformed attachment equals the tail.

Best, a middle dot, shell icon and count share a centred HBox with 12px spacing. The pale cyan/white arrow is intentional projected-course guidance, drawn by `main.gd::_draw()` at lines 462–475 ahead of the board from `run.visual_heading`; it fades near hazards/while airborne. It is not debug UI or the steering target, and is retained without physics changes.

Current ignored evidence: `art/qa/rider-v5/`, including actual 1× phone pixels beside nearest-neighbour 3× legs and a real 600-frame/30fps gameplay movie. Smoke, asset audit and Web export pass; dummy-audio shutdown resource warnings remain and physical iPhone testing is pending.

## Gameplay readability correction

A running-scene probe confirmed board texture `board_classic.png`, scale `(0.248276,0.249711)`, alpha/modulate 1 and relative z=0 throughout the rig. The wake was already before the rider, not concealing it. The actual readability failure was geometric self-occlusion: the upper body/outlined legs covered the nose/deck of the narrow, alpha-padded board at the shared origin. Moving the board to `(10,13)` and enlarging it only 12% exposes the approved cream deck and terracotta nose; rotated strap endpoints move/scale with it. No approved art changed. Explicit world z=1 wake/particles and z=2 rider/kite prevent particle bursts painting over the rig. Continuous wake, jump/landing particles and local spray all originate at the transformed tail.

Kite offset now follows signed lateral velocity (±170 logical px) rather than the much weaker physical heading sine. Exponential 0.18s follow is frame-rate independent and interruptible; Reduce Motion removes lag. Steering physics is untouched. Existing `bar_point()` already used the entire flip transform; regression tests now check all four live line endpoints at six flip phases.

The title XP track is darker, Best/shell stats are grouped more tightly, and all action rows share an explicit 20px gap.

`tools/rider_pixel_proof.py` projects original texture alpha through a capture-sidecar transform and samples final screenshot pixels, not generated colour swatches. `board_pixel_proof.json` contains full-frame/crop bounds, the mean RGB over the complete board footprint (including rails, straps and leg occlusion), and independently counted visible cream/terracotta pixels. Straight/left/right frames contain respectively 1186/1368/1368 cream pixels with mean RGB approximately `(243,235,222)`, plus 41/114/114 terracotta pixels. Screenshots are 1179×2556; 3× crops retain both kite tips and all lines. Movie is 600 real rendered frames at 30 FPS, 720×1562, 20s; gameplay harness confirms both sides, full blend range and no crash. Project viewport and Web preset are unchanged.
