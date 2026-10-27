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
 # Input regression: one phone tap = touch + emulated mouse; tack must flip exactly once.
 game.start(); game._process(1.0/60)
 var taps_ok: bool=true
 for i in range(3):
  var before: int=game.run.tack
  game.last_tap_ms=-1000
  var touch: InputEventScreenTouch=InputEventScreenTouch.new(); touch.pressed=true; touch.position=Vector2(360,900)
  var mouse: InputEventMouseButton=InputEventMouseButton.new(); mouse.pressed=true; mouse.button_index=MOUSE_BUTTON_LEFT; mouse.position=Vector2(360,900); mouse.device=InputEvent.DEVICE_ID_EMULATION
  var mouse_real: InputEventMouseButton=mouse.duplicate(); mouse_real.device=0
  game._unhandled_input(touch); game._unhandled_input(mouse); game._unhandled_input(mouse_real)
  game._process(1.0/60)
  taps_ok=taps_ok and game.run.tack==-before
 var pause_ok: bool=true
 var t0: int=game.run.tack; game.last_tap_ms=-1000
 var on_pause: InputEventScreenTouch=InputEventScreenTouch.new(); on_pause.pressed=true; on_pause.position=game.pause_button.get_global_rect().get_center()
 game._unhandled_input(on_pause); pause_ok=game.run.tack==t0
 print("INPUT one tap flips tack exactly once: ",taps_ok,"; tap on pause button does not flip: ",pause_ok)
 ok=ok and taps_ok and pause_ok
 var gestures: bool=true
 for kind: String in ["tap","swipe","hold"]:
  game.start(); game.run.launch(true); game.last_tap_ms=-1000
  var press: InputEventScreenTouch=InputEventScreenTouch.new(); press.pressed=true; press.position=Vector2(360,900)
  game._unhandled_input(press)
  if kind=="swipe":
   var drag: InputEventScreenDrag=InputEventScreenDrag.new(); drag.position=Vector2(360,820); game._unhandled_input(drag)
  if kind=="hold": game._process(0.22)
  else:
   var release: InputEventScreenTouch=InputEventScreenTouch.new(); release.position=Vector2(360,900); game._unhandled_input(release)
   game._process(0.01)
  gestures=gestures and (game.run.spin>0 if kind=="tap" else game.run.flip>0 if kind=="swipe" else game.run.grabbing)
 print("INPUT air tap->spin swipe->flip hold->grab: ",gestures)
 game.run.golden=true; game.run.air=0.7; game.apex_done=false; game._process(0.01)
 game.run.crash("time reset test"); game._process(0.01)
 var time_ok: bool=Engine.time_scale==1.0
 print("INPUT golden slow motion crash restores time_scale: ",time_ok)
 ok=ok and gestures and time_ok
 game.ambient.stream_paused=false
 game.ambient.stop()
 game.ambient.stream=null
 await create_timer(0.15).timeout
 game.queue_free()
 await process_frame
 await create_timer(0.15).timeout
 quit(0 if ok else 1)
