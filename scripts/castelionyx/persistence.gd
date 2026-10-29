class_name CxPersistence
extends RefCounted

const PATH="user://castelionyx_v1.json"
var data:Dictionary={}
var last_error=""

func _init() -> void:
 load_data()

static func defaults() -> Dictionary:
 return {"version":2,"profile":{},"gems":0,"selected":0,"heroes":[1,0,0,0,0,0],"towers":[1,1,1,1,1,1,0],"spells":[1,1,1,1,1],"settings":{"music":0.32,"sfx":0.45,"ui":0.35,"speed":1,"quality":true},"stats":{"total":0,"waves":0,"bosses":0,"time":0.0,"best":0,"worst":-1,"last":{},"adventure_best":0,"adventure_attempts":0,"adventure_claimed":false,"adventure_wins":0,"adventure_extra":0},"player_level":0,"exclusive":{"coin_generator":false,"sky_ballista":false,"barrier_realm":false,"meteor_plus":false,"gem_mine":false,"second_hero_slot":false,"giant_hunter_cosmetic":false},"events":{"survivor_no_army":{"progress":0,"goal":50,"complete":false,"reward_claimed":false},"sky_falls":{"progress":0,"goal":35,"complete":false,"reward_claimed":false},"last_hope":{"progress":0,"goal":25,"complete":false,"reward_claimed":false},"mutant_plague":{"progress":0,"goal":40,"complete":false,"reward_claimed":false},"scarcity_master":{"progress":0,"goal":30,"complete":false,"reward_claimed":false},"extra_hero":{"progress":0,"goal":50,"complete":false,"reward_claimed":false}},"claimed":[]}

static func clean_number(value:Variant,fallback:float,minimum:float,maximum:float) -> float:
 if not (value is int or value is float): return fallback
 if not is_finite(float(value)): return fallback
 return clampf(float(value),minimum,maximum)

static func valid_email(value:String) -> bool:
 var email=value.strip_edges()
 var at=email.find("@")
 var dot=email.rfind(".")
 return email.length()>=6 and at>0 and dot>at+1 and dot<email.length()-1 and email.find(" ")<0

static func validate(candidate:Variant) -> Dictionary:
 var result=defaults()
 if not candidate is Dictionary: return result
 var c:Dictionary=candidate
 if int(clean_number(c.get("version",1),1,0,100))>2: return result
 var profile=c.get("profile",{})
 if profile is Dictionary and not str(profile.get("name","")).strip_edges().is_empty():
  var saved_email=str(profile.get("email",profile.get("country",""))).strip_edges().left(120)
  result.profile={"name":str(profile.name).replace("\n"," ").replace("\r"," ").strip_edges().left(24),"email":saved_email if valid_email(saved_email) else "","avatar":int(clean_number(profile.get("avatar",0),0,0,7)),"photo":str(profile.get("photo","")).left(160000)}
 result.gems=int(clean_number(c.get("gems",0),0,0,99999999))
 result["player_level"]=int(clean_number(c.get("player_level",0),0,0,9999))
 if c.get("events",{}) is Dictionary: result["events"]=c.get("events",{}).duplicate(true)
 if c.get("exclusive",{}) is Dictionary:
  for key in result.exclusive: result.exclusive[key]=c.get("exclusive",{}).get(key,false)==true
 for key in ["heroes","towers","spells"]:
  var values=c.get(key,[])
  if values is Array:
   for i in range(mini(values.size(),result[key].size())):
    result[key][i]=int(clean_number(values[i],result[key][i],0 if key=="heroes" or (key=="towers" and i==6) else 1,10))
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
  for key in ["total","waves","bosses","best","adventure_best","adventure_attempts","adventure_wins","adventure_extra"]: result.stats[key]=int(clean_number(stats.get(key,0),0,0,9999999))
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
 return not str(data.profile.get("name","")).strip_edges().is_empty() and valid_email(str(data.profile.get("email","")))

func profile(name:String,country:String,avatar:int,photo:String="") -> bool:
 if name.strip_edges().is_empty(): last_error="Digite seu nome ou apelido."; return false
 if not valid_email(country): last_error="Digite um e-mail válido para salvar o perfil."; return false
 var old=data.duplicate(true)
 data.profile={"name":name.strip_edges().replace("\n"," ").left(24),"email":country.strip_edges().left(120),"avatar":clampi(avatar,0,7),"photo":photo.left(160000)}
 if commit(): return true
 data=old
 return false

func buy(kind:String,index:int) -> bool:
 if not kind in ["heroes","towers","spells"]: return false
 if index<0 or index>=data[kind].size(): return false
 var level=int(data[kind][index])
 if level>=10: return false
 if level==0 and index>0 and int(data[kind][index-1])<=0: return false
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
 var base=3600.0*pow(1.17,level)
 return clampi(int(round(base*pow(1.22,index))),3600,88000)

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
 var adventure_attempt=int(data.stats.adventure_wins)
 if result.mode=="adventure" and result.victory:
  gems=1000 if adventure_attempt==0 else 6742 if adventure_attempt==9 and result.completed==10 and result.time<1500.0 else 500
 if result.mode=="adventure" and result.victory and result.completed==5 and not data.stats.adventure_claimed:
  data.stats.adventure_claimed=true
 data.gems+=gems
 data.stats.total+=1
 data.stats.waves+=result.completed
 data.stats.bosses+=result.bosses
 data.stats.time+=result.time
 data.player_level=int(floor(float(data.stats.waves)/100.0))
 data.stats.best=maxi(data.stats.best,result.completed)
 if data.stats.worst<0 or result.completed<data.stats.worst: data.stats.worst=result.completed
 if result.mode=="adventure":
  data.stats.adventure_attempts+=1
  data.stats.adventure_best=maxi(data.stats.adventure_best,result.completed)
  if result.victory:
   data.stats.adventure_wins+=1
  data.stats.adventure_extra=(data.stats.adventure_wins-1)*10
 update_events(result)
 claim_event_rewards(result)
 var stored=result.duplicate(true)
 stored.gems=gems
 data.stats.last=stored
 data.claimed.append(result.id)
 if data.claimed.size()>128: data.claimed.pop_front()
 if commit(): return gems
 data=before
 return -1

func update_events(result:Dictionary) -> void:
 if result.mode!="infinite": return
 var conditions={
  "survivor_no_army": modifiers_match(result,"reduced","nohero"),
  "sky_falls": modifiers_match(result,"aerial","reduced"),
  "last_hope": modifiers_match(result,"wall","economy"),
  "mutant_plague": modifiers_match(result,"mutants","aerial"),
  "scarcity_master": modifiers_match(result,"reduced","economy","nohero"),
  "extra_hero": modifiers_match(result,"wall","mutants")
 }
 var ids=conditions.keys()
 for id in ids:
  if not data.events.has(id): continue
  var e:Dictionary=data.events[id]
  if conditions[id]: e.progress=maxi(int(e.progress),int(result.completed))
  if int(e.progress)>=int(e.goal): e.complete=true
  data.events[id]=e

func modifiers_match(result:Dictionary,a:String,b:String,c:String="") -> bool:
 var mods=result.get("modifiers",[])
 return mods is Array and mods.has(a) and mods.has(b) and (c.is_empty() or mods.has(c))


func claim_event_rewards(result:Dictionary) -> void:
 if result.mode!="infinite": return
 var rules={"survivor_no_army":[50,"coin_generator"],"sky_falls":[35,"sky_ballista"],"last_hope":[25,"barrier_realm"],"mutant_plague":[40,"meteor_plus"],"scarcity_master":[30,"gem_mine"],"extra_hero":[50,"second_hero_slot"]}
 for id in rules:
  if not data.events.has(id) or not data.events[id].complete or data.exclusive[rules[id][1]]: continue
  data.exclusive[rules[id][1]]=true
  data.events[id].reward_claimed=true
  if id=="last_hope": data.gems+=250
  if id=="scarcity_master": data.gems+=500
  if id=="sky_falls": data.gems+=300
  if id=="extra_hero": data.gems+=400

func reset() -> bool:
 var old=data.duplicate(true)
 data=defaults()
 if commit(): return true
 data=old
 return false
