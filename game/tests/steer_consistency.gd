extends SceneTree
const Model=preload("res://tests/steer_fixed.gd")
const DT: float=1.0/60.0
var failed: int=0
var passed: int=0
func check(ok: bool, label_: String) -> void:
 if ok: passed+=1; print("PASS ",label_)
 else: failed+=1; printerr("FAIL ",label_)
func set_speed(r: RunModel, value: float) -> void:
 r.fixed_speed=value; r.elapsed=180
 r.gust=10 if value>700 else 0
func _initialize() -> void:
 var baseline: Array=[]
 var releases: Array=[]
 for value: float in [380.0,260.0,540.0,700.0,1050.0]:
  var r: RunModel=Model.new(); r.speed=value; r.begin_steering(0)
  var curve: Array=[]; var overshoot: bool=false; var t90: float=99
  r.drag_to(60)
  for i in range(90):
   set_speed(r,value); r.tick(DT); curve.append(r.x)
   overshoot=overshoot or r.x>r.target_x+0.00001
   if r.x>=360+0.9*120 and t90==99: t90=float(i+1)*DT
  if baseline.is_empty(): baseline=curve
  var error: float=0
  for i in range(curve.size()): error=maxf(error,absf(curve[i]-baseline[i]))
  check(error<=120*0.05,"step curve speed-independent "+str(value))
  check(not overshoot and t90<=0.6,"step no overshoot and t90 <=600ms "+str(value))
  r=Model.new(); r.speed=value; r.begin_steering(0)
  var rng=RandomNumberGenerator.new(); rng.seed=9182
  var sum_sq: float=0
  for i in range(180):
   set_speed(r,value); r.drag_to(10 if i<60 else 10+rng.randf_range(-1.5,1.5)); r.tick(DT)
   if i>=90: sum_sq+=r.heading*r.heading
  check(rad_to_deg(sqrt(sum_sq/90))<1,"1.5px noise heading RMS <1deg "+str(value))
  r=Model.new(); r.speed=value; r.begin_steering(0)
  for i in range(12):
   set_speed(r,value); r.drag_to(float(i)*10); r.tick(DT)
  r.end_steering(); r.x=360
  set_speed(r,value); r.tick(DT)
  releases.append(r.lateral_velocity)
 check(absf(float(releases.max())-float(releases.min()))<0.001,"released lateral velocity equal at every speed")
 var r: RunModel=Model.new(); r.elapsed=90; r.begin_steering(0)
 var reference: RunModel=Model.new(); reference.elapsed=90; reference.begin_steering(0)
 var consistent: bool=true; var smooth: bool=true
 for i in range(45):
  r.elapsed=90; reference.elapsed=90
  r.gust=10 if i>=12 and i<30 else 0
  r.drag_to(float(i)*3); reference.drag_to(float(i)*3)
  var previous: float=r.visual_heading
  r.tick(DT); reference.tick(DT)
  consistent=consistent and absf(r.x-reference.x)<0.001 and absf(r.heading-atan2(r.lateral_velocity,r.speed))<0.00001
  smooth=smooth and absf(r.visual_heading-previous)<=Model.HEADING_RATE*DT+0.00001
 check(consistent,"gust start/end mid-carve changes only natural atan2 heading, not lateral motion")
 check(smooth,"board rotation rate bounded through gust transitions")
 # Shallows may constrain vx only when the physical 40-degree limit requires it.
 r=Model.new(); r.x=130; r.elapsed=90; r.begin_steering(0)
 reference=Model.new(); reference.elapsed=90; reference.begin_steering(0)
 for i in range(8):
  r.drag_to(float(i)*3); reference.drag_to(float(i)*3); r.tick(DT); reference.tick(DT)
 check(absf((r.x-130)-(reference.x-360))<0.001,"shallows preserve lateral response when angle cap permits")
 r=Model.new(); r.x=586; r.lateral_velocity=Model.LATERAL_MAX
 r.tick(DT); r.tick(DT)
 check(absf(r.heading-atan2(r.lateral_velocity,r.speed))<0.00001 and absf(r.lateral_velocity)<=Model.LATERAL_MAX,"sudden shallow entry preserves physical heading/velocity agreement")
 print("STEERING RESULT ",passed," passed, ",failed," failed")
 quit(1 if failed else 0)
