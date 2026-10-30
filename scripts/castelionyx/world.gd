class_name CxWorld
extends Control

const HERO_TEXTURE=preload("res://assets/combat/heroes_runtime.png")
const ENEMY_TEXTURE=preload("res://assets/combat/enemies_runtime.png")
const BUILDING_TEXTURE=preload("res://assets/combat/structures_runtime.png")
const BACKGROUND=preload("res://assets/kingdom/realm_runtime.png")
var battle:Variant=null
var field=Rect2(0,0,1000,550)
var selected_slot=-1
var aiming=-1
var clock=0.0
var intro=false
var reduced=false
var sprite_cache:Dictionary={}
var display_map=0

func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST

func _process(delta:float) -> void:
 if not reduced: clock+=delta
 queue_redraw()

func set_field(rect:Rect2) -> void:
 field=rect

func screen_to_world(point:Vector2) -> Vector2:
 var scale_value=minf(field.size.x/1000.0,field.size.y/550.0)
 var offset=field.position+(field.size-Vector2(1000,550)*scale_value)*0.5
 return (point-offset)/maxf(scale_value,0.001)

func inside(point:Vector2) -> bool:
 var p=screen_to_world(point)
 return Rect2(0,0,1000,550).has_point(p)

func atlas(kind:String,index:int) -> AtlasTexture:
 var key=kind+str(index)
 if sprite_cache.has(key): return sprite_cache[key]
 var texture=HERO_TEXTURE if kind=="hero" else ENEMY_TEXTURE if kind=="enemy" else BUILDING_TEXTURE
 var rows=3 if kind=="enemy" else 2
 var columns=4
 var safe_index=index% (columns*rows)
 var cell=Vector2(float(texture.get_width())/4.0,float(texture.get_height())/rows)
 var item=AtlasTexture.new()
 item.atlas=texture
 item.region=Rect2(Vector2(safe_index%columns,int(safe_index/columns))*cell,cell)
 sprite_cache[key]=item
 return item

func sprite(kind:String,index:int,point:Vector2,height:float,tint:Color=Color.WHITE,rotation_value:float=0.0) -> void:
 var texture=atlas(kind,index)
 var width=height*float(texture.get_width())/maxf(1.0,texture.get_height())
 var rect=Rect2(Vector2(-width*0.5,-height),Vector2(width,height))
 draw_set_transform(point,rotation_value)
 draw_texture_rect(texture,rect,false,tint)
 draw_set_transform(Vector2.ZERO)

func health(point:Vector2,value:float,maximum:float,width:float=35,color:Color=Color("74bf87")) -> void:
 var ratio=clampf(value/maxf(1,maximum),0,1)
 var bar_color=Color("e36c63") if ratio<0.28 else color
 draw_rect(Rect2(point+Vector2(-width/2-1,-4),Vector2(width+2,7)),Color("0b171b"))
 draw_rect(Rect2(point+Vector2(-width/2,-3),Vector2(width,5)),Color("39454a"))
 draw_rect(Rect2(point+Vector2(-width/2,-3),Vector2(width*ratio,4)),bar_color)
 if ratio<0.28 and sin(clock*8.0)>0.0:
  draw_rect(Rect2(point+Vector2(-width/2,-3),Vector2(width*ratio,1)),Color("ffd08b"))

func _draw() -> void:
 var size_value=get_viewport_rect().size
 draw_rect(Rect2(Vector2.ZERO,size_value),Color("10242a"))
 if battle==null:
  draw_texture_rect(BACKGROUND,Rect2(Vector2.ZERO,size_value),false)
  draw_rect(Rect2(Vector2.ZERO,size_value),Color(0.025,0.07,0.09,0.45))
  draw_rect(Rect2(Vector2.ZERO,Vector2(minf(size_value.x,450),size_value.y)),Color(0.035,0.085,0.1,0.68))
  for i in range(26):
   var p=Vector2(fmod(i*97.0+clock*3.0,size_value.x),fmod(i*151.0-clock*14.0+size_value.y*20,size_value.y))
   draw_rect(Rect2(p,Vector2(2,2)),Color(0.94,0.73,0.36,0.4+0.2*sin(clock+i)))
  return
 var s=minf(field.size.x/1000.0,field.size.y/550.0)
 var offset=field.position+(field.size-Vector2(1000,550)*s)*0.5
 draw_rect(Rect2(offset-Vector2(3,3),Vector2(1000,550)*s+Vector2(6,6)),Color("7b7952"))
 draw_set_transform(offset,0,Vector2(s,s))
 draw_map()
 draw_set_transform(offset,0,Vector2(s,s))
 for i in range(battle.pads.size()):
  var p=battle.pads[i]
  var t=battle.towers[i]
  draw_rect(Rect2(p-Vector2(24,15),Vector2(48,30)),Color("313c36"))
  draw_rect(Rect2(p-Vector2(21,13),Vector2(42,24)),Color("67705d"))
  draw_rect(Rect2(p-Vector2(17,10),Vector2(34,18)),Color("81866d"))
  if selected_slot==i:
   draw_rect(Rect2(p-Vector2(25,17),Vector2(50,32)),Color("e3ba75"),false,3)
   for ring in range(3):
    draw_arc(p,32+ring*5,clock*1.5+ring,clock*1.5+ring+1.7,10,Color(0.95,0.78,0.39,0.7-0.18*ring),2)
   if t!=null:
    var d=CxCatalog.tower(t.kind,t.level)
    draw_arc(p,d.range,0,TAU,48,Color(0.83,0.7,0.35,0.3),2)
  if t==null:
   draw_rect(Rect2(p-Vector2(8,2),Vector2(16,4)),Color("bec6a2"))
   draw_rect(Rect2(p-Vector2(2,8),Vector2(4,16)),Color("bec6a2"))
  else:
   var color=Color("fff4dc") if t.hit>0.0 else Color.WHITE
   var pos=p+Vector2(0,-2 if t.anim>0 else 0)
   draw_set_transform(offset,0,Vector2(s,s))
   draw_atlas_in_world("building",t.kind,pos,75+8*(t.level-1),color,s,offset)
   for star in range(t.level): draw_rect(Rect2(p+Vector2(-10+star*9,6),Vector2(6,4)),Color("e2b56a"))
   health(p+Vector2(0,13),t.hp,t.max_hp,42)
   if t.buff: draw_rect(Rect2(p+Vector2(21,-24),Vector2(5,10)),Color("eaca72"))
 var castle_index=6 if battle.hp>0.0 else 7
 draw_atlas_in_world("building",castle_index,Vector2(955,330),155,Color.WHITE,s,offset)
 if battle.hp>0.0 and battle.hp/maxf(1.0,battle.max_hp)<0.35:
  var danger_alpha=0.18+0.12*(0.5+0.5*sin(clock*7.0))
  draw_arc(Vector2(955,330),92,0,TAU,32,Color(1.0,0.32,0.24,danger_alpha),5)
  draw_arc(Vector2(955,330),104,clock,clock+1.2,18,Color(0.95,0.58,0.28,danger_alpha),3)
 if battle.barrier>0.0:
  draw_arc(Vector2(945,280),95,0,TAU,32,Color(0.55,0.86,1,0.75),4)
 var actors:Array=[]
 for e in battle.enemies: actors.append({"enemy":true,"a":e,"sort":e.pos.y+40 if e.air else e.pos.y})
 for a in battle.allies:
  if a.hp>0.0 and (a.kind!="hero" or battle.hero_allowed()): actors.append({"enemy":false,"a":a,"sort":a.pos.y})
 actors.sort_custom(func(a,b): return a.sort<b.sort)
 for item in actors:
  var a=item.a
  var air=a.get("air",false) if item.enemy else false
  var flying=Vector2(0,-24+sin(clock*5+a.get("uid",a.get("id",0)))*4) if air else Vector2.ZERO
  var p=a.pos+flying
  var motion=sin(battle.elapsed*10.0+a.get("uid",a.get("id",0)))*1.8 if a.anim<=0.0 and a.get("freeze",0.0)<=0.0 else 0.0
  p.y+=motion
  var color=Color(1,0.75,0.6) if a.hit>0.0 else Color(0.55,0.82,1) if a.get("freeze",0.0)>0.0 else Color.WHITE
  var height=90.0 if a.get("boss",false) else 50.0 if not item.enemy else 44.0
  var turn=0.14*sin(a.anim*12.0) if a.anim>0.0 else 0.0
  draw_atlas_in_world("enemy" if item.enemy else "hero",a.sprite,p,height,color,s,offset,turn)
  health(p+Vector2(0,-height+5),a.hp,a.max_hp,65 if a.get("boss",false) else 32,Color("e9a16a") if item.enemy else Color("79c59a"))
  if not item.enemy and a.shield>0.0:
   draw_rect(Rect2(p+Vector2(-16,-height+10),Vector2(32*minf(a.shield/70,1),3)),Color("81c5de"))
  if a.get("freeze",0)>0:
   for j in range(3):
    var x=p.x-18+j*15
    draw_colored_polygon(PackedVector2Array([Vector2(x,p.y),Vector2(x+6,p.y-24),Vector2(x+12,p.y)]),Color(0.55,0.86,1,0.75))
  if a.get("shell",0)>0: draw_arc(p-Vector2(0,16),27,0,TAU,16,Color("b88df2"),2)
  if a.get("telegraph",0)>0: draw_arc(p,120,0,TAU,32,Color(1,0.45,0.3,0.7),3)
  if a.get("kind","")=="regen" and a.get("regen_block",0)<=0:
   draw_rect(Rect2(p+Vector2(16,-25),Vector2(4,11)),Color("a4e368"))
   draw_rect(Rect2(p+Vector2(12,-21),Vector2(12,4)),Color("a4e368"))
 for p in battle.projectiles:
  var color=Color("f2d48f") if p.kind=="arrow" else Color("b3edff") if p.kind=="ice" else Color("d08df4") if p.kind=="magic" else Color("3e3839")
  var dir=(p.destination-p.pos).normalized()
  if p.kind=="arrow":
   draw_line(p.pos-dir*14,p.pos,color,2)
   draw_colored_polygon(PackedVector2Array([p.pos+dir*3,p.pos-dir*4+dir.orthogonal()*3,p.pos-dir*4-dir.orthogonal()*3]),color)
  else:
   var radius=5.0 if p.kind=="cannon" else 4.0
   draw_circle(p.pos,radius+2,Color(color,0.18))
   draw_rect(Rect2(p.pos-Vector2(radius,radius),Vector2(radius*2,radius*2)),color)
   draw_rect(Rect2(p.pos-Vector2(1,1),Vector2(2,2)),Color("fff2c2"))
 for fx in battle.effects: draw_effect(fx)
 if aiming>=0:
  var pointer=screen_to_world(get_global_mouse_position())
  draw_arc(pointer,105.0,0,TAU,32,Color("f0cf85"),3)
 draw_set_transform(Vector2.ZERO)

func draw_atlas_in_world(kind:String,index:int,point:Vector2,height:float,tint:Color,s:float,offset:Vector2,turn:float=0.0) -> void:
 if kind=="hero":
  draw_set_transform(offset+point*s,turn,Vector2(s,s))
  draw_hero_art(index,height,tint)
  draw_set_transform(offset,0,Vector2(s,s))
  return
 if kind=="enemy":
  draw_set_transform(offset+point*s,turn,Vector2(s,s))
  draw_enemy_art(index,height,tint)
  draw_set_transform(offset,0,Vector2(s,s))
  return
 if kind=="building":
  draw_set_transform(offset+point*s,turn,Vector2(s,s))
  draw_building_art(index,height,tint)
  draw_set_transform(offset,0,Vector2(s,s))
  return
 var texture=atlas(kind,index)
 var width=height*float(texture.get_width())/maxf(texture.get_height(),1)
 draw_set_transform(offset+point*s,turn,Vector2(s,s))
 draw_texture_rect(texture,Rect2(Vector2(-width/2,-height),Vector2(width,height)),false,tint)
 draw_set_transform(offset,0,Vector2(s,s))

func draw_hero_art(index:int,height:float,tint:Color) -> void:
 var scale_value=height/50.0
 var bodies=[Color("315c73"),Color("2f7b76"),Color("b74d3f"),Color("c66b35"),Color("59616a"),Color("435a88"),Color("6a3d86"),Color("a84543"),Color("4f8f67"),Color("d29b4e")]
 var accents=[Color("b9e3ee"),Color("9de9d0"),Color("f1a15c"),Color("f3c46c"),Color("c3ccd3"),Color("a7c8ff"),Color("d8a8f0"),Color("f0b34f"),Color("b9d978"),Color("f6df86")]
 var body=bodies[clampi(index,0,bodies.size()-1)]
 var accent=accents[clampi(index,0,accents.size()-1)]
 if tint!=Color.WHITE: body=body.lightened(0.25)
 draw_rect(Rect2(Vector2(-10,-30)*scale_value,Vector2(20,24)*scale_value),body)
 draw_rect(Rect2(Vector2(-8,-42)*scale_value,Vector2(16,12)*scale_value),Color("d7b18a"))
 draw_rect(Rect2(Vector2(-6,-39)*scale_value,Vector2(3,3)*scale_value),Color("19272b"))
 draw_rect(Rect2(Vector2(3,-39)*scale_value,Vector2(3,3)*scale_value),Color("19272b"))
 draw_rect(Rect2(Vector2(-14,-27)*scale_value,Vector2(4,17)*scale_value),accent)
 draw_rect(Rect2(Vector2(10,-27)*scale_value,Vector2(4,17)*scale_value),accent)
 if index==0:
  draw_rect(Rect2(Vector2(-15,-30)*scale_value,Vector2(30,5)*scale_value),Color("d6e0e5"))
  draw_rect(Rect2(Vector2(-4,-50)*scale_value,Vector2(8,9)*scale_value),accent)
 elif index==1:
  draw_rect(Rect2(Vector2(-3,-54)*scale_value,Vector2(6,21)*scale_value),accent)
  draw_colored_polygon(PackedVector2Array([Vector2(0,-54),Vector2(-7,-44),Vector2(7,-44)]),accent)
 elif index==2:
  draw_rect(Rect2(Vector2(-18,-24)*scale_value,Vector2(7,16)*scale_value),Color("d94f4c"))
  draw_rect(Rect2(Vector2(11,-24)*scale_value,Vector2(7,16)*scale_value),Color("f08b38"))
 elif index==3:
  draw_rect(Rect2(Vector2(-15,-28)*scale_value,Vector2(30,5)*scale_value),Color("dbe1e0"))
  draw_rect(Rect2(Vector2(13,-39)*scale_value,Vector2(4,28)*scale_value),accent)
 elif index==4:
  draw_rect(Rect2(Vector2(-15,-27)*scale_value,Vector2(30,7)*scale_value),Color("c8d0d6"))
  draw_rect(Rect2(Vector2(-4,-50)*scale_value,Vector2(8,10)*scale_value),Color("8bd2e8"))
 elif index==5:
  draw_rect(Rect2(Vector2(13,-41)*scale_value,Vector2(3,34)*scale_value),accent)
  draw_circle(Vector2(14,-45)*scale_value,7*scale_value,Color("c7ddff"))
 elif index==6:
  draw_rect(Rect2(Vector2(12,-42)*scale_value,Vector2(4,35)*scale_value),accent)
  draw_circle(Vector2(14,-46)*scale_value,6*scale_value,Color("c987e3"))
 elif index==7:
  draw_rect(Rect2(Vector2(-22,-30)*scale_value,Vector2(8,3)*scale_value),accent)
  draw_rect(Rect2(Vector2(14,-30)*scale_value,Vector2(8,3)*scale_value),accent)
  draw_rect(Rect2(Vector2(-20,-34)*scale_value,Vector2(3,9)*scale_value),Color("7f352f"))
  draw_rect(Rect2(Vector2(17,-34)*scale_value,Vector2(3,9)*scale_value),Color("7f352f"))
 elif index==8:
  draw_colored_polygon(PackedVector2Array([Vector2(9,-18),Vector2(25,-11),Vector2(12,-5)]),Color("9b6a46"))
  draw_rect(Rect2(Vector2(21,-12)*scale_value,Vector2(8,4)*scale_value),accent)
 elif index==9:
  draw_arc(Vector2(0,-39)*scale_value,13*scale_value,0,TAU,12,accent,3*scale_value)
  draw_rect(Rect2(Vector2(13,-38)*scale_value,Vector2(3,30)*scale_value),accent)
 draw_rect(Rect2(Vector2(-9,-6)*scale_value,Vector2(7,8)*scale_value),Color("263943"))
 draw_rect(Rect2(Vector2(2,-6)*scale_value,Vector2(7,8)*scale_value),Color("263943"))

func draw_enemy_art(index:int,height:float,tint:Color) -> void:
 var k=height/44.0
 var colors=[Color("8c453e"),Color("d4a137"),Color("6d7379"),Color("7897ae"),Color("875b45"),Color("6e9c58"),Color("8d4e9a"),Color("c8d4d8"),Color("8f3f36"),Color("8799a8"),Color("59636e"),Color("583d75"),Color("8b5db8"),Color("69b7c3"),Color("a9d5e0")]
 var accent=[Color("f1b95b"),Color("f3e39a"),Color("aab4bb"),Color("d9f4ff"),Color("e5a46b"),Color("b9e37b"),Color("d590e5"),Color("edf5f2"),Color("f07d5d"),Color("d7edff"),Color("bbc8d3"),Color("c18be9"),Color("e1b5ff"),Color("a9f5f0"),Color("e7fbff")]
 var body=colors[clampi(index,0,colors.size()-1)]
 var trim=accent[clampi(index,0,accent.size()-1)]
 if tint!=Color.WHITE: body=body.lightened(0.25)
 var boss=index>=8
 draw_rect(Rect2(Vector2(-11,-28)*k,Vector2(22,22)*k),body)
 draw_rect(Rect2(Vector2(-8,-39)*k,Vector2(16,11)*k),Color("b77c5c") if not boss else body.darkened(0.18))
 draw_rect(Rect2(Vector2(-5,-36)*k,Vector2(3,3)*k),Color("241c27"))
 draw_rect(Rect2(Vector2(3,-36)*k,Vector2(3,3)*k),Color("241c27"))
 if index==0: draw_rect(Rect2(Vector2(-16,-25)*k,Vector2(5,10)*k),trim)
 elif index==1: draw_rect(Rect2(Vector2(-15,-15)*k,Vector2(30,4)*k),trim)
 elif index==2: draw_rect(Rect2(Vector2(-16,-33)*k,Vector2(32,5)*k),trim)
 elif index==3:
  draw_colored_polygon(PackedVector2Array([Vector2(-25,-25),Vector2(-9,-15),Vector2(-18,-5)]),trim)
  draw_colored_polygon(PackedVector2Array([Vector2(25,-25),Vector2(9,-15),Vector2(18,-5)]),trim)
 elif index==4: draw_rect(Rect2(Vector2(12,-32)*k,Vector2(4,21)*k),trim)
 elif index==5: draw_rect(Rect2(Vector2(14,-33)*k,Vector2(4,15)*k),trim)
 elif index==6:
  draw_rect(Rect2(Vector2(-15,-30)*k,Vector2(5,17)*k),trim); draw_rect(Rect2(Vector2(10,-30)*k,Vector2(5,17)*k),trim)
 elif index==7:
  draw_rect(Rect2(Vector2(-9,-42)*k,Vector2(18,4)*k),trim); draw_rect(Rect2(Vector2(-4,-46)*k,Vector2(8,4)*k),trim)
 elif index==8:
  draw_colored_polygon(PackedVector2Array([Vector2(-11,-39),Vector2(-22,-55),Vector2(-5,-47)]),trim); draw_colored_polygon(PackedVector2Array([Vector2(11,-39),Vector2(22,-55),Vector2(5,-47)]),trim)
 elif index==9: draw_arc(Vector2(0,-32)*k,18*k,PI,TAU,10,trim,4*k)
 elif index==10: draw_rect(Rect2(Vector2(-16,-20)*k,Vector2(32,7)*k),trim)
 elif index==11: draw_circle(Vector2(0,-46)*k,8*k,trim); draw_rect(Rect2(Vector2(-3,-40)*k,Vector2(6,20)*k),trim)
 elif index==12: draw_rect(Rect2(Vector2(-18,-27)*k,Vector2(36,4)*k),trim); draw_rect(Rect2(Vector2(-4,-48)*k,Vector2(8,9)*k),trim)
 elif index==13: draw_colored_polygon(PackedVector2Array([Vector2(-14,-39),Vector2(-4,-55),Vector2(0,-39)]),trim); draw_colored_polygon(PackedVector2Array([Vector2(14,-39),Vector2(4,-55),Vector2(0,-39)]),trim)
 elif index==14: draw_arc(Vector2(0,-43)*k,12*k,0,TAU,12,trim,3*k)
 if boss: draw_rect(Rect2(Vector2(-5,-5)*k,Vector2(10,8)*k),Color("252d38"))

func draw_building_art(index:int,height:float,tint:Color) -> void:
 var k=height/75.0
 var stone=Color("596b68") if tint==Color.WHITE else Color("a9beb0")
 var roof=[Color("c96d55"),Color("7b8794"),Color("82c1d1"),Color("a58bd0"),Color("b9a46c"),Color("78a878"),Color("c69a55"),Color("83b8d1"),Color("9d664d"),Color("cc9a54"),Color("7d9b67"),Color("7c9eae")][clampi(index,0,11)]
 if height>120.0:
  draw_rect(Rect2(Vector2(-42,-56)*k,Vector2(84,56)*k),Color("546168"))
  draw_rect(Rect2(Vector2(-55,-82)*k,Vector2(25,82)*k),Color("68777b"))
  draw_rect(Rect2(Vector2(30,-82)*k,Vector2(25,82)*k),Color("68777b"))
  draw_rect(Rect2(Vector2(-63,-91)*k,Vector2(41,10)*k),Color("c98b52"))
  draw_rect(Rect2(Vector2(22,-91)*k,Vector2(41,10)*k),Color("c98b52"))
  draw_rect(Rect2(Vector2(-8,-48)*k,Vector2(16,48)*k),Color("2a3b42"))
  draw_rect(Rect2(Vector2(-4,-75)*k,Vector2(8,8)*k),Color("e7c76e"))
  return
 draw_rect(Rect2(Vector2(-24,-29)*k,Vector2(48,29)*k),stone)
 draw_rect(Rect2(Vector2(-20,-36)*k,Vector2(40,9)*k),roof)
 if index==0:
  draw_rect(Rect2(Vector2(-4,-58)*k,Vector2(8,23)*k),roof); draw_colored_polygon(PackedVector2Array([Vector2(0,-65),Vector2(-12,-52),Vector2(12,-52)]),roof)
 elif index==1:
  draw_circle(Vector2(0,-48)*k,13*k,Color("d99a63")); draw_rect(Rect2(Vector2(-6,-58)*k,Vector2(12,20)*k),Color("4c3b3b"))
 elif index==2:
  draw_rect(Rect2(Vector2(-5,-60)*k,Vector2(10,24)*k),Color("a5e5f2")); draw_rect(Rect2(Vector2(-15,-50)*k,Vector2(30,5)*k),roof)
 elif index==3:
  draw_arc(Vector2(0,-47)*k,17*k,0,TAU,10,Color("d8c7ff"),5*k); draw_rect(Rect2(Vector2(-3,-67)*k,Vector2(6,22)*k),roof)
 elif index==4:
  draw_rect(Rect2(Vector2(-18,-55)*k,Vector2(8,28)*k),roof); draw_rect(Rect2(Vector2(10,-55)*k,Vector2(8,28)*k),roof); draw_line(Vector2(-14,-55)*k,Vector2(14,-55)*k,Color("d7d9c6"),4*k)
 elif index==5:
  draw_rect(Rect2(Vector2(-3,-66)*k,Vector2(6,38)*k),roof); draw_circle(Vector2(0,-67)*k,10*k,Color("f1d783"))
 elif index==6:
  draw_rect(Rect2(Vector2(-6,-62)*k,Vector2(12,31)*k),roof); draw_rect(Rect2(Vector2(-14,-52)*k,Vector2(28,5)*k),Color("f3d280"))
 elif index==7:
  draw_rect(Rect2(Vector2(-4,-74)*k,Vector2(8,44)*k),roof); draw_colored_polygon(PackedVector2Array([Vector2(0,-79),Vector2(-16,-65),Vector2(16,-65)]),roof)
 elif index==8:
  draw_rect(Rect2(Vector2(-19,-48)*k,Vector2(38,9)*k),roof); draw_rect(Rect2(Vector2(-12,-62)*k,Vector2(7,24)*k),roof); draw_rect(Rect2(Vector2(5,-62)*k,Vector2(7,24)*k),roof)
 elif index==9:
  draw_rect(Rect2(Vector2(-2,-76)*k,Vector2(4,50)*k),roof); draw_rect(Rect2(Vector2(-15,-55)*k,Vector2(30,4)*k),roof)
 elif index==10:
  draw_rect(Rect2(Vector2(-15,-52)*k,Vector2(30,8)*k),roof); draw_colored_polygon(PackedVector2Array([Vector2(0,-69),Vector2(-13,-53),Vector2(13,-53)]),roof)
 elif index==11:
  draw_rect(Rect2(Vector2(-18,-60)*k,Vector2(36,5)*k),roof); draw_rect(Rect2(Vector2(-6,-73)*k,Vector2(12,22)*k),roof); draw_circle(Vector2(0,-78)*k,8*k,Color("e8d48a"))

func draw_map() -> void:
 var index=battle.map_index
 var base=[Color("557347"),Color("324f61"),Color("6b98af"),Color("29483e")][index]
 draw_rect(Rect2(0,0,1000,550),base)
 # Seeded deterministic pixel texture; cosmetic only.
 for i in range(320):
  var p=Vector2((i*173)%1000,(i*89)%550)
  var color=base.lightened(0.035) if i%2==0 else base.darkened(0.05)
  draw_rect(Rect2(p,Vector2(3+i%5,2)),color)
 if index==1:
  for i in range(12):
   draw_line(Vector2(0,45+i*42),Vector2(1000,45+i*42),Color(0.53,0.73,0.78,0.2),3)
 elif index==2:
  for i in range(15):
   var p=Vector2((i*153+int(clock*3))%1150-80,(i*127)%540)
   draw_rect(Rect2(p,Vector2(110,19)),Color(0.84,0.91,0.93,0.22))
  for p in battle.pads:
   draw_colored_polygon(PackedVector2Array([p+Vector2(-48,22),p+Vector2(48,22),p+Vector2(22,65),p+Vector2(-20,61)]),Color("486779"))
   draw_rect(Rect2(p-Vector2(48,25),Vector2(96,48)),Color("6b805d"))
 for route in battle.ground_routes:
  var points=PackedVector2Array(route)
  draw_polyline(points,Color("263c33") if index!=1 else Color("283c43"),47,false)
  draw_polyline(points,Color("a4a078") if index!=1 else Color("8d9990"),36,false)
  draw_polyline(points,Color("b3ad86") if index!=1 else Color("a9b0a0"),24,false)
  var length=CxCatalog.path_length(route)
  for j in range(int(length/17)):
   var p=CxCatalog.path_position(route,j*17)
   draw_rect(Rect2(p+Vector2(j%5-3,4),Vector2(6,3)),Color(0.36,0.37,0.27,0.32))
  if index==1:
   for q in range(int(length/36)):
    var p=CxCatalog.path_position(route,q*36)
    draw_rect(Rect2(p-Vector2(3,22),Vector2(6,44)),Color(0.75,0.74,0.61,0.4))
   for k in range(int(length/84)+1):
    var arrow_at=CxCatalog.path_position(route,fmod(k*84.0+clock*18.0,length))
    var arrow_next=CxCatalog.path_position(route,fmod(k*84.0+clock*18.0+14.0,length))
    var arrow_dir=(arrow_next-arrow_at).normalized()
    var arrow_side=arrow_dir.orthogonal()*5.0
    draw_line(arrow_at-arrow_dir*9.0,arrow_at+arrow_dir*7.0,Color(0.98,0.86,0.5,0.38),2)
    draw_line(arrow_at+arrow_dir*7.0,arrow_at+arrow_side-arrow_dir*1.0,Color(0.98,0.86,0.5,0.38),2)
    draw_line(arrow_at+arrow_dir*7.0,arrow_at-arrow_side-arrow_dir*1.0,Color(0.98,0.86,0.5,0.38),2)
 var air_route=battle.aerial_route
 for j in range(int(CxCatalog.path_length(air_route)/35)):
  var p=CxCatalog.path_position(air_route,j*35)
  draw_rect(Rect2(p,Vector2(7,2)),Color(0.69,0.87,0.94,0.4))
 for m in range(int(CxCatalog.path_length(air_route)/105)+1):
  var arrow_at=CxCatalog.path_position(air_route,fmod(m*105.0+clock*22.0,CxCatalog.path_length(air_route)))
  var arrow_next=CxCatalog.path_position(air_route,fmod(m*105.0+clock*22.0+18.0,CxCatalog.path_length(air_route)))
  var arrow_dir=(arrow_next-arrow_at).normalized()
  draw_line(arrow_at-arrow_dir*8.0,arrow_at+arrow_dir*7.0,Color(0.75,0.93,1.0,0.6),2)
  draw_line(arrow_at+arrow_dir*7.0,arrow_at+arrow_dir.orthogonal()*4.0,Color(0.75,0.93,1.0,0.6),2)
  draw_line(arrow_at+arrow_dir*7.0,arrow_at-arrow_dir.orthogonal()*4.0,Color(0.75,0.93,1.0,0.6),2)
 for i in range(26):
  var p=Vector2((i*157+48)%950,(i*111+20)%550)
  var near=false
  for route in battle.ground_routes:
   for segment in range(1,route.size()):
    if p.distance_to(Geometry2D.get_closest_point_to_segment(p,route[segment-1],route[segment]))<48: near=true
  for pad in battle.pads:
   if p.distance_to(pad)<60: near=true
  if near or index in [1,2]: continue
  tree(p,Color("163e35") if index==3 else Color("2c523e"))

func tree(p:Vector2,color:Color) -> void:
 draw_rect(Rect2(p+Vector2(-3,-13),Vector2(6,18)),Color("4b4834"))
 for level in range(3):
  var width=18+level*12
  draw_colored_polygon(PackedVector2Array([p+Vector2(0,-62+level*14),p+Vector2(-width,-30+level*14),p+Vector2(width,-30+level*14)]),color.lightened(0.025*level))

func draw_effect(fx:Dictionary) -> void:
 var progress=1.0-fx.life/maxf(0.01,fx.max)
 var p=fx.pos
 if fx.type=="bolt":
  var points=PackedVector2Array([fx.from,fx.from.lerp(p,0.25)+Vector2(0,-9),fx.from.lerp(p,0.5)+Vector2(0,9),fx.from.lerp(p,0.75)+Vector2(0,-5),p])
  draw_polyline(points,Color(0.35,0.8,1.0,0.2),10,false)
  draw_polyline(points,Color("d2edfa"),3,false)
  for point in points:
   draw_rect(Rect2(point-Vector2(3,3),Vector2(6,6)),Color("88eaff"))
  return
 if fx.type=="death":
  draw_rect(Rect2(p+Vector2(-13,0),Vector2(26,5)),Color(0.08,0.14,0.16,1-progress))
  for i in range(5):
   var spark=Vector2(float(i-2)*7.0,-10.0-progress*18.0+sin(clock*4.0+i)*4.0)
   draw_rect(Rect2(p+spark,Vector2(3,3)),Color(0.95,0.68,0.32,1.0-progress))
  return
 if fx.type=="meteor":
  draw_circle(p,fx.radius*0.72,Color(1,0.45,0.14,0.08))
  draw_arc(p,fx.radius,0,TAU,32,Color("efb767"),2)
  draw_arc(p,fx.radius*0.78,0,TAU,24,Color(1,0.82,0.38,0.45),2)
  for i in range(3):
   var at=p+Vector2((i-1)*32,-200*(1-progress))
   draw_line(at-Vector2(24,45),at,Color("eea357"),8)
   draw_rect(Rect2(at-Vector2(8,8),Vector2(16,16)),Color("ffe0a1"))
  return
 var color=Color("f1b66d")
 if fx.type in ["ice","barrier"]: color=Color("b8efff")
 if fx.type in ["summon","shell"]: color=Color("bf90ed")
 if fx.type in ["build","upgrade"]: color=Color("e8d399")
 if fx.type=="warning": color=Color("f88660")
 color.a=1.0-progress
 if fx.type in ["summon","warning","shock","barrier","rage"]: draw_arc(p,fx.radius*maxf(0.3,progress),0,TAU,24,color,3)
 if fx.type=="barrier":
  draw_arc(p,fx.radius*0.72,clock*2,clock*2+4.6,28,Color(0.62,0.9,1,0.8),3)
  draw_arc(p,fx.radius*0.55,-clock*2,-clock*2+4.1,24,Color(0.95,0.82,0.38,0.7),2)
 for i in range(12 if not reduced else 4):
  var angle=float(i)*TAU/12
  var distance=fx.radius*progress*(0.8+float(i%3)*0.1)
  var at=p+Vector2(cos(angle),sin(angle))*distance
  draw_rect(Rect2(at,Vector2(3+i%3,3+i%3)),color)
