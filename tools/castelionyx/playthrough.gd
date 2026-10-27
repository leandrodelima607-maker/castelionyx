extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 for mode in ["infinite","adventure"]:
  var b=CxBattle.new(0,mode,[],CxPersistence.defaults())
  for slot in [1,4,6]:
   if slot<b.towers.size(): b.build(slot,0)
  var last=0
  for step in range(12000):
   if b.state=="finished" or (mode=="infinite" and b.completed>=10): break
   if b.state=="preparation":
    for slot in [1,4,6,0,2,3,5,7,8,9]:
     if slot>=b.towers.size(): continue
     if b.towers[slot]==null: b.build(slot,1 if slot==2 else 2 if slot==0 else 0)
     elif b.towers[slot].level<3: b.upgrade(slot)
    b.start_wave()
   if not b.enemies.is_empty():
    var target=b.enemies[-1].pos
    b.move_hero(target)
    b.skill()
    for spell in [0,1,3,4]:
     if b.spells[spell]<=0: b.cast(spell,target)
    if b.hp<250 and b.spells[2]<=0: b.cast(2,Vector2(945,285))
   b.advance(0.25)
   if b.completed!=last:
    last=b.completed
    print(mode," complete ",last," castle ",b.hp," gold ",b.gold)
  print("[castelionyx-playthrough] ",mode," completed ",b.completed," state ",b.state," castle ",b.hp," bosses ",b.bosses)
 quit()
