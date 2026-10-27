# Meltemi — one-page GDD (working title)

Portrait, one-thumb, top-down arcade kitesurf game. Godot 4 (typed GDScript), Compatibility renderer.
Target: iPhone 15 Safari (web build first, later native via cloud Mac CI). Keep 60 fps.

## Core loop: ride → zig-zag → wave → send → trick → land → repeat
- World scrolls DOWN; rider always travels UP-screen, carving diagonally (cosmetic board angle limited to ±50°).
- **Relative drag steering**: touch anywhere outside UI to anchor; horizontal finger displacement moves a target at 2:1 gain (test range 1.5–2.5). Lateral motion is independent of forward speed: cap 318 logical px/s (test range 260–340), pursuit tau 0.035 s with acceleration limit 2400 px/s², braking and per-frame travel bounds to prevent overshoot. A 2.35 px soft settling band rejects stationary thumb noise (small final position residual is intentional). Physical heading is unclamped atan2(actual lateral velocity, forward velocity); lateral authority stays318px/s even at260px/s and in156px/s slow-start shallows. A 1-Euro finger filter (mincutoff1.5Hz,beta2,dcutoff1Hz) precedes tracking. Filtered finger speed<25px/s for100ms locks the target; moving>10px from the lock point unlocks with full displacement preserved. Board rotation and course arrow are cosmetic: straighten below20px/s with35px/s exit hysteresis, clamp visually to±50°, smooth0.08s and rate-limit6rad/s. Initial accumulated 2 px slop unlocks tracking; after a stationary hold lock, the10px excursion rule takes over. Normal target travel preserves full finger distance; only shore/safety saturation (256 px outstanding lead) discards excess. Reversal discards old-direction backlog immediately outside the settled noise envelope; settled ±1.5 px jitter does not rebase anchors. Large flicks intentionally coast to their full destination (120 px finger / 0.15 s takes about 0.69 s extra to settle); see docs/steering-consistency.md for the speed/angle trade-off. Release preserves the last meaningful commanded lateral **velocity** within 50 ms, capped at 318 × release drift 1.0, not heading; a stationary finger settles straight. Gusts change forward speed and natural atan2 heading, not sideways response. Arrows/A-D move the target; Space only spins in air.
  Mouse drag works like touch. Rider rotates continuously, kite follows; spray + wake mark changes.
- **Wave ramps** (foam lips across part of the lane): riding over one launches automatically.
  Normal wave ≈ 0.9 s airtime (scaled by speed), golden wave ≈ 1.8 s.
  Air = rider+kite scale up to ~1.6× at apex, shadow separates/offsets, camera zooms out slightly.
- **Tap in the air = spin trick** (360° in ~0.45 s, taps queue). Landing mid-spin (>25° off) = wipeout.
  Clean landing with ≥1 spin = trick score + combo +1. Airborne rider ignores water obstacles and can grab air shells.
- **Edges**: shallow sand strip near each shore slows you 40% and kicks sand (warning); touching shore = "beached" wipeout.
- **Obstacles**: buoys, small/big rocks, sleeping turtles, fishing boats & jet-skis (move sideways), sailboats.
- **Pickups**: shells (+1 shell, +10 pts), starfish (+5 shells), wind gust (1.5× speed for 2 s).
- **Wipeout** = splash, kite drops, game over panel after ~0.6 s. Retry in one tap (<1 s to riding again).

## Difficulty & zones
- Smooth calm-start speed keys (seconds:px/s): 0:260, 8:270, 30:380, 90:500, 180:700. Smoothstep between keys. `game/scripts/pacing.gd` owns all pacing constants.
- First 8s: open water and two easy pickups, steering hint even for returning players. First single buoy arrives12s, next22s (10s spacing), first gentle wave20s. Density eases up30–90s toward old opening density, then90–180s toward old full density. Gusts remain1.5× for2s, first offered40s.
- Every retry keeps the complete8s warm-up. Seeded1280px chunks use analytically integrated speed for arrival positions; shallows/gusts naturally delay/advance later encounters. Always leave a passable gap≥180px including moving sweep.
- Zones every 1000 m (distance = px/10): Lagoon (turquoise, sandbars) → Harbour (boats, pier walls) →
  Open Sea (deeper blue, bigger waves) → Sunset Bay (warm tint) → loop.

## Measured pacing timeline (seed81273)

|Seconds|Before speed px/s|After speed px/s|Before hazards / pickups / waves|After hazards / pickups / waves|
|---|---|---|---|---|
|0–10|380→416|260→273|10 / 16 / 3|0 / 2 / 0|
|10–20|416→451|273→332|15 / 22 / 4|1 / 3 / 1|
|20–30|451→487|333→380|22 / 27 / 3|1 / 2 / 0|
|30–40|487→522|380→389|28 / 33 / 4|1 / 3 / 0|
|40–50|522→558|389→411|27 / 38 / 5|1 / 3 / 1|
|50–60|558→593|411→440|28 / 40 / 4|2 / 5 / 1|
|60–70|593→629|440→469|37 / 43 / 5|2 / 6 / 0|
|70–80|629→664|469→491|35 / 46 / 5|4 / 10 / 2|
|80–90|665→700|491→500|34 / 48 / 5|7 / 20 / 2|
|90–100|700→700|500→507|36 / 48 / 6|10 / 22 / 3|
|100–110|700→700|507→525|37 / 50 / 5|10 / 22 / 4|
|110–120|700→700|525→552|36 / 49 / 6|10 / 25 / 3|
|120–130|700→700|552→583|37 / 50 / 5|13 / 27 / 3|
|130–140|700→700|583→617|30 / 49 / 6|14 / 31 / 4|
|140–150|700→700|617→648|24 / 49 / 5|19 / 34 / 5|
|150–160|700→700|648→675|34 / 49 / 5|22 / 40 / 4|
|160–170|700→700|675→693|38 / 50 / 6|29 / 44 / 5|
|170–180|700→700|693→700|33 / 48 / 5|34 / 48 / 6|

Rider-line crossings,60Hz,open water,no collected gusts/deaths; pickups include gusts. First obstacle2.20s→12.00s. Exact-boundary arrivals may fall in the previous bin by one frame. See [QA](calm-start-qa.md) for method, hold metrics, artifacts and risks.

## Score & meta
- Score = distance m + trick 100 × combo + shells × 10. Combo x1..x5, resets after 6 s without a trick or on wipeout.
- Slower forward distance reduces base score: at180s, no gusts/tricks/pickups, old11160m versus new8967m. Distance missions100/500/1500m remain reachable at approximately3.82/18.01/44.83s. No medals or fixed-score achievements exist; best-score storage and score formula are unchanged. Sparse opening waves intentionally delay combo missions; later wave spacing below6s still permits combos x3/x5, and golden/spin/backflip/grab goals remain available.
- Save (user://save.json, versioned): best score, total shells, owned/selected kite, settings, tutorial_done.
- Kite shop (cosmetic only): Sunset (free), Sea Glass 50, Olive 150, Lemon 300 shells.

## Screens
Title (logo, idle rider on water, "Tap to ride", best, shells, Kites, settings) · HUD (distance, score, combo, shells,
pause; respect iPhone safe areas — nothing in the top ~60 logical px or bottom ~40) · Pause (resume, restart, home,
sound, reduce motion) · Game over (score, best, NEW BEST, shells earned, big Retry, Home) · Kite shop.
First run: in-context hints "Drag to steer · lift to keep your line" then at first wave "Tap in the air to spin!".
A subtle 76 px foam-white projected course arrow ahead of the board shares the cosmetic board heading (straightens at tiny velocity), including after release; it fades 85% in air and is spatially separate from the wake. Native iOS defers edge UI gestures via `display/window/ios/suppress_ui_gesture=true` (verified by installed Godot 4.7.2 `ProjectSettings.has_setting` and `main/main.cpp` / `doc/classes/ProjectSettings.xml` at engine commit `ed1daf0bf001b61586d9930840f2f1394092c079`).

## Feel
Juice after control: wake trail, spray particles on tack, squash on landing, small shake on crash
(off with Reduce Motion), SFX for tack whoosh, jump, clean/bad land, splash, shell ding, gust, UI click, ocean ambient.

## Visual identity
Flat vector, soft shading, Mediterranean: cream #F4EBDD, terracotta #C8643B, olive #7A8B4A, sea-glass #8FC9B9,
deep sea #1F6F8B, lagoon #4FB3BF, sand #E8D3A8, foam white #FFFFFF, ink #2B2B2B. Rounded friendly font (OFL).
Shores: sand, white/terracotta houses, olive trees, umbrellas, lighthouse; harbour walls and boats in Harbour zone.

## Non-goals (for now)
Real physics, multiplayer, ads/IAP, accounts, leaderboards, store release.


## Improvement rounds 1–3
Drag steering tracks gameplay touches by index (UI excluded), deduplicates Safari compatibility
events, and emits `tacks` on water direction changes. Pre-launch holds never trigger air tricks;
only fresh air presses start gestures. Air drift stays damped (takeoff course is damped once;
air steering velocity is quarter-strength, with physical heading calculated after displacement/clamping).
Speed denotes forward velocity, so distance and atan2 heading share the same forward component.
Landing re-anchors the current finger.
Pause clears steering without changing heading.

Air gestures use raw touch history in logical pixels: tap release <=0.18 s and maximum
excursion <=15 px; horizontal steering locks permanently at |dx|>=15 px and
|dx|>=1.5×|dy|. A swipe up locks a 0.6 s backflip at dy<=-55 px within 0.3 s
and upward>=1.73×|dx|. Stationary hold >=0.35 s with excursion <=15 px
starts a grab (release before landing). Pre-launch fingers retain steering ownership,
never tricks. Spin duration remains 0.45 s.
One active trick and at most one queued trick. Grab earns 60 per 0.25 s.
Last spin/flip completion in final 0.15 s makes the landing perfect (1.5x).
Normal course retains seed 81273; daily seed is local calendar YYYYMMDD.
Missions use an ordered 20-goal pool, three slots, 10–40 shell/XP rewards,
100 XP per level, schema v2 migrates schema v1. Repeated pool cycles remain available.
Daily share uses native web share when present and also copies text as fallback.
Presentation tuning: main.gd juice timers/draw; run_model.gd trick durations,
score/landing rules; missions.gd goals/rewards. Device haptics/share and 60fps
need a real iPhone Safari playtest; VPS screenshots cannot establish those.
