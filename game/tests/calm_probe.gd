extends SceneTree
const Model=preload("res://tests/steer_fixed.gd")
const DT: float=1.0/120.0
func _initialize() -> void:
 var result: Array=[]
 for speed_: float in [260.0,380.0,700.0]:
  for swipe: bool in [false,true]:
   var r=Model.new(); r.begin_steering(0)
   var xs: Array=[]; var vs: float=0; var angles: float=0; var flips: int=0; var last_sign: float=0
   for i in range(600):
    var t: float=float(i)*DT
    var finger: float=60*minf(t/0.25,1) if swipe else 0
    if t>0.5: finger+=2*sin(TAU*8*t)+1*sin(TAU*12*t)+3*sin(TAU*0.25*t)+float(int(t*3)%2)
    r.fixed_speed=speed_; r.drag_to(finger); r.tick(DT)
    if t>=2:
     xs.append(r.x); vs+=r.lateral_velocity*r.lateral_velocity; angles+=pow(rad_to_deg(r.visual_heading),2)
     var s: float=signf(r.visual_heading) if absf(r.visual_heading)>0.00001 else 0
     if s*last_sign<0: flips+=1
     if s!=0: last_sign=s
   var mean: float=0; var variance: float=0
   for x_: float in xs: mean+=x_/xs.size()
   for x_: float in xs: variance+=pow(x_-mean,2)/xs.size()
   result.append({"speed":speed_,"after_swipe":swipe,"x_sd":sqrt(variance),"x_pp":xs.max()-xs.min(),"vx_rms":sqrt(vs/xs.size()),"board_rms_deg":sqrt(angles/xs.size()),"flips_per_s":flips/3.0})
 var failed: bool=false
 for row: Dictionary in result:
  if row.x_pp>=1.5 or row.board_rms_deg>=0.3 or row.flips_per_s!=0: failed=true
 print("HOLD ",JSON.stringify(result)); quit(1 if failed else 0)
