class_name CxPersistence
extends RefCounted

const PATH="user://castelionyx_v1.json"
var data:Dictionary={}
var last_error=""

func _init() -> void:
 load_data()

static func defaults() -> Dictionary:
 return {"version":1,"profile":{},"gems":0,"selected":0,"heroes":[1,0,0,0,0,0],"towers":[1,1,1,1,1,1],"spells":[1,1,1,1,1],"settings":{"music":0.32,"sfx":0.45,"ui":0.35,"speed":1,"quality":true},"stats":{"total":0,"waves":0,"bosses":0,"time":0.0,"best":0,"worst":-1,"last":{},"adventure_best":0,"adventure_attempts":0,"adventure_claimed":false},"claimed":[]}

static func clean_number(value:Variant,fallback:float,minimum:float,maximum:float) -> float:
 if not (value is int or value is float): return fallback
 if not is_finite(float(value)): return fallback
 return clampf(float(value),minimum,maximum)

static func validate(candidate:Variant) -> Dictionary:
 var result=defaults()
 if not candidate is Dictionary: return result
 var c:Dictionary=candidate
 if int(clean_number(c.get("version",1),1,0,100))>1: return result
 var profile=c.get("profile",{})
 if profile is Dictionary and not str(profile.get("name","")).strip_edges().is_empty():
  result.profile={"name":str(profile.name).replace("\n"," ").replace("\r"," ").strip_edges().left(24),"country":str(profile.get("country","Brasil")).strip_edges().left(40),"avatar":int(clean_number(profile.get("avatar",0),0,0,7)),"photo":str(profile.get("photo","")).left(160000)}
 result.gems=int(clean_number(c.get("gems",0),0,0,999999))
 for key in ["heroes","towers","spells"]:
  var values=c.get(key,[])
  if values is Array:
   for i in range(mini(values.size(),result[key].size())):
    result[key][i]=int(clean_number(values[i],result[key][i],0 if key=="heroes" else 1,10))
 result.heroes[0]=maxi(1,result.heroes[0])
 result.selected=int(clean_number(c.get("selected",0),0,0,5))
 if result.heroes[result.selected]<1: result.selected=0
 var settings=c.get("settings",{})
 if settings is Dictionary:
  for key in ["music","sfx","ui"]: result.settings[key]=clean_number(settings.get(key,result.settings[key]),result.settings[key],0,1)
  result.settings.speed=2 if settings.get("speed",1)==2 else 1
  result.settings.quality=settings.get("quality",true)==true
 var stats=c.get("stats",{})
 if stats is Dictionary:
  for key in ["total","waves","bosses","best","adventure_best","adventure_attempts"]: result.stats[key]=int(clean_number(stats.get(key,0),0,0,9999999))
  result.stats.worst=int(clean_number(stats.get("worst",-1),-1,-1,9999999))
  result.stats.time=clean_number(stats.get("time",0),0,0,999999999)
  result.stats.adventure_claimed=stats.get("adventure_claimed",false)==true
  if stats.get("last",{}) is Dictionary: result.stats.last=stats.get("last",{}).duplicate(true)
 var claimed=c.get("claimed",[])
 if claimed is Array:
  for item in claimed.slice(maxi(0,claimed.size()-128)):
   if item is String and item.length()<80: result.claimed.append(item)
 return result

func load_data() -> void:
 data=defaults()
 for path in [PATH,PATH+".bak"]:
  if not FileAccess.file_exists(path): continue
  var file=FileAccess.open(path,FileAccess.READ)
  if file==null: continue
  var parsed=JSON.parse_string(file.get_as_text())
  if parsed is Dictionary:
   data=validate(parsed)
   return
 last_error=""

func commit() -> bool:
 var tmp=FileAccess.open(PATH+".tmp",FileAccess.WRITE)
 if tmp==null:
  last_error="Não foi possível salvar neste dispositivo. O progresso permanece nesta sessão."
  return false
 tmp.store_string(JSON.stringify(data))
 tmp.close()
 if FileAccess.file_exists(PATH):
  DirAccess.copy_absolute(ProjectSettings.globalize_path(PATH),ProjectSettings.globalize_path(PATH+".bak"))
 var err=DirAccess.rename_absolute(ProjectSettings.globalize_path(PATH+".tmp"),ProjectSettings.globalize_path(PATH))
 if err!=OK:
  last_error="Falha ao confirmar o salvamento. Tente novamente."
  return false
 last_error=""
 return true

func has_profile() -> bool:
 return not data.profile.is_empty()

func profile(name:String,country:String,avatar:int,photo:String="") -> bool:
 if name.strip_edges().is_empty(): return false
 var old=data.duplicate(true)
 data.profile={"name":name.strip_edges().replace("\n"," ").left(24),"country":country.strip_edges().left(40),"avatar":clampi(avatar,0,7),"photo":photo.left(160000)}
 if commit(): return true
 data=old
 return false

func buy(kind:String,index:int) -> bool:
 if not kind in ["heroes","towers","spells"]: return false
 if index<0 or index>=data[kind].size(): return false
 var level=int(data[kind][index])
 if level>=10: return false
 var cost=purchase_cost(kind,index)
 if data.gems<cost: return false
 var old=data.duplicate(true)
 data.gems-=cost
 data[kind][index]+=1
 if commit(): return true
 data=old
 return false

func purchase_cost(kind:String,index:int) -> int:
 var level=int(data[kind][index])
 if kind=="heroes" and level==0: return int(CxCatalog.HEROES[index].cost)
 return maxi(1,(level*2)+(index if kind=="heroes" else 0))

func select_hero(index:int) -> bool:
 if index<0 or index>5 or data.heroes[index]<=0: return false
 var old=int(data.selected)
 data.selected=index
 if commit(): return true
 data.selected=old
 return false

func record(result:Dictionary) -> int:
 if data.claimed.has(result.id): return 0
 var before=data.duplicate(true)
 var gems=int(result.completed/10) if result.mode=="infinite" else 0
 if result.mode=="adventure" and result.victory and result.completed==5 and not data.stats.adventure_claimed:
  gems=1000
  data.stats.adventure_claimed=true
 data.gems+=gems
 data.stats.total+=1
 data.stats.waves+=result.completed
 data.stats.bosses+=result.bosses
 data.stats.time+=result.time
 data.stats.best=maxi(data.stats.best,result.completed)
 if data.stats.worst<0 or result.completed<data.stats.worst: data.stats.worst=result.completed
 if result.mode=="adventure":
  data.stats.adventure_attempts+=1
  data.stats.adventure_best=maxi(data.stats.adventure_best,result.completed)
 var stored=result.duplicate(true)
 stored.gems=gems
 data.stats.last=stored
 data.claimed.append(result.id)
 if data.claimed.size()>128: data.claimed.pop_front()
 if commit(): return gems
 data=before
 return -1

func reset() -> bool:
 var old=data.duplicate(true)
 data=defaults()
 if commit(): return true
 data=old
 return false
