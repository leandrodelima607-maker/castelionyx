extends SceneTree

var passed=0
var failed=0

func audit(condition:bool,label:String) -> void:
 if condition: passed+=1; print("AUDIT PASS ",label)
 else: failed+=1; push_error("AUDIT FAIL "+label)

func ids_unique(items:Array) -> bool:
 var seen=[]
 for item in items:
  if seen.has(item.id): return false
  seen.append(item.id)
 return true

func _init() -> void:
 var fresh=CxPersistence.defaults()
 audit(fresh.spells.count(1)==1 and fresh.spells[0]==1,"01 conta nova libera somente Meteoros")
 audit(not CxPersistence.valid_email("sem-email"),"02 e-mail inválido é rejeitado")
 var p=CxPersistence.new(); p.data=CxPersistence.defaults()
 audit(p.profile("Audit","audit@reino.com",0) and p.data.gems==100,"03 cadastro dá 100 gemas")
 audit(p.profile("Audit editado","audit2@reino.com",1) and p.data.gems==100,"04 editar perfil não duplica brinde")
 audit(not p.buy("spells",2),"05 compra bloqueada sem gemas")
 p.data.gems=100000
 audit(p.buy("spells",1) and p.data.spells[1]==1,"06 compra de feitiço persiste")
 audit(p.select_hero(0) and p.data.selected==0,"07 herói desbloqueado pode ser selecionado")
 audit(not p.select_second_hero(0),"08 segundo espaço rejeita duplicata")
 var adv=CxBattle.new(0,"adventure",[],fresh)
 audit(not adv.hero_allowed() and adv.allies.is_empty(),"09 Aventura não cria herói")
 audit(adv.pads.size()==5,"10 Aventura usa cinco espaços")
 audit(not adv.build(0,2),"11 Aventura bloqueia construção fora da regra")
 audit(adv.wave_schedule(1).size()>0 and adv.wave_schedule(5).size()>0,"12 Aventura tem cinco agendas válidas")
 audit(adv.wave_schedule(5).any(func(x): return x.get("final",false)),"13 Aventura tem chefe final marcado")
 var r=CxPersistence.new(); r.data=CxPersistence.defaults()
 audit(r.record({"id":"a1","mode":"adventure","completed":5,"victory":true,"bosses":1,"time":1.0})==1000,"14 primeira vitória paga 1000")
 audit(r.record({"id":"a1","mode":"adventure","completed":5,"victory":true,"bosses":1,"time":1.0})==0,"15 resultado repetido não paga")
 audit(r.record({"id":"a2","mode":"adventure","completed":5,"victory":true,"bosses":1,"time":1.0})==500,"16 repetição paga 500")
 var tenth=CxPersistence.new(); tenth.data=CxPersistence.defaults(); tenth.data.stats.adventure_wins=9
 audit(tenth.record({"id":"a10","mode":"adventure","completed":5,"victory":true,"bosses":5,"time":1.0})==6742,"17 décima vitória paga 6742")
 var inf=CxBattle.new(0,"infinite",[],fresh)
 audit(inf.wave_schedule(10).any(func(x): return x.get("boss",false)),"18 chefe aparece na onda 10")
 audit(inf.ground_routes!=CxCatalog.MAPS[0].ground,"19 rota terrestre é sorteada")
 audit(inf.pads.size()==10,"20 defesa infinita preserva dez espaços padrão")
 var build=CxBattle.new(0,"buildout",[],fresh)
 audit(build.gold==9999 and build.allies.is_empty(),"21 Construção 101 começa com 9999 e sem herói")
 audit(build.build(0,0),"22 Construção 101 permite preparar estrutura")
 build.start_wave()
 audit(not build.build(1,0),"23 Construção 101 bloqueia construção após iniciar")
 audit(not build.cast(0,Vector2(300,200)),"24 Construção 101 bloqueia feitiços")
 audit(build.wave_schedule(102).is_empty(),"25 Construção 101 termina na onda 101")
 var swarm_data=CxPersistence.defaults(); var swarm=CxBattle.new(0,"swarm12",[],swarm_data)
 audit(swarm.max_hp==600.0,"26 Enxame tem dobro de vida")
 audit(swarm.wave_schedule(1).size()==10,"27 Enxame começa com dez inimigos")
 audit(swarm.wave_schedule(2).size()==20,"28 Enxame dobra a quantidade")
 audit(not swarm.set_swarm_loadout(0,[0,1,2]),"29 Enxame rejeita feitiços bloqueados")
 swarm_data.spells[1]=1; swarm_data.spells[2]=1; swarm_data.heroes[1]=1
 var swarm_ready=CxBattle.new(0,"swarm12",[],swarm_data)
 audit(swarm_ready.set_swarm_loadout(1,[0,1,2]),"30 Enxame aceita exatamente três desbloqueados")
 audit(swarm_ready.allowed_spells==[0,1,2],"31 batalha recebe somente loadout escolhido")
 audit(swarm_ready.allies.size()==1 and swarm_ready.allies[0].hero==1,"32 batalha usa o herói escolhido")
 audit(not swarm_ready.cast(3,Vector2(400,200)),"33 feitiço fora do loadout não pode ser lançado")
 audit(swarm_ready.spells.size()==10,"34 cada feitiço tem cooldown próprio")
 var falcon_data=CxPersistence.defaults(); falcon_data.towers[11]=1
 var falcon=CxBattle.new(0,"infinite",[],falcon_data); falcon.gold=2000
 audit(falcon.build(0,11),"35 Ninho do Falcão pode ser construído")
 falcon.update_towers(5.1)
 audit(falcon.allies.size()>1 and falcon.allies[-1].air and falcon.allies[-1].life>1000,"36 falcão permanente ataca pelo ar")
 audit(CxCatalog.TOWERS[10].range>=300.0 and CxCatalog.TOWERS[10].interval<1.0,"37 Arco Longo tem alcance e cadência declarados")
 audit(ids_unique(CxCatalog.HEROES),"38 heróis têm IDs únicos")
 audit(ids_unique(CxCatalog.TOWERS) and ids_unique(CxCatalog.SPELLS) and ids_unique(CxCatalog.ENEMIES) and ids_unique(CxCatalog.BOSSES),"39 estruturas, feitiços, inimigos e chefes têm IDs únicos")
 print("[castelionyx-audit-39] ","PASS: " if failed==0 else "FAIL: ",passed," passing, ",failed," failing")
 quit(0 if failed==0 else 1)
