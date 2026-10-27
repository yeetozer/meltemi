# Editor-only in-engine portrait evidence, no exported entry point.
extends SceneTree
var game: Node
var frame: int=0
var recording: bool=false
var directory: String="res://../art/qa/carve-v1/"
func _initialize() -> void: call_deferred("setup")
func setup() -> void:
 if not OS.has_feature("editor"): quit(1); return
 root.content_scale_size=Vector2i(720,1561)
 root.size=Vector2i(1179,2556)
 recording="--record-carve" in OS.get_cmdline_user_args()
 game=load("res://scripts/main.gd").new(); root.add_child(game)
 game.save.data=game.save.defaults(); game.save.data.best=1240
 game.show_menu("title"); game.set_process(false)
 DirAccess.make_dir_recursive_absolute(directory)
 if recording:
  game.start(); game.run.begin_steering(360)
  return
 await process_frame
 game._process(0)
 await save_frame("menu.png")
 game.start(); game.state="pause"
 for amount: float in [-1.0,-0.5,0.0,0.5,1.0]:
  game.run.lateral_velocity=signf(amount)*(20+298*absf(amount))
  game.run.visual_heading=amount*0.42
  game.rider_visual.solve(amount)
  for tick: int in range(60): game._process(1.0/60)
  # Snap the kite follow to the actual gameplay position for deterministic stills.
  game.save.data.reduce_motion=true
  game.state="play"; game._process(0)
  game.save.data.reduce_motion=false; game.state="pause"
  var tag: String="left_carve" if amount==-1 else ("right_carve" if amount==1 else "straight")
  if amount in [-1.0,0.0,1.0]: await save_frame("gameplay_"+tag+".png")
  await save_frame("transition_"+str(amount)+".png")
 quit()
func _process(_dt: float) -> bool:
 if not recording or not is_instance_valid(game): return false
 frame+=1
 game.run.drag_to(360+90*sin(float(frame)/30.0*TAU/3.0))
 game._process(1.0/30)
 if game.run.dead: push_error("Evidence run crashed: "+game.run.reason); quit(1)
 if frame>=600: quit()
 return false
func save_frame(filename: String) -> void:
 await RenderingServer.frame_post_draw
 var image: Image=root.get_texture().get_image()
 assert(image.get_size()==Vector2i(1179,2556))
 assert(image.save_png(directory+filename)==OK)
 print("CARVE CAPTURE ",filename)
