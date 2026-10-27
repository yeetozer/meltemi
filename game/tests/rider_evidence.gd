# Editor-only reproducible visual evidence; never reachable from an exported game.
extends SceneTree
var game: Node
var count: int=0
var mode: String="menu"
var rigs: Array[Node2D]=[]
var min_carve: float=1.0
var max_carve: float=0.0
var saw_left: bool=false
var saw_right: bool=false
func _initialize() -> void: call_deferred("setup")
func setup() -> void:
 if not OS.has_feature("editor"): quit(1); return
 root.content_scale_size=Vector2i(720,1562); root.size=Vector2i(720,1562)
 for arg: String in OS.get_cmdline_user_args():
  if arg.begins_with("--qa-mode="): mode=arg.trim_prefix("--qa-mode=")
 if mode=="skins":
  var bg: ColorRect=ColorRect.new(); bg.color=Color("4fb3bf"); bg.size=Vector2(720,1561); root.add_child(bg)
  var index: int=0
  for c: String in ["navy","terra"]:
   for b: String in ["classic","seaglass"]:
    var rig: Node2D=load("res://scripts/rider_visual.gd").new(); root.add_child(rig); rig.set_skins(b,c); rig.position=Vector2(190+(index%2)*340,570+(index/2)*570); rig.scale=Vector2.ONE*5; rigs.append(rig)
    var label: Label=Label.new(); label.text=b+" / "+c; label.position=rig.position+Vector2(-135,140); label.add_theme_font_size_override("font_size",25); root.add_child(label); index+=1
 else:
  game=load("res://scripts/main.gd").new(); root.add_child(game)
  game.save.data=game.save.defaults(); game.save.data.best=1240; game.save.data.xp=145; game.save.data.shells=83; game.show_menu("title")
  if mode=="play": game.start(); game.run.begin_steering(360)
func _process(_dt: float) -> bool:
 if mode=="skins":
  count+=1
  if count==8: capture_grid()
  return false
 if not is_instance_valid(game): return false
 count+=1
 if mode=="play":
  var time: float=float(count)/30.0
  game.run.drag_to(360+90*sin(time*TAU/3.0))
  min_carve=minf(min_carve,game.rider_visual.carve); max_carve=maxf(max_carve,game.rider_visual.carve)
  saw_left=saw_left or game.rider_visual.side<0; saw_right=saw_right or game.rider_visual.side>0
  if game.run.dead: push_error("QA gameplay crashed: "+game.run.reason); quit(1)
 if count>=(600 if mode=="play" else 180):
  if mode=="play": assert(saw_left and saw_right and min_carve<0.1 and max_carve>0.99)
  print("EVIDENCE carve range=",min_carve,"..",max_carve," left=",saw_left," right=",saw_right)
  print("EVIDENCE ",mode," frames=",count," state=",game.state)
  quit()
 return false
func capture_grid() -> void:
 await RenderingServer.frame_post_draw
 var image: Image=root.get_texture().get_image()
 image.save_png("res://../art/qa/rider-v4/skins_grid.png")
 quit()
