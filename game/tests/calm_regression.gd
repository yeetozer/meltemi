extends SceneTree
const Model=preload("res://tests/steer_fixed.gd")
const Pacing=preload("res://scripts/pacing.gd")
const Chunks=preload("res://scripts/chunks.gd")
var failed: int=0
func check(ok: bool, label_: String) -> void:
 print("PASS " if ok else "FAIL ",label_)
 if not ok: failed+=1
func _initialize() -> void:
 var r=Model.new(); r.begin_steering(100)
 for i in range(30): r.drag_to(100); r.tick(1.0/120)
 check(r.hold_locked,"stationary hold enters lock")
 var frozen: float=r.target_x; var lock: float=r.lock_finger
 r.drag_to(lock+9); r.tick(1.0/120)
 check(r.hold_locked and r.target_x==frozen,"sub-threshold movement cannot move target")
 r.drag_to(lock+11)
 check(not r.hold_locked and absf(r.target_x-frozen-22)<0.001,"unlock preserves full 11px excursion, not only 1px excess")
 r.end_steering(false); r.begin_steering(500)
 check(r.filtered_finger==500 and r.filtered_derivative==0 and not r.hold_locked,"new touch resets filter and lock")
 var max_lag: float=0
 for speed_: float in [210.0,300.0,600.0,1200.0]:
  r=Model.new(); r.begin_steering(0)
  for i in range(30):
   var raw: float=(i+1)*speed_/120.0
   r.drag_to(raw)
   max_lag=maxf(max_lag,absf(raw-r.filtered_finger)/speed_)
   r.tick(1.0/120)
   check(not r.hold_locked,"swipe stays unlocked %s frame %s" % [speed_,i])
 check(max_lag<=0.010,"1-Euro added position-equivalent swipe lag <=10ms: %.3fms" % (max_lag*1000))
 r=Model.new(); r.begin_steering(0); r.drag_to(60)
 for i in range(240): r.tick(1.0/120)
 check(r.hold_locked and r.visual_heading==0,"no subsequent drag events still locks and straightens")
 var smooth: bool=true; var previous: float=Pacing.speed_at(0)
 for i in range(1,24001):
  var speed_: float=Pacing.speed_at(i/120.0)
  smooth=smooth and speed_>=previous and speed_-previous<0.07
  previous=speed_
 check(smooth,"speed monotonic and smooth through every pacing boundary")
 var maker=Chunks.new(); var times: Array=[]; var waves: Array=[]
 for i in range(90):
  for obj: Dictionary in maker.chunk(81273,i).objects:
   if obj.kind in ["wave","wave_gold"]: waves.append(obj.arrival)
   elif obj.kind not in ["shell","starfish","gust"]: times.append(obj.arrival)
 times.sort(); waves.sort()
 check(times[0]>=Pacing.WARMUP and times[0]==12,"no obstacles before warm-up; first arrival 12s")
 var spacing: bool=true
 for i in range(1,times.size()):
  if times[i]<=30: spacing=spacing and times[i]-times[i-1]>=10
 check(spacing,"8-30s single obstacles have >=10s arrival spacing")
 check(waves[0]==20,"first gentle wave arrives at20s")
 var shallow=Model.new(); shallow.fixed_speed=260; shallow.x=105; shallow.begin_steering(0); shallow.drag_to(100)
 for i in range(12): shallow.tick(1.0/120)
 check(shallow.speed==156 and shallow.lateral_velocity>200,"slow-start shallow retains lateral authority at156px/s forward")
 print("CALM RESULT failed=",failed); quit(1 if failed else 0)
