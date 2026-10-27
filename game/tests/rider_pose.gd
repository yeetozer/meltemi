extends SceneTree
func _initialize() -> void: call_deferred("test")
func test() -> void:
 var game: Node=load("res://scripts/main.gd").new(); root.add_child(game)
 game.start(); game.run.launch(true); game.run.backflip()
 game._process(0.12)
 assert(game.run.flip>0 and absf(game.rider_visual.scale.y-1)>0.1,"Normal update must apply the flip pose after base transforms")
 game.run.flip=0; game.run.grab(true); game._process(0.016)
 assert(game.rider_visual.scale.y<0.9 and game.rider_visual.upper.position.y>-17.28,"Normal update must tuck a grab")
 game.run.grab(false); game._process(0.016)
 assert(game.rider_visual.scale.y==1 and is_equal_approx(game.rider_visual.upper.position.y,-17.28))
 game.rider_visual.update_pose(0.1,-318,true,0,false)
 assert(game.rider_visual.side==-1 and game.rider_visual.scale.x==-1)
 game.rider_visual.update_pose(0.1,30,true,0,false); assert(game.rider_visual.side==-1)
 game.rider_visual.update_pose(0.1,36,true,0,false); assert(game.rider_visual.side==1)
 game.set_process(false)
 game.rider_visual.update_pose(0.016,-318,false,0,false)
 assert(game.rider_visual.scale.x==1,"Mirror must not snap")
 await create_timer(0.06).timeout
 var halfway: float=game.rider_visual.scale.x
 assert(halfway>-1 and halfway<1)
 game.rider_visual.update_pose(0.016,318,false,0,false)
 assert(is_equal_approx(game.rider_visual.scale.x,halfway),"Reversal must interrupt without snapping")
 await create_timer(0.14).timeout
 assert(is_equal_approx(game.rider_visual.scale.x,1))
 print("POSE PASS normal-play flip, grab/release, mirror hysteresis, interruptible 0.12s tween and Reduce Motion")
 game.queue_free(); await process_frame; quit()
