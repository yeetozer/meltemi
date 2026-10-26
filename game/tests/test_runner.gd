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
 print("RESULT ",passed," passed, ",failed," failed")
 quit(1 if failed else 0)
