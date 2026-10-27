extends SceneTree
# Editor-only QA harness; no production scene references this script.
func _initialize() -> void:
 if not OS.has_feature("editor"): quit(); return
 call_deferred("render")
func sprite(path: String, pos: Vector2, parent: Node2D, rotation_: float=0.0) -> void:
 var image: Image=Image.load_from_file(path)
 var s: Sprite2D=Sprite2D.new(); s.texture=ImageTexture.create_from_image(image); s.position=pos; s.rotation=rotation_; parent.add_child(s)
func render() -> void:
 var v: String=OS.get_environment("VARIANT")
 var pose: String=OS.get_environment("POSE")
 var color_: String=OS.get_environment("COLORWAY")
 var stage: Node2D=Node2D.new(); root.add_child(stage)
 var background: Polygon2D=Polygon2D.new(); background.polygon=PackedVector2Array([Vector2.ZERO,Vector2(720,0),Vector2(720,1280),Vector2(0,1280)]); background.color=Color("4fb3bf"); stage.add_child(background)
 var lean: float=-0.25 if pose=="left" else 0.25 if pose=="right" else 0.0
 var origin: Vector2=Vector2(360,780)
 if pose!="air":
  var foam: Line2D=Line2D.new(); foam.width=14; foam.default_color=Color(1,1,1,0.55); foam.points=PackedVector2Array([origin+Vector2(-32,18),origin+Vector2(-55,55),origin+Vector2(-72,100)]); var taper: Curve=Curve.new(); taper.add_point(Vector2(0,1)); taper.add_point(Vector2(1,0)); foam.width_curve=taper; stage.add_child(foam)
 else: origin.y-=65
 var folder: String="res://../art/variants/"+v+"/"
 var kite_pos: Vector2=Vector2(410,510)
 for i in range(4):
  var line: Line2D=Line2D.new(); line.width=1.3; line.default_color=Color("183e49"); var start: Vector2=origin+Vector2((-30 if i==0 else 30 if i==3 else 0),-61); var end: Vector2=kite_pos+Vector2([-105,-60,60,105][i],30); line.points=PackedVector2Array([start,start.lerp(end,0.5)+Vector2(7,0),end]); stage.add_child(line)
 var parts: Node2D=Node2D.new(); parts.position=origin; parts.scale=Vector2.ONE*1.5; stage.add_child(parts)
 sprite(folder+"board.png",Vector2.ZERO,parts,lean)
 sprite(folder+"body.png",Vector2(lean*20,-3),parts,lean*0.4)
 sprite(folder+"arms.png",Vector2(lean*20,-3),parts,lean*0.4)
 var kite_node: Node2D=Node2D.new(); kite_node.scale=Vector2.ONE*1.2; kite_node.position=kite_pos; stage.add_child(kite_node); sprite(folder+"kite_"+color_+".png",Vector2.ZERO,kite_node)
 await process_frame
 await RenderingServer.frame_post_draw
 var target: String="res://../art/qa/variants/"+v+"_"+pose+"_"+color_+".png"
 print("VARIANT CAPTURE ",root.get_texture().get_image().save_png(target)); quit()
