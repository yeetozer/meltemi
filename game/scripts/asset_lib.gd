extends Node
var cache: Dictionary = {}
func _exit_tree() -> void:
 cache.clear()
func texture(file: String, size: Vector2 = Vector2(72,72)) -> Texture2D:
 var path: String = "res://assets/" + file
 if cache.has(path): return cache[path] as Texture2D
 var tex: Texture2D
 if ResourceLoader.exists(path): tex = load(path) as Texture2D
 else:
  push_warning("Missing asset: " + path)
  var image: Image = Image.create(int(size.x), int(size.y), false, Image.FORMAT_RGBA8)
  image.fill(Color.TRANSPARENT)
  for y in range(int(size.y)):
   for x in range(int(size.x)):
    var p: Vector2 = Vector2(x,y) / size * 2.0 - Vector2.ONE
    if p.length() < 0.94: image.set_pixel(x,y,Color("f4ebdd") if p.length() < 0.75 else Color("c8643b"))
  tex = ImageTexture.create_from_image(image)
 cache[path] = tex
 return tex
func sound(name_: String) -> AudioStream:
 var path: String = "res://assets/audio/" + name_ + ".wav"
 if cache.has(path): return cache[path] as AudioStream
 var stream: AudioStream
 if ResourceLoader.exists(path): stream = load(path) as AudioStream
 else:
  push_warning("Missing asset: " + path)
  var silent: AudioStreamWAV = AudioStreamWAV.new()
  silent.data = PackedByteArray([0,0,0,0])
  stream = silent
 cache[path] = stream
 return stream
