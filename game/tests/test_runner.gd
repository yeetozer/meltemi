extends SceneTree
const Model=preload("res://scripts/run_model.gd")
const Chunks=preload("res://scripts/chunks.gd")
const Saves=preload("res://scripts/save_store.gd")
var passed: int=0
var failed: int=0
func check(ok: bool,name_: String) -> void:
 if ok: passed+=1; print("PASS ",name_)
 else: failed+=1; printerr("FAIL ",name_)
func _initialize() -> void:
 var r: RunModel=Model.new(); r.tap(); r.tick(0.2); check(r.tack==-1 and r.heading<0,"tack flips heading")
 r=Model.new(); r.launch(); r.x=360
 for i in range(60): r.x=360; r.tick(1.0/60)
 check(r.air==0 and not r.dead,"wave airborne lands")
 r=Model.new(); r.launch(); r.air=0.01; r.spin=0.5; r.tick(0.02); check(r.dead,"mid spin wipeout")
 r=Model.new(); r.collide("rock_big"); check(r.dead,"obstacle game over")
 r=Model.new(); r.x=80; r.tick(0.01); check(r.reason=="Beached","beached")
 r=Model.new(); r.shells=3; r.distance=12.3; r.combo=2; r.launch(); r.air=0.01; r.spins=1; r.tick(0.02); check(r.trick_points==200 and r.combo==3 and r.score()==242,"score combo math")
 var air_ok: bool=true
 for start_x: float in [140.0,360.0,580.0]:
  for t: int in [1,-1]:
   r=Model.new(); r.elapsed=90; r.x=start_x; r.tack=t; r.heading=t*0.698; r.tick(0.0); r.launch(true)
   var steps: int=0
   while r.air>0 and steps<600: r.tick(1.0/60); steps+=1
   air_ok=air_ok and not r.dead and r.x>=Model.SHORE+Model.AIR_MARGIN-0.01 and r.x<=720-Model.SHORE-Model.AIR_MARGIN+0.01
   r.tap(); var tk: int=r.tack; air_ok=air_ok and tk==-t
 check(air_ok,"golden jump at max speed never beaches; tap after landing switches")
 var maker: ChunkMaker=Chunks.new(); var gaps: bool=true
 for i in range(500):
  var c: Dictionary=maker.chunk(9182,i)
  gaps=gaps and c.gap_width>=180
  for o: Dictionary in c.objects:
   if o.kind in ["shell","starfish","gust","wave","wave_gold"]: continue
   gaps=gaps and absf(float(o.x)-float(c.gap))-float(o.size.x)/2-18>=90
 check(gaps,"500 seeded passable chunks including moving sweep")
 var s: SaveStore=Saves.new(); s.path="user://test_save.json"; s.read_save(); s.data.best=987; s.write_save(); var t: SaveStore=Saves.new(); t.path=s.path; t.read_save(); check(t.data.best==987,"save roundtrip")
 var f: FileAccess=FileAccess.open(s.path,FileAccess.WRITE); f.store_string("{bad"); f.close(); t.read_save(); check(t.data.best==0 and FileAccess.file_exists(s.path+".corrupt"),"corrupt recovery")
 r=Model.new(); r.launch(true); r.backflip()
 for i in range(110): r.tick(1.0/60)
 check(not r.dead and r.trick_points==250,"backflip scoring")
 r=Model.new(); r.launch(); r.flip=0.4; r.air=0.01; r.tick(0.02); check(r.dead,"mid flip wipeout")
 r=Model.new(); r.launch(); r.grab(true); r.air=0.01; r.tick(0.02); check(r.reason=="Held the grab too long","grab held landing wipeout")
 r=Model.new(); r.launch(true); r.grab(true)
 for i in range(31): r.tick(1.0/60)
 r.grab(false); r.air=0.01; r.tick(0.02); check(r.trick_points==120,"released grab scores quarter seconds")
 r=Model.new(); r.launch(); r.spins=1; r.last_completion=0.1; r.air=0.01; r.tick(0.02); check(r.trick_points==150 and r.perfect,"perfect multiplier")
 r=Model.new(); check(r.near_miss(123) and not r.near_miss(123) and r.trick_points==25,"near miss once per hazard")
 var missions=load("res://scripts/missions.gd")
 var d: Dictionary=s.defaults(); var rewards: Array=missions.update(d,{"spins":1,"distance":100,"tacks":5})
 check(rewards.size()==3 and d.missions.active==[3,4,5] and d.shells==30,"mission completion reward replacement")
 check(missions.level(200)==3,"XP level up")
 t.data.hints=3; t.data.xp=99; t.write_save(); t.read_save(); check(t.data.hints==3 and t.data.xp==99,"tutorial hints and XP persist")
 r=Model.new(); r.launch(true); r.tap()
 for i in range(110): r.tick(1.0/60)
 check(not r.dead and r.spins==1 and r.trick_points==100,"actual queued spin scoring")
 f=FileAccess.open(s.path,FileAccess.WRITE); f.store_string('{"version":1,"best":123,"shells":45,"owned":["sunset","olive"],"selected":"olive"}'); f.close(); t.read_save()
 check(t.data.version==2 and t.data.best==123 and t.data.shells==45 and t.data.selected=="olive" and t.data.missions.active.size()==3,"v1 migration retains possessions")
 var date: Dictionary={"year":2026,"month":10,"day":27}; var deterministic: bool=true
 for i in range(20): deterministic=deterministic and maker.chunk(missions.daily_seed(date),i)==maker.chunk(missions.daily_seed(date),i)
 check(deterministic,"daily same date same first 20 chunks")
 print("RESULT ",passed," passed, ",failed," failed")
 quit(1 if failed else 0)
