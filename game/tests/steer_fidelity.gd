extends SceneTree
const Model=preload("res://scripts/run_model.gd")
const DT: float=1.0/120.0
func _initialize() -> void:
 var rows: Array=[]
 var failed: int=0
 var baseline: Dictionary={}
 var verify: bool=not "--capture" in OS.get_cmdline_user_args()
 for speed: float in [380.0,700.0,1050.0]:
  for amount: float in [60.0,120.0]:
   for duration: float in [0.08,0.15,0.25,0.4]:
    var r=Model.new(); r.x=300; r.begin_steering(0)
    var curve: Array=[]; var last_far: float=0; var overshoot: float=0
    for i in range(360):
     var t: float=(i+1)*DT
     var u: float=minf(t/duration,1)
     r.elapsed=90 if speed>=700 else 0; r.gust=10 if speed>700 else 0
     r.drag_to(amount*(0.5-0.5*cos(PI*u))); r.tick(DT)
     curve.append(r.x-300)
     overshoot=maxf(overshoot,r.x-r.target_x)
    var final: float=r.x-300
    for i in range(curve.size()):
     if absf(float(curve[i])-final)>3: last_far=(i+1)*DT
    var error: float=100*absf(final-amount*2)/(amount*2)
    var key: String=str(amount)+"/"+str(duration)
    if speed==380: baseline[key]=curve
    var deviation: float=0
    for i in range(curve.size()): deviation=maxf(deviation,absf(float(curve[i])-float(baseline[key][i]))/(amount*2)*100)
    var row={"speed":speed,"finger":amount,"duration":duration,"expected":amount*2,"actual":final,"error_pct":error,"coast_s":maxf(0,last_far+DT-duration),"overshoot":overshoot,"speed_curve_error_pct":deviation}
    rows.append(row)
    if verify and (error>(10 if duration<0.15 else 5) or overshoot>0.0001 or deviation>5): failed+=1
 # Reversal must erase old-direction backlog even without hitting safety clamp.
 var r=Model.new(); r.elapsed=90; r.begin_steering(0); r.drag_to(60); r.tick(DT)
 r.drag_to(55); r.tick(DT)
 if verify and r.lateral_velocity>=0: failed+=1
 var reversals: int=0; var immediate: int=0; var previous_delta: float=0; var last: float=0
 r=Model.new(); r.begin_steering(0)
 for i in range(480):
  var finger: float=30*sin(TAU*2*(i+1)*DT)
  var delta: float=finger-last
  r.drag_to(finger); r.tick(DT)
  if delta*previous_delta<0:
   reversals+=1
   if r.lateral_velocity*delta>=0: immediate+=1
  if delta!=0: previous_delta=delta
  last=finger
 if verify and immediate!=reversals: failed+=1
 print("FIDELITY ",JSON.stringify({"swipes":rows,"wiggle_reversals":reversals,"immediate_reversals":immediate,"wiggle_final_x":r.x,"failed":failed}))
 quit(1 if failed else 0)
