extends SceneTree
var game: Node
func _initialize() -> void:
 call_deferred("test")
func press(text: String) -> void:
 for b: Node in game.title_ui.get_children():
  if b is Button and b.text==text: b.pressed.emit(); return
 assert(false,"Missing menu button: "+text)
func test() -> void:
 game=load("res://scripts/main.gd").new(); root.add_child(game)
 await process_frame
 game.save.data=game.save.defaults(); game.show_menu("title")
 var background_tap: InputEventScreenTouch=InputEventScreenTouch.new(); background_tap.position=Vector2(360,650); background_tap.pressed=true
 game._unhandled_input(background_tap); assert(game.state=="title","Background taps must not start a ride")
 for child: Node in game.title_ui.get_children():
  if child is Button: assert(child.size.y>=84,"Menu action touch target too short")
 var found: bool=false
 for child: Node in game.title_ui.find_children("*","Label",true,false):
  if child.text=="First ride": found=true
 assert(found,"First ride must be a plain label")
 press("Missions · 0/3"); assert(game.state=="missions")
 for b: Node in game.panel.get_children():
  if b is Button and b.text=="Close": b.pressed.emit(); break
 assert(game.state=="title")
 press("⚙"); assert(game.state=="settings")
 game.show_menu("title"); press("Kites"); assert(game.state=="shop")
 game.show_menu("title"); press("Daily"); assert(game.state=="play" and game.daily)
 game.show_menu("title"); press("Ride"); assert(game.state=="play" and not game.daily)
 game.save.data.reduce_motion=true; game.show_menu("title"); game._process(0.1)
 var pos: Vector2=game.rider.position; var kp: Vector2=game.kite.position
 game._process(2.0); assert(pos==game.rider.position and kp==game.kite.position)
 print("MENU PASS first-launch, missions close, settings, shop, daily, ride, reduce-motion pose")
 game.queue_free(); await process_frame; quit()
