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
   if (r.x>505 and r.tack==1) or (r.x<215 and r.tack==-1): game.space_held=not r.held; game.sync_steering()
   for obj: Dictionary in game.objects:
    if obj.kind in ["shell","starfish","gust","wave","wave_gold"]: continue
    if float(obj.y)>game.rider_y()-190 and float(obj.y)<game.rider_y()-50 and absf(float(obj.x)-r.x)<90:
     if (float(obj.x)>r.x and r.tack==1) or (float(obj.x)<r.x and r.tack==-1): game.space_held=not r.held; game.sync_steering()
   if frame==1800: r.crash("Smoke forced wipeout")
  game._process(1.0/60)
  if game.state=="over": game.start(); retries+=1
 if game.state=="crash": game._process(0.7)
 if game.state=="over": game.start(); retries+=1
 print("SMOKE title -> play -> wipeout -> retry -> play; simulated=60s retries=",retries," final=",game.state)
 var ok: bool=retries>0 and game.state=="play"
 game.start(); game._process(1.0/60)
 var touch: InputEventScreenTouch=InputEventScreenTouch.new(); touch.pressed=true; touch.position=Vector2(360,900)
 var mouse: InputEventMouseButton=InputEventMouseButton.new(); mouse.pressed=true; mouse.button_index=MOUSE_BUTTON_LEFT
 game._unhandled_input(touch); game._unhandled_input(touch); game._unhandled_input(mouse)
 var taps_ok: bool=game.run.held and game.run.events.get("tacks",0)==1
 var second: InputEventScreenTouch=touch.duplicate(); second.index=1; game._unhandled_input(second)
 touch.pressed=false; game._unhandled_input(touch)
 taps_ok=taps_ok and game.run.held
 second.pressed=false; game._unhandled_input(second)
 taps_ok=taps_ok and not game.run.held and game.run.events.get("tacks",0)==2
 var on_pause: InputEventScreenTouch=InputEventScreenTouch.new(); on_pause.pressed=true; on_pause.position=game.pause_button.get_global_rect().get_center()
 game._unhandled_input(on_pause)
 var pause_ok: bool=not game.run.held
 print("INPUT dedup/multitouch/press-release: ",taps_ok,"; pause excludes steering: ",pause_ok)
 ok=ok and taps_ok and pause_ok
 game.start(); game.next_chunk=10000; game.objects.clear(); touch.pressed=true; game._unhandled_input(touch); game.run.launch()
 for i in range(60): game._process(1.0/60)
 var clean: bool=not game.run.dead and game.run.air==0 and game.run.spins==0 and game.run.flips==0 and game.run.grab_time==0 and game.run.held
 print("INPUT held through launch clean without tricks: ",clean)
 ok=ok and clean
 game.start(); game._process(1.0/60)
 var key: InputEventKey=InputEventKey.new(); key.keycode=KEY_SPACE; key.pressed=true; game._unhandled_input(key)
 var keyboard_ok: bool=game.run.held
 key.pressed=false; game._unhandled_input(key); keyboard_ok=keyboard_ok and not game.run.held
 game.run.launch(true); key.pressed=true; game._unhandled_input(key); key.pressed=false; game._unhandled_input(key); game._process(0.01)
 keyboard_ok=keyboard_ok and game.run.spin>0
 print("INPUT Space hold/release and new air tap: ",keyboard_ok)
 ok=ok and keyboard_ok
 var gestures: bool=true
 for kind: String in ["tap","swipe","hold"]:
  game.start(); game.run.launch(true)
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
 var cancellation_ok: bool=true
 for hold_grab: bool in [false,true]:
  game.start(); game.run.launch(true)
  var press: InputEventScreenTouch=InputEventScreenTouch.new(); press.pressed=true; press.position=Vector2(360,900)
  game._unhandled_input(press)
  if hold_grab: game._process(0.22)
  var cancel: InputEventScreenTouch=press.duplicate(); cancel.pressed=false; cancel.canceled=true
  game._input(cancel)
  cancellation_ok=cancellation_ok and not game.run.held and game.gameplay_touches.is_empty() and game.touch_id==-1 and not game.run.grabbing and game.run.queued==0 and game.run.spin==0 and game.run.flip==0
 print("INPUT canceled air tap/grab clears holds without tricks: ",cancellation_ok)
 var background_ok: bool=true
 for notification: int in [MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT,MainLoop.NOTIFICATION_APPLICATION_PAUSED]:
  game.start(); touch.pressed=true; game._unhandled_input(touch); game.space_held=true
  game._notification(notification)
  background_ok=background_ok and game.state=="pause" and not game.run.held and not game.space_held and game.gameplay_touches.is_empty() and game.touch_id==-1
 print("INPUT focus loss/application pause clears holds: ",background_ok)
 ok=ok and cancellation_ok and background_ok
 game.ambient.stream_paused=false
 game.ambient.stop()
 game.ambient.stream=null
 await create_timer(0.15).timeout
 game.queue_free()
 await process_frame
 await create_timer(0.15).timeout
 quit(0 if ok else 1)
