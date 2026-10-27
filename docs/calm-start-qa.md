# Calm start: measured QA

Baseline: origin/main e815baa. All evidence is local/ignored under `art/qa/calm/`.

## Hold still

Deterministic 120Hz, fresh press and 60px/250ms swipe, then tremor: 8Hz amplitude2px +12Hz amplitude1px, slow roll amplitude3px at0.25Hz, occasional1px quantisation steps at3Hz. Noise starts at0.5s. Metrics use the three-second settled hold window t=2–5s (not swipe travel or acquisition). Baseline source was unchanged apart from test-only constant forward speed injection; new tests use a subclass, never a shipped CLI flag.

|Speed|After swipe|Before x SD / p-p px|Before vx RMS px/s|Before board RMS deg / flips per s|After x SD / p-p / vx RMS / board RMS / flips|
|---|---|---|---|---|---|
|260|False|3.854 / 13.621|33.419|2.448 / 7.333|0.000 / 0.000 / 0.000 / 0.000 / 0.000|
|260|True|3.854 / 13.621|33.419|2.448 / 7.333|0.000 / 0.000 / 0.000 / 0.000 / 0.000|
|380|False|3.854 / 13.621|33.419|1.693 / 7.333|0.000 / 0.000 / 0.000 / 0.000 / 0.000|
|380|True|3.854 / 13.621|33.419|1.693 / 7.333|0.000 / 0.000 / 0.000 / 0.000 / 0.000|
|700|False|3.854 / 13.621|33.419|0.925 / 7.333|0.000 / 0.000 / 0.000 / 0.000 / 0.000|
|700|True|3.854 / 13.621|33.419|0.925 / 7.333|0.000 / 0.000 / 0.000 / 0.000 / 0.000|

1-Euro: mincutoff1.5Hz, beta2, derivative cutoff1Hz; hold25px/s for0.10s, unlock10px from lock point. Unlock rebases at the lock point and retains the complete excursion (11px unlock accepts22px target). Board straightens below20px/s, exits straight above35px/s; cosmetic angle ≤50°, smooth80ms and rate6rad/s; arrow shares cosmetic heading. Raw air gesture recognition is unchanged. Zero drag events still decay derivative and acquire lock. Saturated reversals bypass filter catch-up.

Filter position-equivalent added lag: worst3.835ms in120Hz 210/300/600/1200px/s straight swipes, bound10ms. All32 fidelity cases at260/380/700/1050px/s: max error1.958%, zero overshoot, zero speed-curve divergence; 16/16 immediate wiggle reversals. Full swipe coast intentionally remains up to0.745s, unchanged distance-preservation trade-off.

## Pacing

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

Counts are rider-line crossings at60Hz for seed81273, no collision deaths or collected pickups/gusts; pickups include gusts and starfish. First hazard crossing2.20s→12.00s. Scheduled first gentle wave20s; fixed-step integration can put an exact20s crossing in the preceding ten-second bin. Collision/contact begins slightly before line crossing.

`pacing.gd` owns smoothstep speed keys0:260,8:270,30:380,90:500,180:700; smoothstep density keys30:0,90:0.92,180:1. Obstacle intervals10→0.29s; pickup4→0.23s; waves20→1.83s; gusts18→1.83s. First pickups4/8s, hazards12/22s, wave20s, gust40s. Course converted analytically to forward distance, so gust and shallows change actual arrival times naturally; no early gust can shorten the warm-up. Full density roughly matches the old full-level seeded hazard/pickup/wave counts. Chunk gap remains seeded/passable, including moving18px sweep. Every retry deliberately keeps the full8s introduction (not a shortened variant).

## Verification / artifacts

`bash tools/run_smoke.sh`:44 model tests,20 steering tests,32 fidelity cases,6 settled-hold tracks, explicit lock/unlock/filter/speed/pacing/shallow tests,60s play/crash/retry and input gesture/cancel/pause/handover/keyboard checks all pass. `bash tools/export_web.sh` succeeds. All heavy Godot/ffmpeg commands scoped MemoryMax=3G with bounded timeouts.

720×1280 llvmpipe/Xvfb captures:t002.png,t010.png,t025.png,t060.png,t120.png. first-minute.mp4: H.264,540×960,30fps,1800frames,60.000s,2239109bytes (under15MB). `calm_visual.gd` is an explicitly launched test runner with a model crash override; main scene never loads it. No invulnerability option exists in shipped main. Reduce Motion enabled for reproducible QA; footage is synthetic autoplay, not device performance evidence. Image inspection confirms legible HUD and calm opening; existing square spray/long wake and persistent pre-first-spin hint remain visual polish risks, not part of this steering/pacing change.

Real iPhone15 hold/feel/performance playtest remains pending. No merge, publishing, store calls, workflow or preset edits.
