extends Node2D
const Model = preload("res://scripts/run_model.gd")
const Chunks = preload("res://scripts/chunks.gd")
const Saves = preload("res://scripts/save_store.gd")
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
func _exit_tree() -> void:
 if is_instance_valid(ambient):
  ambient.stop()
  ambient.stream=null
func _ready() -> void:
 Engine.max_fps = 60
 save.read_save()
 var theme_: Theme = Theme.new()
 var fonts: DirAccess = DirAccess.open("res://assets/fonts")
 if fonts:
  for file: String in fonts.get_files():
   if file.ends_with(".ttf"): theme_.default_font = load("res://assets/fonts/"+file); break
 theme_.default_font_size = 26
 world = Node2D.new(); add_child(world)
 wake = Line2D.new(); wake.width = 7; wake.default_color = Color(1,1,1,0.45); world.add_child(wake)
 var gradient_: Gradient = Gradient.new(); gradient_.set_color(0,Color(1,1,1,0)); gradient_.set_color(1,Color(1,1,1,0.6)); wake.gradient = gradient_
 shadow = Polygon2D.new()
 var oval: PackedVector2Array = PackedVector2Array()
 for j in range(24): oval.append(Vector2(cos(float(j)*TAU/24)*25,sin(float(j)*TAU/24)*36))
 shadow.polygon=oval; shadow.color=Color(0.169,0.169,0.169,0.25); world.add_child(shadow)
 for i in range(2):
  var line: Line2D = Line2D.new(); line.width=1.5; line.default_color=Color(0.15,0.25,0.25,0.7); world.add_child(line); lines.append(line)
 rider = Sprite2D.new(); rider.texture=AssetLib.texture("sprites/rider.png",Vector2(72,72)); world.add_child(rider)
 kite = Sprite2D.new(); kite.position=Vector2(470,790); world.add_child(kite)
 spray=CPUParticles2D.new(); spray.amount=22; spray.lifetime=0.4; spray.one_shot=true; spray.explosiveness=0.9; spray.direction=Vector2(0,1); spray.spread=65; spray.initial_velocity_min=70; spray.initial_velocity_max=160; spray.gravity=Vector2(0,80); spray.scale_amount_min=2; spray.scale_amount_max=5; spray.emitting=false; world.add_child(spray)
 var canvas: CanvasLayer = CanvasLayer.new(); add_child(canvas)
 ui=Control.new(); ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); ui.mouse_filter=Control.MOUSE_FILTER_IGNORE; ui.theme=theme_; canvas.layer=10; canvas.add_child(ui)
 panel=VBoxContainer.new(); panel.add_theme_constant_override("separation",18); ui.add_child(panel)
 hud=Label.new(); hud.position=Vector2(125,64); hud.add_theme_font_size_override("font_size",25); ui.add_child(hud)
 distance_label=Label.new(); distance_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; distance_label.add_theme_font_size_override("font_size",48); ui.add_child(distance_label)
 shell_icon=TextureRect.new(); shell_icon.texture=AssetLib.texture("ui/icon_shell.png",Vector2(48,48)); shell_icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; shell_icon.size=Vector2(32,32); ui.add_child(shell_icon)
 pause_button=Button.new(); pause_button.icon=AssetLib.texture("ui/icon_pause.png",Vector2(64,64)); pause_button.expand_icon=true; pause_button.custom_minimum_size=Vector2(64,64); pause_button.pressed.connect(func() -> void: show_menu("pause")); ui.add_child(pause_button)
 hint=Label.new(); hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; hint.add_theme_font_size_override("font_size",24); ui.add_child(hint)
 ambient=AudioStreamPlayer.new(); ambient.stream=AssetLib.sound("amb_ocean"); ambient.volume_db=-16; add_child(ambient); ambient.finished.connect(func() -> void: ambient.play()); ambient.play()
 for arg: String in OS.get_cmdline_user_args():
  if arg.begins_with("--capture="): snap=arg.trim_prefix("--capture=")
 show_menu("title")
 if snap=="shop": show_menu("shop")
 if snap=="pause": start(); show_menu("pause")
 if snap in ["riding","airborne","game_over"]:
  start()
  if snap=="airborne": run.launch(true); run.air=1.1; run.spin=0.35
  if snap=="game_over": run.crash("A spectacular splash"); finish()
func audio(name_: String) -> void:
 if not save.data.sound: return
 var player: AudioStreamPlayer=AudioStreamPlayer.new(); player.stream=AssetLib.sound("sfx_"+name_); add_child(player); player.finished.connect(player.queue_free); player.play()
func label_(text: String, size: int = 28) -> void:
 var l: Label=Label.new(); l.text=text; l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; l.add_theme_font_size_override("font_size",size); l.add_theme_color_override("font_color",Color("2b2b2b")); panel.add_child(l)
func button(text: String, action: Callable) -> void:
 var b: Button=Button.new(); b.text=text; b.custom_minimum_size=Vector2(420,72)
 var style: StyleBoxFlat=StyleBoxFlat.new(); style.bg_color=Color("aa4c2c") if text in ["Ride","Retry","Resume"] else Color("f4ebdd"); style.border_color=Color("1f6f8b"); style.set_border_width_all(2); style.shadow_color=Color(0.12,0.25,0.28,0.3); style.shadow_size=5; style.shadow_offset=Vector2(0,4); style.corner_radius_top_left=24; style.corner_radius_top_right=24; style.corner_radius_bottom_left=24; style.corner_radius_bottom_right=24; b.add_theme_stylebox_override("normal",style); b.add_theme_color_override("font_color",Color("f4ebdd") if text in ["Ride","Retry","Resume"] else Color("2b2b2b")); b.pressed.connect(func() -> void: audio("click"); action.call()); panel.add_child(b)
func clear_panel() -> void:
 for node: Node in panel.get_children(): panel.remove_child(node); node.queue_free()
func show_menu(which: String) -> void:
 state=which; clear_panel(); panel.show(); hud.hide(); hint.text=""
 if which=="title":
  label_("MELTEMI",64)
  label_("CHASE THE WIND",20); label_("Best  %s   ·   Shells  %s" % [save.data.best,save.data.shells],23); button("Ride",start); button("Kites",func() -> void: show_menu("shop")); button("Settings",func() -> void: show_menu("settings"))
 elif which=="pause" or which=="settings":
  label_("Catch your breath" if which=="pause" else "Make it yours",36)
  if which=="pause":
   button("Resume",resume); button("Restart",start)
  button("Sound: "+("On" if save.data.sound else "Off"),func() -> void: save.data.sound=not save.data.sound; save.write_save(); show_menu(which))
  button("Reduce motion: "+("On" if save.data.reduce_motion else "Off"),func() -> void: save.data.reduce_motion=not save.data.reduce_motion; save.write_save(); show_menu(which))
  button("Home",func() -> void: show_menu("title"))
 elif which=="over":
  label_("Beautiful wipeout",38); label_(run.reason,23); label_("%s" % run.score(),64); label_("NEW BEST!" if new_best else "Best  %s" % save.data.best,26); label_("+%s shells earned" % run.shells); button("Retry",start); button("Home",func() -> void: show_menu("title"))
 elif which=="shop":
  label_("Your patch of sky",36); label_("%s shells · cosmetics only" % save.data.shells,23)
  var names: Array[String]=["sunset","seaglass","olive","lemon"]
  var costs: Array[int]=[0,50,150,300]
  for i in range(4):
   var name_: String=names[i]; var cost: int=costs[i]
   button(name_.capitalize()+ ("  ✓" if save.data.selected==name_ else "  ·  "+("Owned" if name_ in save.data.owned else str(cost)+" shells")),func() -> void: save.buy(name_,cost); show_menu("shop"))
  button("Home",func() -> void: show_menu("title"))
func start() -> void:
 run=Model.new(); objects.clear(); chunk_index=0; next_chunk=0; wake.clear_points(); crash_timer=0; state="play"; panel.hide(); clear_panel(); hud.show();  spin_hint=false
 for entry: Array in [["wave",360.0, rider_y()-500],["shell",320.0,rider_y()-660],["shell",360.0,rider_y()-740],["buoy",500.0,rider_y()-850]]:
  objects.append({"kind":entry[0],"x":entry[1],"y":entry[2],"size":Chunks.SIZES[entry[0]],"move":false})
func resume() -> void:
 state="play"; clear_panel(); panel.hide(); hud.show()
func action() -> void:
 if state=="title": start(); return
 if state!="play": return
 var airborne: bool=run.air>0
 run.tap(); audio("trick" if airborne else "tack")
 if not airborne: spray.position=Vector2(run.x,rider_y()); spray.restart(); spray.emitting=true
 Input.vibrate_handheld(12)
func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventScreenTouch and event.pressed: action()
 elif event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and not Input.emulate_touch_from_mouse: action()
 elif event is InputEventKey and event.pressed:
  if event.keycode==KEY_SPACE: action()
  elif event.keycode==KEY_ESCAPE and state=="play": show_menu("pause")
func rider_y() -> float: return get_viewport_rect().size.y*0.68
func _notification(what: int) -> void:
 if what==NOTIFICATION_APPLICATION_FOCUS_OUT and state=="play": show_menu("pause")
func _process(dt: float) -> void:
 clock+=dt
 ambient.stream_paused=not save.data.sound
 var height: float=get_viewport_rect().size.y
 var safe: Rect2i=DisplayServer.get_display_safe_area()
 safe_top=maxf(64,float(safe.position.y)*720.0/maxf(1,DisplayServer.screen_get_size().x)) if not OS.has_feature("headless") else 64
 pause_button.visible=state=="play"; pause_button.position=Vector2(616,safe_top+36); pause_button.size=Vector2(64,64)
 distance_label.visible=state=="play"; distance_label.position=Vector2(210,safe_top+32); distance_label.size=Vector2(300,64); distance_label.text="%d m" % int(run.distance)
 shell_icon.visible=state=="play"; shell_icon.position=Vector2(32,safe_top+90)
 hud.position=Vector2(72,safe_top+88); hint.position=Vector2(105,height-125); hint.size=Vector2(510,60)
 if state=="play":
  panel.position=Vector2(24,safe_top); panel.size=Vector2(76,70)
  for child: Node in panel.get_children():
   if child is Button: child.custom_minimum_size=Vector2(76,70)
  var before_air: float=run.air
  var before_distance: float=run.distance
  run.tick(dt)
  var scroll: float=(run.distance-before_distance)*10
  next_chunk-=scroll
  if next_chunk<=0:
   var chunk: Dictionary=maker.chunk(81273,chunk_index)
   for obj: Dictionary in chunk.objects:
    obj.y+=next_chunk-120; objects.append(obj)
   next_chunk+=1280; chunk_index+=1
  for obj: Dictionary in objects:
   obj.y+=scroll
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
  if before_air<=0 and run.air>0: audio("jump"); spin_hint=true; spray.position=rider.position; spray.restart(); spray.emitting=true
  if run.landed:
   audio("land_bad" if run.dead else "land_clean"); spray.position=rider.position; spray.restart(); spray.emitting=true
   if not run.dead and run.spins>0: save.data.tutorial_done=true; save.write_save()
  for i in range(wake.get_point_count()): wake.set_point_position(i,wake.get_point_position(i)+Vector2(0,scroll))
  if run.air<=0: wake.add_point(Vector2(run.x,rider_y()+25))
  while wake.get_point_count()>55: wake.remove_point(0)
  hud.text="%s    ·    %s pts%s" % [run.shells,run.trick_points+run.shells*10,("    x%s" % run.combo) if run.combo>1 else ""]
  hint.text=("Tap in the air to spin!" if spin_hint else "Tap to switch direction") if not save.data.tutorial_done else ("SHALLOWS — TURN!" if run.x<132 or run.x>588 else "")
  if run.dead: state="crash"; crash_timer=0; audio("splash"); Input.vibrate_handheld(80)
 elif state=="crash":
  crash_timer+=dt
  if crash_timer>0.6: finish()
 else:
  panel.position=Vector2(150,height*0.13); panel.size=Vector2(420,0)
 var air_height: float=sin(PI*run.air/maxf(run.air_total,0.01)) if run.air>0 else 0
 if snap=="airborne":
  run.air=run.air_total*0.5; run.spin=0.3; air_height=1; spin_hint=true; hint.text="Tap in the air to spin!"
 var zoom_: float=1.0-0.035*air_height if not save.data.reduce_motion else 1.0
 var center_: Vector2=Vector2(360,height*0.5)
 var shake_: Vector2=Vector2(sin(clock*93),cos(clock*77))*5 if state=="crash" and not save.data.reduce_motion else Vector2.ZERO
 get_viewport().canvas_transform=Transform2D(Vector2(zoom_,0),Vector2(0,zoom_),center_*(1-zoom_)+shake_)
 var scale_: float=1+air_height*0.6 if not save.data.reduce_motion else 1
 var pos: Vector2=Vector2(run.x,rider_y()) if state in ["play","crash"] else Vector2(360,height*0.88)
 rider.position=pos+Vector2(0,-air_height*60); rider.scale=Vector2.ONE*scale_*1.5; rider.rotation=run.heading+(run.spin*TAU if run.air>0 else 0)
 rider.texture=AssetLib.texture("sprites/rider_wipeout.png" if run.dead else "sprites/rider.png",Vector2(72,72))
 kite.texture=AssetLib.texture("sprites/kite_"+str(save.data.selected)+".png",Vector2(140,70)); kite.position=kite.position.lerp(pos+Vector2(sin(run.heading)*170,-190-air_height*90),minf(dt/0.35,1)); kite.scale=Vector2.ONE*scale_*1.2; kite.rotation=-run.heading*0.25
 shadow.position=pos+Vector2(air_height*35,air_height*35); shadow.scale=Vector2.ONE*(1-air_height*0.35); shadow.color.a=0.25-air_height*0.12
 for i in range(2): lines[i].points=PackedVector2Array([rider.position+Vector2((i*2-1)*13,-10),kite.position+Vector2((i*2-1)*55,15).rotated(kite.rotation)*scale_*1.2])
 queue_redraw()
 if snap!="" and not capture_done:
  snap_frames+=1
  if snap_frames==8: capture()
func finish() -> void:
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
 if state in ["play","crash"]:
  for obj: Dictionary in objects:
   var size_: Vector2=obj.size
   var pickup: bool=obj.kind in ["shell","starfish"]
   var bob: float=sin(clock*3+float(obj.x))*5 if pickup else 0
   if pickup:
    draw_line(Vector2(obj.x+20,obj.y+bob-10),Vector2(obj.x+20,obj.y+bob-22),Color(1,1,1,0.8),2)
    draw_line(Vector2(obj.x+14,obj.y+bob-16),Vector2(obj.x+26,obj.y+bob-16),Color(1,1,1,0.8),2)
   elif obj.kind not in ["wave","wave_gold","gust"]: draw_arc(Vector2(obj.x,obj.y),size_.x*0.58,0,TAU,32,Color(0.12,0.44,0.55,0.6),2,true)
   draw_texture_rect(AssetLib.texture("sprites/"+str(obj.kind)+".png",size_),Rect2(Vector2(obj.x,obj.y+bob)-size_/2,size_),false)
 if state not in ["play","crash"]:
  draw_rect(Rect2(115,height*0.10,490,650),Color("f4ebdd"))
