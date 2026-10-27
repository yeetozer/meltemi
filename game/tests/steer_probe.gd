extends SceneTree
const Model=preload("res://scripts/run_model.gd")
const DT: float=1.0/60.0
func _initialize() -> void:
 var output: Dictionary={}
 for speed_: float in [380.0,540.0,700.0,1050.0]:
  for track: String in ["step","sine","jitter","release","gust"]:
   var r=Model.new()
   var rng=RandomNumberGenerator.new(); rng.seed=9182
   r.speed=speed_; r.begin_steering(0)
   var rows: Array=[]
   for i in range(180):
    r.elapsed=clampf((minf(speed_,700.0)-380.0)/320.0*90.0-DT,0,90)
    r.gust=10 if speed_>700 else 0
    if track=="gust" and i>=30 and i<90: r.gust=10
    var finger: float=0
    if track=="step": finger=60
    elif track=="sine": finger=40*sin(TAU*float(i)*DT)
    elif track=="jitter": finger=10 if i<60 else 10+rng.randf_range(-1.5,1.5)
    elif track=="release" or track=="gust": finger=minf(float(i)*10,300)
    if track=="release" and i==12:
     r.end_steering(); r.x=360
    if track!="release" or i<12: r.drag_to(finger)
    var previous: float=r.x
    r.tick(DT)
    rows.append([float(i+1)*DT,r.x,(r.x-previous)/DT,r.heading,r.visual_heading,r.target_x,r.speed,r.dead])
   output[str(int(speed_))+"_"+track]=rows
 var args=OS.get_cmdline_user_args()
 var path: String=args[0] if args.size()>0 else "../art/qa/steer/probe.json"
 DirAccess.make_dir_recursive_absolute(path.get_base_dir())
 var file=FileAccess.open(path,FileAccess.WRITE)
 file.store_string(JSON.stringify(output)); file.close()
 print("STEER_PROBE ",path)
 quit()
