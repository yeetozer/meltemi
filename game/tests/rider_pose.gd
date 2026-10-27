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
 for amount: float in [-1.0,-0.75,-0.5,-0.25,0.0,0.25,0.5,0.75,1.0]:
  for phase: float in [0.0,0.1,0.25,0.35,0.5,0.75,0.9]:
   for grabbing: bool in [false,true]:
    game.run.lateral_velocity=amount*318
    game.run.visual_heading=amount*0.42
    game.run.flip=phase; game.run.grabbing=grabbing
    game.rider_visual.solve(amount); game._process(0.0)
    var left: Vector2=game.lines[0].points[0]
    var right: Vector2=game.lines[1].points[0]
    assert(left.x<right.x,"Screen bar ordering")
    assert(Geometry2D.segment_intersects_segment(left,game.lines[0].points[1],right,game.lines[1].points[1])==null,"Screen kite lines do not cross")
 game.run.grabbing=false
 assert(game.rider.z_index>game.wake.z_index and game.rider.z_index>game.spray.z_index)
 game.run.flip=0; game.run.grab(true); game._process(0.016)
 assert(game.rider_visual.scale.y<0.9 and game.rider_visual.upper.position.y>-17.28,"Normal update must tuck a grab")
 game.run.grab(false); game._process(0.016)
 assert(game.rider_visual.scale.y==1 and is_equal_approx(game.rider_visual.upper.position.y,-17.28))
 game.rider_visual.update_pose(0.1,-318,true,0,false)
 assert(game.rider_visual.signed_carve<0 and game.rider_visual.scale.x==1)
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
 for tick: int in range(300):
  game.rider_visual.update_pose(0.016,-318 if tick%2==0 else 318,false,0,false)
  assert(game.rider_visual.scale.x==1)
  assert(is_finite(game.rider_visual.board.rotation))
  for path: PackedVector2Array in game.rider_visual.paths:
   for point: Vector2 in path: assert(point.is_finite())
  assert(game.rider_visual.board.rotation>=deg_to_rad(-40) and game.rider_visual.board.rotation<=deg_to_rad(45))
 print("POSE PASS flip, grab, signed carve, rapid reversal and Reduce Motion")
 game.show_menu("title")
 game.save.data.reduce_motion=false
 var saw_left: bool=false
 var saw_right: bool=false
 for tick: int in range(900):
  game._process(1.0/60)
  saw_left=saw_left or game.rider_visual.signed_carve<-0.3
  saw_right=saw_right or game.rider_visual.signed_carve>0.3
 assert(saw_left and saw_right,"Menu gently carves both directions")
 game.save.data.reduce_motion=true; game._process(0.016)
 var resting: Transform2D=game.rider.transform
 for tick: int in range(60): game._process(1.0/60)
 assert(game.rider.transform.is_equal_approx(resting) and game.rider_visual.signed_carve==0,"Reduced-motion menu static")
 print("POSE PASS menu signed carving both directions and static Reduce Motion")
 game.queue_free(); await process_frame; quit()
