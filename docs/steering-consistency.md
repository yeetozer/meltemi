# Drag distance fidelity (supersedes the earlier lead-clipped comparison)

Baseline b6f347a; deterministic 120 Hz ease-in-out (half cosine), finger held
for the remainder of a three-second trace. Start x=300 avoids shores. Coast is
last sample more than 3px from settled final position, plus one sample, minus
finger-stop time. Final expected position is gain × total finger displacement,
not the accepted/clipped target. Tables below are at forward speed 380;
700 and 1050 give the same final result and post-fix curves.

|Finger px|Swipe s|Expected px|Before px|Before error %|Before coast s|After px|After error %|After coast s|
|---|---|---|---|---|---|---|---|---|
|60.000|0.080|120.000|27.470|77.109|0.087|117.650|1.958|0.378|
|60.000|0.150|120.000|40.062|66.615|0.067|117.650|1.958|0.317|
|60.000|0.250|120.000|64.337|46.386|0.058|117.650|1.958|0.225|
|60.000|0.400|120.000|96.540|19.550|0.033|117.650|1.958|0.092|
|120.000|0.080|240.000|29.150|87.854|0.087|237.650|0.979|0.745|
|120.000|0.150|240.000|43.473|81.886|0.075|237.650|0.979|0.683|
|120.000|0.250|240.000|69.272|71.137|0.067|237.650|0.979|0.592|
|120.000|0.400|240.000|108.018|54.992|0.058|237.650|0.979|0.450|

## Implementation and trade-off

The old 24px lead clamp rebased the anchor during normal pursuit and tick also
clipped the outstanding target: rapid finger travel was silently consumed.
Normal drag now preserves the complete target. Shore bounds still consume excess;
a 256px safety bound prevents runaway. This deliberately exceeds the suggested
160px: a 120px finger flick requests 240px, so 160px would still lose distance.
Direction reversal rebases outstanding backlog at the rider and applies the
new delta immediately. Inside the settled noise envelope (2.35 + 2×3px), do not
rebase unless saturated: otherwise alternating ±1.5px noise ratchets anchors.
The deadband is intentionally not interpreted as meaningful opposite steering.
At 2Hz, 30px amplitude, four seconds, all 16 direction reversals respond in the
correct direction on the first physics sample (baseline also 16/16). End-of-track
rider x before/after is 342.807/340.781 from x=360; the finger is back at zero.
Reversal rebasing intentionally makes this cyclic waveform path-dependent; this
is not an absolute-position or zero-net-displacement guarantee. This is a reversal test, not a
promise to follow a 754px/s peak finger-velocity waveform without lag.

LATERAL_MAX rises from 300 to 318px/s; acceleration remains 2400px/s²,
tau 35ms, gain 2, deadband 2.35px, heading 0.698rad, slop 2px and release drift 1.
340px/s was tested: the 380px/s forward-speed angle limit reduced lateral speed
and produced 5.040% maximum curve divergence for 240px travel. 318 preserves
identical open-water curves and release velocity at all tested forward speeds.

**Coast <=0.35s for 120px/0.15s is NOT achieved.** Honouring 240px needs at
least 0.706s even at constant 340px/s, before acceleration/braking; only 0.5s
is available if swipe + coast must finish in 0.15+0.35s. Reaching that bound
would require >480px/s (and a higher angle cap at forward speed 380), outside
this tuning range. Preserve distance rather than hide this constraint by
throwing away travel. The longer catch-up is a human-playtest risk.

## Verification and reproduce

`game/tests/steer_fidelity.gd` asserts all 24 swipes (60/120px × four durations ×
380/700/1050), <=5% error (<=10% at 80ms), zero overshoot, <=5% curve divergence,
and reversal. Output includes all raw scalar results and wiggle reversal counts.
`game/tests/steer_consistency.gd` retains seeded ±1.5px jitter RMS <1 degree
at 60Hz and validates gusts, shallow limits, cosmetic rate and release velocity.
The instantaneous 60px step test now measures arrival at the true 120px target,
with 600ms t90 allowance rather than arrival at a discarded-distance target.

Run `bash tools/run_smoke.sh` and `bash tools/export_web.sh`; each Godot process
is systemd-scoped at MemoryMax=3G with a 15-minute timeout. Before/after raw
logs live in ignored `art/qa/steer/`. For baseline capture, use this probe against
b6f347a in a separate checkout with `-- --capture` (skip post-fix assertions).
44 model checks, 17 steering checks, fidelity assertions and the 60-second
play/wipeout/retry smoke pass. Local web export passes; no merge/publication.
Human iPhone 15 playtest remains pending.
