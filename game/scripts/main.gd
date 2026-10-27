extends Node2D
const LIGHT_OFFSET: Vector2 = Vector2(5,7)
const Missions = preload("res://scripts/missions.gd")
const Model = preload("res://scripts/run_model.gd")
const Chunks = preload("res://scripts/chunks.gd")
const Saves = preload("res://scripts/save_store.gd")
var daily: bool=false
var course_seed: int=81273
var daily_date: String=""
var gameplay_touches: Dictionary={}
var key_left: bool=false
var key_right: bool=false
var touch_id: int=-1
var touch_origin: Vector2
var touch_position: Vector2
var touch_travel: float=0
var touch_age: float=0
var touch_air: bool=false
var gesture_done: bool=false
var turn_juice: float=0
var landing_juice: float=0
var flash: float=0
var slow_age: float=-1
var apex_done: bool=false
var popups: Array=[]
var toast: String=""
var toast_time: float=0
var mission_gained: Array=[]
var mission_start: Dictionary={}
var run_spins: float=0
func restore_time() -> void:
 Engine.time_scale=1.0; slow_age=-1
func popup(text: String) -> void:
 popups.append({"text":text,"pos":Vector2(clampf(run.x-30,170,460),rider_y()-155),"age":0.0})
func daily_start() -> void:
 daily=true; start()
func share_daily() -> void:
 var text: String="Meltemi Daily %s: %s pts 🪁 https://yeetozer.github.io/meltemi-play/" % [daily_date,run.score()]
 DisplayServer.clipboard_set(text)
 if OS.has_feature("web"):
  JavaScriptBridge.eval("if(navigator.share){navigator.share({text:%s}).catch(()=>{});}" % JSON.stringify(text))
 toast="Copied!"; toast_time=3
 for child: Node in panel.get_children():
  if child is Button and child.text=="Share": child.text="Copied!"
func mission_labels() -> void:
 label_("Lv %d  ·  %d / 100 XP" % [Missions.level(int(save.data.xp)),int(save.data.xp)%100],22)
 var bar: ProgressBar=ProgressBar.new(); bar.custom_minimum_size=Vector2(420,12); bar.show_percentage=false; bar.value=int(save.data.xp)%100; panel.add_child(bar)
 for id: int in save.data.missions.active:
  var goal: Array=Missions.POOL[id%Missions.POOL.size()]
  var card: PanelContainer=PanelContainer.new()
  var style: StyleBoxFlat=StyleBoxFlat.new(); style.bg_color=Color("dce9dc"); style.set_corner_radius_all(8); style.content_margin_top=3; style.content_margin_bottom=3
  card.add_theme_stylebox_override("panel",style); panel.add_child(card)
  var row: Label=Label.new(); row.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; row.add_theme_font_size_override("font_size",19); row.add_theme_color_override("font_color",Color("2b2b2b"))
  row.text="%s  ·  %s/%s" % [goal[0],str(snappedf(float(save.data.missions.progress.get(str(id),0)),0.1)) if goal[1]=="grab" else str(int(save.data.missions.progress.get(str(id),0))),goal[2]]; card.add_child(row)
var run: RunModel = Model.new()
var maker: ChunkMaker = Chunks.new()
var save: SaveStore = Saves.new()
var state: String = "title"
var objects: Array[Dictionary] = []
var chunk_index: int = 0
var next_chunk: float = 0
var clock: float = 0
var crash_timer: float = 0
var new_best: bool = false
var ui: Control
var panel: VBoxContainer
var pause_button: Button
var shell_icon: TextureRect
var distance_label: Label
var hud: Label
var hint: Label
var wake: Line2D
var lines: Array[Line2D] = []
var spray: CPUParticles2D
var ambient: AudioStreamPlayer
var world: Node2D
var rider: Sprite2D
var kite: Sprite2D
var shadow: Polygon2D
var safe_top: float = 64
var snap: String = ""
var snap_frames: int = 0
var capture_done: bool = false
var spin_hint: bool = false
var web_debug: bool = false
var raw_touches: int = 0
var unhandled_touches: int = 0
var actions: int = 0
func _exit_tree() -> void:
 restore_time()
 if is_instance_valid(ambient):
  ambient.stop()
  ambient.stream=null
func _ready() -> void:
 Engine.max_fps = 60
 Input.emulate_touch_from_mouse = not DisplayServer.is_touchscreen_available()
 save.read_save()
 var theme_: Theme = Theme.new()
 var fonts: DirAccess = DirAccess.open("res://assets/fonts")
 if fonts:
  for file: String in fonts.get_files():
   if file.ends_with(".ttf"): theme_.default_font = load("res://assets/fonts/"+file); break
 theme_.default_font_size = 26
 world = Node2D.new(); add_child(world)
 wake = Line2D.new(); wake.width = 18; wake.default_color = Color(1,1,1,0.45); world.add_child(wake)
 var taper: Curve=Curve.new(); taper.add_point(Vector2(0,0)); taper.add_point(Vector2(0.7,0.65)); taper.add_point(Vector2(1,1)); wake.width_curve=taper
 var gradient_: Gradient = Gradient.new(); gradient_.set_color(0,Color(1,1,1,0)); gradient_.set_color(1,Color(1,1,1,0.6)); wake.gradient = gradient_
 shadow = Polygon2D.new()
 var oval: PackedVector2Array = PackedVector2Array()
 for j in range(24): oval.append(Vector2(cos(float(j)*TAU/24)*25,sin(float(j)*TAU/24)*36))
 shadow.polygon=oval; shadow.color=Color(0.169,0.169,0.169,0.25); world.add_child(shadow)
 for i in range(2):
  var line: Line2D = Line2D.new(); line.width=1.5; line.default_color=Color(0.15,0.25,0.25,0.7); world.add_child(line); lines.append(line)
 rider = Sprite2D.new(); if not save.data.reduce_motion:
  rider.rotation+=sin(turn_juice/0.22*PI)*0.22*run.tack
  rider.skew=sin(turn_juice/0.22*PI)*0.12*run.tack
  if landing_juice>0.18: rider.scale*=Vector2(1.2,0.8)
 if run.flip>0: rider.scale.y*=cos(run.flip*TAU); rider.position.y-=sin(run.flip*PI)*15
 if run.grabbing: rider.scale*=1.08; rider.rotation+=0.2
 rider.texture=AssetLib.texture("sprites/rider.png",Vector2(72,72)); world.add_child(rider)
 kite = Sprite2D.new(); kite.position=Vector2(470,790); world.add_child(kite)
 spray=CPUParticles2D.new(); spray.amount=42; spray.lifetime=0.4; spray.one_shot=true; spray.explosiveness=0.9; spray.direction=Vector2(0,1); spray.spread=65; spray.initial_velocity_min=70; spray.initial_velocity_max=160; spray.gravity=Vector2(0,80); spray.scale_amount_min=2; spray.scale_amount_max=5; spray.emitting=false; world.add_child(spray)
 var canvas: CanvasLayer = CanvasLayer.new(); add_child(canvas)
 ui=Control.new(); ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); ui.mouse_filter=Control.MOUSE_FILTER_IGNORE; ui.theme=theme_; canvas.layer=10; canvas.add_child(ui)
 panel=VBoxContainer.new(); panel.add_theme_constant_override("separation",10); ui.add_child(panel)
 hud=Label.new(); hud.position=Vector2(125,64); hud.add_theme_font_size_override("font_size",25); ui.add_child(hud)
 distance_label=Label.new(); distance_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; distance_label.add_theme_font_size_override("font_size",48); ui.add_child(distance_label)
 shell_icon=TextureRect.new(); shell_icon.texture=AssetLib.texture("ui/icon_shell.png",Vector2(48,48)); shell_icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; shell_icon.size=Vector2(32,32); ui.add_child(shell_icon)
 pause_button=Button.new(); pause_button.text="Pause";  pause_button.expand_icon=true; pause_button.custom_minimum_size=Vector2(100,64); pause_button.pressed.connect(func() -> void: show_menu("pause")); ui.add_child(pause_button)
 hint=Label.new(); hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; hint.add_theme_font_size_override("font_size",22); ui.add_child(hint)
 ambient=AudioStreamPlayer.new(); ambient.stream=AssetLib.sound("amb_ocean"); ambient.volume_db=-16; add_child(ambient); ambient.finished.connect(func() -> void: ambient.play()); ambient.play()
 for arg: String in OS.get_cmdline_user_args():
  if arg.begins_with("--capture="): snap=arg.trim_prefix("--capture=")
 if OS.has_feature("web"):
  web_debug=str(JavaScriptBridge.eval("location.search")).contains("debug=1")
 show_menu("title")
 if snap=="shop": show_menu("shop")
 if snap=="pause": start(); show_menu("pause")
 if snap in ["riding","airborne","game_over","airborne_flip","airborne_grab","landing","game_over_daily"]:
  start()
  if snap=="game_over_daily": daily=true
  if snap=="riding": run.combo=3; save.data.tutorial_done=false
  if snap=="airborne": run.launch(true); run.air=1.1; run.spin=0.35
  if snap in ["game_over","game_over_daily"]: run.crash("A spectacular splash"); finish()
func audio(name_: String) -> void:
 if not save.data.sound: return
 var player: AudioStreamPlayer=AudioStreamPlayer.new(); player.stream=AssetLib.sound("sfx_"+name_); player.pitch_scale=1.0+0.05*(run.combo-1); add_child(player); player.finished.connect(player.queue_free); player.play()
func label_(text: String, size: int = 28) -> void:
 var l: Label=Label.new(); l.text=text; l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; l.add_theme_font_size_override("font_size",size); l.add_theme_color_override("font_color",Color("2b2b2b")); panel.add_child(l)
func button(text: String, action: Callable) -> void:
 var b: Button=Button.new(); b.text=text; b.custom_minimum_size=Vector2(420,60)
 var style: StyleBoxFlat=StyleBoxFlat.new(); style.bg_color=Color("aa4c2c") if text in ["Ride","Retry","Resume"] else Color("f4ebdd"); style.border_color=Color("1f6f8b"); style.set_border_width_all(2); style.shadow_color=Color(0.12,0.25,0.28,0.3); style.shadow_size=5; style.shadow_offset=Vector2(0,4); style.corner_radius_top_left=24; style.corner_radius_top_right=24; style.corner_radius_bottom_left=24; style.corner_radius_bottom_right=24; b.add_theme_stylebox_override("normal",style); b.add_theme_color_override("font_color",Color("f4ebdd") if text in ["Ride","Retry","Resume"] else Color("2b2b2b")); b.pressed.connect(func() -> void: audio("click"); action.call()); panel.add_child(b)
func clear_panel() -> void:
 for node: Node in panel.get_children(): panel.remove_child(node); node.queue_free()
func show_menu(which: String) -> void:
 restore_time(); clear_controls(); run.grab(false)
 state=which; clear_panel(); panel.show(); hud.hide(); hint.text=""
 if which=="title":
  label_("MELTEMI",64)
  label_("CHASE THE WIND",20); label_("Best  %s   ·   Shells  %s" % [save.data.best,save.data.shells],23); mission_labels(); button("Ride",func() -> void: daily=false; start()); button("Daily",daily_start); button("Kites",func() -> void: show_menu("shop")); button("Settings",func() -> void: show_menu("settings"))
 elif which=="pause" or which=="settings":
  label_("Catch your breath" if which=="pause" else "Make it yours",36)
  if which=="pause":
   button("Resume",resume); button("Restart",start)
  button("Sound: "+("On" if save.data.sound else "Off"),func() -> void: save.data.sound=not save.data.sound; save.write_save(); show_menu(which))
  button("Reduce motion: "+("On" if save.data.reduce_motion else "Off"),func() -> void: save.data.reduce_motion=not save.data.reduce_motion; save.write_save(); show_menu(which))
  button("Home",func() -> void: show_menu("title"))
 elif which=="over":
  label_("Beautiful wipeout",38); label_(run.reason,23); label_("%s" % run.score(),64); label_("NEW BEST!" if new_best else "Best  %s" % save.data.best,26); label_("+%s shells earned" % run.shells); button("Retry",start); button("Home",func() -> void: show_menu("title"))
  if daily:
   label_("Daily best today: %s" % save.data.daily_best.get(daily_date,0),22)
   button("Share",share_daily)
  for text: String in mission_gained.slice(0,2): label_(text,18)
  for id: int in save.data.missions.active:
   var gained: float=float(save.data.missions.progress.get(str(id),0))-float(mission_start.get(str(id),0))
   if gained>0: label_("%s +%s" % [Missions.POOL[id%Missions.POOL.size()][0],snappedf(gained,0.1)],17)
 elif which=="shop":
  label_("Your patch of sky",36); label_("%s shells · cosmetics only" % save.data.shells,23)
  var names: Array[String]=["sunset","seaglass","olive","lemon"]
  var costs: Array[int]=[0,50,150,300]
  for i in range(4):
   var name_: String=names[i]; var cost: int=costs[i]
   button(name_.capitalize()+ ("  ✓" if save.data.selected==name_ else "  ·  "+("Owned" if name_ in save.data.owned else str(cost)+" shells")),func() -> void: save.buy(name_,cost); show_menu("shop"))
  button("Home",func() -> void: show_menu("title"))
func start() -> void:
 mission_start=save.data.missions.progress.duplicate(true)
 restore_time(); clear_controls(); apex_done=false; popups.clear(); mission_gained.clear(); run_spins=0
 var date: Dictionary=Time.get_date_dict_from_system()
 daily_date=Missions.date_key(date); course_seed=Missions.daily_seed(date) if daily else 81273
 run=Model.new(); objects.clear(); chunk_index=0; next_chunk=0; wake.clear_points(); crash_timer=0; state="play"; panel.hide(); clear_panel(); hud.show();  spin_hint=false
 for entry: Array in [["wave",360.0, rider_y()-500],["shell",320.0,rider_y()-660],["shell",360.0,rider_y()-740],["buoy",500.0,rider_y()-850]]:
  objects.append({"kind":entry[0],"x":entry[1],"y":entry[2],"size":Chunks.SIZES[entry[0]],"move":false})
func resume() -> void:
 state="play"; clear_panel(); panel.hide(); hud.show()
func clear_controls() -> void:
 gameplay_touches.clear(); key_left=false; key_right=false; touch_id=-1; touch_air=false
 run.end_steering(false)
func anchor_touch(id: int, pos: Vector2, allow_trick: bool) -> void:
 touch_id=id; touch_origin=pos; touch_position=pos; touch_travel=0; touch_age=0; gesture_done=false
 touch_air=allow_trick and run.air>0
 run.begin_steering(pos.x)
func over_button(pos: Vector2) -> bool:
 if pause_button.visible and pause_button.get_global_rect().grow(8).has_point(pos): return true
 if panel.visible:
  for child: Node in panel.get_children():
   if child is Button and (child as Button).get_global_rect().has_point(pos): return true
 return false
## Ignore mouse compatibility events; desktop mouse is emulated as touch.
## Deduplicate by touch index, not time, so fast pulses/multitouch stay valid.
func _input(event: InputEvent) -> void:
 if event is InputEventScreenTouch and event.pressed: raw_touches+=1
 # Releases must clear gameplay holds even when the pointer ends over UI.
 if event is InputEventScreenTouch and not event.pressed and gameplay_touches.has(event.index):
  _unhandled_input(event); get_viewport().set_input_as_handled()
func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventScreenDrag and gameplay_touches.has(event.index):
  gameplay_touches[event.index]=event.position
  if event.index!=touch_id: return
  touch_position=event.position
  run.drag_to(event.position.x)
  touch_travel=maxf(touch_travel,touch_origin.distance_to(touch_position))
  var displacement: Vector2=touch_position-touch_origin
  if absf(displacement.x)>=15 and absf(displacement.x)>=1.5*absf(displacement.y):
   gesture_done=true; run.grab(false)
  if touch_air and not gesture_done and touch_age<=0.3 and displacement.y<=-55 and -displacement.y>=1.73*absf(displacement.x):
   run.grab(false); run.backflip(); gesture_done=true; audio("trick")
 elif event is InputEventScreenTouch:
  if event.pressed:
   if gameplay_touches.has(event.index) or over_button(event.position): return
   if state=="title": start()
   if state!="play": return
   gameplay_touches[event.index]=event.position; unhandled_touches+=1
   if touch_id<0: anchor_touch(event.index,event.position,true)
   get_viewport().set_input_as_handled()
  elif gameplay_touches.has(event.index):
   gameplay_touches.erase(event.index)
   if event.index==touch_id:
    if not event.canceled and run.air>0 and touch_air and not gesture_done and touch_age<=0.18 and maxf(touch_travel,touch_origin.distance_to(event.position))<=15: run.tap(); audio("trick")
    run.grab(false); touch_id=-1; touch_air=false; run.end_steering()
    if not gameplay_touches.is_empty():
     var next_id: int=int(gameplay_touches.keys()[0])
     anchor_touch(next_id,gameplay_touches[next_id],false)
 elif event is InputEventKey and not event.echo:
  if event.keycode in [KEY_LEFT,KEY_A]: key_left=event.pressed
  elif event.keycode in [KEY_RIGHT,KEY_D]: key_right=event.pressed
  elif event.keycode==KEY_SPACE and event.pressed:
   if state=="title": start()
   elif state=="play" and run.air>0: run.tap()
  elif event.pressed and event.keycode==KEY_ESCAPE and state=="play": show_menu("pause")
  if touch_id<0:
   if key_left or key_right:
    if not run.steering: run.begin_steering(0)
   else: run.end_steering()
func rider_y() -> float: return get_viewport_rect().size.y*0.68
func _notification(what: int) -> void:
 if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:
  clear_controls(); run.grab(false)
  if state=="play": show_menu("pause")
func _process(dt: float) -> void:
 var real_dt: float=dt/maxf(Engine.time_scale,0.01)
 clock+=dt
 turn_juice=maxf(0,turn_juice-dt); landing_juice=maxf(0,landing_juice-dt); flash=maxf(0,flash-real_dt); toast_time=maxf(0,toast_time-real_dt)
 for p: Dictionary in popups: p.age+=real_dt
 popups=popups.filter(func(p: Dictionary) -> bool: return p.age<1.1)
 if state=="play" and run.air>0 and touch_id>=0 and touch_air:
  touch_age+=real_dt
  if touch_age>=0.35 and touch_travel<=15 and not gesture_done:
   run.grab(true); gesture_done=true
 if slow_age>=0:
  slow_age+=real_dt
  Engine.time_scale=lerpf(0.55,1.0,clampf((slow_age-0.15)/0.15,0,1))
  if slow_age>=0.3: restore_time()
 if state!="play" or save.data.reduce_motion: restore_time()
 ambient.stream_paused=not save.data.sound
 var height: float=get_viewport_rect().size.y
 var safe: Rect2i=DisplayServer.get_display_safe_area()
 safe_top=maxf(64,float(safe.position.y)*720.0/maxf(1,DisplayServer.screen_get_size().x)) if not OS.has_feature("headless") else 64
 pause_button.visible=state=="play"; pause_button.position=Vector2(554,safe_top+36); pause_button.size=Vector2(110,64)
 distance_label.visible=state=="play"; distance_label.position=Vector2(210,safe_top+32); distance_label.size=Vector2(300,64); distance_label.text="%d m" % int(run.distance)
 shell_icon.visible=state=="play"; shell_icon.position=Vector2(32,safe_top+90)
 hud.position=Vector2(72,safe_top+88); hint.position=Vector2(24,height-125); hint.size=Vector2(672,60)
 if state=="play":
  panel.position=Vector2(24,safe_top); panel.size=Vector2(76,70)
  for child: Node in panel.get_children():
   if child is Button: child.custom_minimum_size=Vector2(76,70)
  var before_air: float=run.air
  var before_distance: float=run.distance
  if touch_id<0 and (key_left or key_right):
   run.target_x=clampf(run.target_x+(float(key_right)-float(key_left))*Model.KEYBOARD_SPEED*dt,Model.SHORE-Model.TARGET_MARGIN,720-Model.SHORE+Model.TARGET_MARGIN)
  run.tick(dt)
  var scroll: float=(run.distance-before_distance)*10
  next_chunk-=scroll
  if next_chunk<=0:
   var chunk: Dictionary=maker.chunk(course_seed,chunk_index)
   for obj: Dictionary in chunk.objects:
    obj.y+=next_chunk-120; objects.append(obj)
   next_chunk+=1280; chunk_index+=1
  for obj: Dictionary in objects:
   var old_y: float=float(obj.y)
   obj.y+=scroll
   if run.air<=0 and obj.kind not in ["shell","starfish","gust","wave","wave_gold"] and old_y<rider_y() and float(obj.y)>=rider_y():
    var dx: float=absf(float(obj.x)-run.x)
    if dx>float(obj.size.x)*0.5+20 and dx<float(obj.size.x)*0.5+50 and not obj.get("near",false):
     obj.near=true
     if run.near_miss(int(obj.get("id",obj.hash()))): popup("CLOSE! +25")
   if obj.move:
    obj.x=float(obj.base)+sin(clock*0.9+float(obj.phase))*18.0
   var radius: Vector2=obj.size*0.5+Vector2(20,20)
   if absf(float(obj.x)-run.x)<radius.x and absf(float(obj.y)-rider_y())<radius.y and not obj.get("used",false):
    var kind: String=obj.kind
    if run.air>0 and kind not in ["shell","starfish","gust"]: continue
    obj.used=true; run.collide(kind)
    if kind in ["shell","starfish"]: audio("shell")
    elif kind=="gust": audio("gust")
  objects=objects.filter(func(o: Dictionary) -> bool: return float(o.y)<height+200 and not o.get("used",false))
  if before_air<=0 and run.air>0:
   apex_done=false
   if run.golden and not save.data.reduce_motion: flash=0.12
   if int(save.data.hints)<3:
    toast=["Tap in the air to spin!","Swipe up for a backflip!","Hold for a grab - let go before you land!"][int(save.data.hints)]; toast_time=4; save.data.hints=int(save.data.hints)+1; save.write_save()
  if run.golden and run.air>0 and run.air<run.air_total*0.5 and not apex_done and not save.data.reduce_motion:
   apex_done=true; slow_age=0; Engine.time_scale=0.55
  if before_air<=0 and run.air>0: audio("jump"); spin_hint=true; spray.position=rider.position; spray.restart(); spray.emitting=true
  if run.landed:
   touch_air=false; run.grab(false)
   if touch_id>=0: anchor_touch(touch_id,touch_position,false)
   landing_juice=0.3
   Input.vibrate_handheld(80 if run.dead else (35 if run.perfect else 20))
   if not run.dead:
    popup("PERFECT" if run.perfect else "+%d" % (100*run.spins+250*run.flips))
    if run.grab_time>=0.25: popup("GRAB +%d" % (60*int(run.grab_time/0.25)))
   audio("land_bad" if run.dead else "land_clean"); spray.position=rider.position; spray.restart(); spray.emitting=true
   if not run.dead and run.spins>0: save.data.tutorial_done=true; save.write_save()
  for i in range(wake.get_point_count()): wake.set_point_position(i,wake.get_point_position(i)+Vector2(0,scroll))
  if run.air<=0: wake.add_point(Vector2(run.x,rider_y()+25))
  while wake.get_point_count()>15: wake.remove_point(0)
  hud.text="%s    ·    %s pts%s" % [run.shells,run.trick_points+run.shells*10,("    x%s" % run.combo) if run.combo>1 else ""]
  hint.text=("Tap in the air to spin!" if spin_hint else "Drag to steer · lift to keep your line") if not save.data.tutorial_done else ("SHALLOWS — TURN!" if run.x<132 or run.x>588 else "")
  run_spins+=float(run.events.get("spins",0))
  run.events.distance=run.distance; run.events.run_spins=run_spins; run.events.run_shells=run.shells
  var completed: Array=Missions.update(save.data,run.events)
  run.events.clear()
  if not completed.is_empty():
   for done: Dictionary in completed:
    toast="Mission complete! +%d shells" % done.reward; toast_time=3; mission_gained.append(done.title+" ✓")
   save.write_save()
  if run.grabbing: hint.text="GRAB — release before landing"
  elif run.flip>0: hint.text="BACKFLIP"
  if run.dead: restore_time(); state="crash"; crash_timer=0; audio("splash"); Input.vibrate_handheld(80)
 elif state=="crash":
  crash_timer+=dt
  if crash_timer>0.6: finish()
 else:
  panel.position=Vector2(150,maxf(safe_top+24,height*0.08)); panel.size=Vector2(420,0)
 var air_height: float=sin(PI*run.air/maxf(run.air_total,0.01)) if run.air>0 else 0
 if snap in ["airborne","airborne_flip","airborne_grab"]:
  run.air=run.air_total*0.5; run.spin=0.3; air_height=1; spin_hint=true; hint.text="Tap in the air to spin!"
 if snap=="airborne_flip": run.flip=0.35; run.spin=0; hint.text="BACKFLIP"
 if snap=="airborne_grab": run.grabbing=true; run.spin=0; hint.text="GRAB — release before landing"
 if snap=="landing": landing_juice=0.23; run.perfect=true; popup("PERFECT") if popups.is_empty() else null
 var zoom_: float=1.0-0.035*air_height if not save.data.reduce_motion else 1.0
 var center_: Vector2=Vector2(360,height*0.5)
 var shake_: Vector2=Vector2(sin(clock*93),cos(clock*77))*5 if state=="crash" and not save.data.reduce_motion else Vector2.ZERO
 get_viewport().canvas_transform=Transform2D(Vector2(zoom_,0),Vector2(0,zoom_),center_*(1-zoom_)+shake_)
 var scale_: float=1+air_height*0.6 if not save.data.reduce_motion else 1
 var pos: Vector2=Vector2(run.x,rider_y()) if state in ["play","crash"] else Vector2(360,height*0.88)
 rider.position=pos+Vector2(0,-air_height*60); rider.scale=Vector2.ONE*scale_*1.5; rider.rotation=run.visual_heading+(run.spin*TAU if run.air>0 else 0)
 rider.texture=AssetLib.texture("sprites/rider_wipeout.png" if run.dead else "sprites/rider.png",Vector2(72,72))
 kite.texture=AssetLib.texture("sprites/kite_"+str(save.data.selected)+".png",Vector2(140,70)); kite.position=kite.position.lerp(pos+Vector2(sin(run.heading)*170,-190-air_height*90),minf(dt/0.35,1)); kite.scale=Vector2.ONE*scale_*1.2; kite.rotation=-run.heading*0.25
 shadow.position=pos+LIGHT_OFFSET*(1+air_height*2); shadow.scale=Vector2(0.65,0.65)*(1-air_height*0.35); shadow.color.a=0.13-air_height*0.04
 for i in range(2): lines[i].points=PackedVector2Array([rider.to_global(Vector2(-1+i*24,-19)),kite.position+Vector2((i*2-1)*62,23).rotated(kite.rotation)*scale_*1.2])
 queue_redraw()
 if web_debug:
  JavaScriptBridge.eval("window.__meltemi=%s" % JSON.stringify({"state":state,"tack":run.tack,"held":run.held,"steering":run.steering,"target_x":run.target_x,"heading":snappedf(run.heading,0.001),"x":snappedf(run.x,0.1),"raw":raw_touches,"unhandled":unhandled_touches,"actions":actions,"dead":run.dead,"trick":("flip" if run.flip>0 else "spin" if run.spin>0 else "none"),"grab":run.grabbing,"missions":save.data.missions}))
 if snap!="" and not capture_done:
  snap_frames+=1
  if snap_frames==8: capture()
func finish() -> void:
 restore_time()
 if daily: save.data.daily_best[daily_date]=maxi(run.score(),int(save.data.daily_best.get(daily_date,0)))
 new_best=run.score()>int(save.data.best); save.data.best=maxi(run.score(),int(save.data.best)); save.data.shells=int(save.data.shells)+run.shells; save.write_save(); show_menu("over")
 if new_best: audio("newbest")
func capture() -> void:
 capture_done=true
 await RenderingServer.frame_post_draw
 var image: Image=get_viewport().get_texture().get_image()
 DirAccess.make_dir_recursive_absolute("res://../build/qa")
 var error: Error=image.save_png("res://../build/qa/"+snap+".png")
 print("CAPTURE ",snap," ",error)
 ambient.stop(); ambient.stream=null
 await get_tree().create_timer(0.1).timeout
 get_tree().quit()
func _draw() -> void:
 var height: float=get_viewport_rect().size.y
 var zone: int=int(run.distance/1000)%4
 var colors: Array[Color]=[Color("4fb3bf"),Color("398f9f"),Color("1f6f8b"),Color("ac8585")]
 draw_rect(Rect2(-80,-80,880,height+160),colors[zone])
 for i in range(32):
  var yy: float=fposmod(float(i)*67+run.distance*10+clock*8,height)
  var xx: float=150+fposmod(float(i)*137,430)
  draw_arc(Vector2(xx,yy),35,0.2,2.4,12,Color(0.9,1,1,0.10),2,true)
 draw_rect(Rect2(0,0,94,height),Color("e8d3a8")); draw_rect(Rect2(626,0,94,height),Color("e8d3a8"))
 draw_rect(Rect2(94,0,36,height),Color(0.9,0.85,0.63,0.28)); draw_rect(Rect2(590,0,36,height),Color(0.9,0.85,0.63,0.28))
 for side in range(2):
  var shore: Texture2D=AssetLib.texture("sprites/scenery/shore_"+("left" if side==0 else "right")+".png",Vector2(160,512))
  for j in range(int(height/512)+2): draw_texture_rect(shore,Rect2(side*650-45,float(j)*512+fposmod(run.distance*10,512)-512,115,512),false)
  for j in range(5):
   var scenery: String=["olive_tree","umbrella","house_terracotta","olive_tree","umbrella"][(j+side*2)%5]
   if zone==1 and j%2==0: scenery="pier"
   var tex: Texture2D=AssetLib.texture("sprites/scenery/"+scenery+".png",Vector2(80,80))
   draw_texture_rect(tex,Rect2(10+side*640,fposmod(j*320+side*147+(j*73+side*41)%110+run.distance*10,height+240)-120,60,75),false)
 if is_instance_valid(kite) and kite.texture!=null:
  draw_set_transform(kite.position+LIGHT_OFFSET,kite.rotation,kite.scale*0.36)
  draw_texture_rect(kite.texture,Rect2(-70,-35,140,70),false,Color(0.08,0.27,0.32,0.045))
  draw_set_transform(Vector2.ZERO)
 if state in ["play","crash"]:
  if not run.dead:
   # Projected course sits ahead of the board; wake stays behind it.
   var course: Vector2=Vector2(sin(run.heading),-cos(run.heading))
   var origin: Vector2=Vector2(run.x,rider_y())+course*48
   var tip: Vector2=origin+course*76
   var foam: Color=Color(1,1,1,0.42*(1.0-0.85*minf(run.air*5,1)))
   draw_line(origin,tip,foam,2.5,true)
   draw_line(tip,tip-course.rotated(0.55)*12,foam,2.5,true)
   draw_line(tip,tip-course.rotated(-0.55)*12,foam,2.5,true)
  if run.air<=0 and not run.dead:
   var heel: Vector2=Vector2(run.x,rider_y())
   for j in range(5):
    var fade_: float=1.0-float(j)/5
    var tip_: Vector2=heel+Vector2(-14-j*5,18+j*10).rotated(run.heading)
    draw_circle(tip_,4+float(j),Color(1,1,1,fade_*0.52))
    draw_line(tip_,tip_+Vector2(-9,8).rotated(run.heading),Color(1,1,1,fade_*0.6),2,true)
  for obj: Dictionary in objects:
   var size_: Vector2=obj.size
   var pickup: bool=obj.kind in ["shell","starfish","gust"]
   var center: Vector2=Vector2(obj.x,obj.y)
   var tex_: Texture2D=AssetLib.texture("sprites/"+str(obj.kind)+".png",size_)
   var bob: float=sin(clock*3+float(obj.x))*5 if pickup else 0
   if pickup:
    draw_circle(center+Vector2(0,bob),size_.x*0.65,Color(0.96,0.92,0.70,0.14))
    draw_line(Vector2(obj.x+20,obj.y+bob-10),Vector2(obj.x+20,obj.y+bob-22),Color(1,1,1,0.8),2)
    draw_line(Vector2(obj.x+14,obj.y+bob-16),Vector2(obj.x+26,obj.y+bob-16),Color(1,1,1,0.8),2)
   elif obj.kind not in ["wave","wave_gold"]:
    # Shared alpha silhouettes: sunlight from upper left, no collision-ring decals.
    draw_texture_rect(tex_,Rect2(center-size_/2+LIGHT_OFFSET,size_),false,Color(0.09,0.27,0.31,0.18))
    draw_texture_rect(tex_,Rect2(center-size_/2+LIGHT_OFFSET*1.6,size_),false,Color(0.09,0.27,0.31,0.08))
    var pulse: float=sin(clock*2+float(obj.x))*2
    if obj.kind in ["rock_small","rock_big","buoy","turtle"]:
     draw_set_transform(center,0,Vector2(1,0.62))
     draw_arc(Vector2(0,size_.y*0.23),size_.x*0.56+pulse,0.05,2.8,16,Color(1,1,1,0.78),2,true)
     draw_arc(Vector2(0,size_.y*0.23),size_.x*0.51+pulse,2.0,3.5,10,Color(0.91,1,0.97,0.38),1.5,true)
     draw_set_transform(Vector2.ZERO)
    if obj.kind in ["boat_fishing","sailboat","jetski"]:
     draw_arc(center+Vector2(0,-size_.y*0.28),size_.x*0.48,3.45,5.98,16,Color(1,1,1,0.7),2.5,true)
     for side_: int in [-1,1]:
      draw_line(center+Vector2(side_*size_.x*0.3,size_.y*0.36),center+Vector2(side_*size_.x*0.65,size_.y*0.5+22+pulse),Color(1,1,1,0.30),5,true)
      draw_line(center+Vector2(side_*size_.x*0.3,size_.y*0.36),center+Vector2(side_*size_.x*0.65,size_.y*0.5+22+pulse),Color(1,1,1,0.6),1.5,true)
   draw_texture_rect(tex_,Rect2(center+Vector2(0,bob)-size_/2,size_),false)
 if state not in ["play","crash"]:
  draw_rect(Rect2(115,maxf(safe_top,height*0.065),490,panel.size.y+45),Color("f4ebdd"))

 if state=="play" and not save.data.reduce_motion:
  if run.combo>=3 or run.gust>0:
   for i in range(16):
    var pos_: Vector2=Vector2(140+fposmod(i*137,440),fposmod(i*97+clock*850,height))
    draw_line(pos_,pos_+Vector2(0,45),Color(1,1,1,0.35),1.5,true)
  if landing_juice>0:
   draw_arc(Vector2(run.x,rider_y()),(0.3-landing_juice)*240,0,TAU,40,Color(1,1,1,landing_juice*3),3,true)
  if turn_juice>0: draw_arc(Vector2(run.x,rider_y()+20),35+(0.22-turn_juice)*100,0.2,2.9,20,Color(1,1,1,turn_juice*3),3,true)
  if run.grabbing or run.perfect and landing_juice>0:
   for i in range(6):
    var pt: Vector2=rider.position+Vector2(cos(i*TAU/6+clock)*65,sin(i*TAU/6+clock)*65)
    draw_line(pt-Vector2(4,0),pt+Vector2(4,0),Color.WHITE,2); draw_line(pt-Vector2(0,4),pt+Vector2(0,4),Color.WHITE,2)
 if flash>0 and not save.data.reduce_motion: draw_rect(Rect2(0,0,720,height),Color(0.96,0.92,0.86,flash*1.5))
 var font: Font=ThemeDB.fallback_font
 for p: Dictionary in popups:
  draw_string_outline(font,p.pos+Vector2(-60,-float(p.age)*65),p.text,HORIZONTAL_ALIGNMENT_LEFT,-1,28,4,Color(0.12,0.3,0.35,1-float(p.age)/1.1))
  draw_string(font,p.pos+Vector2(-60,-float(p.age)*65),p.text,HORIZONTAL_ALIGNMENT_LEFT,-1,28,Color(1,1,1,1-float(p.age)/1.1))
 if toast_time>0: draw_string(font,Vector2(130,safe_top+180),toast,HORIZONTAL_ALIGNMENT_LEFT,470,22,Color.WHITE)
