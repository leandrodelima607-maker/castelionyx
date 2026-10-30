class_name CxPersistence
extends RefCounted

const PATH="user://castelionyx_v1.json"
var data:Dictionary={}
var last_error=""

func _init() -> void:
 load_data()

static func defaults() -> Dictionary:
 return {"version":4,"profile":{},"gems":0,"selected":0,"selected_heroes":[0],"heroes":[1,0,0,0,0,0,0],"towers":[1,1,0,0,0,0,0,0,0],"spells":[1,0,0,0,0,0],"settings":{"music":0.32,"sfx":0.45,"ui":0.35,"speed":1,"quality":true},"stats":{"total":0,"waves":0,"kills":0,"bosses":0,"time":0.0,"best":0,"worst":-1,"last":{},"adventure_best":0,"adventure_attempts":0,"adventure_claimed":false,"adventure_wins":0,"adventure_extra":0,"modes":{"boss":{"total":0,"waves":0,"bosses":0,"time":0.0,"best":0,"worst":-1,"last":{}},"extreme":{"total":0,"waves":0,"bosses":0,"time":0.0,"best":0,"worst":-1,"last":{}}}},"player_level":0,"exclusive":{"coin_generator":false,"sky_ballista":false,"barrier_realm":false,"meteor_plus":false,"gem_mine":false,"second_hero_slot":false,"giant_hunter_cosmetic":false,"arcane_sentinel":false,"boss_mode_unlocked":false,"extreme_mode_unlocked":false},"events":{"first_fortune":{"progress":0,"goal":100,"complete":false,"reward_claimed":false},"survivor_no_army":{"progress":0,"goal":50,"complete":false,"reward_claimed":false},"sky_falls":{"progress":0,"goal":35,"complete":false,"reward_claimed":false},"last_hope":{"progress":0,"goal":25,"complete":false,"reward_claimed":false},"mutant_plague":{"progress":0,"goal":40,"complete":false,"reward_claimed":false},"scarcity_master":{"progress":0,"goal":30,"complete":false,"reward_claimed":false},"extra_hero":{"progress":0,"goal":50,"complete":false,"reward_claimed":false}},"claimed":[]}

static func clean_number(value:Variant,fallback:float,minimum:float,maximum:float) -> float:
 if not (value is int or value is float): return fallback
 if not is_finite(float(value)): return fallback
 return clampf(float(value),minimum,maximum)

static func valid_email(value:String) -> bool:
 var email=value.strip_edges()
 if email.length()<6 or email.length()>120: return false
 var pattern=RegEx.new()
 if pattern.compile("^[^\\s@]+@[^\\s@]+\\.[^\\s@]{2,}$")!=OK: return false
 return pattern.search(email)!=null

static func validate(candidate:Variant) -> Dictionary:
 var result=defaults()
 if not candidate is Dictionary: return result
 var c:Dictionary=candidate
 if int(clean_number(c.get("version",1),1,0,100))>4: return result
 var profile=c.get("profile",{})
 if profile is Dictionary and not str(profile.get("name","")).strip_edges().is_empty():
  var saved_email=str(profile.get("email",profile.get("country",""))).strip_edges().left(120)
  result.profile={"name":str(profile.name).replace("\n"," ").replace("\r"," ").strip_edges().left(24),"email":saved_email if valid_email(saved_email) else "","avatar":int(clean_number(profile.get("avatar",0),0,0,7)),"photo":str(profile.get("photo","")).left(160000)}
 result.gems=int(clean_number(c.get("gems",0),0,0,99999999))
 for key in ["heroes","towers","spells"]:
  var values=c.get(key,[])
  if values is Array:
   for i in range(mini(values.size(),result[key].size())):
    var minimum=0 if key=="heroes" or (key=="towers" and i>=6) or (key=="spells" and i>=1) else 1
    result[key][i]=int(clean_number(values[i],result[key][i],minimum,4))
 result.heroes[0]=maxi(1,result.heroes[0])
 if c.get("exclusive",{}) is Dictionary:
  for key in result.exclusive:
   result.exclusive[key]=c.get("exclusive",{}).get(key,false)==true
 var stats=c.get("stats",{})
 if stats is Dictionary:
  for key in ["total","waves","kills","bosses","best","adventure_best","adventure_attempts","adventure_wins","adventure_extra"]:
   result.stats[key]=int(clean_number(stats.get(key,0),0,0,9999999))
  result.stats.worst=int(clean_number(stats.get("worst",-1),-1,-1,9999999))
  result.stats.time=clean_number(stats.get("time",0),0,0,999999999)
  result.stats.adventure_claimed=stats.get("adventure_claimed",false)==true
  if stats.get("last",{}) is Dictionary: result.stats.last=stats.get("last",{}).duplicate(true)
  var saved_modes=stats.get("modes",{})
  if saved_modes is Dictionary:
   for mode_id in ["boss","extreme"]:
    var saved_mode=saved_modes.get(mode_id,{})
    if saved_mode is Dictionary:
     for key in ["total","waves","bosses","best"]:
      result.stats.modes[mode_id][key]=int(clean_number(saved_mode.get(key,0),0,0,9999999))
     result.stats.modes[mode_id].worst=int(clean_number(saved_mode.get("worst",-1),-1,-1,9999999))
     result.stats.modes[mode_id].time=clean_number(saved_mode.get("time",0),0,0,999999999)
     if saved_mode.get("last",{}) is Dictionary: result.stats.modes[mode_id].last=saved_mode.get("last",{}).duplicate(true)
 result.player_level=int(floor(float(result.stats.waves)/100.0))
 result.exclusive.boss_mode_unlocked=result.exclusive.boss_mode_unlocked or result.player_level>=5
 result.exclusive.extreme_mode_unlocked=result.exclusive.extreme_mode_unlocked or result.player_level>=24
 var raw_events=c.get("events",{})
 if raw_events is Dictionary:
  for event_id in result.events:
   var ev=raw_events.get(event_id,{})
   if not ev is Dictionary: continue
   var goal=int(result.events[event_id].goal)
   var progress=int(clean_number(ev.get("progress",0),0,0,9999999))
   result.events[event_id]={"progress":mini(progress,goal),"goal":goal,"complete":ev.get("complete",false)==true or progress>=goal,"reward_claimed":ev.get("reward_claimed",false)==true}
 var selected=int(clean_number(c.get("selected",0),0,0,result.heroes.size()-1))
 var selected_list=c.get("selected_heroes",[selected])
 if not selected_list is Array: selected_list=[selected]
 var choices:Array=[]
 for value in selected_list:
  var hero_id=int(clean_number(value,-1,-1,result.heroes.size()-1))
  if hero_id>=0 and result.heroes[hero_id]>0 and not choices.has(hero_id): choices.append(hero_id)
 if choices.is_empty(): choices=[0]
 if not result.exclusive.second_hero_slot: choices=choices.slice(0,1)
 else: choices=choices.slice(0,2)
 result.selected_heroes=choices
 result.selected=int(choices[0])
 var settings=c.get("settings",{})
 if settings is Dictionary:
  for key in ["music","sfx","ui"]: result.settings[key]=clean_number(settings.get(key,result.settings[key]),result.settings[key],0,1)
  result.settings.speed=2 if settings.get("speed",1)==2 else 1
  result.settings.quality=settings.get("quality",true)==true
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

func profile(name:String,email:String,avatar:int,photo:String="") -> bool:
 if name.strip_edges().is_empty(): last_error="Digite seu nome ou apelido."; return false
 if not valid_email(email): last_error="Digite um e-mail válido para salvar o perfil."; return false
 var old=data.duplicate(true)
 data.profile={"name":name.strip_edges().replace("\n"," ").left(24),"email":email.strip_edges().left(120),"avatar":clampi(avatar,0,7),"photo":photo.left(160000)}
 if commit(): return true
 data=old
 return false

func buy(kind:String,index:int) -> bool:
 if not kind in ["heroes","towers","spells"]: return false
 if index<0 or index>=data[kind].size(): return false
 var level=int(data[kind][index])
 if level>=4: return false
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
 return CxCatalog.purchase_cost(kind,index,int(data[kind][index]))

func select_hero(index:int,slot:int=0) -> bool:
 if index<0 or index>=data.heroes.size() or data.heroes[index]<=0: return false
 if slot<0 or slot>1 or (slot==1 and not data.exclusive.second_hero_slot): return false
 var old=data.duplicate(true)
 var choices:Array=data.selected_heroes.duplicate()
 while choices.size()<=slot: choices.append(-1)
 if slot==1 and choices[0]==index: return false
 choices[slot]=index
 if slot==0 and choices.size()>1 and choices[1]==index: choices.remove_at(1)
 choices=choices.filter(func(x): return int(x)>=0)
 data.selected_heroes=choices.slice(0,2 if data.exclusive.second_hero_slot else 1)
 data.selected=int(data.selected_heroes[0])
 if commit(): return true
 data=old
 return false

func record(result:Dictionary) -> int:
 var run_id=str(result.get("id",""))
 if run_id.is_empty() or data.claimed.has(run_id): return 0
 var before=data.duplicate(true)
 var mode_id=str(result.get("mode","infinite"))
 var completed=int(result.get("completed",0))
 var gems=0
 if mode_id=="infinite": gems=int(floor(float(completed)/10.0))
 elif mode_id=="boss": gems=int(floor(float(completed)/5.0))
 elif mode_id=="extreme": gems=int(floor(float(completed)/5.0))*2
 var adventure_attempt=int(data.stats.adventure_wins)
 if mode_id=="adventure" and result.get("victory",false):
  gems=1000 if adventure_attempt==0 else 6742 if adventure_attempt==9 and completed==10 and float(result.get("time",0.0))<1500.0 else 500
 if mode_id=="adventure" and result.get("victory",false) and completed==5 and not data.stats.adventure_claimed:
  data.stats.adventure_claimed=true
 data.gems+=gems+int(result.get("gem_mine_unpaid",result.get("gem_mine_gems",0)))
 data.stats.total+=1
 if mode_id=="infinite":
  data.stats.waves+=completed
  data.stats.kills+=int(result.get("kills",0))
  data.stats.best=maxi(data.stats.best,completed)
  if data.stats.worst<0 or completed<data.stats.worst: data.stats.worst=completed
  data.player_level=int(floor(float(data.stats.waves)/100.0))
  if data.player_level>=5: data.exclusive.boss_mode_unlocked=true
  if data.player_level>=24: data.exclusive.extreme_mode_unlocked=true
 if mode_id in ["boss","extreme"]:
  var mode_stats:Dictionary=data.stats.modes[mode_id]
  mode_stats.total+=1
  mode_stats.waves+=completed
  mode_stats.bosses+=int(result.get("bosses",0))
  mode_stats.time+=float(result.get("time",0.0))
  mode_stats.best=maxi(mode_stats.best,completed)
  if mode_stats.worst<0 or completed<mode_stats.worst: mode_stats.worst=completed
 if mode_id!="adventure" or result.get("victory",false): data.stats.bosses+=int(result.get("bosses",0))
 data.stats.time+=float(result.get("time",0.0))
 if mode_id=="adventure":
  data.stats.adventure_attempts+=1
  data.stats.adventure_best=maxi(data.stats.adventure_best,completed)
  if result.get("victory",false): data.stats.adventure_wins+=1
  data.stats.adventure_extra=(data.stats.adventure_wins-1)*10
 update_events(result)
 var stored=result.duplicate(true)
 stored.gems=gems
 data.stats.last=stored
 if mode_id in ["boss","extreme"]: data.stats.modes[mode_id].last=stored.duplicate(true)
 data.claimed.append(run_id)
 if data.claimed.size()>128: data.claimed.pop_front()
 if commit(): return gems
 data=before
 return -1

func update_events(result:Dictionary) -> void:
 if str(result.get("mode",""))!="infinite": return
 var conditions={"survivor_no_army":modifiers_match(result,"reduced","nohero"),"sky_falls":modifiers_match(result,"aerial","reduced"),"last_hope":modifiers_match(result,"wall","economy"),"mutant_plague":modifiers_match(result,"mutants","aerial"),"scarcity_master":modifiers_match(result,"reduced","economy","nohero"),"extra_hero":modifiers_match(result,"wall","mutants")}
 for event_id in conditions:
  var e:Dictionary=data.events[event_id]
  if conditions[event_id]: e.progress=maxi(int(e.progress),int(result.get("completed",0)))
  e.complete=int(e.progress)>=int(e.goal)
  data.events[event_id]=e
 var fortune:Dictionary=data.events.first_fortune
 fortune.progress=mini(int(fortune.goal),int(fortune.progress)+int(result.get("kills",0)))
 fortune.complete=int(fortune.progress)>=int(fortune.goal)
 data.events.first_fortune=fortune
 claim_event_rewards()

func modifiers_match(result:Dictionary,a:String,b:String,c:String="") -> bool:
 var mods=result.get("modifiers",[])
 return mods is Array and mods.has(a) and mods.has(b) and (c.is_empty() or mods.has(c))

func claim_event_rewards() -> void:
 var rewards={"first_fortune":"coin_generator","survivor_no_army":"arcane_sentinel","sky_falls":"sky_ballista","last_hope":"barrier_realm","mutant_plague":"meteor_plus","scarcity_master":"gem_mine","extra_hero":"second_hero_slot"}
 for event_id in rewards:
  if not data.events.has(event_id) or not data.events[event_id].complete or data.events[event_id].reward_claimed: continue
  data.exclusive[rewards[event_id]]=true
  data.events[event_id].reward_claimed=true
  if event_id=="first_fortune": data.towers[6]=1
  elif event_id=="survivor_no_army": data.heroes[6]=1
  elif event_id=="sky_falls": data.towers[7]=1
  elif event_id=="last_hope": data.spells[5]=1
  elif event_id=="scarcity_master": data.towers[8]=1
  if event_id=="survivor_no_army": data.heroes[6]=1
  elif event_id=="sky_falls": data.towers[7]=1
  elif event_id=="last_hope": data.spells[5]=1
  elif event_id=="scarcity_master": data.towers[8]=1

func reset() -> bool:
 var old=data.duplicate(true)
 data=defaults()
 if commit(): return true
 data=old
 return false
