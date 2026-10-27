class_name Missions
extends RefCounted
const POOL: Array = [
 ["Land a spin","spins",1], ["Ride 100 m","distance",100], ["Switch tack 5 times","tacks",5],
 ["Collect 5 shells","shells",5], ["Land a backflip","flips",1], ["Grab for 1 second","grab",1],
 ["Make a perfect landing","perfect",1], ["Jump a golden wave","golden",1], ["Make 3 close passes","near",3],
 ["Reach combo x3","combo",3], ["Land 5 spins in one run","run_spins",5], ["Ride 500 m","distance",500],
 ["Collect 15 shells in one run","run_shells",15], ["Switch tack 25 times","tacks",25],
 ["Land 3 backflips","flips",3], ["Grab for 3 seconds","grab",3], ["Make 3 perfect landings","perfect",3],
 ["Jump 5 golden waves","golden",5], ["Reach combo x5","combo",5], ["Ride 1500 m","distance",1500]]
static func ensure(data: Dictionary) -> void:
 if not data.has("missions"): data.missions={"next":3,"active":[0,1,2],"progress":{}}
static func level(xp: int) -> int: return 1+int(xp/100)
static func update(data: Dictionary, stats: Dictionary) -> Array:
 ensure(data)
 var completed: Array=[]
 for id: int in data.missions.active.duplicate():
  var goal: Array=POOL[id%POOL.size()]
  var key: String=str(id)
  var previous: float=float(data.missions.progress.get(key,0))
  var value: float=float(stats.get(goal[1],0))
  data.missions.progress[key]=maxf(previous,value) if goal[1] in ["distance","combo","run_spins","run_shells"] else previous+value
  if float(data.missions.progress[key])>=float(goal[2]):
   var reward: int=10+mini(int(id/3)*5,40)
   data.shells=int(data.shells)+reward; data.xp=int(data.xp)+reward
   completed.append({"title":goal[0],"reward":reward})
   var slot: int=data.missions.active.find(id)
   data.missions.active[slot]=int(data.missions.next); data.missions.next=int(data.missions.next)+1
 return completed
static func date_key(date: Dictionary) -> String: return "%04d-%02d-%02d" % [date.year,date.month,date.day]
static func daily_seed(date: Dictionary) -> int: return int(date.year)*10000+int(date.month)*100+int(date.day)
