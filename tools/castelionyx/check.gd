extends SceneTree
var passed=0
var failed=0

func check(condition:bool,message:String) -> void:
 if condition:
  passed+=1
  print("PASS ",message)
 else:
  failed+=1
  push_error("FAIL "+message)

func run() -> void:
 var d=CxPersistence.defaults()
 d.spells=[1,1,1,1,1,1]
 check(CxPersistence.validate({"gems":"bad","heroes":[0,9],"selected":99}).heroes[0]==1,"corrupt save safe and initial hero preserved")
 check(CxPersistence.validate({"gems":-99}).gems==0,"negative currency rejected")
 check(CxPersistence.validate({"heroes":[1,9],"towers":[1,1,1,1,1,1,1,1,1],"spells":[1,9,9,9,9,1]}).heroes[1]==4,"legacy permanent levels migrate to the 0–4 limit")
 var level_five_save=CxPersistence.defaults()
 level_five_save.stats.waves=500
 var level_five=CxPersistence.validate(level_five_save)
 var level_twenty_four_save=CxPersistence.defaults()
 level_twenty_four_save.stats.waves=2400
 var level_twenty_four=CxPersistence.validate(level_twenty_four_save)
 check(level_five.player_level==5 and level_five.exclusive.boss_mode_unlocked and not level_five.exclusive.extreme_mode_unlocked,"level 5 permanently unlocks Boss Challenge only")
 check(level_twenty_four.player_level==24 and level_twenty_four.exclusive.boss_mode_unlocked and level_twenty_four.exclusive.extreme_mode_unlocked,"level 24 permanently unlocks Extreme Survival")
 check(CxCatalog.purchase_cost("spells",0,0)>=300 and CxCatalog.purchase_cost("spells",5,0)<=500,"spell gem costs remain in the 300–500 range")
 check(CxCatalog.purchase_cost("heroes",1,0)>=3600 and CxCatalog.purchase_cost("towers",1,0)>=3600,"hero/tower permanent upgrades start at 3,600 gems")
 check(CxPersistence.valid_email("player+castle@example.com") and not CxPersistence.valid_email("player@invalid.c") and not CxPersistence.valid_email("player @example.com"),"profile email validation accepts normal addresses and rejects malformed input")
 check(CxCatalog.HEROES[6].hp<=130.0 and CxCatalog.HEROES[6].interval==1.5 and CxCatalog.HEROES[6].range>=200.0 and CxCatalog.HEROES[6].cooldown==20.0,"Arcane Sentinel has low health, long reach, 1.5-second attacks and 20-second special")
 check(CxCatalog.TOWERS[7].cost==180 and CxCatalog.TOWERS[7].interval==2.5 and CxCatalog.TOWERS[7].range>=230.0 and CxCatalog.tower(7,3,4).interval==2.5,"Sky Ballista remains 180 coins and 2.5-second cadence through upgrades")

 var m=CxBattle.new(0,"infinite",[],d,1101)
 check(m.pads.size()==10 and m.route_configuration_valid(),"infinite creates ten build spaces and valid randomized routes")
 var limited_economy=CxBattle.new(0,"infinite",["economy"],d,1102)
 check(limited_economy.gold==roundi(float(CxBattle.STARTING_GOLD)*0.7) and limited_economy.gold==298,"Limited Economy starts at 70% of standard starting gold, rounded to a whole coin")
 check(m.ground_routes.size()>=1 and m.ground_routes.size()+1<=4,"one to four active routes including the air route")
 check(m.start_wave(),"start first wave")
 check(not m.start_wave(),"no duplicate start")
 m.tick(0.1)
 check(m.wave==1 and m.pending_count()>0 and m.alive_count()==1,"scheduled queue and live counters")
 m.damage_enemy(m.enemies[0],100000)
 m.tick(0.1)
 check(m.wave==1 and m.state=="combat","empty live list cannot complete pending wave")
 check(m.gold==475,"a defeated enemy pays exactly 50 temporary coins")
 check(m.build(0,0),"construction spends real gold")
 check(m.gold==375,"tower construction deducts its actual price")
 check(not m.build(0,1),"occupied slot rejected")
 var before=m.gold
 m.gold=0
 check(not m.build(1,0),"insufficient funds reject build")
 m.gold=before
 var damage=CxCatalog.tower(0,1).damage
 check(m.upgrade(0) and CxCatalog.tower(0,2).damage>damage,"upgrade changes real attack")
 var air=m.spawn_enemy({"kind":3,"boss":false,"route":0})
 check(air.path==m.air_route and m.route_is_valid(air.path),"flying units use their per-match aerial route")
 check(m.target_at(air.pos,1,false)==null,"ground attacks cannot target air")
 check(m.target_at(air.pos,1,true)!=null,"anti-air can target flyers")
 var varied=CxBattle.new(0,"infinite",[],d,2202)
 check(varied.pads.size()==10 and varied.route_configuration_valid(),"a second new match independently gets ten valid spaces/routes")
 check(varied.ground_routes!=m.ground_routes or varied.air_route!=m.air_route,"route layout changes between seeded matches")
 for map_id in range(CxCatalog.MAPS.size()):
  for seed_index in range(8):
   var sample=CxBattle.new(map_id,"infinite",[],d,30000+map_id*100+seed_index)
   check(sample.pads.size()==10 and sample.route_configuration_valid() and sample.ground_routes.size()+1<=4,"stress route/space configuration map %d seed %d" % [map_id,seed_index])
 var reduced=CxBattle.new(1,"infinite",["reduced"],d,3303)
 check(reduced.pads.size()==5 and reduced.route_configuration_valid(),"Reduced Army applies its explicit five-slot rule")
 for pad in m.pads: check(m.point_clear_of_routes(pad,60.0),"every build position is clear of roads")
 for i in range(m.pads.size()):
  for j in range(i+1,m.pads.size()): check(m.pads[i].distance_to(m.pads[j])>=68.0,"build positions do not overlap")

 var hp_before=air.hp
 check(m.cast(1,air.pos) and air.freeze>0,"ice prison really freezes")
 check(not m.cast(1,air.pos),"spell cooldown enforced")
 var frozen=air.freeze
 check(not m.freeze_enemy(air,9.0) and air.freeze==frozen,"freeze cannot stack indefinitely")
 check(m.cast(2,air.pos) and m.barrier>0,"castle barrier active")
 check(m.cast(3,air.pos) and air.hp<hp_before,"chain deals damage")
 var realm_data=d.duplicate(true)
 var realm=CxBattle.new(0,"infinite",[],realm_data,4242)
 realm.gold=119
 check(not realm.cast(5,Vector2(0,0)),"exclusive Kingdom Barrier requires its 120-coin manual cast")
 realm.gold=120
 check(realm.cast(5,Vector2(0,0)) and realm.gold==0 and realm.barrier==6.0 and is_equal_approx(realm.barrier_reduction,0.4) and realm.spells[5]==45.0,"Kingdom Barrier costs 120, lasts six seconds, reduces damage by 60%, and has a 45-second cooldown")
 realm.hp=100.0
 var breach=realm.spawn_enemy({"kind":0,"boss":false,"route":0})
 breach.distance=CxCatalog.path_length(breach.path)-1.0
 breach.pos=CxCatalog.path_position(breach.path,breach.distance)
 realm.update_enemies(0.1)
 check(breach.dead and is_equal_approx(realm.hp,96.4),"Kingdom Barrier reduces actual castle breach damage by 60% without stopping the enemy")
 check(m.cast(4,Vector2(815,285)),"emergency guards cast")
 var guards=m.allies.filter(func(a): return a.kind=="guard")
 check(guards.size()==3 and guards[0].shield>0 and guards[0].life>0,"three guards independent shields and timed life")
 var guard=guards[0]
 var guard_hp=guard.hp
 m.damage_ally(guard,20)
 check(guard.hp==guard_hp and guard.shield<55,"shield absorbs before life")
 m.damage_ally(guard,100)
 check(guard.shield==0 and guard.hp<guard_hp,"shield breaks and guard remains damageable")
 var meteor_enemy=m.spawn_enemy({"kind":2,"boss":false,"route":0})
 var meteor_hp=meteor_enemy.hp
 check(m.cast(0,meteor_enemy.pos),"meteors cast")
 m.update_effects(0.9)
 check(meteor_enemy.hp<meteor_hp,"delayed meteor impact deals area damage")
 var enhanced_data=d.duplicate(true)
 enhanced_data.exclusive.meteor_plus=true
 var enhanced=CxBattle.new(0,"infinite",[],enhanced_data,4404)
 enhanced.spells[0]=0.0
 check(enhanced.cast(0,Vector2(300,250)),"event-upgraded Meteor can still cast normally")
 check(is_equal_approx(enhanced.effects[0].damage,218.75) and is_equal_approx(enhanced.effects[0].radius,120.75),"Meteor event applies exactly +25% damage and +15% radius")

 var reg=m.spawn_enemy({"kind":5,"boss":false,"route":0})
 reg.hp=40
 m.update_enemies(1.0)
 check(reg.hp>40,"regenerating enemy really heals")
 m.damage_enemy(reg,5)
 var reg_hp=reg.hp
 m.update_enemies(0.1)
 check(is_equal_approx(reg.hp,reg_hp),"damage interrupts regeneration")
 var mut=m.spawn_enemy({"kind":6,"boss":false,"route":0})
 m.damage_enemy(mut,43)
 check(mut.shell==0 and mut.dash>0,"mutant shield break causes speed burst")

 var twins_data=d.duplicate(true)
 twins_data.heroes[2]=1
 twins_data.selected=2
 twins_data.selected_heroes=[2]
 var twins=CxBattle.new(0,"infinite",[],twins_data,5505)
 check(twins.allies.size()==2 and twins.allies[0].id!=twins.allies[1].id,"twins are two entities with distinct life")
 check(twins.skill() and twins.allies[0].combo>0 and twins.allies[1].combo>0,"twin combo changes both attack rates")
 var summon_data=d.duplicate(true)
 summon_data.heroes[5]=1
 summon_data.selected=5
 summon_data.selected_heroes=[5]
 var summoner=CxBattle.new(0,"infinite",[],summon_data,6606)
 check(summoner.skill() and summoner.allies.size()==4,"summoner creates three living allies")
 summoner.update_allies(19.0)
 summoner.tick(0.1)
 check(summoner.allies.size()==1,"summons expire and are removed")

 var sentinel_data=d.duplicate(true)
 sentinel_data.heroes[6]=1
 sentinel_data.selected=6
 sentinel_data.selected_heroes=[6]
 sentinel_data.exclusive.arcane_sentinel=true
 var sentinel=CxBattle.new(0,"infinite",[],sentinel_data,7707)
 var sentinel_target=sentinel.spawn_enemy({"kind":0,"boss":false,"route":0})
 sentinel_target.pos=sentinel.hero_target
 sentinel.state="combat"
 sentinel.allies[0].special_cd=0.0
 sentinel.update_allies(0.1)
 check(sentinel.allies[0].special_cd>19.8,"Arcane Sentinel triggers its runic explosion every 20 seconds automatically")
 check(sentinel.effects.any(func(fx): return fx.type=="rune"),"Arcane Sentinel runic burst has a visible effect")
 sentinel_target.hp=1000.0
 sentinel_target.max_hp=1000.0
 sentinel_target.dead=false
 sentinel.allies[0].arcane_target=sentinel_target.uid
 sentinel.allies[0].arcane_hits=5
 sentinel.allies[0].attack=0.0
 sentinel.update_allies(0.1)
 check(sentinel.projectiles.size()>0 and is_equal_approx(sentinel.projectiles[-1].damage,42.0),"five consecutive hits double the following Arcane Mark attack")

 var ballista_data=d.duplicate(true)
 ballista_data.exclusive.sky_ballista=true
 ballista_data.towers[7]=1
 var ballista=CxBattle.new(0,"infinite",[],ballista_data,8080)
 check(ballista.build(0,7) and ballista.build(1,5),"Sky Ballista and support build with real temporary-gold costs")
 var ballista_tower:Dictionary=ballista.towers[0]
 ballista.towers[1].pos=ballista_tower.pos+Vector2(80,0)
 ballista.state="combat"
 ballista_tower.attack=0.0
 ballista_tower.shots=3
 var aligned:Array=[]
 for offset in [70.0,100.0,130.0]:
  var flyer=ballista.spawn_enemy({"kind":3,"boss":false,"route":0})
  flyer.pos=ballista_tower.pos+Vector2(offset,0)
  aligned.append(flyer)
 ballista.update_towers(0.01)
 check(ballista_tower.shots==4 and aligned.all(func(e): return e.dead),"fourth Ballista shot pierces and defeats three aligned flying targets")
 ballista_tower.attack=0.0
 var ground_target=ballista.spawn_enemy({"kind":0,"boss":false,"route":0})
 ground_target.pos=ballista_tower.pos+Vector2(100,0)
 ballista.update_towers(0.01)
 check(ballista.projectiles.size()==1 and is_equal_approx(ballista.projectiles[-1].damage,45.24),"Sky Ballista deals moderate damage to ground and keeps its projectile")
 ballista.update_towers(0.5)
 check(is_equal_approx(ballista_tower.attack,2.0),"support does not make the Ballista exceed its 2.5-second cadence")

 var coin_data=d.duplicate(true)
 coin_data.exclusive.coin_generator=true
 coin_data.towers[6]=1
 var generator=CxBattle.new(0,"infinite",[],coin_data,8808)
 check(generator.build(0,6) and generator.gold==412,"Coin Generator costs exactly 13 temporary coins")
 var generator_gold=generator.gold
 generator.update_towers(2.0)
 check(generator.gold==generator_gold,"Coin Generator counts active time before four seconds")
 generator.state="preparation"
 generator.update_towers(2.1)
 check(generator.gold==generator_gold+1,"Coin Generator begins producing as soon as built, including active preparation")
 generator.state="combat"
 generator.update_towers(4.1)
 check(generator.gold==generator_gold+2,"Coin Generator produces one coin per four active seconds")
 generator.sell(0)
 var gold_after_sale=generator.gold
 generator.update_towers(8.0)
 check(generator.gold==gold_after_sale,"removed generator stops producing after its sale refund")
 var mine_data=d.duplicate(true)
 mine_data.exclusive.gem_mine=true
 mine_data.towers[8]=1
 var mine=CxBattle.new(0,"infinite",[],mine_data,9909)
 check(mine.build(0,8) and mine.gold==175,"Gem Mine costs exactly 250 temporary coins")
 mine.state="combat"
 mine.update_towers(59.9)
 check(mine.gem_earned==0,"Gem Mine does not pay before 60 active seconds")
 mine.update_towers(0.2)
 check(mine.gem_earned==1,"Gem Mine produces one permanent-gem reward per 60 active seconds")
 mine.paused=true
 mine.update_towers(60.0)
 check(mine.gem_earned==1,"Gem Mine cannot accrue during pause")
 mine.paused=false
 mine.state="finished"
 mine.update_towers(60.0)
 check(mine.gem_earned==1,"Gem Mine stops after battle end")

 var normal=CxBattle.new(0,"infinite",[],d,10101)
 var fast=CxBattle.new(0,"infinite",[],d,10102)
 fast.speed=2
 normal.advance(0.1)
 fast.advance(0.1)
 check(abs(fast.elapsed-normal.elapsed*2)<0.0001,"2× accelerates simulation time")
 fast.paused=true
 var elapsed_before=fast.elapsed
 fast.advance(0.1)
 check(fast.elapsed==elapsed_before,"pause stops simulation")
 var endless=CxBattle.new(0,"infinite",[],d,11111)
 var boss_types:Array=[]
 for wave in range(1,41):
  var schedule=endless.wave_schedule(wave)
  var bosses_in_wave=schedule.filter(func(x): return x.boss)
  check(bosses_in_wave.size()==(1 if wave%10==0 else 0),"infinite boss schedule wave "+str(wave))
  if not bosses_in_wave.is_empty(): boss_types.append(bosses_in_wave[0].kind)
 check(boss_types==[0,1,2,3],"all four infinite bosses ordered correctly")
 var boss_mode=CxBattle.new(0,"boss",["boss_challenge"],d,12121)
 check(boss_mode.wave_schedule(5).filter(func(x): return x.boss).size()==1 and boss_mode.wave_schedule(20).filter(func(x): return x.boss).size()==1,"Boss Challenge schedules its distinct four bosses")
 check(boss_mode.mode=="boss" and boss_mode.wave_schedule(10).filter(func(x): return x.boss).size()==1,"boss mode does not masquerade as Infinito")
 var extreme=CxBattle.new(0,"extreme",["reduced","economy","mutants","aerial","extreme"],d,13131)
 check(extreme.wave_schedule(3).filter(func(x): return x.boss).size()==1 and extreme.mode=="extreme","Extreme mode schedules a boss every three waves")
 check(extreme.wave_schedule(3).size()>endless.wave_schedule(3).size(),"Extreme mode has more enemies than standard Infinito")

 var adventure=CxBattle.new(0,"adventure",[],d,14141)
 check(adventure.pads.size()==5 and adventure.route_configuration_valid(),"adventure has exactly five valid spaces/routes")
 check(adventure.wave_schedule(1).size()==24 and adventure.wave_schedule(5).size()==41,"adventure pressure rises across all five waves including the final boss")
 for i in range(5):
  check(adventure.start_wave(),"adventure wave "+str(i+1)+" starts")
  for spec in adventure.queue.duplicate():
   var e=adventure.spawn_enemy(spec)
   adventure.damage_enemy(e,1000000)
  adventure.queue.clear()
  adventure.tick(0.01)
 check(adventure.state=="finished" and adventure.completed==5 and adventure.terminal.victory,"adventure ends only after exactly five cleared waves")
 check(not adventure.build(0,2),"adventure blocks non-arrow/cannon structures")

 var persistence=CxPersistence.new()
 var saved=persistence.data.duplicate(true)
 persistence.data=CxPersistence.defaults()
 check(persistence.profile("Teste Castelo","teste@castelionyx.com",2),"profile writes valid email locally")
 var reload=CxPersistence.new()
 check(reload.has_profile() and reload.data.profile.name=="Teste Castelo" and reload.data.profile.email=="teste@castelionyx.com","profile reload persists locally")
 var reward=persistence.record(adventure.terminal)
 check(reward==1000 and persistence.data.gems==1000,"complete adventure grants 1,000 gems")
 check(persistence.record(adventure.terminal)==0 and persistence.data.gems==1000,"reopening result cannot duplicate reward")
 var partial={"id":"test-partial-"+str(Time.get_ticks_usec()),"mode":"adventure","map":0,"completed":4,"defeat_wave":5,"bosses":0,"time":50.0,"earned":100,"victory":false}
 check(persistence.record(partial)==0,"partial adventure grants no full reward")
 var infinite={"id":"test-infinite-"+str(Time.get_ticks_usec()),"mode":"infinite","map":0,"completed":16,"defeat_wave":17,"bosses":1,"kills":12,"time":110.0,"earned":230,"victory":false,"modifiers":[]}
 check(persistence.record(infinite)==1,"16 completed Infinite waves produce one gem")
 check(persistence.data.stats.last.completed==16 and persistence.data.stats.last.defeat_wave==17,"completed count differs from defeat wave")
 var ordinary_waves=persistence.data.stats.waves
 var boss_result={"id":"test-boss-"+str(Time.get_ticks_usec()),"mode":"boss","completed":5,"bosses":1,"time":75.0,"victory":false}
 check(persistence.record(boss_result)==1 and persistence.data.stats.waves==ordinary_waves and persistence.data.stats.modes.boss.waves==5,"Boss Challenge has its own stats/reward and does not inflate Infinite player level")
 var mine_result={"id":"test-gems-"+str(Time.get_ticks_usec()),"mode":"infinite","completed":0,"gem_mine_unpaid":2,"victory":false}
 var gems_before_mine=int(persistence.data.gems)
 persistence.record(mine_result)
 check(persistence.data.gems==gems_before_mine+2 and persistence.record(mine_result)==0 and persistence.data.gems==gems_before_mine+2,"unpaid Gem Mine output is credited once on a recorded result")
 persistence.data.gems=4392
 check(persistence.buy("heroes",1) and persistence.data.heroes[1]==1,"progressive hero purchase costs 4,392 gems")
 check(persistence.select_hero(1),"unlocked hero can be selected")
 check(not persistence.select_hero(5),"locked hero cannot be selected")
 check(not persistence.buy("heroes",1) or persistence.data.heroes[1]<=4,"permanent hero level never exceeds four")

 var event_persistence=CxPersistence.new()
 event_persistence.data=CxPersistence.defaults()
 var event_cases={"survivor_no_army":{"goal":50,"mods":["reduced","nohero"],"key":"arcane_sentinel"},"sky_falls":{"goal":35,"mods":["aerial","reduced"],"key":"sky_ballista"},"last_hope":{"goal":25,"mods":["wall","economy"],"key":"barrier_realm"},"mutant_plague":{"goal":40,"mods":["mutants","aerial"],"key":"meteor_plus"},"scarcity_master":{"goal":30,"mods":["reduced","economy","nohero"],"key":"gem_mine"},"extra_hero":{"goal":50,"mods":["wall","mutants"],"key":"second_hero_slot"}}
 for event_id in event_cases:
  var req:Dictionary=event_cases[event_id]
  var event_result={"id":"event-"+event_id,"mode":"infinite","completed":req.goal,"kills":0,"modifiers":req.mods}
  event_persistence.update_events(event_result)
  check(event_persistence.data.events[event_id].reward_claimed and event_persistence.data.exclusive[req.key],"event "+event_id+" unlocks its permanent reward")
 var event_progress=CxPersistence.new()
 event_progress.data=CxPersistence.defaults()
 event_progress.update_events({"mode":"infinite","completed":49,"modifiers":["reduced","nohero"]})
 check(event_progress.data.events.survivor_no_army.progress==49 and not event_progress.data.events.survivor_no_army.reward_claimed,"event progress alone cannot award an incomplete challenge")
 event_progress.update_events({"mode":"infinite","completed":50,"modifiers":["reduced","nohero"]})
 check(event_progress.data.events.survivor_no_army.reward_claimed and event_progress.data.heroes[6]==1,"the event awards its reward only after one qualifying run reaches its goal")
 check(event_persistence.data.heroes[6]==1 and event_persistence.data.towers[7]==1 and event_persistence.data.spells[5]==1 and event_persistence.data.towers[8]==1,"exclusive items become usable in inventory after their events")
 check(event_persistence.data.exclusive.second_hero_slot,"extra-hero event unlocks a second slot, not a free duplicate")
 var fortune={"id":"fortune","mode":"infinite","completed":2,"kills":100,"modifiers":[]}
 event_persistence.update_events(fortune)
 check(event_persistence.data.events.first_fortune.reward_claimed and event_persistence.data.towers[6]==1,"100 cumulative Infinito kills unlock the Coin Generator")
 event_persistence.data.heroes[1]=1
 check(event_persistence.select_hero(1,1) and event_persistence.data.selected_heroes.size()==2,"second distinct unlocked hero persists in slot two")
 var duo=CxBattle.new(0,"infinite",[],event_persistence.data,15151)
 check(duo.allies.filter(func(a): return a.kind=="hero").size()==2,"both selected heroes enter the same battle")
 check(not event_persistence.select_hero(1,0) or event_persistence.data.selected_heroes.size()<=2,"hero slots remain bounded")
 event_persistence.data=saved
 event_persistence.commit()
 persistence.data=saved
 persistence.commit()
 check(CxCatalog.MAPS[0].ground!=CxCatalog.MAPS[1].ground and CxCatalog.MAPS[3].ground.size()==2,"maps retain different authored route bases")
 var tenth=CxPersistence.defaults()
 tenth.stats.adventure_wins=9
 tenth.stats.adventure_extra=80
 var special=CxBattle.new(0,"adventure",[],tenth,16161)
 special.tick(1500.1)
 check(special.terminal.get("special_defeat",false)==true,"special defeat only after tenth adventure cycle timeout")
 var normal_run=CxBattle.new(0,"infinite",[],d,17171)
 normal_run.hp=0.0
 normal_run.tick(0.1)
 check(normal_run.terminal.get("special_defeat",false)==false,"normal defeat does not use special defeat music")
 print("[castelionyx-check] ","PASS:" if failed==0 else "FAIL:"," ",passed," passing, ",failed," failing")
 quit(0 if failed==0 else 1)

func _initialize() -> void:
 call_deferred("run")
