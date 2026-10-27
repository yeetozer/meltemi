extends SceneTree
const Model=preload("res://scripts/run_model.gd")
const Chunks=preload("res://scripts/chunks.gd")
func _initialize() -> void:
 var r=Model.new(); var maker=Chunks.new(); var objects: Array=[]; var index: int=0; var next: float=0
 var rows: Array=[]; var first: float=-1
 for i in range(18): rows.append({"window":i*10,"speed_start":0.0,"speed_end":0.0,"obstacles":0,"pickups":0,"waves":0})
 # Legacy authored opening, removed by the calm-start implementation.
 if not Model.START_SPEED<300:
  for entry: Array in [["wave",500.0],["shell",660.0],["shell",740.0],["buoy",850.0]]: objects.append({"kind":entry[0],"y":870.4-entry[1]})
 for frame in range(10800):
  var time_: float=frame/60.0; var row: Dictionary=rows[mini(17,int(time_/10))]
  var before: float=r.distance; r.tick(1.0/60.0); var scroll: float=(r.distance-before)*10
  if frame%600==0: row.speed_start=r.speed
  row.speed_end=r.speed
  next-=scroll
  if next<=0:
   var chunk: Dictionary=maker.chunk(81273,index)
   for obj: Dictionary in chunk.objects:
    obj.y+=next-120; objects.append(obj)
   next+=1280; index+=1
  for obj: Dictionary in objects:
   var old: float=obj.y; obj.y+=scroll
   if old<870.4 and obj.y>=870.4:
    if obj.kind in ["wave","wave_gold"]: row.waves+=1
    elif obj.kind in ["shell","starfish","gust"]: row.pickups+=1
    else:
     row.obstacles+=1
     if first<0: first=time_
  objects=objects.filter(func(o: Dictionary) -> bool: return o.y<1500)
 print("PACING ",JSON.stringify({"first_obstacle":first,"rows":rows})); quit()
