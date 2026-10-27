extends SceneTree
func _initialize() -> void: call_deferred("test")
func test() -> void:
 var game: Node=load("res://scripts/main.gd").new(); root.add_child(game)
 game.start(); game._process(0.016)
 assert(game.wake.get_point_position(game.wake.get_point_count()-1).distance_to(game.world.to_local(game.rider_visual.tail_point()))<0.001,"Wake starts at this frame's transformed tail")
 game.run.launch(true); game.run.backflip()
 game._process(0.12)
 assert(game.run.flip>0 and absf(game.rider_visual.scale.y-1)>0.1,"Normal update must apply the flip pose after base transforms")
 for phase: float in [0.1,0.25,0.35,0.5,0.75,0.9]:
  game.run.flip=phase; game._process(0.0)
  for i: int in range(4):
   assert(game.lines[i].points[0].distance_to(game.world.to_local(game.rider_visual.bar_point(i)))<0.001,"Flip lines must follow the full bar transform")
 assert(game.rider.z_index>game.wake.z_index and game.rider.z_index>game.spray.z_index)
 game.run.flip=0; game.run.grab(true); game._process(0.016)
 assert(game.rider_visual.scale.y<0.9 and game.rider_visual.upper.position.y>-17.28,"Normal update must tuck a grab")
 game.run.grab(false); game._process(0.016)
 assert(game.rider_visual.scale.y==1 and is_equal_approx(game.rider_visual.upper.position.y,-17.28))
 game.rider_visual.update_pose(0.1,-318,true,0,false)
 assert(game.rider_visual.side==-1 and game.rider_visual.scale.x==-1)
 game.rider_visual.update_pose(0.1,30,true,0,false); assert(game.rider_visual.side==-1)
 game.rider_visual.update_pose(0.1,36,true,0,false); assert(game.rider_visual.side==1)
 game.state="pause"
 game.run.lateral_velocity=-318
 for tick: int in range(30): game._process(1.0/30)
 assert(game.kite.position.x<game.rider.position.x-150,"Kite swings to left carve")
 var prior: float=game.kite.position.x
 game.run.lateral_velocity=318; game._process(1.0/30)
 assert(game.kite.position.x>prior and game.kite.position.x<game.rider.position.x+170,"Kite reversal is smooth and interruptible")
 game.save.data.reduce_motion=true; game._process(1.0/30)
 assert(is_equal_approx(game.kite.position.x,game.rider.position.x+170),"Reduce Motion removes kite lag")
 game.save.data.reduce_motion=false
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
