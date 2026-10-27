extends SceneTree
func _initialize() -> void: call_deferred("test")
func test() -> void:
 var spec: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://resources/rider_rig.json"))
 var rig: Node2D=load("res://scripts/rider_visual.gd").new(); root.add_child(rig)
 for b: String in rig.Skins.BOARDS:
  for c: String in rig.Skins.CHARACTERS:
   rig.set_skins(b,c)
   assert(rig.board.texture.resource_path.ends_with("board_"+b+".png"))
   assert(rig.upper.texture.resource_path.ends_with("rider_"+c+".png"))
   for amount: float in [-1.0,-0.75,-0.5,-0.25,0.0,0.25,0.5,0.75,1.0]:
    rig.solve(amount)
    assert(rig.scale.x==1)
    assert((rig.board.scale*rig.board.texture.get_size()).distance_to(Vector2(28.8,43.2)*spec.board.readability_scale)<0.001)
    assert(rig.spray_sprite.to_global(Vector2(1.44,-5.04)/rig.spray_sprite.scale).distance_to(rig.tail_point())<0.001)
    for foot: Vector2 in rig.feet:
     var closest: float=INF
     for point: Array in [spec.board.front_strap_px,spec.board.back_strap_px]:
      closest=minf(closest,foot.distance_to(rig.board.position+Vector2(point[0],point[1]).rotated(rig.board.rotation)))
     assert(closest<0.5)
    for a: int in range(2):
     for b_: int in range(2):
      assert(Geometry2D.segment_intersects_segment(rig.paths[0][a],rig.paths[0][a+1],rig.paths[1][b_],rig.paths[1][b_+1])==null,"Legs must not cross")
    for phase: float in [0.0,0.1,0.25,0.35,0.5,0.75,0.9]:
     for grab: bool in [false,true]:
      rig.update_pose(0,0,false,phase,grab)
      for i: int in range(4):
       var anchor: Array=spec.upper.bar_px[["left","right","center","center"][i]]
       var pivot: Vector2=Vector2(spec.upper.sprite_offset_px[0],spec.upper.sprite_offset_px[1])
       var expected: Vector2=rig.to_global(rig.upper.position+(Vector2(anchor[0],anchor[1])-pivot).rotated(rig.upper.rotation))
       assert(rig.bar_point(i).is_finite() and rig.bar_point(i).distance_to(expected)<0.01)
      var left: Vector2=rig.bar_point(0)
      var right: Vector2=rig.bar_point(1)
      assert(left.x<right.x)
      assert(Geometry2D.segment_intersects_segment(left,Vector2(-170,-300),right,Vector2(170,-300))==null)
 print("SKINS PASS all four combinations, nine signed carves, feet, legs, spray, six flip phases and grab anchors")
 var store: RefCounted=load("res://scripts/save_store.gd").new()
 assert(store.defaults().selected_board=="classic" and store.defaults().selected_character=="navy")
 store.path="user://rider_skin_migration_test.json"
 var legacy: FileAccess=FileAccess.open(store.path,FileAccess.WRITE); legacy.store_string('{"version":1,"best":42}'); legacy.close()
 store.read_save(); assert(store.data.selected_board=="classic" and store.data.selected_character=="navy" and store.data.best==42)
 store.data.selected_board="seaglass"; store.data.selected_character="terra"; store.write_save(); store.read_save()
 assert(store.data.selected_board=="seaglass" and store.data.selected_character=="terra")
 DirAccess.remove_absolute(store.path)
 rig.queue_free(); await process_frame; quit()
