class_name ChunkMaker
extends RefCounted
const Pacing=preload("res://scripts/pacing.gd")
const SIZES: Dictionary = {"buoy":Vector2(40,40),"rock_small":Vector2(70,60),"rock_big":Vector2(140,110),"turtle":Vector2(60,70),"boat_fishing":Vector2(70,160),"jetski":Vector2(44,90),"sailboat":Vector2(80,180),"shell":Vector2(32,32),"starfish":Vector2(40,40),"gust":Vector2(80,80),"wave":Vector2(256,48),"wave_gold":Vector2(256,48)}
var rng: RandomNumberGenerator=RandomNumberGenerator.new()
var schedule_cursor: Dictionary={}
var last_seed: int=0
var last_index: int=-1
# Times describe arrival at the rider in open water, without collected gusts.
# Main spawns 990.4px ahead: subtract that lead once, never once per chunk.
const SPAWN_LEAD: float=990.4
func chunk(seed_: int, index: int) -> Dictionary:
 # Retain schedule positions for sequential chunks; resets/replays remain valid.
 if seed_!=last_seed or index!=last_index+1: schedule_cursor.clear()
 last_seed=seed_; last_index=index
 var objects: Array[Dictionary]=[]
 var start: float=index*1280.0
 var end: float=start+1280
 var until: float=Pacing.time_at(end+SPAWN_LEAD)
 rng.seed=seed_+index*7919
 var course_gap: float=rng.randf_range(260,460) if start>Pacing.distance_at(30) else 360.0
 for category: String in ["obstacle","pickup","wave","gust"]:
  var cursor: Dictionary=schedule_cursor.get(category,{"time":Pacing.FIRST[category],"n":0})
  var time_: float=cursor.time
  var n: int=cursor.n
  while time_<=until:
   var position: float=Pacing.distance_at(time_)-SPAWN_LEAD
   if position>=start and position<end:
    rng.seed=seed_+n*7919+category.hash()
    var gap: float=rng.randf_range(280,440)
    var kind: String=category
    var px: float=gap
    if category=="obstacle":
     kind="buoy" if time_<30 else ["buoy","rock_small","rock_big","turtle","boat_fishing","jetski","sailboat"][rng.randi_range(0,6)]
     # One early obstacle, stationary and well clear of the central training lane.
     px=190.0 if n%2==0 else 530.0
     if time_>=30:
      var offset: float=110+SIZES[kind].x/2+18
      px=course_gap+(-1 if n%2==0 else 1)*offset
      if px-SIZES[kind].x/2-18<104 or px+SIZES[kind].x/2+18>616: px=course_gap+(1 if n%2==0 else -1)*offset
    elif category=="pickup": kind="starfish" if n%5==4 else "shell"
    elif category=="wave": kind="wave_gold" if n%3==2 else "wave"
    objects.append({"kind":kind,"x":px,"y":-(position-start),"size":SIZES[kind],"base":px,"phase":rng.randf()*TAU,"move":time_>=30 and kind in ["boat_fishing","jetski"],"arrival":time_})
   var density: float=Pacing.density(time_)
   time_+=lerpf(Pacing.EASY_GAPS[category],Pacing.FULL_GAPS[category],density)
   n+=1
  schedule_cursor[category]={"time":time_,"n":n}
 return {"gap":course_gap,"gap_width":200.0,"objects":objects}
