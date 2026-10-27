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
   for mirror: float in [-1.0,1.0]:
    rig.scale.x=mirror
    for amount: float in [0.0,1.0]:
     rig.solve(amount)
     assert(rig.board.position==Vector2(spec.board.sprite_offset_px[0],spec.board.sprite_offset_px[1]))
     assert(spec.board.readability_scale<=1.15)
     assert((rig.board.scale*rig.board.texture.get_size()).distance_to(Vector2(28.8,43.2)*spec.board.readability_scale)<0.001)
     var tail: Vector2=Vector2(spec.board.tail_px[0],spec.board.tail_px[1])
     assert(rig.tail_point().distance_to(rig.to_global(rig.board.position+tail.rotated(rig.board.rotation)))<0.001)
     for i: int in range(2):
      var point: Array=spec.board.front_strap_px if i==0 else spec.board.back_strap_px
      var strap: Vector2=Vector2(point[0],point[1])
      assert(rig.to_global(rig.feet[i]).distance_to(rig.board.to_global(strap/rig.board.scale))<0.5)
     for i: int in range(4):
      assert(rig.bar_point(i).is_finite())
      var bar: Array=spec.upper.bar_px[["left","right","center","center"][i]]
      assert(rig.bar_point(i).distance_to(rig.to_global(Vector2(bar[0],bar[1])))<0.01)
      var kite_transform: Transform2D=Transform2D(0.2,Vector2(430,700)).scaled_local(Vector2.ONE*1.45)
      assert((kite_transform*[Vector2(-53.2,31.5),Vector2(53.2,31.5),Vector2(-28.6,1.31),Vector2(28.6,1.31)][i]).is_finite())
 print("SKINS PASS all four combinations; 15/45 degrees, both mirrors, feet and four bar anchors")
 var store: RefCounted=load("res://scripts/save_store.gd").new()
 assert(store.defaults().selected_board=="classic" and store.defaults().selected_character=="navy")
 store.path="user://rider_skin_migration_test.json"
 var legacy: FileAccess=FileAccess.open(store.path,FileAccess.WRITE); legacy.store_string('{"version":1,"best":42}'); legacy.close()
 store.read_save(); assert(store.data.selected_board=="classic" and store.data.selected_character=="navy" and store.data.best==42)
 store.data.selected_board="seaglass"; store.data.selected_character="terra"; store.write_save(); store.read_save()
 assert(store.data.selected_board=="seaglass" and store.data.selected_character=="terra")
 DirAccess.remove_absolute(store.path)
 rig.queue_free(); await process_frame; quit()
