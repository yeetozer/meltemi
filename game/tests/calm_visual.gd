extends SceneTree
# Launched explicitly with --script; production scene never loads this runner.
class QAModel extends "res://scripts/run_model.gd":
 func crash(_why: String) -> void: pass
var game: Node
var frame: int=0
var stills: bool=false
const DT: float=1.0/30.0
const OUT: String="../art/qa/calm/"
func _initialize() -> void: call_deferred("begin")
func begin() -> void:
 stills="--stills" in OS.get_cmdline_user_args()
 game=load("res://scenes/main.tscn").instantiate(); game.save.path="user://calm_qa_save.json"; root.add_child(game)
 game.set_process(false); game.save.data.sound=false; game.save.data.reduce_motion=true; game.start(); game.run=QAModel.new(); game.run.begin_steering(0)
 if stills:
  for second: int in [2,10,25,60,120]:
   while game.run.elapsed<second: advance()
   game.queue_redraw(); await process_frame; await process_frame
   root.get_texture().get_image().save_png(OUT+"t%03d.png" % second)
  game.queue_free(); await process_frame; quit()
func advance() -> void:
 game.run.target_x=360+45*sin(game.run.elapsed*0.2)
 game._process(DT)
func _process(_dt: float) -> bool:
 if game==null or stills: return false
 advance(); frame+=1
 if frame>=1800:
  print("CALM MOVIE 60 seconds simulated; elapsed=",game.run.elapsed)
  game.queue_free(); quit()
 return false
