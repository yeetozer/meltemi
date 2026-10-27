class_name RunModel
extends RefCounted
const START_SPEED: float = 380.0
const MAX_SPEED: float = 700.0
const SHORE: float = 94.0
const AIR_DRIFT: float = 0.25
const AIR_MARGIN: float = 110.0
var x: float = 360.0
var heading: float = 0.698
var tack: int = 1
var elapsed: float = 0.0
var distance: float = 0.0
var speed: float = START_SPEED
var air: float = 0.0
var air_total: float = 0.9
var spin: float = 0.0
var spins: int = 0
var queued: int = 0
var trick_points: int = 0
var shells: int = 0
var combo: int = 1
var combo_time: float = 0.0
var gust: float = 0.0
var dead: bool = false
var reason: String = ""
var landed: bool = false
func tap() -> void:
 if dead: return
 if air > 0: queued += 1
 else: tack *= -1
func launch(golden: bool = false) -> void:
 if air > 0: return
 air_total = (1.8 if golden else 0.9) * clampf(speed / 380.0,1.0,1.3)
 air = air_total
 spins = 0
 spin = 0
 queued = 0
func crash(why: String) -> void:
 dead = true
 reason = why
 combo = 1
func score() -> int: return int(distance) + trick_points + shells * 10
func tick(dt: float) -> void:
 landed = false
 if dead: return
 elapsed += dt
 gust = maxf(0,gust-dt)
 combo_time += dt
 if combo_time > 6: combo = 1
 speed = lerpf(START_SPEED,MAX_SPEED,minf(elapsed/90.0,1.0)) * (1.5 if gust > 0 else 1.0)
 if x < SHORE+38 or x > 720-SHORE-38: speed *= 0.6
 heading = lerp_angle(heading,float(tack)*0.698,minf(dt/0.15,1.0))
 # In the air the rider flies mostly forward: sideways drift is damped and kept
 # clear of the shallows, so a long (golden) jump can't carry you into the beach.
 var lateral: float = AIR_DRIFT if air > 0 else 1.0
 x += sin(heading)*speed*dt*lateral
 if air > 0: x = clampf(x,SHORE+AIR_MARGIN,720-SHORE-AIR_MARGIN)
 distance += cos(heading)*speed*dt/10.0
 if air <= 0 and (x < SHORE or x > 720-SHORE): crash("Beached")
 if air > 0:
  if queued > 0 and spin <= 0: spin = 0.0001; queued -= 1
  if spin > 0:
   spin += dt/0.45
   if spin >= 1: spin = 0; spins += 1
  air -= dt
  if air <= 0:
   air = 0
   landed = true
   var off: float = minf(spin,1.0-spin)*360.0
   if off > 25: crash("Landing mid-spin")
   elif spins > 0:
    trick_points += 100*combo*spins
    combo = mini(combo+1,5)
    combo_time = 0
func collect(kind: String) -> void:
 if kind == "shell": shells += 1
 elif kind == "starfish": shells += 5
 elif kind == "gust": gust = 2
func collide(kind: String) -> void:
 if kind == "wave" or kind == "wave_gold": launch(kind == "wave_gold")
 elif kind in ["shell","starfish","gust"]: collect(kind)
 elif air <= 0: crash("Watch the " + kind.replace("_"," "))
