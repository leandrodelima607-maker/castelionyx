class_name CxBattle
extends RefCounted

const STARTING_GOLD=425

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
var ground_routes:Array=[]
var air_route:Array=[]
var spells:Array=[0.0,0.0,0.0,0.0,0.0,0.0]
var kills=0
var event_id=""
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

func _init(which_map:int=0,which_mode:String="infinite",mods:Array=[],progress:Dictionary={},seed_value:int=0) -> void:
 map_index=clampi(which_map,0,3)
 mode=which_mode if which_mode in ["infinite","adventure","boss","extreme"] else "infinite"
 modifiers=mods.duplicate()
 progression=CxPersistence.validate(progress)
 adventure_wins=int(progression.stats.get("adventure_wins",0))
 adventure_extra=int(progression.stats.get("adventure_extra",0))
 speed=int(progression.settings.speed)
 rng.seed=seed_value if seed_value!=0 else int(Time.get_ticks_usec()+Time.get_unix_time_from_system()*1000000.0+map_index*137)
 run_id="%s-%d-%d" % [str(Time.get_unix_time_from_system()),Time.get_ticks_usec(),rng.randi()]
 generate_routes()
 generate_building_pads()
 if modifiers.has("wall"): max_hp=150.0
 hp=max_hp
 if modifiers.has("economy"): gold=roundi(float(STARTING_GOLD)*0.7)
 if mode=="adventure": gold=540
 for i in range(pads.size()): towers.append(null)
 create_heroes()

func generate_routes() -> void:
 ground_routes=[]
 var bases:Array=CxCatalog.MAPS[map_index].ground
 var entries=[70.0,135.0,200.0,270.0,340.0,410.0,475.0]
 entries.shuffle()
 var route_count=rng.randi_range(1,3)
 for i in range(route_count):
  var base:Array=bases[i%bases.size()]
  var points=make_route_variant(base,float(entries[i]))
  ground_routes.append(points)
 air_route=make_route_variant(CxCatalog.MAPS[map_index].air,float(rng.randi_range(80,470)))

func make_route_variant(base:Array,entry_y:float) -> Array:
 var route:Array=[]
 for i in range(base.size()):
  var point:Vector2=base[i]
  if i==0: point=Vector2(-35.0,entry_y)
  elif i==base.size()-1: point=Vector2(945.0,285.0)
  else:
   var progress=clampf(float(point.x+35.0)/980.0,0.0,1.0)
   var drift=(entry_y-float(base[0].y))*(1.0-progress)
   point=Vector2(point.x,clampf(point.y+drift+rng.randf_range(-18.0,18.0),65.0,490.0))
  route.append(point)
 return route

func route_is_valid(route:Array) -> bool:
 if route.size()<2 or route[0].x>=0.0 or route[-1].distance_to(Vector2(945,285))>1.0: return false
 for i in range(route.size()):
  var point:Vector2=route[i]
  if point.x < -50.0 or point.x > 950.0 or point.y < 55.0 or point.y > 500.0: return false
  if i>0 and route[i-1].distance_to(point)<5.0: return false
 return CxCatalog.path_length(route)>=500.0

func route_configuration_valid() -> bool:
 if ground_routes.is_empty() or ground_routes.size()>3 or not route_is_valid(air_route): return false
 for route in ground_routes:
  if not route_is_valid(route): return false
 return ground_routes.size()+1<=4

func point_clear_of_routes(point:Vector2,clearance:float=64.0) -> bool:
 var all_routes:Array=ground_routes.duplicate()
 all_routes.append(air_route)
 for route in all_routes:
  for i in range(1,route.size()):
   if point.distance_to(Geometry2D.get_closest_point_to_segment(point,route[i-1],route[i]))<clearance: return false
 return true

func generate_building_pads() -> void:
 pads=[]
 var wanted=5 if mode=="adventure" else 10
 if modifiers.has("reduced") and mode!="adventure": wanted=5
 var source:Array=CxCatalog.MAPS[map_index].pads.duplicate()
 source.shuffle()
 for point in source:
  if pads.size()>=wanted: break
  if point.x<55.0 or point.x>900.0 or point.y<70.0 or point.y>500.0 or not point_clear_of_routes(point): continue
  var separated=true
  for old in pads:
   if point.distance_to(old)<74.0: separated=false; break
  if separated: pads.append(point)
 var attempts=0
 while pads.size()<wanted and attempts<2400:
  attempts+=1
  var point=Vector2(rng.randf_range(60.0,895.0),rng.randf_range(75.0,495.0))
  if not point_clear_of_routes(point,62.0): continue
  var separated=true
  for old in pads:
   if point.distance_to(old)<74.0: separated=false; break
  if separated: pads.append(point)
 if pads.size()<wanted:
  for y in range(75,496,42):
   for x in range(60,896,70):
    var point=Vector2(x,y)
    if not point_clear_of_routes(point,55.0): continue
    var separated=true
    for old in pads:
     if point.distance_to(old)<68.0: separated=false; break
    if separated: pads.append(point)
    if pads.size()>=wanted: break
   if pads.size()>=wanted: break
 pads.shuffle()
 if pads.size()>wanted: pads=pads.slice(0,wanted)

func new_id() -> int:
 var value=next_id
 next_id+=1
 return value

func create_heroes() -> void:
 if modifiers.has("nohero") or mode=="adventure": return
 var choices:Array=progression.selected_heroes.duplicate()
 if not progression.exclusive.second_hero_slot: choices=choices.slice(0,1)
 for slot in range(mini(choices.size(),2)):
  var index=int(choices[slot])
  var level=maxi(1,int(progression.heroes[index]))
  var d=CxCatalog.hero(index,level)
  for twin in range(2 if index==2 else 1):
   var p=hero_target+Vector2(slot*30,twin*28)
   allies.append({"id":new_id(),"kind":"hero","hero":index,"hero_slot":slot,"sprite":d.sprite+twin,"pos":p,"hp":d.hp,"max_hp":d.hp,"shield":0.0,"damage":d.damage,"interval":d.interval,"range":d.range,"speed":d.speed,"armor":d.armor,"air":d.air,"attack":0.0,"anim":0.0,"hit":0.0,"life":-1.0,"respawn":0.0,"owner":-1,"combo":0.0,"arcane_target":-1,"arcane_hits":0,"special_cd":20.0 if index==6 else 0.0})

func hero_skill_cooldown(slot:int=0) -> float:
 var cooldown=0.0
 for ally in allies:
  if ally.kind=="hero" and int(ally.get("hero_slot",0))==slot:
   cooldown=maxf(cooldown,float(ally.get("special_cd",0.0)))
 return cooldown

func hero_allowed() -> bool:
 return not modifiers.has("nohero") and mode!="adventure"

func start_wave() -> bool:
 if state!="preparation" or hp<=0.0: return false
 wave+=1
 spawn_clock=0.0
 queue=wave_schedule(wave)
 state="combat"
 events.append({"type":"wave","wave":wave})
 return true

func wave_schedule(number:int) -> Array:
 var result:Array=[]
 var count=6+number*2
 if mode=="boss": count=8+number*3
 if mode=="extreme": count=10+number*3
 if map_index==1: count=int(ceil(count*1.25))
 if modifiers.has("reduced"): count=int(ceil(count*1.25))
 count=mini(count,100)
 if mode=="adventure": count=([24,28,32,36,40][clampi(number-1,0,4)]+adventure_extra) if adventure_wins<9 else (18+adventure_extra)
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
  result.append({"kind":kind,"boss":false,"route":i%maxi(1,ground_routes.size())})
 if number%10==0 and mode=="infinite": result.insert(int(count/2.0),{"kind":int(number/10.0-1)%4,"boss":true,"route":0})
 if mode=="boss" and number%5==0: result.insert(int(count/3.0),{"kind":int(number/5.0-1)%4,"boss":true,"route":0})
 if mode=="extreme" and number%3==0: result.insert(int(count/3.0),{"kind":int(number/3.0-1)%4,"boss":true,"route":0})
 if mode=="adventure" and adventure_wins<9 and number==5: result.append({"kind":3,"boss":true,"route":0,"final":true})
 if mode=="adventure" and adventure_wins>=9:
  result.insert(mini(result.size(),2),{"kind":(number-1)%4,"boss":true,"route":0,"final":number==10})
  if number==10:
   for boss_kind in range(5): result.append({"kind":boss_kind%4,"boss":true,"route":boss_kind%CxCatalog.MAPS[map_index].ground.size(),"final":true})
 return result

func spawn_enemy(spec:Dictionary) -> Dictionary:
 var d=(CxCatalog.BOSSES[spec.kind] if spec.get("boss",false) else CxCatalog.ENEMIES[spec.kind]).duplicate(true)
 var tier=maxi(0,wave-1)
 var factor=1.0+0.11*tier+0.004*tier*tier
 if mode=="adventure": factor=[0.82,1.05,1.3,1.55,1.8][clampi(wave-1,0,4)]
 if spec.get("boss",false) and mode=="infinite": factor=1.0+0.3*maxi(0,int(wave/10.0)-1)
 if mode=="boss": factor*=1.15+0.08*float(wave/5)
 if mode=="extreme": factor*=1.7
 if modifiers.has("extreme"): factor*=1.2
 if spec.get("final",false): d.hp=2200.0
 var route:Array=air_route if d.air else ground_routes[clampi(int(spec.get("route",0)),0,ground_routes.size()-1)]
 if mode=="adventure" and adventure_wins>=9:
  factor*=1.1 if not spec.get("boss",false) else 1.19
 var enemy={"uid":new_id(),"kind":d.id,"name":d.name,"sprite":d.sprite,"hp":d.hp*factor,"max_hp":d.hp*factor,"damage":d.damage*(1.0+0.04*tier)*(1.25 if mode=="extreme" else 1.0)*(1.39 if mode=="adventure" and adventure_wins>=9 and spec.get("boss",false) else 1.1 if mode=="adventure" and adventure_wins>=9 else 1.0),"speed":d.speed*minf(1.65,1.0+0.008*tier)*(1.1 if mode=="adventure" and adventure_wins>=9 else 1.0),"reward":d.reward,"armor":d.armor,"air":d.air,"boss":spec.get("boss",false),"final":spec.get("final",false),"phase":1,"path":route,"distance":0.0,"pos":route[0],"freeze":0.0,"immune":0.0,"slow":0.0,"hit":0.0,"anim":0.0,"attack":0.0,"special":7.0,"telegraph":0.0,"regen_block":0.0,"dead":false,"shell":42.0 if d.id=="mutant" else 0.0,"dash":0.0}
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
 if state=="finished" or paused: return
 elapsed+=dt
 if mode=="adventure" and adventure_wins>=9 and elapsed>=1500.0 and not special_defeat:
  special_defeat=true
  special_horde_clock=12.0
  events.append({"type":"special_defeat_start"})
  for i in range(28): queue.append({"kind":i%7,"boss":false,"route":i%maxi(1,ground_routes.size())})
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
 if hp<=0.0:
  finish(false)
  return
 if state=="combat" and queue.is_empty() and enemies.is_empty():
  completed=wave
  var wave_reward=35+wave*2
  if modifiers.has("economy"): wave_reward=int(floor(float(wave_reward)*0.7))
  gold+=wave_reward
  earned+=wave_reward
  if (mode=="adventure" and ((adventure_wins<9 and wave==5) or (adventure_wins>=9 and wave==10))) or (mode=="boss" and wave>=20):
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
 if mode=="adventure" and kind not in [0,1]: return false
 if kind>=progression.towers.size() or progression.towers[kind]<=0: return false
 if kind==6 and not progression.exclusive.get("coin_generator",false): return false
 if kind==7 and not progression.exclusive.get("sky_ballista",false): return false
 if kind==8 and not progression.exclusive.get("gem_mine",false): return false
 var d=CxCatalog.tower(kind,1,progression.towers[kind])
 var cost=d.cost
 if kind==6: cost=13
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
  t.anim=maxf(0.0,t.anim-dt)
  t.hit=maxf(0.0,t.hit-dt)
  if t.kind==6:
   if state=="finished" or paused: continue
   t.prod=maxf(0.0,t.get("prod",4.0)-dt)
   if t.prod<=0.0:
    gold+=1; t.prod=4.0; events.append({"type":"coin"})
   continue
  if t.kind==8:
   if state!="combat" or paused: continue
   t.prod=maxf(0.0,t.get("prod",60.0)-dt)
   if t.prod<=0.0:
    gem_earned+=1; t.prod=60.0; events.append({"type":"gem"})
   continue
  t.buff=support_for(t)
  t.attack-=dt*(1.25 if t.buff and t.kind!=7 else 1.0)
  if t.attack>0.0: continue
  var d=CxCatalog.tower(t.kind,t.level,progression.towers[t.kind])
  if t.kind==5: continue
  if t.kind==4:
   var count=0
   for a in allies:
    if a.owner==t.id and a.hp>0.0 and a.life>0.0: count+=1
   if count<1+t.level:
    summon(CxCatalog.nearest_ground(map_index,t.pos),1,45.0,t.id,t.level,false)
    t.attack=d.interval
   continue
  var target=null
  if t.kind==7:
   for candidate in enemies:
    if not candidate.dead and candidate.air and t.pos.distance_to(candidate.pos)<=d.range and (target==null or candidate.distance>target.distance): target=candidate
  if target==null: target=target_at(t.pos,d.range*(1.15 if t.buff else 1.0),d.air)
  if target==null: continue
  t.attack=d.interval
  t.anim=0.25
  if t.kind==3:
   chain(t.pos,target.pos,d.damage,1+t.level,85.0)
  elif t.kind==7:
   t.shots=int(t.get("shots",0))+1
   if t.shots%4==0:
    var direction=(target.pos-t.pos).normalized()
    var aligned:Array=[]
    for candidate in enemies:
     if candidate.dead: continue
     var offset=candidate.pos-t.pos
     var along=offset.dot(direction)
     var across=absf(offset.cross(direction))
     if along>0.0 and along<=d.range and across<=15.0: aligned.append({"enemy":candidate,"along":along})
    aligned.sort_custom(func(a,b): return a.along<b.along)
    for hit_index in range(mini(3,aligned.size())):
     var candidate:Dictionary=aligned[hit_index].enemy
     damage_enemy(candidate,d.damage if candidate.air else d.damage*0.58,"arrow")
    events.append({"type":"arrow"})
   else:
    var shot_damage=d.damage if target.air else d.damage*0.58
    fire(t.pos+Vector2(0,-24),target,shot_damage,"arrow",true)
  else:
   fire(t.pos+Vector2(0,-24),target,d.damage,["arrow","cannon","ice"][t.kind],d.air)

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
 e.hp-=amount*(1.0-reduction)
 e.hit=0.16
 e.regen_block=3.0
 if e.hp<=0.0:
  e.dead=true
  gold+=50
  earned+=50
  kills+=1
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
  if a.kind=="hero": a.special_cd=maxf(0.0,float(a.get("special_cd",0.0))-dt)
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
  if a.kind=="hero" and a.hero==6 and target!=null and a.special_cd<=0.0 and state=="combat":
   a.special_cd=20.0
   area_damage(target.pos,72.0,a.damage*2.2,true)
   burst(target.pos,"rune",72.0)
  if a.kind=="hero":
   var destination=hero_target+Vector2(int(a.get("hero_slot",0))*34,24 if a.hero==2 and a.sprite%2==1 else 0)
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
    if target.uid!=a.get("arcane_target",-1): a.arcane_target=target.uid; a.arcane_hits=0
    if int(a.arcane_hits)>=5:
     amount*=2.0; a.arcane_hits=0; burst(target.pos,"rune",28)
    else: a.arcane_hits=int(a.arcane_hits)+1
   fire(a.pos+Vector2(0,-15),target,amount,"ice" if a.hero==4 else "magic" if a.hero==5 or a.hero==6 or a.kind=="summon" else "arrow",true)
  else:
   damage_enemy(target,amount)
   burst(target.pos,"slash",20)

func skill(slot:int=0) -> bool:
 if not hero_allowed() or paused or state=="finished" or hero_skill_cooldown(slot)>0.0: return false
 var selected:Array=progression.selected_heroes
 if slot<0 or slot>=selected.size(): return false
 var index=int(selected[slot])
 if index==6: return false
 var living=allies.filter(func(a): return a.kind=="hero" and a.hp>0.0 and int(a.get("hero_slot",0))==slot)
 if living.is_empty(): return false
 var level=maxi(1,int(progression.heroes[index]))
 var d=CxCatalog.hero(index,level)
 var point=living[0].pos
 for ally in allies:
  if ally.kind=="hero" and int(ally.get("hero_slot",0))==slot: ally.special_cd=d.cooldown
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
  5: summon(point,3,18.0,-2,level,true)
 events.append({"type":"ice" if index==4 else "summon" if index==5 else "skill"})
 return true

func cast(index:int,point:Vector2) -> bool:
 if index<0 or index>=spells.size() or index>=progression.spells.size() or progression.spells[index]<=0 or paused or state=="finished" or spells[index]>0.0: return false
 var level=progression.spells[index]
 var spell_cost=int(CxCatalog.SPELLS[index].get("cost",0))
 if gold<spell_cost: return false
 gold-=spell_cost
 spells[index]=CxCatalog.SPELLS[index].cooldown*maxf(0.65,1.0-0.035*(level-1))
 match index:
  0:
   var upgraded=bool(progression.exclusive.get("meteor_plus",false))
   effects.append({"type":"meteor","pos":point,"radius":105.0*(1.15 if upgraded else 1.0),"life":0.8,"max":0.8,"damage":(175.0+30*(level-1))*(1.25 if upgraded else 1.0),"enhanced":upgraded})
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
 return true

func update_enemies(dt:float) -> void:
 for e in enemies.duplicate():
  if e.dead: continue
  e.freeze=maxf(0.0,e.freeze-dt)
  e.immune=maxf(0.0,e.immune-dt)
  e.slow=maxf(0.0,e.slow-dt)
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
   if e.kind=="necro":
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
 terminal={"id":run_id,"mode":mode,"event_id":event_id,"map":map_index,"completed":completed,"defeat_wave":0 if victory else wave,"bosses":bosses,"kills":kills,"time":elapsed,"earned":earned,"gem_mine_gems":gem_earned,"victory":victory,"special_defeat":special_defeat,"modifiers":modifiers.duplicate()}
 events.append({"type":"victory" if victory else "defeat"})
 burst(Vector2(925,285),"explosion",130)

func pending_count() -> int:
 return queue.size()

func alive_count() -> int:
 return enemies.filter(func(e): return not e.dead).size()
