# Rounds 1–3 QA

## Reproduce

Run every Godot command inside `systemd-run --user --scope -p MemoryMax=3G timeout 15m ...`.
`tools/run_smoke.sh` reports **22 passed, 0 failed** and a 60-second simulated
smoke with 15 retries, final state play. Input assertions report true for:

- Touch + emulated + compatibility mouse causes exactly one tack switch.
- Touch on Pause never switches tack.
- Air touch tap → spin, upward drag → flip, stationary hold → grab.
- Golden apex slow motion followed by crash restores Engine.time_scale to 1.

No SCRIPT ERROR or Parse Error in final test, capture or publish/export logs.
Existing golden max-speed drift and 500-chunk passable-gap assertions pass.

## Rendered evidence

`build/qa/{title,title_tall,riding,airborne_flip,airborne_grab,landing,game_over,game_over_daily}.png`
are in-engine captures (720×1280 and 720×1560 for title_tall), not mocked images.
Capture with `xvfb-run -a godot --audio-driver Dummy --path game --resolution 720x1280 -- --capture=NAME`.
The capture harness pins representative poses; model and input tests exercise their rules.

Vision reviewed all eight final captures. All pass functional clipping/readability
and overlap checks. Title cards clear idle rider/kite on both aspect ratios.
PERFECT was moved and outlined after first-pass feedback. Grab has an explicit
release instruction. Remaining cosmetic notes: Pause layers over a decorative
shore prop, speed streaks are intentionally subtle, flip inversion could read
more strongly, and daily-best positioning between Home and Share is unconventional.
Edge-cropped shore decorations and entering world objects are intentional.

## Device acceptance still needed

VPS renders use Compatibility + llvmpipe with Dummy audio, not iPhone hardware.
Real Safari 60 fps, audio, haptics and navigator.share invocation need device QA.
Browser share is exposed only when supported; clipboard copy provides fallback.
The normal run seed remains 81273; daily uses the device's local calendar YYYYMMDD,
so two players in different local dates receive different daily courses.

## Implementation map

- main.gd: touch ownership/thresholds, presentation timers/drawing, menu/HUD,
  tutorial, daily selection/share, mission updates, capture/debug fields.
- run_model.gd: queued mutually exclusive spin/flip, grab scoring, perfect window,
  collision and once-per-hazard near-miss score, mission event counters.
- missions.gd: 20 ordered goals, three slots, rewards/XP/levels/date seed.
- save_store.gd: v2 schema; v1 migration retains best, currency and cosmetics.
- tests/test_runner.gd and tests/smoke.gd: model/save/seed and live-scene input checks.
