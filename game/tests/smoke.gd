extends SceneTree
var game: Node
func _initialize() -> void: call_deferred("go")
func go() -> void:
 game=load("res://scenes/main.tscn").instantiate(); game.save.path="user://smoke_save.json"; root.add_child(game)
 if game.state!="title": quit(1); return
 game.start()
 game.save.data.sound=false
 var retries: int=0
 for frame in range(3600):
  if game.state=="play":
   var r: RunModel=game.run
   if (r.x>505 and r.tack==1) or (r.x<215 and r.tack==-1): game.action()
   for obj: Dictionary in game.objects:
    if obj.kind in ["shell","starfish","gust","wave","wave_gold"]: continue
    if float(obj.y)>game.rider_y()-190 and float(obj.y)<game.rider_y()-50 and absf(float(obj.x)-r.x)<90:
     if (float(obj.x)>r.x and r.tack==1) or (float(obj.x)<r.x and r.tack==-1): game.action()
   if frame==1800: r.crash("Smoke forced wipeout")
  game._process(1.0/60)
  if game.state=="over": game.start(); retries+=1
 if game.state=="crash": game._process(0.7)
 if game.state=="over": game.start(); retries+=1
 print("SMOKE title -> play -> wipeout -> retry -> play; simulated=60s retries=",retries," final=",game.state)
 var ok: bool=retries>0 and game.state=="play"
 game.queue_free()
 await process_frame
 await create_timer(0.15).timeout
 quit(0 if ok else 1)
