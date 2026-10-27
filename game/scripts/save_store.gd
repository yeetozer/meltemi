class_name SaveStore
extends RefCounted
var path: String = "user://save.json"
var data: Dictionary = {}
func defaults() -> Dictionary:
 return {"version":2,"selected_board":"classic","selected_character":"navy","xp":0,"missions":{"next":3,"active":[0,1,2],"progress":{}},"daily_best":{},"hints":0,"best":0,"shells":0,"owned":["sunset"],"selected":"sunset","sound":true,"reduce_motion":false,"tutorial_done":false}
func read_save() -> void:
 data = defaults()
 if not FileAccess.file_exists(path): return
 var text: String = FileAccess.get_file_as_string(path)
 var parser: JSON = JSON.new()
 var parsed: Variant = parser.data if parser.parse(text) == OK else null
 if not parsed is Dictionary or int(parsed.get("version",0)) not in [1,2]:
  var backup: FileAccess = FileAccess.open(path+".corrupt",FileAccess.WRITE)
  if backup: backup.store_string(text)
  write_save()
  return
 for key: String in data.keys():
  if parsed.has(key) and typeof(parsed[key]) == typeof(data[key]): data[key] = parsed[key]
 # JSON numbers are floats, defaults are integers.
 data.best = maxi(0,int(parsed.get("best",0)))
 data.shells = maxi(0,int(parsed.get("shells",0)))
 data.version=2
 data.xp=maxi(0,int(parsed.get("xp",0)))
 data.hints=clampi(int(parsed.get("hints",0)),0,3)
 if not data.selected in data.owned: data.selected = "sunset"
func write_save() -> void:
 var f: FileAccess = FileAccess.open(path,FileAccess.WRITE)
 if f: f.store_string(JSON.stringify(data))
func buy(kite: String, cost: int) -> bool:
 if kite in data.owned: data.selected = kite
 elif int(data.shells) >= cost:
  data.shells = int(data.shells)-cost
  data.owned.append(kite)
  data.selected = kite
 else: return false
 write_save()
 return true
