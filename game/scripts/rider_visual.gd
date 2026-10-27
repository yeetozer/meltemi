extends Node2D
const Skins=preload("res://scripts/rider_skins.gd")
var board: Sprite2D
var upper: Sprite2D
var spray_sprite: Sprite2D
var legs: Node2D
var carve: float=0.0
var signed_carve: float=0.0
var suit: Color=Color("22384a")
var feet: Array[Vector2]=[]
var paths: Array[PackedVector2Array]=[]
func sprite(asset: String, dimensions: Vector2) -> Sprite2D:
 var s: Sprite2D=Sprite2D.new()
 s.texture=AssetLib.texture("sprites/"+asset+".png",dimensions)
 s.scale=dimensions/s.texture.get_size()
 add_child(s)
 return s
func _ready() -> void:
 spray_sprite=sprite("spray",Vector2(12.96,12.96))
 board=sprite("board_classic",Vector2(28.8,43.2))
 legs=Node2D.new(); add_child(legs); legs.draw.connect(draw_legs)
 upper=sprite("rider_navy",Vector2(72,72)); upper.position=Vector2(0,-17.28)
 solve(0)
func set_skins(b: String, c: String) -> void:
 if not Skins.BOARDS.has(b): b="classic"
 if not Skins.CHARACTERS.has(c): c="navy"
 board.texture=AssetLib.texture("sprites/"+str(Skins.BOARDS[b].texture)+".png",Vector2(28.8,43.2))
 upper.texture=AssetLib.texture("sprites/"+str(Skins.CHARACTERS[c].texture)+".png",Vector2(72,72))
 suit=Color(Skins.CHARACTERS[c].suit)
func update_pose(dt: float, velocity: float, _reduce: bool, flip: float, grab: bool) -> void:
 var target: float=signf(velocity)*clampf((absf(velocity)-20)/298,0,1)
 signed_carve=lerpf(signed_carve,target,1-exp(-dt/0.10))
 solve(signed_carve)
 scale.y=cos(flip*TAU) if flip>0 else (0.78 if grab else 1.0)
 rotation=0.22 if grab else 0.0
 upper.position=Vector2(0,-17.28+(3.0 if grab else 0.0))
func solve(amount: float) -> void:
 signed_carve=clampf(amount,-1,1)
 carve=absf(signed_carve)
 upper.rotation=deg_to_rad(6)*signed_carve
 var angle_deg: float=lerpf(15,45,signed_carve) if signed_carve>=0 else lerpf(15,-40,-signed_carve)
 var angle: float=deg_to_rad(angle_deg)
 board.rotation=angle
 # Expose the nose beside/below the hips instead of burying it under both legs.
 board.position=Vector2(10*clampf(angle_deg/15,-1,1),13)
 board.scale=Vector2(28.8,43.2)*1.12/board.texture.get_size()
 # Approved SVG attachment (-6,-2), relative to viewBox centre (-8,5), at 0.72 scale.
 spray_sprite.rotation=angle
 spray_sprite.position=board.position+(Vector2(0,23)-Vector2(1.44,-5.04)).rotated(angle)
 feet.assign([board.position+Vector2(0,-10.44*1.12).rotated(angle),board.position+Vector2(0,10.44*1.12).rotated(angle)])
 if feet[0].x<feet[1].x: feet.reverse()
 paths.clear()
 for i in range(2):
  var sign_: float=1.0 if i==0 else -1.0
  var hip: Vector2=Vector2(sign_*lerpf(4.68,4.32,carve),-12.24)
  var delta: Vector2=feet[i]-hip
  var perp: Vector2=Vector2(-delta.y,delta.x).normalized()
  if perp.x*sign_<0: perp=-perp
  var knee: Vector2=(hip+feet[i])*0.5+perp*maxf(3.5,9-delta.length()/0.72*0.12)*0.72
  paths.append(PackedVector2Array([hip,knee,feet[i]]))
 legs.queue_redraw()
func draw_legs() -> void:
 # Composite each whole leg so the front outline cuts across the back fill.
 var back: int=0 if feet[0].y>feet[1].y else 1
 for i: int in [back,1-back]:
  for width: float in [8.64,6.12]:
   var color: Color=Color(1,1,1,0.92) if width>8 else (suit.lightened(0.18) if i==back else suit)
   legs.draw_polyline(paths[i],color,width,true)
   for p: Vector2 in paths[i]: legs.draw_circle(p,width/2,color,true,-1,true)
 for foot: Vector2 in feet:
  legs.draw_set_transform(foot,board.rotation,Vector2(3.6,2.304))
  legs.draw_circle(Vector2.ZERO,1,suit,true,-1,true)
 legs.draw_set_transform(Vector2.ZERO)
func tail_point() -> Vector2:
 return to_global(board.position+Vector2(0,23).rotated(board.rotation))
func bar_point(index: int) -> Vector2:
 var point: Vector2=[Vector2(-10.97,-32.77),Vector2(8.423,-34.126),Vector2(-1.273,-33.448),Vector2(-1.273,-33.448)][index]
 return to_global(upper.position+(point-Vector2(0,-17.28)).rotated(upper.rotation))
