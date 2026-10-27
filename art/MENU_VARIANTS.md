# Menu and owner-review rider concepts

Production art remains unchanged. `art/build_variants.py` (CairoSVG) builds A/B/C as separate board/body/arms layers and four canopy colourways. No production scene loads these assets. `tools/capture_menu_variants.py` renders evidence with Godot/Mesa and an isolated XDG save. `game/tests/variant_capture.gd` and `menu_movie.gd` are QA-only scripts, not referenced by the shipped scene.

Menu: open-water hero, double-size idle rider and kite, attached lines and wake, reduced-motion static pose, primary bottom Ride with Daily/Kites, top settings target, first-ride badge instead of zeros, optional returning-player XP, missions sheet. Background tap-to-start removed to prevent missed-button launches. Existing settings/shop/results/pause layout retained.

Evidence is ignored under art/qa/menu-v2 and art/qa/variants. Both 720x1280 and 720x1561 are rendered. Movie is real Godot Movie Maker footage transcoded to H.264. Smoke includes menu routes and static reduced-motion pose.

Outstanding: first-launch stats are styled as noninteractive pills but implemented as mouse-ignoring Buttons. Shell badge currently uses text, not the shell icon. XP is text rather than a thin progress bar. Missions chip does not yet show completion count. Static safe offsets need physical iPhone validation. Variant scenes are staged water illustrations, not deterministic t=10 course frames. Comparison enlargement is illustrative, not a calibrated 3x layout for every column. Variant B neutral vision still mentioned a paraglider-style canopy; these concepts are not approved production replacements. Existing Godot ObjectDB/resource exit warnings remain.
