class_name ChunkMaker
extends RefCounted
const SIZES: Dictionary = {"buoy":Vector2(40,40),"rock_small":Vector2(70,60),"rock_big":Vector2(140,110),"turtle":Vector2(60,70),"boat_fishing":Vector2(70,160),"jetski":Vector2(44,90),"sailboat":Vector2(80,180),"shell":Vector2(32,32),"starfish":Vector2(40,40),"gust":Vector2(80,80),"wave":Vector2(256,48),"wave_gold":Vector2(256,48)}
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
func chunk(seed_: int, index: int) -> Dictionary:
 rng.seed = seed_ + index * 7919
 var gap: float = rng.randf_range(230,490)
 var objects: Array[Dictionary] = []
 var rows: int=5+mini(index/4,3)
 var spacing: float=1225.0/float(rows)
 for row in range(rows):
  var kind: String = ["buoy","rock_small","rock_big","turtle","boat_fishing","jetski","sailboat"][rng.randi_range(0,6)]
  var size: Vector2 = SIZES[kind]
  var side: int = -1 if rng.randf() < 0.5 else 1
  var px: float = gap + float(side)*(110+size.x/2)
  if px-size.x/2 > 104 and px+size.x/2 < 616:
   objects.append({"kind":kind,"x":px,"y":-float(row)*spacing,"size":size,"base":px,"phase":rng.randf()*TAU,"move":kind in ["boat_fishing","jetski"],"side":side,"gap":gap})
  var pickup: String = "starfish" if row == 3 else "shell"
  objects.append({"kind":pickup,"x":gap,"y":-float(row)*spacing-80,"size":SIZES[pickup],"move":false})
 var wave: String = "wave_gold" if index%3 == 2 else "wave"
 objects.append({"kind":wave,"x":gap,"y":-650.0,"size":SIZES[wave],"move":false})
 objects.append({"kind":"gust","x":gap,"y":-1100.0,"size":SIZES["gust"],"move":false})
 return {"gap":gap,"gap_width":200.0,"objects":objects}
