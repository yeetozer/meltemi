# Meltemi — one-page GDD (working title)

Portrait, one-thumb, top-down arcade kitesurf game. Godot 4 (typed GDScript), Compatibility renderer.
Target: iPhone 15 Safari (web build first, later native via cloud Mac CI). Keep 60 fps.

## Core loop: ride → zig-zag → wave → send → trick → land → repeat
- World scrolls DOWN; rider always travels UP-screen, carving diagonally (heading ±40° from vertical).
- **Relative drag steering**: touch anywhere outside UI to anchor; horizontal finger displacement moves a target at 1:1 gain. The rider follows with exponential response and a 40° lateral speed cap. Release preserves current heading; a stationary finger settles straight. Arrows/A-D move the target; Space only spins in air.
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
- Speed 380 px/s → 700 px/s over ~90 s. Spawn density rises with distance. Procedural 1280 px chunks from
  hand-authored patterns; always leave a passable gap ≥ 180 px. Seeded RNG.
- Zones every 1000 m (distance = px/10): Lagoon (turquoise, sandbars) → Harbour (boats, pier walls) →
  Open Sea (deeper blue, bigger waves) → Sunset Bay (warm tint) → loop.

## Score & meta
- Score = distance m + trick 100 × combo + shells × 10. Combo x1..x5, resets after 6 s without a trick or on wipeout.
- Save (user://save.json, versioned): best score, total shells, owned/selected kite, settings, tutorial_done.
- Kite shop (cosmetic only): Sunset (free), Sea Glass 50, Olive 150, Lemon 300 shells.

## Screens
Title (logo, idle rider on water, "Tap to ride", best, shells, Kites, settings) · HUD (distance, score, combo, shells,
pause; respect iPhone safe areas — nothing in the top ~60 logical px or bottom ~40) · Pause (resume, restart, home,
sound, reduce motion) · Game over (score, best, NEW BEST, shells earned, big Retry, Home) · Kite shop.
First run: in-context hints "Drag to steer — let go to hold your line" then at first wave "Tap in the air to spin!".

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
only fresh air presses start gestures. Air drift stays damped; landing re-anchors the current finger.
Pause clears steering without changing heading.

Air gestures use logical pixels: tap release <0.2 s and <40 px travel;
upward movement >50 px queues a 0.6 s backflip; stationary hold >=0.2 s
starts a grab (release before landing). Spin duration remains 0.45 s.
One active trick and at most one queued trick. Grab earns 60 per 0.25 s.
Last spin/flip completion in final 0.15 s makes the landing perfect (1.5x).
Normal course retains seed 81273; daily seed is local calendar YYYYMMDD.
Missions use an ordered 20-goal pool, three slots, 10–40 shell/XP rewards,
100 XP per level, schema v2 migrates schema v1. Repeated pool cycles remain available.
Daily share uses native web share when present and also copies text as fallback.
Presentation tuning: main.gd juice timers/draw; run_model.gd trick durations,
score/landing rules; missions.gd goals/rewards. Device haptics/share and 60fps
need a real iPhone Safari playtest; VPS screenshots cannot establish those.
