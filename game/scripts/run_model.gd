class_name RunModel
extends RefCounted
const START_SPEED: float = 380.0
const MAX_SPEED: float = 700.0
const SHORE: float = 94.0
const AIR_DRIFT: float = 0.25
const AIR_MARGIN: float = 110.0
var x: float = 360.0
# Horizontal finger-to-water displacement multiplier.
const DRAG_GAIN: float = 2.0 # test range 1.5-2.5
# Position follow time constant, seconds.
const FOLLOW_TAU: float = 0.015
# Board-heading visual response time, seconds; cosmetic only.
const HEADING_SMOOTH: float = 0.06
# Accumulated touch slop; disabled after crossing it until the next touch.
const DRAG_DEADZONE: float = 2.0
# Seconds of maximum lateral travel allowed ahead of the rider.
const TARGET_LEAD: float = 0.08
var slop_crossed: bool = false
var last_finger: float = 0.0
var saturated_direction: float = 0.0
var command_age: float = 1.0
var command_heading: float = 0.0
var command_pending: bool = false
var visual_heading: float = 0.0
# Maximum lateral carve angle, radians (40 degrees).
const MAX_HEADING: float = 0.698
# Opposite heading required to register a mission tack.
const TACK_THRESHOLD: float = 0.25
# Allow intentional beaching without an offscreen runaway target.
const TARGET_MARGIN: float = 12.0
# Keyboard target movement in logical pixels per second.
const KEYBOARD_SPEED: float = 380.0
var held: bool = false
var steering: bool = false
var target_x: float = 360.0
var anchor_x: float = 360.0
var anchor_finger: float = 0.0
var heading: float = 0.0
var tack: int = 0
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
func begin_steering(finger_x: float) -> void:
 steering=true; held=true; anchor_x=x; target_x=x; anchor_finger=finger_x
 slop_crossed=false; last_finger=finger_x; saturated_direction=0; command_age=1; command_heading=0; command_pending=false
func drag_to(finger_x: float) -> void:
 if not steering: return
 var delta: float=finger_x-last_finger
 last_finger=finger_x
 if not slop_crossed:
  if absf(finger_x-anchor_finger)<=DRAG_DEADZONE: return
  slop_crossed=true
 if delta!=0: command_age=0; command_pending=true
 # Reversal after saturation discards any outstanding lead, not finger travel.
 if saturated_direction*delta<0:
  anchor_x=x; anchor_finger=finger_x-delta; saturated_direction=0
 var desired: float=anchor_x+(finger_x-anchor_finger)*DRAG_GAIN
 var lead: float=TARGET_LEAD*speed*sin(MAX_HEADING)
 target_x=clampf(clampf(desired,x-lead,x+lead),SHORE-TARGET_MARGIN,720-SHORE+TARGET_MARGIN)
 if target_x!=desired:
  saturated_direction=signf(desired-x)
  anchor_x=target_x; anchor_finger=finger_x
func end_steering(keep_command: bool = true) -> void:
 if keep_command and steering and command_age<=0.05 and absf(command_heading)>0.03: heading=command_heading
 steering=false; held=false
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
 # Apply airborne drift damping once; subsequent heading is the actual course.
 heading=atan2(tan(heading)*AIR_DRIFT,1.0)
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
 var lateral: float = AIR_DRIFT if air > 0 else 1.0
 var vx: float = tan(heading)*speed
 if steering:
  var cap: float = speed*sin(MAX_HEADING)
  target_x=clampf(target_x,x-cap*TARGET_LEAD,x+cap*TARGET_LEAD)
  vx=clampf((target_x-x)*(1.0-exp(-dt/FOLLOW_TAU))/maxf(dt,0.00001),-cap,cap)*lateral
 var previous_x: float=x
 x+=vx*dt
 if air>0: x=clampf(x,SHORE+AIR_MARGIN,720-SHORE-AIR_MARGIN)
 if dt>0 and (steering or x!=previous_x+vx*dt):
  heading=clampf(atan2((x-previous_x)/dt,speed),-MAX_HEADING,MAX_HEADING)
 if steering and command_pending and absf(heading)>0.03: command_heading=heading
 command_pending=false
 command_age+=dt
 visual_heading=lerpf(visual_heading,heading,1.0-exp(-dt/HEADING_SMOOTH))
 if air<=0 and absf(heading)>TACK_THRESHOLD:
  var side: int = 1 if heading>0 else -1
  if tack!=0 and side!=tack: event("tacks")
  tack=side
 distance += speed*dt/10.0 # speed is forward velocity; heading = atan2(lateral, forward).
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
