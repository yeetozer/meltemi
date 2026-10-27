# Steering deterministic comparison

All runs 60 Hz, seed 9182. Step t90 uses the accepted target displacement (the anti-runaway lead clips a 60px finger step, not the full 120px gain); deadband residual is explicit. Shore includes automatic shallows and discrete collision, so it is not simply distance / initial vx.

| Speed | Phase | Target px | t90 s | Overshoot px | Settle error px | Wobble SD px | Heading RMS deg | Release vx | Shore s |
|---|---|---|---|---|---|---|---|---|---|
| 380 | before | 19.538 | 0.083 | 0 | 0.0 | 1.223 | 12.4175 | 244.259 | 1.183 |
| 380 | after | 24.0 | 0.15 | 0 | 2.35 | 0.2048 | 0.8497 | 300.0 | 0.967 |
| 540 | before | 27.764 | 0.083 | 0 | 0.0 | 1.223 | 8.9066 | 347.051 | 0.833 |
| 540 | after | 24.0 | 0.15 | 0 | 2.35 | 0.2048 | 0.5982 | 300.0 | 0.9 |
| 700 | before | 35.99 | 0.083 | 0 | 0.0 | 1.223 | 6.9258 | 449.881 | 0.65 |
| 700 | after | 24.0 | 0.15 | 0 | 2.35 | 0.2048 | 0.4615 | 300.0 | 0.9 |
| 1050 | before | 53.986 | 0.083 | 0 | 0.0 | 1.223 | 4.6483 | 674.821 | 0.433 |
| 1050 | after | 24.0 | 0.15 | 0 | 2.35 | 0.2048 | 0.3077 | 300.0 | 0.9 |

## Diagnosis and implementation

Baseline: `34aad73` (live build 1000.6). The same 60px finger step accepted
19.538–53.986px of target displacement because both cap and anti-runaway lead
scaled with forward speed. Release saved heading, multiplying sideways drift by
forward speed and gusts. Noise after initial slop went straight through a 15ms
follow filter; steady 1.5px uniform finger jitter produced 4.65–12.42deg physical
heading RMS. These are measured model effects, not a claim of human approval.

`run_model.gd` now uses a 300px/s lateral cap and a fixed 24px target lead;
acceleration-limited pursuit (2400px/s², tau 35ms), braking bound and final
per-frame travel clamp prevent overshoot. Reversal and target arrival may override
the acceleration ramp to avoid wrong-way travel/overshoot. A 2.35px soft target
settling band is intentional: residual error is visible above rather than hidden.
At 2px the noise RMS was still 1.575deg at 380px/s, so the settle band was increased.
Gain stays 2.0. Release keeps recent meaningful velocity within 50ms; physical
heading is atan2(vx,forward speed). Cosmetic board response is 80ms, at most 6rad/s.
The existing heading arrow already uses physical heading and needed no change.

At all four speeds the recorded step, sine and jitter x curves now coincide
(the regression tolerance is 5%, not a claim of differing curves). The 60px step
is deliberately **lead-clipped**; it does not move the rider 120px in either build.
Shore times are equal at 540/700/1050. At 380 the final shallow strip reduces the
40-degree physical cap below 300px/s, extending shore time to 0.967s; this is the
explicit low-speed exception, not residual gust-dependent steering.

## Reproduce and evidence

- `game/tests/steer_probe.gd`: 60Hz, 180 frames per track and speed; seed 9182.
  Tracks: 60px step/hold, 40px 1Hz sine, settled finger with ±1.5px uniform noise,
  maximum carve then release from lane center, plus a gust trace.
- Each JSON row: seconds, x, actual vx, physical heading, cosmetic board rotation,
  target x, forward speed, dead. Noise RMS/wobble use frames 90–179.
- Before traces were captured **before editing the model** on this branch.
- Capture current model:

```sh
systemd-run --user --scope -p MemoryMax=3G timeout 15m \
  "$HOME/.local/bin/godot" --headless --path game \
  --script tests/steer_probe.gd -- "$PWD/art/qa/steer/after.json"
python3 tools/steer_report.py
bash tools/run_smoke.sh
bash tools/export_web.sh
```

The report script needs Pillow (available on this host); matplotlib was unavailable
because its packaging dependency was missing. Raw before/after traces, metrics,
logs and ten PNG plots are local under ignored `art/qa/steer/`.
To reconstruct baseline elsewhere, run the same probe against model `34aad73` in
an isolated checkout; do not overwrite a working main checkout.

Verified: 44 existing model/controller checks and 17 steering checks pass;
60s smoke ends in play after seven retries, including air gestures, cancellation,
focus/pause, multitouch handover, golden timing and keyboard gating. Local Web
export succeeds with 3GiB memory caps. No merge, publication, native build,
workflow dispatch, secret or export-preset edits. iPhone 15 human feel test pending.
