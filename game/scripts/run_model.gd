class_name RunModel
extends RefCounted
const START_SPEED: float = 380.0
const MAX_SPEED: float = 700.0
const SHORE: float = 94.0
const AIR_DRIFT: float = 0.25
const AIR_MARGIN: float = 110.0
var x: float = 360.0
const TURN_RATE: float = 4.0
const CARVE_ANGLE: float = 0.698
const TURN_EASE: float = 14.0
var held: bool = false
var heading: float = -CARVE_ANGLE
var tack: int = -1
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
var flip: float = 0.0
var flips: int = 0
var queued_flip: bool = false
var grabbing: bool = false
var grab_time: float = 0.0
var last_completion: float = -100.0
var perfect: bool = false
var golden: bool = false
var near_ids: Dictionary = {}
var events: Dictionary = {}
func event(key: String, amount: float=1.0) -> void: events[key]=float(events.get(key,0))+amount
func backflip() -> void:
 if air>0 and not grabbing: queued=1; queued_flip=true
func grab(active: bool) -> void:
 if not active: grabbing=false
 elif air>0 and spin<=0 and flip<=0: grabbing=true; queued=0
func near_miss(id: int) -> bool:
 if dead or air>0 or near_ids.has(id): return false
 near_ids[id]=true; trick_points+=25; event("near"); return true
func set_held(active: bool) -> void:
 if held==active: return
 held=active
 tack=1 if held else -1
 if not dead and air<=0: event("tacks")
func tap() -> void:
 if dead: return
 if air > 0:
  if not grabbing and queued==0: queued=1; queued_flip=false
 # Water steering is stateful; taps are only air tricks.
func launch(is_golden: bool = false) -> void:
 if air > 0: return
 golden=is_golden
 if golden: event("golden")
 air_total = (1.8 if golden else 0.9) * clampf(speed / 380.0,1.0,1.3)
 air = air_total
 flips=0; flip=0; grabbing=false; grab_time=0; perfect=false; last_completion=-100
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
 if air<=0:
  var target: float = CARVE_ANGLE if held else -CARVE_ANGLE
  var delta: float = target-heading
  heading = move_toward(heading,target,minf(TURN_RATE*dt,absf(delta)*(1.0-exp(-TURN_EASE*dt))))
 # In the air the rider flies mostly forward: sideways drift is damped and kept
 # clear of the shallows, so a long (golden) jump can't carry you into the beach.
 var lateral: float = AIR_DRIFT if air > 0 else 1.0
 x += sin(heading)*speed*dt*lateral
 if air > 0: x = clampf(x,SHORE+AIR_MARGIN,720-SHORE-AIR_MARGIN)
 distance += cos(heading)*speed*dt/10.0
 if air <= 0 and (x < SHORE or x > 720-SHORE): crash("Beached")
 if air > 0:
  if grabbing: grab_time+=dt
  if queued > 0 and spin <= 0 and flip<=0 and not grabbing:
   if queued_flip: flip=0.0001
   else: spin=0.0001
   queued=0
  if flip>0:
   flip+=dt/0.6
   if flip>=1: flip=0; flips+=1; last_completion=air-dt
  if spin > 0:
   spin += dt/0.45
   if spin >= 1: spin = 0; spins += 1; last_completion=air-dt
  air -= dt
  if air <= 0:
   air = 0
   landed = true
   var off: float = minf(spin,1.0-spin)*360.0
   perfect=last_completion>=0 and last_completion<=0.15
   if grabbing: crash("Held the grab too long")
   elif flip>0 and flip<0.85: crash("Landing mid-backflip")
   elif off > 25: crash("Landing mid-spin")
   elif spins > 0 or flips>0 or grab_time>=0.25:
    trick_points += int((100*spins+250*flips+60*int(grab_time/0.25))*combo*(1.5 if perfect else 1.0))
    event("spins",spins); event("flips",flips); event("grab",grab_time)
    if perfect: event("perfect")
    combo = mini(combo+1,5)
    combo_time = 0
    events.combo=combo
func collect(kind: String) -> void:
 if kind == "shell": shells += 1; event("shells")
 elif kind == "starfish": shells += 5; event("shells",5)
 elif kind == "gust": gust = 2
func collide(kind: String) -> void:
 if kind == "wave" or kind == "wave_gold": launch(kind == "wave_gold")
 elif kind in ["shell","starfish","gust"]: collect(kind)
 elif air <= 0: crash("Watch the " + kind.replace("_"," "))
