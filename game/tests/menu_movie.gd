extends SceneTree
var count: int=0
func _initialize() -> void:
 root.add_child(load("res://scripts/main.gd").new())
func _process(_dt: float) -> bool:
 count+=1
 if count>=300: quit()
 return false
