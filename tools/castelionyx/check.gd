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

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var d=CxPersistence.defaults()
 check(CxPersistence.validate({"gems":"bad","heroes":[0,9],"selected":99}).heroes[0]==1,"corrupt save safe and initial hero preserved")
 check(CxPersistence.validate({"gems":-99}).gems==0,"negative currency rejected")
 var m=CxBattle.new(0,"infinite",[],d)
 check(m.start_wave(),"start first wave")
 check(not m.start_wave(),"no duplicate start")
 m.tick(0.1)
 check(m.wave==1 and m.pending_count()>0 and m.alive_count()==1,"scheduled queue and live counters")
 m.damage_enemy(m.enemies[0],100000)
 m.tick(0.1)
 check(m.wave==1 and m.state=="combat","empty live list cannot complete pending wave")
 check(m.build(0,0),"construction spends real gold")
 check(m.gold==375,"50 coins per defeated enemy and build cost")
 check(not m.build(0,1),"occupied slot rejected")
 var before=m.gold
 m.gold=0
 check(not m.build(1,0),"insufficient funds reject build")
 m.gold=before
 var damage=CxCatalog.tower(0,1).damage
 check(m.upgrade(0) and CxCatalog.tower(0,2).damage>damage,"upgrade changes real attack")
 var air=m.spawn_enemy({"kind":3,"boss":false,"route":0})
 check(air.path==m.aerial_route and air.path.size()==CxCatalog.MAPS[0].air.size(),"flying units use actual aerial route")
 var layout_b=CxBattle.new(0,"infinite",[],d)
 check(m.ground_routes!=layout_b.ground_routes and m.pads!=layout_b.pads,"routes and spaces change between partidas")
 check(m.pads.size()==10 and CxBattle.new(0,"adventure",[],d).pads.size()==5,"mode construction-space counts remain exact")
 check(m.target_at(air.pos,1,false)==null,"ground attacks cannot target air")
 check(m.target_at(air.pos,1,true)!=null,"anti-air can target flyers")
 var at=air.pos
 var hp_before=air.hp
 check(m.cast(1,at) and air.freeze>0,"ice prison really freezes")
 check(not m.cast(1,at),"spell cooldown enforced")
 var frozen=air.freeze
 check(not m.freeze_enemy(air,9.0) and air.freeze==frozen,"freeze cannot stack indefinitely")
 check(m.cast(2,at) and m.barrier>0,"castle barrier active")
 check(m.cast(3,at) and air.hp<hp_before,"chain deals damage")
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
 var twins=CxBattle.new(0,"infinite",[],twins_data)
 check(twins.allies.size()==2 and twins.allies[0].id!=twins.allies[1].id,"twins are two entities with distinct life")
 check(twins.skill() and twins.allies[0].combo>0 and twins.allies[1].combo>0,"twin combo changes both attack rates")
 var summon_data=d.duplicate(true)
 summon_data.heroes[5]=1
 summon_data.selected=5
 var summoner=CxBattle.new(0,"infinite",[],summon_data)
 check(summoner.skill() and summoner.allies.size()==4,"summoner creates three living allies")
 summoner.update_allies(19.0)
 summoner.tick(0.1)
 check(summoner.allies.size()==1,"summons expire and are removed")
 var normal=CxBattle.new()
 var fast=CxBattle.new()
 fast.speed=2
 normal.advance(0.1)
 fast.advance(0.1)
 check(abs(fast.elapsed-normal.elapsed*2)<0.0001,"2x accelerates simulation time")
 fast.paused=true
 var elapsed_before=fast.elapsed
 fast.advance(0.1)
 check(fast.elapsed==elapsed_before,"pause stops simulation")
 var endless=CxBattle.new()
 var boss_types:Array=[]
 for wave in range(1,41):
  var schedule=endless.wave_schedule(wave)
  var bosses_in_wave=schedule.filter(func(x): return x.boss)
  check(bosses_in_wave.size()==(1 if wave%10==0 else 0),"boss schedule wave "+str(wave))
  if not bosses_in_wave.is_empty(): boss_types.append(bosses_in_wave[0].kind)
 check(boss_types==[0,1,2,3],"all four bosses ordered correctly")
 var adventure=CxBattle.new(0,"adventure",[],d)
 for i in range(5):
  check(adventure.start_wave(),"adventure wave "+str(i+1)+" starts")
  var end_spec=adventure.queue[-1]
  for spec in adventure.queue.duplicate():
   var e=adventure.spawn_enemy(spec)
   adventure.damage_enemy(e,1000000)
  adventure.queue.clear()
  adventure.tick(0.01)
 check(adventure.state=="finished" and adventure.completed==5 and adventure.terminal.victory,"adventure ends only after exactly five cleared waves")
 check(adventure.towers.size()==5 and adventure.allies.is_empty() and not adventure.hero_allowed() and not adventure.build(0,2),"adventure has five pads, no heroes and blocks non-arrow/cannon structures")
 var final_data=CxPersistence.defaults()
 final_data.stats.adventure_wins=9
 final_data.stats.adventure_extra=80
 var tenth_run=CxBattle.new(0,"adventure",[],final_data)
 var tenth_schedule=tenth_run.wave_schedule(10)
 check(tenth_schedule.any(func(spec): return spec.get("final",false)) and tenth_schedule.size()>20,"tenth adventure has a final boss and extended reinforcements")
 var persistence=CxPersistence.new()
 var saved=persistence.data.duplicate(true)
 persistence.data=CxPersistence.defaults()
 check(persistence.profile("Teste Castelo","teste@castelionyx.com",2),"profile writes successfully")
 var reload=CxPersistence.new()
 check(reload.has_profile() and reload.data.profile.name=="Teste Castelo" and reload.data.profile.email=="teste@castelionyx.com","profile reload persists")
 var reward=persistence.record(adventure.terminal)
 check(reward==1000 and persistence.data.gems==1000,"complete adventure grants exactly 1000 gems")
 check(persistence.record(adventure.terminal)==0 and persistence.data.gems==1000,"reopening result cannot duplicate gems")
 var second_result={"id":"adventure-second-"+str(Time.get_ticks_usec()),"mode":"adventure","map":0,"completed":5,"defeat_wave":0,"bosses":1,"time":200.0,"earned":100,"victory":true}
 check(persistence.record(second_result)==500 and persistence.data.gems==1500,"second adventure victory grants 500 gems")
 var tenth_persistence=CxPersistence.new()
 tenth_persistence.data=CxPersistence.defaults()
 tenth_persistence.data.stats.adventure_wins=9
 var tenth_result={"id":"adventure-tenth-"+str(Time.get_ticks_usec()),"mode":"adventure","map":0,"completed":10,"defeat_wave":0,"bosses":6,"time":5000.0,"earned":200,"victory":true}
 check(tenth_persistence.record(tenth_result)==6742 and tenth_persistence.data.gems==6742,"tenth adventure victory grants exactly 6742 gems without a time cap")
 var partial={"id":"test-partial-"+str(Time.get_ticks_usec()),"mode":"adventure","map":0,"completed":4,"defeat_wave":5,"bosses":0,"time":50.0,"earned":100,"victory":false}
 check(persistence.record(partial)==0,"partial adventure no full reward")
 var infinite={"id":"test-infinite-"+str(Time.get_ticks_usec()),"mode":"infinite","map":0,"completed":16,"defeat_wave":17,"bosses":1,"time":110.0,"earned":230,"victory":false}
 check(persistence.record(infinite)==1,"16 complete defeat17 produces one gem")
 check(persistence.data.stats.last.completed==16 and persistence.data.stats.last.defeat_wave==17,"completed count distinct from defeat wave")
 persistence.data.gems=4392
 check(persistence.buy("heroes",1) and persistence.data.heroes[1]==1,"progressive hero purchase costs 3600 gems")
 check(persistence.select_hero(1),"unlocked hero can be selected")
 check(not persistence.select_hero(5),"locked hero cannot be selected")
 persistence.data.exclusive.second_hero_slot=true
 persistence.data.heroes[2]=1
 check(persistence.select_second_hero(2) and persistence.data.selected_heroes[1]==2,"second hero slot selects a distinct hero")
 var duo=CxBattle.new(0,"infinite",[],persistence.data)
 check(duo.allies.size()==3,"two selected heroes appear in combat, including twins")
 var economy=CxBattle.new(0,"infinite",[],persistence.data)
 economy.gold=20
 economy.progression.exclusive.coin_generator=true
 economy.progression.towers[6]=1
 economy.start_wave()
 check(economy.build(0,6) and economy.gold==7,"coin generator costs exactly 13 coins")
 var generator=economy.towers[0]
 economy.update_towers(4.0)
 check(economy.gold==8,"coin generator produces one coin per four seconds")
 economy.damage_tower(generator,9999)
 economy.update_towers(4.0)
 check(economy.gold==8,"destroyed coin generator stops production")
 var exclusive=CxBattle.new(0,"infinite",[],persistence.data)
 exclusive.gold=120
 exclusive.start_wave()
 exclusive.progression.spells[5]=1
 check(exclusive.cast(5,Vector2(945,285)) and exclusive.gold==0,"realm barrier costs 120 coins")
 var event_data=CxPersistence.defaults()
 event_data.gems=10000
 event_data.heroes[6]=1
 var event_save=CxPersistence.new()
 event_save.data=event_data
 var event_result={"id":"event-test-"+str(Time.get_ticks_usec()),"mode":"infinite","completed":50,"defeat_wave":51,"bosses":5,"time":400.0,"earned":0,"victory":false,"modifiers":["reduced","nohero"]}
 event_save.record(event_result)
 check(event_save.data.exclusive.arcane_sentinel and event_save.data.events.survivor_no_army.reward_claimed,"event reward is persistent and real")
 persistence.data=saved
 persistence.commit()
 check(CxCatalog.MAPS[0].ground!=CxCatalog.MAPS[1].ground and CxCatalog.MAPS[3].ground.size()==2,"different maps have different actual routes")
 var tenth=CxPersistence.defaults()
 tenth.stats.adventure_wins=9
 tenth.stats.adventure_extra=80
 var special=CxBattle.new(0,"adventure",[],tenth)
 special.tick(1500.1)
 check(special.terminal.get("special_defeat",false)==true,"special defeat only after tenth adventure cycle timeout")
 var normal_run=CxBattle.new(0,"infinite",[],d)
 normal_run.hp=0.0
 normal_run.tick(0.1)
 check(normal_run.terminal.get("special_defeat",false)==false,"normal defeat does not use special defeat music")
 print("[castelionyx-check] ","PASS:" if failed==0 else "FAIL:"," ",passed," passing, ",failed," failing")
 quit(0 if failed==0 else 1)
