class_name CxBattle
extends RefCounted

var map_index=0
var mode="infinite"
var modifiers:Array=[]
var progression:Dictionary={}
var state="preparation"
var paused=false
var speed=1
var wave=0
var completed=0
var bosses=0
var hp=300.0
var max_hp=300.0
var gold=425
var earned=0
var elapsed=0.0
var prep=7.0
var queue:Array=[]
var spawn_clock=0.0
var enemies:Array=[]
var towers:Array=[]
var allies:Array=[]
var projectiles:Array=[]
var effects:Array=[]
var events:Array=[]
var pads:Array=[]
var spells:Array=[0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0]
var special_cd=0.0
var barrier=0.0
var barrier_reduction=0.2
var hero_target=Vector2(810,310)
var next_id=1
var terminal:Dictionary={}
var run_id=""
var previous_boss=false
var special_defeat=false
var special_horde_clock=0.0
var adventure_wins=0
var adventure_extra=0
var gem_earned=0
var rng=RandomNumberGenerator.new()
var ground_routes:Array=[]
var aerial_route:Array=[]
var thorn_walls:Array=[]
var build_locked=false
var allowed_spells:Array=[]
var selected_hero_override=-1

func _init(which_map:int=0,which_mode:String="infinite",mods:Array=[],progress:Dictionary={}) -> void:
 map_index=clampi(which_map,0,3)
 mode=which_mode
 modifiers=mods.duplicate()
 progression=CxPersistence.validate(progress)
 adventure_wins=int(progression.stats.get("adventure_wins",0))
 adventure_extra=int(progression.stats.get("adventure_extra",0))
 speed=int(progression.settings.speed)
 rng.seed=Time.get_ticks_usec()+map_index*137
 run_id="%s-%d-%d" % [str(Time.get_unix_time_from_system()),Time.get_ticks_usec(),rng.randi()]
 prepare_layout()
 var wanted=5 if mode=="adventure" else 10
 if modifiers.has("reduced") and mode!="adventure": wanted=maxi(5,int(ceil(float(wanted)/2.0)))
 pads=valid_pads(wanted)
 if mode=="boss67": max_hp=1.0
 if mode=="swarm12": max_hp=600.0
 if modifiers.has("wall"): max_hp=150.0
 hp=max_hp
 if modifiers.has("economy"): gold=300
 if mode=="adventure": gold=540
 if mode=="buildout":
  gold=9999
  prep=999999.0
  allowed_spells=[]
 if mode=="swarm12": allowed_spells=[]
 for i in range(pads.size()): towers.append(null)
 create_heroes()

func prepare_layout() -> void:
 ground_routes=[]
 for route in CxCatalog.MAPS[map_index].ground:
  var variant:Array=[]
  for i in range(route.size()):
   var point:Vector2=route[i]
   if i>0 and i<route.size()-1:
    point+=Vector2(rng.randf_range(-24.0,24.0),rng.randf_range(-22.0,22.0))
    point=Vector2(clampf(point.x,40.0,900.0),clampf(point.y,70.0,500.0))
   variant.append(point)
  ground_routes.append(variant)
 aerial_route=[]
 for i in range(CxCatalog.MAPS[map_index].air.size()):
  var air_point:Vector2=CxCatalog.MAPS[map_index].air[i]
  if i>0 and i<CxCatalog.MAPS[map_index].air.size()-1:
   air_point+=Vector2(rng.randf_range(-28.0,28.0),rng.randf_range(-18.0,18.0))
  aerial_route.append(air_point)

func valid_pads(wanted:int) -> Array:
 var candidates=CxCatalog.MAPS[map_index].pads.duplicate()
 candidates.shuffle()
 var chosen:Array=[]
 for candidate in candidates:
  var clear=true
  for route in ground_routes:
   for i in range(1,route.size()):
    if candidate.distance_to(Geometry2D.get_closest_point_to_segment(candidate,route[i-1],route[i]))<43.0: clear=false
  for other in chosen:
   if candidate.distance_to(other)<64.0: clear=false
  if clear: chosen.append(candidate)
  if chosen.size()>=wanted: break
 if chosen.size()<wanted:
  for candidate in candidates:
   if not chosen.has(candidate): chosen.append(candidate)
   if chosen.size()>=wanted: break
 return chosen.slice(0,wanted)

func new_id() -> int:
 var value=next_id
 next_id+=1
 return value

func create_heroes() -> void:
 if modifiers.has("nohero") or mode in ["adventure","buildout"]: return
 var selected=[selected_hero_override if selected_hero_override>=0 else int(progression.selected)]
 if selected_hero_override<0 and progression.exclusive.get("second_hero_slot",false) and progression.selected_heroes is Array and progression.selected_heroes.size()>1 and int(progression.selected_heroes[1])>=0:
  selected.append(int(progression.selected_heroes[1]))
 for index in selected:
  var d=CxCatalog.hero(index,maxi(1,int(progression.heroes[index])))
  for twin in range(2 if index==2 else 1):
   var p=hero_target+Vector2(0,(selected.find(index)*42)+twin*28)
   allies.append({"id":new_id(),"kind":"hero","hero":index,"sprite":d.sprite+twin,"pos":p,"hp":d.hp,"max_hp":d.hp,"shield":0.0,"damage":d.damage,"interval":d.interval,"range":d.range,"speed":d.speed,"armor":d.armor,"air":d.air,"attack":0.0,"anim":0.0,"hit":0.0,"life":-1.0,"respawn":0.0,"owner":-1,"combo":0.0,"arcane_target":-1,"arcane_hits":0})

func set_hero_override(index:int) -> void:
 selected_hero_override=index
 allies.clear()
 create_heroes()

func set_swarm_loadout(hero_index:int,spell_indices:Array) -> bool:
 if mode!="swarm12" or spell_indices.size()!=3: return false
 var unique:Array=[]
 for spell_index in spell_indices:
  var value=int(spell_index)
  if value<0 or value>=progression.spells.size() or progression.spells[value]<=0 or unique.has(value): return false
  unique.append(value)
 if hero_index<0 or hero_index>=progression.heroes.size() or progression.heroes[hero_index]<=0: return false
 allowed_spells=unique
 set_hero_override(hero_index)
 return true

func hero_allowed() -> bool:
 return not modifiers.has("nohero") and mode!="adventure"

func start_wave() -> bool:
 if state!="preparation" or hp<=0.0: return false
 wave+=1
 if mode=="buildout": build_locked=true
 spawn_clock=0.0
 queue=wave_schedule(wave)
 state="combat"
 events.append({"type":"wave","wave":wave})
 return true

func wave_schedule(number:int) -> Array:
 var result:Array=[]
 if mode=="boss67":
  return [{"kind":(number-1)%CxCatalog.BOSSES.size(),"boss":true,"route":0,"final":number==67}]
 if mode=="swarm12":
  var swarm_count=mini(4096,10*int(pow(2.0,number-1)))
  for i in range(swarm_count): result.append({"kind":0,"boss":false,"route":i%ground_routes.size()})
  return result
 if mode=="buildout" and number>101: return []
 var count=6+number*2
 if map_index==1: count=int(ceil(count*1.25))
 if modifiers.has("reduced"): count=int(ceil(count*1.25))
 count=mini(count,100)
 if mode=="adventure": count=([24,25,24,16,14][clampi(number-1,0,4)]+adventure_extra) if adventure_wins<9 else (18+adventure_extra)
 for i in range(count):
  var kind=0
  if number>=2 and i%4==1: kind=1
  if number>=4 and i%5==2: kind=2
  if number>=3 and i%6==3: kind=3
  if number>=6 and i%7==4: kind=4
  if number>=7 and i%7==5: kind=5
  if number>=9 and i%8==6: kind=6
  if map_index==2 and i%3==0: kind=3
  if modifiers.has("aerial") and i%3==0: kind=3
  if modifiers.has("mutants") and i%4==0: kind=6
  if modifiers.has("extreme") and i%2==0: kind=6
  if mode=="adventure":
   if number==1: kind=0
   if number==2: kind=1
   if number==3: kind=3 if i%2==0 else 2
   if number==4: kind=5 if i%2==0 else 2
   if number==5: kind=[2,3,5,6][i%4]
  result.append({"kind":kind,"boss":false,"route":i%ground_routes.size()})
 if number%10==0 and mode=="infinite": result.insert(int(count/2.0),{"kind":int(number/10.0-1)%4,"boss":true,"route":0})
 if modifiers.has("boss_challenge") and number%5==0: result.insert(int(count/3.0),{"kind":int(number/5.0-1)%CxCatalog.BOSSES.size(),"boss":true,"route":0})
 if mode=="adventure" and adventure_wins<9 and number==5: result.append({"kind":3,"boss":true,"route":0,"final":true})
 if mode=="adventure" and adventure_wins>=9:
  result.insert(mini(result.size(),2),{"kind":(number-1)%4,"boss":true,"route":0,"final":number==10})
  if number==10:
   for boss_kind in range(5): result.append({"kind":boss_kind%4,"boss":true,"route":boss_kind%ground_routes.size(),"final":true})
 return result

func spawn_enemy(spec:Dictionary) -> Dictionary:
 var d=(CxCatalog.BOSSES[spec.kind] if spec.get("boss",false) else CxCatalog.ENEMIES[spec.kind]).duplicate(true)
 var tier=maxi(0,wave-1)
 var factor=1.0+0.11*tier+0.004*tier*tier
 if mode=="adventure": factor=[0.7,1.1,1.4,1.6,1.55][clampi(wave-1,0,4)]
 if spec.get("boss",false) and mode=="infinite": factor=1.0+0.3*maxi(0,int(wave/10.0)-1)
 if modifiers.has("extreme"): factor*=1.35
 if spec.get("final",false): d.hp=1900.0
 var route=aerial_route if d.air else ground_routes[spec.get("route",0)%ground_routes.size()]
 if mode=="adventure" and adventure_wins>=9:
  factor*=1.1 if not spec.get("boss",false) else 1.19
 var enemy={"uid":new_id(),"kind":d.id,"name":d.name,"sprite":d.sprite,"hp":d.hp*factor,"max_hp":d.hp*factor,"damage":d.damage*(1.0+0.04*tier)*(1.39 if mode=="adventure" and adventure_wins>=9 and spec.get("boss",false) else 1.1 if mode=="adventure" and adventure_wins>=9 else 1.0),"speed":d.speed*minf(1.65,1.0+0.008*tier)*(1.1 if mode=="adventure" and adventure_wins>=9 else 1.0),"reward":d.reward,"armor":d.armor,"air":d.air,"boss":spec.get("boss",false),"final":spec.get("final",false),"phase":1,"path":route,"distance":0.0,"pos":route[0],"freeze":0.0,"immune":0.0,"slow":0.0,"expose":0.0,"hit":0.0,"anim":0.0,"attack":0.0,"special":7.0,"telegraph":0.0,"regen_block":0.0,"dead":false,"shell":42.0 if d.id=="mutant" else 0.0,"dash":0.0}
 enemies.append(enemy)
 if enemy.boss:
  events.append({"type":"boss","name":enemy.name})
  burst(enemy.pos,"boss",50.0)
 return enemy

func advance(delta:float) -> void:
 if paused or state=="finished": return
 var remaining=clampf(delta,0.0,0.25)*speed
 while remaining>0.00001:
  var dt=minf(remaining,1.0/60.0)
  tick(dt)
  remaining-=dt
  if state=="finished": break

func tick(dt:float) -> void:
 if state=="finished": return
 elapsed+=dt
 if mode=="adventure" and adventure_wins>=9 and elapsed>=1500.0 and not special_defeat:
  special_defeat=true
  special_horde_clock=12.0
  events.append({"type":"special_defeat_start"})
  for i in range(28): queue.append({"kind":i%7,"boss":false,"route":i%ground_routes.size()})
  state="combat"
 if special_defeat:
  special_horde_clock-=dt
  if special_horde_clock<=0.0:
   hp=0.0
 barrier=maxf(0.0,barrier-dt)
 special_cd=maxf(0.0,special_cd-dt)
 for i in range(spells.size()): spells[i]=maxf(0.0,spells[i]-dt)
 update_effects(dt)
 if state=="preparation":
  prep-=dt
  if prep<=0.0: start_wave()
 if state=="combat":
  spawn_clock-=dt
  if not queue.is_empty() and spawn_clock<=0.0:
   spawn_enemy(queue.pop_front())
   spawn_clock=maxf(0.25,0.9-wave*0.018)
 update_towers(dt)
 update_allies(dt)
 update_enemies(dt)
 update_projectiles(dt)
 enemies=enemies.filter(func(e): return not e.dead)
 allies=allies.filter(func(a): return a.kind=="hero" or (a.hp>0.0 and a.life>0.0))
 for wall in thorn_walls: wall.life-=dt
 thorn_walls=thorn_walls.filter(func(w): return w.life>0.0 and w.hp>0.0)
 if hp<=0.0:
  finish(false)
  return
 if state=="combat" and queue.is_empty() and enemies.is_empty():
  completed=wave
  gold+=35+wave*2
  earned+=35+wave*2
  if (mode=="adventure" and ((adventure_wins<9 and wave==5) or (adventure_wins>=9 and wave==10))) or (mode=="boss67" and wave==67) or (mode=="buildout" and wave==101) or (mode=="swarm12" and wave==12):
   finish(true)
  else:
   state="preparation"
   prep=7.0
   events.append({"type":"complete","wave":wave})

func find_enemy(uid:int) -> Variant:
 for e in enemies:
  if e.uid==uid and not e.dead and e.hp>0.0: return e
 return null

func target_at(point:Vector2,radius:float,air:bool) -> Variant:
 var best=null
 var best_score=-INF
 for e in enemies:
  if e.dead or (e.air and not air) or point.distance_to(e.pos)>radius: continue
  var score=e.distance+(400.0 if e.boss else 0.0)+(150.0 if e.kind=="gunner" else 0.0)
  if score>best_score:
   best=e
   best_score=score
 return best

func build(slot:int,kind:int) -> bool:
 if state=="finished" or paused or slot<0 or slot>=towers.size() or towers[slot]!=null or kind<0 or kind>=CxCatalog.TOWERS.size(): return false
 if mode in ["boss67","swarm12"] or (mode=="buildout" and build_locked): return false
 if mode=="adventure" and kind not in [0,1]: return false
 if kind>=progression.towers.size() or progression.towers[kind]<=0: return false
 if kind==6 and not progression.exclusive.get("coin_generator",false): return false
 if kind==7 and not progression.exclusive.get("sky_ballista",false): return false
 if kind==8 and not progression.exclusive.get("gem_mine",false): return false
 var d=CxCatalog.tower(kind,1,progression.towers[kind])
 if mode=="buildout": d.range*=1.25
 var cost=d.cost
 if d.get("economic",false): cost=13
 if kind==7: cost=180
 if kind==8: cost=250
 if kind==11: cost=1700
 if gold<cost: return false
 gold-=cost
 towers[slot]={"id":new_id(),"kind":kind,"level":1,"pos":pads[slot],"hp":d.hp,"max_hp":d.hp,"attack":0.3,"anim":0.0,"hit":0.0,"buff":false,"prod":d.interval,"shots":0}
 events.append({"type":"build"})
 burst(pads[slot],"build",35)
 return true

func upgrade(slot:int) -> bool:
 if state=="finished" or paused or slot<0 or slot>=towers.size() or towers[slot]==null: return false
 var t=towers[slot]
 if t.level>=3: return false
 var cost=CxCatalog.upgrade_cost(t.kind,t.level)
 if gold<cost: return false
 gold-=cost
 t.level+=1
 var d=CxCatalog.tower(t.kind,t.level,progression.towers[t.kind])
 if mode=="buildout": d.range*=1.25
 t.hp+=d.hp-t.max_hp
 t.max_hp=d.hp
 burst(t.pos,"upgrade",45)
 events.append({"type":"upgrade"})
 return true

func sell(slot:int) -> bool:
 if state=="finished" or paused or slot<0 or slot>=towers.size() or towers[slot]==null: return false
 var t=towers[slot]
 gold+=int(CxCatalog.TOWERS[t.kind].cost*0.6)
 for a in allies:
  if a.owner==t.id: a.life=0.0
 towers[slot]=null
 events.append({"type":"coin"})
 return true

func support_for(t:Dictionary) -> bool:
 for other in towers:
  if other==null or other==t or other.kind!=5 or other.hp<=0.0: continue
  if t.pos.distance_to(other.pos)<=CxCatalog.tower(5,other.level).range: return true
 return false

func update_towers(dt:float) -> void:
 for t in towers:
  if t==null: continue
  if t.hp<=0.0: continue
  t.fury=maxf(0.0,t.get("fury",0.0)-dt)
  t.anim=maxf(0.0,t.anim-dt)
  t.hit=maxf(0.0,t.hit-dt)
  if t.kind==6:
   t.prod=maxf(0.0,t.get("prod",4.0)-dt)
   if t.prod<=0.0:
    gold+=1; t.prod=4.0; events.append({"type":"coin"})
   continue
  if t.kind==8:
   t.prod=maxf(0.0,t.get("prod",60.0)-dt)
   if t.prod<=0.0:
    gem_earned+=1; t.prod=60.0; events.append({"type":"gem"})
   continue
  if t.kind==11:
   t.prod=maxf(0.0,t.get("prod",5.0)-dt)
   if t.prod<=0.0:
    summon(CxCatalog.nearest_ground(map_index,t.pos),1,999999.0,t.id,t.level,true)
    for a in allies:
     if a.owner==t.id and a.life>0.0:
      a.hp=180.0+35.0*t.level; a.max_hp=a.hp; a.damage=34.0+8.0*t.level; a.range=225.0; a.interval=0.7; a.speed=125.0; a.air=true
    t.prod=5.0
   continue
  t.buff=support_for(t)
  if t.kind==9: continue
  t.attack-=dt*(1.25 if t.buff else 1.0)
  if t.attack>0.0: continue
  var d=CxCatalog.tower(t.kind,t.level,progression.towers[t.kind])
  if t.kind in [5,9]: continue
  if t.kind==4:
   var count=0
   for a in allies:
    if a.owner==t.id and a.hp>0.0 and a.life>0.0: count+=1
   if count<1+t.level:
    summon(CxCatalog.nearest_ground(map_index,t.pos),1,45.0,t.id,t.level,false)
    t.attack=d.interval
   continue
  var target=null
  if t.kind in [7,10]:
   for candidate in enemies:
    if not candidate.dead and (t.kind==10 or candidate.air) and t.pos.distance_to(candidate.pos)<=d.range:
     target=candidate
     break
  if target==null: target=target_at(t.pos,d.range*(1.15 if t.buff else 1.0),d.air)
  if target==null: continue
  t.attack=d.interval
  t.anim=0.25
  if t.kind==3:
   chain(t.pos,target.pos,d.damage,1+t.level,85.0)
  elif t.kind in [7,10]:
   t.shots=int(t.get("shots",0))+1
   if t.shots%4==0:
    var hits=0
    for candidate in enemies:
     if not candidate.dead and candidate.air and candidate.pos.distance_to(target.pos)<95.0 and hits<3:
      damage_enemy(candidate,d.damage,"arrow")
      hits+=1
    events.append({"type":"arrow"})
   else:
    fire(t.pos+Vector2(0,-24),target,d.damage,"arrow",true)
  else:
   var shot_kind="arrow" if t.kind in [0,10] else "cannon" if t.kind==1 else "ice"
   var shot_damage=d.damage*(2.0 if t.get("fury",0.0)>0.0 else 1.0)
   fire(t.pos+Vector2(0,-24),target,shot_damage,shot_kind,d.air)

func fire(point:Vector2,target:Dictionary,damage:float,kind:String,air:bool=true) -> void:
 if projectiles.size()>=256: return
 projectiles.append({"pos":point,"target":target.uid,"destination":target.pos,"damage":damage,"kind":kind,"air":air,"life":2.5,"speed":420.0 if kind=="arrow" else 285.0})
 if kind=="cannon": events.append({"type":"cannon"})
 elif kind=="arrow": events.append({"type":"arrow"})

func update_projectiles(dt:float) -> void:
 for p in projectiles:
  p.life-=dt
  var target=find_enemy(p.target)
  if target!=null: p.destination=target.pos
  p.pos=p.pos.move_toward(p.destination,p.speed*dt)
  if p.pos.distance_to(p.destination)>8.0 and p.life>0.0: continue
  p.life=0.0
  if p.kind=="cannon":
   area_damage(p.destination,58,p.damage,false)
   burst(p.destination,"explosion",58)
   events.append({"type":"explosion"})
  elif target!=null:
   damage_enemy(target,p.damage,p.kind)
   if p.kind=="ice":
    freeze_enemy(target,2.0)
    target.slow=3.0
    burst(target.pos,"ice",18)
   else: burst(target.pos,"hit",15)
 projectiles=projectiles.filter(func(p): return p.life>0.0)

func damage_enemy(e:Dictionary,amount:float,kind:String="physical") -> void:
 if e.dead or e.hp<=0.0: return
 if e.shell>0.0:
  var absorbed=minf(amount,e.shell)
  e.shell-=absorbed
  amount-=absorbed
  if e.shell<=0.0:
   e.dash=2.0
   burst(e.pos,"shell",28)
 var reduction=e.armor if kind in ["physical","arrow"] else e.armor*0.35
 e.hp-=amount*(1.35 if e.get("expose",0.0)>0.0 else 1.0)*(1.0-reduction)
 e.hit=0.16
 e.regen_block=3.0
 if e.hp<=0.0:
  e.dead=true
  var reward=int(e.reward*(0.7 if modifiers.has("economy") else 1.0))
  gold+=50
  earned+=reward
  earned+=50-reward
  events.append({"type":"coin"})
  burst(e.pos,"death",e.sprite)
  if e.boss:
   bosses+=1
   events.append({"type":"boss_down"})

func area_damage(point:Vector2,radius:float,damage:float,air:bool=true) -> void:
 for e in enemies:
  if e.dead or (e.air and not air): continue
  var distance=point.distance_to(e.pos)
  if distance<=radius: damage_enemy(e,damage*(1.0-0.3*distance/radius)*(0.75 if e.boss else 1.0),"magic")

func freeze_enemy(e:Dictionary,seconds:float) -> bool:
 if e.dead or e.immune>0.0: return false
 e.freeze=maxf(e.freeze,seconds*(0.3 if e.boss else 1.0))
 e.immune=e.freeze+3.2
 return true

func chain(origin:Vector2,point:Vector2,damage:float,hops:int,radius:float) -> void:
 var hit:Array=[]
 var at=point
 var from=origin
 for i in range(hops):
  var target=null
  var dist=INF
  for e in enemies:
   if e.dead or hit.has(e.uid): continue
   var value=at.distance_to(e.pos)
   if value<dist and value<=radius:
    target=e
    dist=value
  if target==null: break
  hit.append(target.uid)
  effects.append({"type":"bolt","from":from,"pos":target.pos,"life":0.28,"max":0.28,"radius":0.0})
  damage_enemy(target,damage*pow(0.88,i),"electric")
  from=target.pos
  at=target.pos
 events.append({"type":"lightning"})

func summon(point:Vector2,count:int,duration:float,owner:int=-1,level:int=1,magic:bool=false) -> void:
 var active=0
 for a in allies:
  if a.kind!="hero" and a.hp>0.0 and a.life>0.0: active+=1
 for i in range(mini(count,maxi(0,24-active))):
  var p=CxCatalog.nearest_ground(map_index,point+Vector2((i-1)*22,0))
  var health=(100.0+25.0*(level-1)) if not magic else 75.0
  allies.append({"id":new_id(),"kind":"summon" if magic else "guard","hero":-1,"sprite":6 if magic else 7,"pos":p,"hp":health,"max_hp":health,"shield":0.0 if magic else 55.0+15*(level-1),"damage":18.0+5*(level-1) if magic else 13.0+4*(level-1),"interval":0.85,"range":100.0 if magic else 40.0,"speed":75.0,"armor":0.1,"air":magic,"attack":0.8,"anim":0.6,"hit":0.0,"life":duration,"respawn":0.0,"owner":owner,"combo":0.0})
 burst(point,"summon",50)

func move_hero(point:Vector2) -> bool:
 if not hero_allowed() or paused or state=="finished": return false
 hero_target=CxCatalog.nearest_ground(map_index,point)
 return true

func damage_ally(a:Dictionary,amount:float) -> void:
 if a.hp<=0.0: return
 if a.shield>0.0:
  var blocked=minf(a.shield,amount)
  a.shield-=blocked
  amount-=blocked
  if a.shield<=0.0: burst(a.pos,"shell",22)
 if a.kind=="hero" and a.hero==0:
  amount*=0.7
  burst(a.pos,"block",17)
 a.hp-=amount*(1.0-a.armor)
 a.hit=0.18
 if a.hp<=0.0:
  a.respawn=18.0
  burst(a.pos,"death",a.sprite)

func update_allies(dt:float) -> void:
 for a in allies:
  a.anim=maxf(0.0,a.anim-dt)
  a.hit=maxf(0.0,a.hit-dt)
  a.combo=maxf(0.0,a.combo-dt)
  if a.kind!="hero": a.life-=dt
  if a.kind=="hero" and a.hp<=0.0:
   a.respawn-=dt
   if a.respawn<=0.0:
    a.hp=a.max_hp
    a.pos=hero_target
    burst(a.pos,"summon",35)
   continue
  if a.hp<=0.0 or (a.kind!="hero" and a.life<=0.0): continue
  if a.kind=="hero" and not hero_allowed(): continue
  a.attack-=dt*(1.9 if a.combo>0.0 else 1.0)
  var target=target_at(a.pos,a.range,a.air)
  if a.kind=="hero":
   var destination=hero_target+Vector2(0,24 if a.hero==2 and a.sprite==3 else 0)
   if a.pos.distance_to(destination)>7.0:
    a.pos=a.pos.move_toward(destination,a.speed*dt)
   elif target==null and not a.air:
    var near=target_at(a.pos,95.0,false)
    if near!=null: a.pos=a.pos.move_toward(near.pos,a.speed*dt)
  elif target==null:
   var near=target_at(a.pos,130.0,a.air)
   if near!=null: a.pos=a.pos.move_toward(near.pos,a.speed*dt)
  if target==null or a.attack>0.0: continue
  a.anim=0.23
  a.attack=a.interval
  var amount=a.damage*(1.4 if a.combo>0.0 else 1.0)
  if a.air:
   if a.hero==6:
    if target.uid==a.get("arcane_target",-1): a.arcane_hits=int(a.get("arcane_hits",0))+1
    else: a.arcane_target=target.uid; a.arcane_hits=1
    if a.arcane_hits>=5:
     amount*=2.0; a.arcane_hits=0; burst(target.pos,"rune",28)
   var weapon_kind="ice" if a.hero==4 else "magic" if a.hero==5 or a.hero==6 or a.kind=="summon" else "arrow"
   fire(a.pos+Vector2(-8,-15),target,amount*(2.0 if a.hero==12 and target.air else 1.0),weapon_kind,true)
   if a.hero==12:
    var second=target_at(a.pos+Vector2(20,0),a.range,true)
    if second!=null and second.uid!=target.uid: fire(a.pos+Vector2(8,-15),second,amount*(2.0 if second.air else 1.0),"arrow",true)
  else:
   damage_enemy(target,amount)
   burst(target.pos,"slash",20)

func skill() -> bool:
 if special_cd>0.0 or not hero_allowed() or paused or state=="finished": return false
 var index=selected_hero_override if selected_hero_override>=0 else int(progression.selected)
 var living=allies.filter(func(a): return a.kind=="hero" and a.hp>0.0)
 if living.is_empty(): return false
 var d=CxCatalog.hero(index,progression.heroes[index])
 var point=living[0].pos
 special_cd=d.cooldown
 for a in living: a.anim=0.6
 match index:
  0:
   var target=target_at(point,180.0,false)
   if target!=null:
    living[0].pos=CxCatalog.nearest_ground(map_index,target.pos)
    hero_target=living[0].pos
    area_damage(target.pos,60,100,false)
    burst(target.pos,"slash",65)
  1:
   var target=target_at(point,260.0,true)
   if target!=null:
    var end=point+(target.pos-point).normalized()*300.0
    effects.append({"type":"bolt","from":point,"pos":end,"life":0.45,"max":0.45,"radius":0})
    for e in enemies:
     if e.dead: continue
     var closest=Geometry2D.get_closest_point_to_segment(e.pos,point,end)
     if e.pos.distance_to(closest)<32.0: damage_enemy(e,100,"arrow")
  2:
   for a in living: a.combo=5.0
   burst(point,"rage",60)
  3:
   for e in enemies:
    if e.dead or e.air or point.distance_to(e.pos)>95.0: continue
    damage_enemy(e,115.0)
    e.distance=maxf(0.0,e.distance-85.0)
    e.pos=CxCatalog.path_position(e.path,e.distance)
   burst(point,"shock",100)
  4:
   for e in enemies:
    if not e.dead and point.distance_to(e.pos)<180.0: freeze_enemy(e,4.0)
   burst(point,"ice",180)
  5: summon(point,3,18.0,-2,progression.heroes[5],true)
  6:
   var target=target_at(point,260.0,true)
   if target!=null:
    area_damage(target.pos,88.0,115.0,true)
    burst(target.pos,"rune",88.0)
  7:
   summon(point,1,18.0,-6,progression.heroes[7],false)
   for a in allies:
    if a.owner==-6 and a.life>0.0:
     a.hp=260.0; a.max_hp=260.0; a.damage=32.0; a.range=46.0; a.speed=105.0; a.shield=20.0
   events.append({"type":"summon"})
  8:
   var marked=target_at(point,240.0,true)
   if marked!=null:
    marked.expose=6.0
    burst(marked.pos,"rune",30.0)
    events.append({"type":"mark"})
  12:
   living[0].pos=CxCatalog.nearest_ground(map_index,point+Vector2(120,0))
   hero_target=living[0].pos
   area_damage(living[0].pos,125.0,420.0,true)
   burst(living[0].pos,"shock",125.0)
 events.append({"type":"ice" if index==4 else "summon" if index==5 else "skill"})
 return true

func cast(index:int,point:Vector2) -> bool:
 if index<0 or index>=spells.size() or index>=progression.spells.size() or progression.spells[index]<=0 or paused or state=="finished" or spells[index]>0.0: return false
 if mode=="buildout" or (mode=="swarm12" and not allowed_spells.has(index)): return false
 var level=progression.spells[index]
 spells[index]=CxCatalog.SPELLS[index].cooldown*maxf(0.65,1.0-0.035*(level-1))
 if index==5:
  if gold<120: spells[index]=0.0; return false
  gold-=120
 match index:
  0:
   var improved=progression.exclusive.get("meteor_plus",false)
   effects.append({"type":"meteor","pos":point,"radius":105.0*(1.15 if improved else 1.0),"life":0.8,"max":0.8,"damage":(175.0+30*(level-1))*(1.25 if improved else 1.0)})
   events.append({"type":"cannon"})
  1:
   for e in enemies:
    if not e.dead and point.distance_to(e.pos)<=120.0: freeze_enemy(e,4.0+0.25*(level-1))
   burst(point,"ice",120)
   events.append({"type":"ice"})
  2:
   barrier=9.0+0.5*(level-1)
   barrier_reduction=0.2
   burst(Vector2(945,285),"barrier",100)
   events.append({"type":"summon"})
  3: chain(point,point,100.0+15*(level-1),5+mini(2,int((level-1)/3.0)),150.0)
  4:
   summon(point,3,20.0,-3,level,false)
   events.append({"type":"summon"})
  5:
   barrier=6.0
   barrier_reduction=0.4
   burst(Vector2(945,285),"barrier",100)
   events.append({"type":"barrier"})
  6:
   summon(point,3,26.0,-4,level,true)
   for a in allies:
    if a.owner==-4 and a.life>0.0: a.damage=42.0+8.0*(level-1); a.range=190.0; a.interval=1.0
   events.append({"type":"summon"})
  7:
   summon(point,1,54.0,-5,level,false)
   for a in allies:
    if a.owner==-5 and a.life>0.0:
     a.hp=720.0+80.0*(level-1); a.max_hp=a.hp; a.damage=18.0+4.0*(level-1); a.range=48.0; a.speed=42.0; a.air=false
   events.append({"type":"summon"})
  8:
   for t in towers:
    if t!=null and t.pos.distance_to(point)<=170.0: t.fury=12.0
   burst(point,"rage",170)
  9:
   thorn_walls.append({"pos":CxCatalog.nearest_ground(map_index,point),"hp":520.0+80.0*(level-1),"life":18.0+2.0*(level-1)})
   burst(point,"summon",70)
 return true

func update_enemies(dt:float) -> void:
 for e in enemies.duplicate():
  if e.dead: continue
  e.freeze=maxf(0.0,e.freeze-dt)
  e.immune=maxf(0.0,e.immune-dt)
  e.slow=maxf(0.0,e.slow-dt)
  e.expose=maxf(0.0,e.get("expose",0.0)-dt)
  e.hit=maxf(0.0,e.hit-dt)
  e.anim=maxf(0.0,e.anim-dt)
  e.dash=maxf(0.0,e.dash-dt)
  e.regen_block=maxf(0.0,e.regen_block-dt)
  e.attack-=dt
  if e.kind=="regen" and e.regen_block<=0.0:
   e.hp=minf(e.max_hp,e.hp+e.max_hp*0.045*dt)
  if e.boss:
   boss_update(e,dt)
  if e.freeze>0.0: continue
  if not e.air:
   var living_wall=null
   for wall in thorn_walls:
    if wall.life>0.0 and wall.hp>0.0 and e.pos.distance_to(wall.pos)<38.0:
     living_wall=wall
     break
   if living_wall!=null:
    if e.attack<=0.0:
     living_wall.hp-=e.damage
     e.attack=1.0
    continue
  var block=null
  if not e.air:
   for a in allies:
    if a.hp<=0.0 or (a.kind=="hero" and not hero_allowed()) or (a.kind!="hero" and a.life<=0.0): continue
    if e.pos.distance_to(a.pos)<33.0+(35.0 if a.hero==3 else 0.0):
     block=a
     break
  if block!=null:
   if e.attack<=0.0:
    damage_ally(block,e.damage*(0.6 if e.boss else 0.75))
    e.attack=1.1 if not e.boss else 1.7
    e.anim=0.28
   continue
  if e.kind=="gunner":
   var tower_target=null
   for t in towers:
    if t!=null and t.pos.distance_to(e.pos)<165.0: tower_target=t; break
   if tower_target!=null:
    if e.attack<=0.0:
     damage_tower(tower_target,e.damage)
     effects.append({"type":"bolt","from":e.pos,"pos":tower_target.pos,"radius":0.0,"life":0.3,"max":0.3})
     e.attack=2.3
     e.anim=0.3
    continue
  var velocity=e.speed*(0.58 if e.slow>0.0 else 1.0)*(1.9 if e.dash>0.0 else 1.0)
  e.distance+=velocity*dt
  e.pos=CxCatalog.path_position(e.path,e.distance)
  if e.distance>=CxCatalog.path_length(e.path):
   hp-=e.damage*(barrier_reduction if barrier>0.0 else 1.0)
   e.dead=true
   burst(Vector2(925,285),"breach",65)
   events.append({"type":"breach"})

func damage_tower(t:Dictionary,amount:float) -> void:
 t.hp-=amount
 t.hit=0.2
 if t.hp<=0.0:
  var slot=towers.find(t)
  if slot>=0: towers[slot]=null
  for a in allies:
   if a.owner==t.id: a.life=0.0
  burst(t.pos,"explosion",45)

func boss_update(e:Dictionary,dt:float) -> void:
 if e.hp/e.max_hp<0.65 and e.phase==1:
  e.phase=2
  e.speed*=1.2
  e.special=1.0
  events.append({"type":"phase","phase":2,"name":e.name})
 if e.hp/e.max_hp<0.3 and e.phase==2:
  e.phase=3
  e.special=1.0
  events.append({"type":"phase","phase":3,"name":e.name})
 e.special-=dt
 if e.telegraph>0.0:
  e.telegraph-=dt
  if e.telegraph<=0.0:
   e.anim=0.6
   if e.final:
    var reinforcement_count=3 if e.phase==2 else 4
    for i in range(reinforcement_count):
     var final_spec={"kind":2 if i%3==0 else 3 if i%3==1 else 5,"boss":false,"route":i%ground_routes.size()}
     var final_helper=spawn_enemy(final_spec)
     if not final_helper.air:
      final_helper.distance=e.distance
      final_helper.pos=CxCatalog.path_position(final_helper.path,final_helper.distance)
    events.append({"type":"reinforcements","name":e.name,"count":reinforcement_count,"phase":e.phase})
   elif e.kind=="necro":
    var alive_aux=0
    for other in enemies:
     if not other.boss and not other.dead: alive_aux+=1
    for i in range(mini(2+e.phase,maxi(0,14-alive_aux))):
     var spec={"kind":7 if e.phase==1 else 3 if i%2==0 else 6,"boss":false,"route":0}
     var helper=spawn_enemy(spec)
     if not helper.air:
      helper.distance=e.distance
      helper.pos=CxCatalog.path_position(helper.path,helper.distance)
    burst(e.pos,"summon",80)
   elif e.kind=="barbarian":
    e.dash=2.0
    for a in allies:
     if a.hp>0.0 and a.pos.distance_to(e.pos)<110: damage_ally(a,60.0)
    burst(e.pos,"shock",110)
   else:
    for a in allies:
     if a.hp>0.0 and a.pos.distance_to(e.pos)<165: damage_ally(a,50.0+e.phase*12.0)
    for t in towers.duplicate():
     if t!=null and t.pos.distance_to(e.pos)<150: damage_tower(t,30.0+e.phase*10.0)
    if e.pos.distance_to(Vector2(945,285))<230:
     hp-=(18.0+e.phase*7.0)*(barrier_reduction if barrier>0.0 else 1.0)
    burst(e.pos,"fire" if e.kind=="dragon" else "shock",165)
   e.special=maxf(3.5,8.0-e.phase)
 elif e.special<=0.0:
  e.telegraph=1.2
  burst(e.pos,"warning",120)

func burst(point:Vector2,kind:String,radius:float=30.0) -> void:
 if effects.size()>140: effects.pop_front()
 effects.append({"type":kind,"pos":point,"radius":radius,"life":0.55 if kind!="death" else 0.8,"max":0.55 if kind!="death" else 0.8})

func update_effects(dt:float) -> void:
 for fx in effects.duplicate():
  fx.life-=dt
  if fx.type=="meteor" and fx.life<=0.0:
   area_damage(fx.pos,fx.radius,fx.damage,true)
   burst(fx.pos,"explosion",fx.radius)
   events.append({"type":"explosion"})
 effects=effects.filter(func(fx): return fx.life>0.0)

func boss_alive() -> Variant:
 for e in enemies:
  if e.boss and not e.dead: return e
 return null

func finish(victory:bool) -> void:
 if state=="finished": return
 state="finished"
 terminal={"id":run_id,"mode":mode,"map":map_index,"completed":completed,"defeat_wave":0 if victory else wave,"bosses":bosses,"time":elapsed,"earned":earned,"gem_mine_gems":gem_earned,"victory":victory,"special_defeat":special_defeat,"modifiers":modifiers.duplicate()}
 events.append({"type":"victory" if victory else "defeat"})
 burst(Vector2(925,285),"explosion",130)

func pending_count() -> int:
 return queue.size()

func alive_count() -> int:
 return enemies.filter(func(e): return not e.dead).size()
