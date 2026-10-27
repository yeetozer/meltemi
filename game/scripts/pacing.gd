class_name RunPacing
extends RefCounted
# All runs, including retries, get the same eight-second safe introduction.
const WARMUP: float=8.0
const START_SPEED: float=260.0
const MAX_SPEED: float=700.0
const SPEED_KEYS: Array[Vector2]=[Vector2(0,260),Vector2(8,270),Vector2(30,380),Vector2(90,500),Vector2(180,700)]
const FIRST_OBSTACLE: float=12.0
const FIRST_WAVE: float=20.0
const DENSITY_START: float=30.0
const FULL_DENSITY: float=180.0
const EASY_OBSTACLE_GAP: float=10.0
const FULL_OBSTACLE_GAP: float=0.29 # ~34 hazards/10s, matching the old full-density seed.
const EARLY_DENSITY: float=0.92 # ~1 hazard/s by90s, old opening density.
const DENSITY_KEYS: Array[Vector2]=[Vector2(30,0),Vector2(90,EARLY_DENSITY),Vector2(180,1)]
# Seconds between arrivals; ease density instead of stepping at chunk boundaries.
const FIRST: Dictionary={"obstacle":FIRST_OBSTACLE,"pickup":4.0,"wave":FIRST_WAVE,"gust":40.0}
const EASY_GAPS: Dictionary={"obstacle":EASY_OBSTACLE_GAP,"pickup":4.0,"wave":20.0,"gust":18.0}
const FULL_GAPS: Dictionary={"obstacle":FULL_OBSTACLE_GAP,"pickup":0.23,"wave":1.83,"gust":1.83}
static func smooth_curve(u: float) -> float:
 return u*u*(3.0-2.0*u)
static func speed_at(t: float) -> float:
 for i in range(1,SPEED_KEYS.size()):
  var a: Vector2=SPEED_KEYS[i-1]; var b: Vector2=SPEED_KEYS[i]
  if t<=b.x: return lerpf(a.y,b.y,smooth_curve(clampf((t-a.x)/(b.x-a.x),0,1)))
 return MAX_SPEED
static func density(t: float) -> float:
 for i in range(1,DENSITY_KEYS.size()):
  var a: Vector2=DENSITY_KEYS[i-1]; var b: Vector2=DENSITY_KEYS[i]
  if t<=b.x: return lerpf(a.y,b.y,smooth_curve(clampf((t-a.x)/(b.x-a.x),0,1)))
 return 1.0
static func integral(u: float) -> float:
 return u*u*u-0.5*u*u*u*u
static func distance_at(t: float) -> float:
 var total: float=0
 for i in range(1,SPEED_KEYS.size()):
  var a: Vector2=SPEED_KEYS[i-1]; var b: Vector2=SPEED_KEYS[i]
  var duration: float=b.x-a.x
  var u: float=clampf((t-a.x)/duration,0,1)
  total+=duration*(a.y*u+(b.y-a.y)*integral(u))
 return total+maxf(0,t-180)*MAX_SPEED
static func time_at(d: float) -> float:
 var lo: float=0; var hi: float=maxf(180,d/START_SPEED)
 for i in range(28):
  var mid: float=(lo+hi)/2
  if distance_at(mid)<d: lo=mid
  else: hi=mid
 return (lo+hi)/2
