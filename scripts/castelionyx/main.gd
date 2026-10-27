extends Control

var persistence=CxPersistence.new()
var battle:Variant=null
var world:CxWorld
var ui:Control
var overlay:Control
var page=""
var selected_map=0
var modifiers:Array=[]
var selected_slot=-1
var selected_spell=-1
var battle_mode="infinite"
var hud:Label
var status_label:Label
var boss_label:Label
var hint:Label
var skill_button:Button
var next_button:Button
var speed_button:Button
var spell_buttons:Array=[]
var intro_time=0.0
var battle_top:VBoxContainer
var battle_bottom:VBoxContainer
var spell_grid:GridContainer
var action_grid:GridContainer
var intro_button:Button
var update_clock=0.0
var result_reward=-2
var previous_result:Dictionary={}
var profile_avatar=0
var profile_photo=""
var profile_name:LineEdit
var profile_country:LineEdit
var toast:Label
var toast_time=0.0
var song_boss=false
var photo_callback:Variant=null
var pointer_touch=false
var returning_from_settings="menu"
var font=preload("res://assets/template/fonts/ui_regular.tres")

func _ready() -> void:
 name="Castelionyx"
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 mouse_filter=Control.MOUSE_FILTER_PASS
 theme=create_theme()
 world=CxWorld.new()
 world.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(world)
 ui=Control.new()
 ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 ui.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(ui)
 overlay=Control.new()
 overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(overlay)
 toast=Label.new()
 toast.add_theme_font_size_override("font_size",17)
 toast.add_theme_color_override("font_color",Color("fae4b5"))
 toast.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(toast)
 setup_audio()
 resized.connect(layout_world)
 if persistence.has_profile(): show_menu()
 else: show_intro()

func create_theme() -> Theme:
 var th=Theme.new()
 th.default_font=font
 th.default_font_size=18
 for type in ["Label","Button","CheckButton","LineEdit","OptionButton"]:
  th.set_color("font_color",type,Color("f0dfb8"))
 th.set_stylebox("normal","Button",box(Color("213a42"),Color("5b7769"),2))
 th.set_stylebox("hover","Button",box(Color("345359"),Color("d6ae71"),2))
 th.set_stylebox("pressed","Button",box(Color("bc955d"),Color("f3ddb0"),2))
 th.set_stylebox("disabled","Button",box(Color("192d33"),Color("34484a"),1))
 th.set_color("font_disabled_color","Button",Color("708887"))
 th.set_stylebox("normal","LineEdit",box(Color("14272e"),Color("718779"),2))
 th.set_stylebox("focus","LineEdit",box(Color("1d353c"),Color("ddb97b"),2))
 th.set_stylebox("panel","PanelContainer",box(Color(0.06,0.13,0.16,0.96),Color("806746"),2))
 th.set_constant("separation","VBoxContainer",10)
 th.set_constant("separation","HBoxContainer",10)
 return th

func box(color:Color,border:Color,width:int=1) -> StyleBoxFlat:
 var style=StyleBoxFlat.new()
 style.bg_color=color
 style.border_color=border
 style.set_border_width_all(width)
 style.content_margin_left=16
 style.content_margin_right=16
 style.content_margin_top=12
 style.content_margin_bottom=12
 return style

func clear(container:Node) -> void:
 for child in container.get_children():
  container.remove_child(child)
  child.queue_free()

func begin_page(which:String,title:String,subtitle:String="") -> VBoxContainer:
 page=which
 clear(ui)
 clear(overlay)
 overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE
 world.battle=null
 battle=null
 world.aiming=-1
 selected_slot=-1
 selected_spell=-1
 var margin=MarginContainer.new()
 margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 margin.add_theme_constant_override("margin_left",24)
 margin.add_theme_constant_override("margin_right",24)
 margin.add_theme_constant_override("margin_top",22)
 margin.add_theme_constant_override("margin_bottom",20)
 if which in ["menu","intro"] and get_viewport_rect().size.x>get_viewport_rect().size.y*1.15:
  margin.add_theme_constant_override("margin_right",int(get_viewport_rect().size.x*0.52))
 ui.add_child(margin)
 var scroll=ScrollContainer.new()
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 margin.add_child(scroll)
 var column=VBoxContainer.new()
 column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 scroll.add_child(column)
 if title!="": label(column,title,32,Color("eed4a0"))
 if subtitle!="": label(column,subtitle,16,Color("a9c0b7"))
 return column

func label(parent:Node,text:String,font_size:int=18,color:Color=Color("eee0c1")) -> Label:
 var value=Label.new()
 value.text=text
 value.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 value.add_theme_font_size_override("font_size",font_size)
 value.add_theme_color_override("font_color",color)
 value.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 parent.add_child(value)
 return value

func button(parent:Node,text:String,action:Callable,primary:bool=false) -> Button:
 var b=Button.new()
 b.text=text
 b.custom_minimum_size.y=56
 b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 b.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
 if primary:
  b.add_theme_stylebox_override("normal",box(Color("be965e"),Color("ebd2a0"),2))
  b.add_theme_color_override("font_color",Color("172c31"))
 b.pressed.connect(func():
  AudioDirector.unlock_audio()
  AudioDirector.play_cue("ui.confirm")
  action.call()
 )
 parent.add_child(b)
 return b

func back(parent:Node,action:Callable=show_menu) -> void:
 button(parent,"Voltar",action)

func card(parent:Node) -> VBoxContainer:
 var panel=PanelContainer.new()
 panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 parent.add_child(panel)
 var content=VBoxContainer.new()
 panel.add_child(content)
 return content

func art(parent:Node,kind:String,index:int,height:float=90.0) -> TextureRect:
 var image=TextureRect.new()
 image.texture=world.atlas(kind,index)
 image.custom_minimum_size=Vector2(height,height)
 image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 image.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 image.mouse_filter=Control.MOUSE_FILTER_IGNORE
 parent.add_child(image)
 return image

func show_intro() -> void:
 AudioDirector.set_game_paused(false)
 var col=begin_page("intro","","")
 intro_time=0.0
 var spacer=Control.new()
 spacer.custom_minimum_size.y=80
 col.add_child(spacer)
 art(col,"building",6,145)
 label(col,"CASTELIONYX",40,Color("efce89"))
 label(col,"DEFESA DO REINO",18)
 label(col,"Seu castelo está esperando. O primeiro toque libera o áudio.",18,Color("bcc9b8"))
 intro_button=button(col,"CRIAR CONTA LOCAL",func():
  AudioDirector.play_music("music.title",0.7)
  show_profile(false)
 ,true)
 intro_button.disabled=true
 label(col,"Perfil e progresso ficam somente neste navegador. Nenhuma conta online será criada.",14)

func show_menu() -> void:
 AudioDirector.set_game_paused(false)
 AudioDirector.stop_music(0.8)
 var col=begin_page("menu","CASTELIONYX","DEFESA DO REINO")
 var header=HBoxContainer.new()
 col.add_child(header)
 var avatar_view=art(header,"hero",int(persistence.data.profile.get("avatar",0)),64)
 var photo=str(persistence.data.profile.get("photo",""))
 if photo.begins_with("data:image/") and photo.contains(";base64,"):
  var bytes=Marshalls.base64_to_raw(photo.split(";base64,",true,1)[1])
  var image=Image.new()
  var loaded=image.load_png_from_buffer(bytes) if photo.begins_with("data:image/png") else image.load_jpg_from_buffer(bytes)
  if loaded==OK and image.get_width()<=512 and image.get_height()<=512:
   avatar_view.texture=ImageTexture.create_from_image(image)
 var texts=VBoxContainer.new()
 texts.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 header.add_child(texts)
 label(texts,str(persistence.data.profile.get("name","Defensor")),22)
 label(texts,"%d gemas · Melhor: %d ondas" % [persistence.data.gems,persistence.data.stats.best],16,Color("dcc38c"))
 button(col,"JOGAR · DEFESA INFINITA",func(): show_setup("infinite"),true)
 var grid=GridContainer.new()
 grid.columns=2
 col.add_child(grid)
 button(grid,"Heróis",func(): show_collection("heroes"))
 button(grid,"Estruturas",func(): show_collection("towers"))
 button(grid,"Feitiços",func(): show_collection("spells"))
 button(grid,"Mapas",show_maps)
 button(grid,"Modo Aventura",func(): show_setup("adventure"))
 button(grid,"Perfil",func(): show_profile(true))
 button(grid,"Estatísticas",show_stats)
 button(grid,"Configurações",func(): show_settings("menu"))
 label(col,"Defenda as rotas. Toque nos espaços de pedra para construir. Use o herói e os feitiços quando o cerco apertar.",16,Color("abc0b3"))
 label(col,"SEM ANÚNCIOS · SALVAMENTO LOCAL",12,Color("a1af9e"))

func show_maps() -> void:
 var col=begin_page("maps","Campos de batalha","Cada cenário tem rotas e posições próprias.")
 for i in range(4):
  var c=card(col)
  label(c,CxCatalog.MAPS[i].name,22)
  label(c,CxCatalog.MAPS[i].tag+" · "+CxCatalog.MAPS[i].desc,16)
  label(c,"%d posições de construção · %d rota(s) terrestre(s) + rota aérea" % [CxCatalog.MAPS[i].pads.size(),CxCatalog.MAPS[i].ground.size()],14,Color("b7cab9"))
  button(c,"Selecionado" if selected_map==i else "Escolher mapa",func(): selected_map=i; show_maps(),selected_map==i)
 back(col)

func show_collection(kind:String) -> void:
 var names={"heroes":"Heróis","towers":"Estruturas","spells":"Feitiços"}
 var col=begin_page(kind,names[kind],"Saldo: %d gemas · melhorias permanentes até nível 10" % persistence.data.gems)
 var items=CxCatalog.HEROES if kind=="heroes" else CxCatalog.TOWERS if kind=="towers" else CxCatalog.SPELLS
 for i in range(items.size()):
  var d=items[i]
  var level=int(persistence.data[kind][i])
  var c=card(col)
  var row=HBoxContainer.new()
  c.add_child(row)
  if kind!="spells": art(row,"hero" if kind=="heroes" else "building",d.sprite,78)
  var info=VBoxContainer.new()
  info.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  row.add_child(info)
  label(info,d.name,21)
  label(info,"BLOQUEADO" if level==0 else "Nível %d%s" % [level," · SELECIONADO" if kind=="heroes" and persistence.data.selected==i else ""],15,Color("d9bb7e"))
  label(c,d.desc,16)
  if kind=="heroes":
   var h=CxCatalog.hero(i,maxi(level,1))
   label(c,"Vida %.0f · Dano %.0f · %.2fs por ataque\nAlcance %.0f · Movimento %.0f · %s · Recarga %.0fs" % [h.hp,h.damage,h.interval,h.range,h.speed,h.skill,h.cooldown],14,Color("adc5be"))
   var select=button(c,"Selecionar herói",func():
    if persistence.select_hero(i): show_collection(kind)
    else: notify("Herói bloqueado ou salvamento indisponível.")
   )
   select.disabled=level==0 or persistence.data.selected==i
  elif kind=="towers":
   var t=CxCatalog.tower(i,1,level)
   label(c,"Construção: %d ouro · Vida %.0f · Dano %.0f\nAlcance %.0f · Ataque %.2fs · 3 níveis na partida\nA melhoria permanente aumenta o dano em 6%% por nível." % [t.cost,t.hp,t.damage,t.range,t.interval],14,Color("adc5be"))
  else:
   label(c,"Recarga-base %.0fs · Duração-base %.1fs\nMelhorias aumentam a força/duração e reduzem a recarga." % [d.cooldown,d.duration],14,Color("adc5be"))
  var cost=persistence.purchase_cost(kind,i)
  var buy=button(c,"Nível máximo" if level>=10 else "%s · %d gemas" % ["Desbloquear" if level==0 else "Melhorar",cost],func():
   if persistence.buy(kind,i):
    AudioDirector.play_cue("score.reward")
    show_collection(kind)
   else: notify("Saldo insuficiente ou falha ao salvar.")
  )
  buy.disabled=level>=10 or persistence.data.gems<cost
 back(col)

func show_setup(mode:String) -> void:
 battle_mode=mode
 var col=begin_page("setup","Modo Aventura" if mode=="adventure" else "Defesa infinita","Prepare as defesas antes de abrir os portões.")
 var option=OptionButton.new()
 option.custom_minimum_size.y=58
 for map in CxCatalog.MAPS: option.add_item(map.name)
 option.selected=selected_map
 option.item_selected.connect(func(index): selected_map=index)
 col.add_child(option)
 label(col,"Herói: "+CxCatalog.HEROES[persistence.data.selected].name,19)
 if mode=="adventure":
  var c=card(col)
  label(c,"Cinco ondas. Uma única recompensa integral.",20)
  label(c,"1 Enxame · sem herói\n2 Velocidade\n3 Céu e Terra\n4 Resistência\n5 Chefe multifases + reforços\nPoucos espaços. 540 de ouro inicial.",16)
  label(c,"Prêmio: 1.000 gemas na primeira conclusão integral." if not persistence.data.stats.adventure_claimed else "Prêmio integral já recebido. Replays contam para o recorde, sem repetir as 1.000 gemas.",16,Color("e8c67f"))
 else:
  label(col,"Gemas da partida = ondas completas ÷ 10, arredondado para baixo. Chefes a cada dez ondas.",16)
  for d in CxCatalog.MODIFIERS:
   var check=CheckButton.new()
   check.text=d.name
   check.button_pressed=modifiers.has(d.id)
   check.custom_minimum_size.y=52
   check.toggled.connect(func(pressed):
    if pressed and not modifiers.has(d.id): modifiers.append(d.id)
    elif not pressed: modifiers.erase(d.id)
   )
   col.add_child(check)
   label(col,d.desc,14,Color("aec3b9"))
 button(col,"DEFENDER O REINO",func(): launch(mode),true)
 back(col)

func launch(mode:String) -> void:
 previous_result=persistence.data.stats.last.duplicate(true)
 battle=CxBattle.new(selected_map,mode,modifiers if mode=="infinite" else [],persistence.data)
 battle_mode=mode
 world.battle=battle
 world.reduced=not persistence.data.settings.quality
 selected_slot=-1
 selected_spell=-1
 result_reward=-2
 song_boss=false
 AudioDirector.set_game_paused(false)
 AudioDirector.play_music("music.gameplay",0.8)
 apply_volumes()
 show_battle_ui()

func show_battle_ui() -> void:
 page="battle"
 clear(ui)
 clear(overlay)
 overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE
 world.battle=battle
 world.selected_slot=selected_slot
 world.aiming=selected_spell
 var top=VBoxContainer.new()
 top.position=Vector2(12,10)
 top.size=Vector2(get_viewport_rect().size.x-24,118)
 battle_top=top
 ui.add_child(top)
 var row=HBoxContainer.new()
 top.add_child(row)
 hud=label(row,"",18)
 hud.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 speed_button=button(row,"%dx" % battle.speed,func(): battle.speed=2 if battle.speed==1 else 1; speed_button.text="%dx" % battle.speed)
 speed_button.custom_minimum_size=Vector2(56,48)
 speed_button.size_flags_horizontal=Control.SIZE_SHRINK_END
 var pause=button(row,"Pausa",show_pause)
 pause.custom_minimum_size=Vector2(76,48)
 pause.size_flags_horizontal=Control.SIZE_SHRINK_END
 status_label=label(top,"",16,Color("b5c6b6"))
 boss_label=label(top,"",16,Color("f4b789"))
 var bottom=VBoxContainer.new()
 bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
 bottom.offset_left=12
 bottom.offset_right=-12
 bottom.offset_top=-192
 bottom.offset_bottom=-12
 battle_bottom=bottom
 ui.add_child(bottom)
 hint=label(bottom,"Toque num espaço de pedra para construir. Toque na rota para mover o herói.",15,Color("c8d1bd"))
 var spells_row=GridContainer.new()
 spells_row.columns=5
 spell_grid=spells_row
 bottom.add_child(spells_row)
 spell_buttons=[]
 for i in range(5):
  var b=button(spells_row,CxCatalog.SPELLS[i].short,func(): choose_spell(i))
  b.add_theme_font_size_override("font_size",14)
  b.custom_minimum_size.y=54
  spell_buttons.append(b)
 var action_row=GridContainer.new()
 action_row.columns=2
 action_grid=action_row
 bottom.add_child(action_row)
 skill_button=button(action_row,"Habilidade do herói",func():
  if battle.skill(): notify("Habilidade ativada!")
  else: notify("Habilidade indisponível.")
 )
 skill_button.add_theme_font_size_override("font_size",16)
 next_button=button(action_row,"Iniciar onda",func(): battle.start_wave())
 next_button.add_theme_font_size_override("font_size",16)
 layout_world()
 refresh_hud()
 call_deferred("layout_world")

func layout_world() -> void:
 if world==null or battle==null: return
 var viewport=get_viewport_rect().size
 var landscape=viewport.x>viewport.y*1.15
 if battle_top!=null:
  battle_top.size.x=viewport.x-24
 if landscape:
  world.set_field(Rect2(12,132,viewport.x-246,maxf(120,viewport.y-146)))
  if battle_bottom!=null:
   spell_grid.columns=2
   action_grid.columns=1
   battle_bottom.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
   battle_bottom.position=Vector2(viewport.x-218,132)
   battle_bottom.size=Vector2(206,viewport.y-130)
   for b in spell_buttons: b.custom_minimum_size.y=44
   skill_button.custom_minimum_size.y=46
   next_button.custom_minimum_size.y=46
 else:
  world.set_field(Rect2(8,138,viewport.x-16,maxf(140,viewport.y-346)))
  if battle_bottom!=null:
   battle_bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
   battle_bottom.offset_left=12
   battle_bottom.offset_right=-12
   battle_bottom.offset_top=-192
   battle_bottom.offset_bottom=-12
   spell_grid.columns=5
   action_grid.columns=2
   for b in spell_buttons: b.custom_minimum_size.y=54
   skill_button.custom_minimum_size.y=56
   next_button.custom_minimum_size.y=56

func refresh_hud() -> void:
 if battle==null or page!="battle" or hud==null: return
 hud.text="CASTELO %.0f/%.0f\n%d OURO · ONDA %d" % [maxf(0,battle.hp),battle.max_hp,battle.gold,maxi(1,battle.wave)]
 status_label.text="Preparação · %ds · %d ondas completas" % [int(ceil(battle.prep)),battle.completed] if battle.state=="preparation" else "Combate · %d vivos · %d por vir" % [battle.alive_count(),battle.pending_count()]
 if battle.mode=="adventure": status_label.text+=" · "+CxCatalog.ADVENTURE_NAMES[clampi(battle.wave-1,0,4)]
 var boss=battle.boss_alive()
 boss_label.text="%s · FASE %d · VIDA %.0f/%.0f" % [boss.name,boss.phase,boss.hp,boss.max_hp] if boss!=null else "Sem herói nesta onda" if not battle.hero_allowed() else "Toque na rota para comandar seu herói"
 next_button.disabled=battle.state!="preparation"
 next_button.text="Iniciar onda %d" % [battle.wave+1] if battle.state=="preparation" else "Onda em combate"
 var living=battle.allies.filter(func(a): return a.kind=="hero" and a.hp>0)
 skill_button.disabled=battle.special_cd>0 or not battle.hero_allowed() or living.is_empty()
 skill_button.text="Habilidade · %ds" % int(ceil(battle.special_cd)) if battle.special_cd>0 else "Habilidade"
 for i in range(5):
  spell_buttons[i].disabled=battle.spells[i]>0
  spell_buttons[i].text=CxCatalog.SPELLS[i].short+("\n%ds" % int(ceil(battle.spells[i])) if battle.spells[i]>0 else "")

func choose_spell(index:int) -> void:
 if battle==null: return
 if index==2:
  if battle.cast(2,Vector2(945,285)): notify("Barreira ativa por %.0fs" % battle.barrier)
  return
 selected_spell=index
 world.aiming=index
 hint.text="%s: toque no campo para marcar o alvo. Esc cancela." % CxCatalog.SPELLS[index].name

func _unhandled_input(event:InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo:
  AudioDirector.unlock_audio()
  if event.keycode==KEY_ESCAPE:
   if page=="battle" and selected_spell>=0:
    selected_spell=-1
    world.aiming=-1
    notify("Feitiço cancelado")
   elif page=="battle": show_pause()
   elif page=="pause": resume()
   return
  if page=="battle":
   if event.keycode==KEY_SPACE: battle.start_wave()
   if event.keycode==KEY_H: battle.skill()
   if event.keycode in [KEY_1,KEY_2,KEY_3,KEY_4,KEY_5]: choose_spell(event.keycode-KEY_1)
 if event is InputEventScreenTouch and event.pressed:
  pointer_touch=true
  handle_field(event.position)
 elif event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and not pointer_touch:
  handle_field(event.position)
 elif event is InputEventScreenTouch and not event.pressed:
  pointer_touch=false

func handle_field(point:Vector2) -> void:
 AudioDirector.unlock_audio()
 if page=="intro": AudioDirector.play_music("music.title",0.5)
 if page!="battle" or battle==null or not world.inside(point): return
 var position_world=world.screen_to_world(point)
 if selected_spell>=0:
  if battle.cast(selected_spell,position_world): notify(CxCatalog.SPELLS[selected_spell].name+" ativado")
  selected_spell=-1
  world.aiming=-1
  return
 for i in range(battle.pads.size()):
  if position_world.distance_to(battle.pads[i])<=42.0:
   selected_slot=i
   show_build(i)
   return
 if battle.move_hero(position_world): notify("Herói em movimento")

func modal(title:String) -> VBoxContainer:
 clear(overlay)
 overlay.mouse_filter=Control.MOUSE_FILTER_STOP
 var shade=ColorRect.new()
 shade.color=Color(0,0.03,0.04,0.82)
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 overlay.add_child(shade)
 var margin=MarginContainer.new()
 margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,24)
 overlay.add_child(margin)
 var scroll=ScrollContainer.new()
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 margin.add_child(scroll)
 var panel=PanelContainer.new()
 panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 scroll.add_child(panel)
 var col=VBoxContainer.new()
 panel.add_child(col)
 label(col,title,26)
 return col

func close_modal() -> void:
 clear(overlay)
 overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE
 if battle!=null:
  battle.paused=false
  AudioDirector.set_game_paused(false)
 apply_volumes()
 page="battle"

func show_build(slot:int) -> void:
 if battle==null: return
 battle.paused=true
 AudioDirector.set_game_paused(true)
 var t=battle.towers[slot]
 var col=modal("Construir defesa" if t==null else CxCatalog.TOWERS[t.kind].name)
 label(col,"Saldo: %d ouro · posição %d" % [battle.gold,slot+1],16)
 if t==null:
  for i in range(6):
   var d=CxCatalog.TOWERS[i]
   var row=HBoxContainer.new()
   col.add_child(row)
   art(row,"building",i,54)
   var b=button(row,"%s · %d ouro" % [d.name,d.cost],func():
    battle.paused=false
    if battle.build(slot,i): close_modal(); notify("Defesa construída")
    else: battle.paused=true; notify("Não há ouro suficiente ou o espaço já está ocupado.")
   )
   b.add_theme_font_size_override("font_size",16)
   b.disabled=battle.gold<d.cost
   label(col,d.desc,14,Color("b6caba"))
 else:
  art(col,"building",t.kind,110)
  var d=CxCatalog.tower(t.kind,t.level,persistence.data.towers[t.kind])
  label(col,"Nível %d/3 · Vida %.0f/%.0f\nDano %.0f · Alcance %.0f · Ataque %.2fs%s" % [t.level,t.hp,t.max_hp,d.damage,d.range,d.interval,"\nSuporte: +25% cadência e +15% alcance" if t.buff else ""],17)
  var cost=CxCatalog.upgrade_cost(t.kind,t.level)
  var b=button(col,"Nível máximo" if t.level>=3 else "Evoluir · %d ouro" % cost,func():
   battle.paused=false
   if battle.upgrade(slot): close_modal(); notify("Defesa evoluída")
   else: battle.paused=true; notify("Melhoria indisponível")
  ,true)
  b.disabled=t.level>=3 or battle.gold<cost
  button(col,"Vender · %d ouro" % int(CxCatalog.TOWERS[t.kind].cost*0.6),func(): battle.paused=false; battle.sell(slot); close_modal())
 back(col,close_modal)
 apply_volumes()

func show_pause() -> void:
 if battle==null: return
 page="pause"
 battle.paused=true
 AudioDirector.set_game_paused(true)
 var col=modal("Cerco pausado")
 label(col,"A simulação está parada. Você não perde vida durante a pausa.",17)
 button(col,"Continuar batalha",resume,true)
 button(col,"Configurações",func(): show_settings("pause"))
 button(col,"Como jogar",func():
  var content=modal("Como defender")
  label(content,"Toque nos espaços de pedra e escolha uma defesa. Ouro é recebido por derrotar invasores. Selecione uma construção para evoluir ou vender.\n\nToque na rota para mover o herói; WASD também funciona. H ativa a habilidade. Gêmeos têm vidas próprias e heróis caídos retornam após 18s.\n\nEscolha um feitiço e toque na área. Barreira protege o castelo imediatamente. Teclas 1–5 escolhem feitiços. Espaço inicia uma onda. Esc pausa ou cancela.\n\nArqueiros, gelo, eletricidade e heróis de alcance mágico atingem voadores. Canhão e combatentes corpo a corpo não. Freeze dá imunidade temporária depois de acabar.\n\nO castelo perde vida quando inimigos chegam ao portão. Vença ondas para ganhar ouro e encare um chefe a cada dez. Construa antes de começar.",17)
  back(content,show_pause)
 )
 button(col,"Encerrar e voltar ao menu",func():
  confirm("Encerrar a partida?","A partida terminará com as ondas já concluídas. A recompensa será calculada uma única vez.",func(): battle.finish(false); complete_run())
 )
 apply_volumes()

func resume() -> void:
 close_modal()
 refresh_hud()

func confirm(title:String,message:String,action:Callable) -> void:
 var col=modal(title)
 label(col,message,18)
 button(col,"Confirmar",action,true)
 back(col,func():
  if battle!=null: show_pause()
  else: show_settings("menu")
 )

func show_settings(from:String="menu") -> void:
 returning_from_settings=from
 var col:VBoxContainer
 if battle!=null:
  page="settings"
  battle.paused=true
  col=modal("Configurações")
 else: col=begin_page("settings","Configurações","Som e preferências salvos neste navegador.")
 for key in ["music","sfx","ui"]:
  var names={"music":"Música","sfx":"Efeitos sonoros","ui":"Sons da interface"}
  var text=label(col,"%s · %d%%" % [names[key],int(persistence.data.settings[key]*100)],18)
  var slider=HSlider.new()
  slider.min_value=0
  slider.max_value=1
  slider.step=0.01
  slider.value=persistence.data.settings[key]
  slider.custom_minimum_size.y=40
  slider.value_changed.connect(func(value):
   persistence.data.settings[key]=value
   text.text="%s · %d%%" % [names[key],int(value*100)]
   apply_volumes()
  )
  slider.drag_ended.connect(func(_changed): persistence.commit())
  col.add_child(slider)
 var quality=CheckButton.new()
 quality.text="Partículas e animações completas"
 quality.button_pressed=persistence.data.settings.quality
 quality.custom_minimum_size.y=52
 quality.toggled.connect(func(value): persistence.data.settings.quality=value; world.reduced=not value; persistence.commit())
 col.add_child(quality)
 button(col,"Velocidade padrão · %dx" % persistence.data.settings.speed,func():
  persistence.data.settings.speed=2 if persistence.data.settings.speed==1 else 1
  persistence.commit()
  show_settings(from)
 )
 button(col,"Alternar tela cheia",func():
  if OS.has_feature("web"):
   JavaScriptBridge.eval("document.fullscreenElement ? document.exitFullscreen() : document.documentElement.requestFullscreen().catch(()=>{});",true)
  else: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
 )
 if battle==null:
  button(col,"Rever introdução",show_intro)
  button(col,"Editar perfil local",func(): show_profile(true))
  button(col,"Reiniciar todo o progresso",func():
   confirm("Apagar o progresso local?","Seu perfil, fotos, gemas, melhorias e estatísticas serão apagados deste navegador. Esta ação não tem desfazer.",func():
    if persistence.reset(): show_intro()
    else: notify(persistence.last_error)
   )
  )
 label(col,"As faixas são gravações cantadas geradas em português. As letras são adaptações originais, não uma gravação fiel da letra enviada.",14,Color("b1c4b7"))
 back(col,func():
  persistence.commit()
  if from=="pause": show_pause()
  else: show_menu()
 )

func show_profile(edit:bool=false) -> void:
 var col=begin_page("profile","Seu perfil local","Não é uma conta online. Perfil e progresso são salvos somente aqui.")
 var saved=persistence.data.profile
 profile_avatar=int(saved.get("avatar",0))
 profile_photo=str(saved.get("photo",""))
 label(col,"Nome do defensor",16)
 profile_name=LineEdit.new()
 profile_name.placeholder_text="Seu nome"
 profile_name.text=str(saved.get("name",""))
 profile_name.max_length=24
 profile_name.custom_minimum_size.y=58
 col.add_child(profile_name)
 label(col,"País",16)
 profile_country=LineEdit.new()
 profile_country.text=str(saved.get("country","Brasil"))
 profile_country.max_length=40
 profile_country.custom_minimum_size.y=58
 col.add_child(profile_country)
 label(col,"Escolha um avatar",18)
 var grid=GridContainer.new()
 grid.columns=4
 col.add_child(grid)
 for i in range(8):
  var b=button(grid,"",func(): profile_avatar=i; profile_photo=""; notify("Avatar escolhido"))
  b.icon=world.atlas("hero",i)
  b.expand_icon=true
  b.icon_alignment=HORIZONTAL_ALIGNMENT_CENTER
  b.custom_minimum_size=Vector2(70,80)
 button(col,"Escolher imagem da galeria",choose_photo)
 button(col,"CONCLUIR PERFIL",func():
  if profile_name.text.strip_edges().is_empty(): notify("Digite seu nome antes de concluir."); return
  if persistence.profile(profile_name.text,profile_country.text,profile_avatar,profile_photo): show_menu()
  else: notify(persistence.last_error)
 ,true)
 if edit: back(col)

func choose_photo() -> void:
 if OS.has_feature("web"):
  if photo_callback==null:
   photo_callback=JavaScriptBridge.create_callback(func(args):
    if args.size()>0:
     profile_photo=str(args[0]).left(160000)
     notify("Foto redimensionada e selecionada")
   )
  var window=JavaScriptBridge.get_interface("window")
  window.castelionyxPhotoReady=photo_callback
  JavaScriptBridge.eval("(()=>{const i=document.createElement('input');i.type='file';i.accept='image/*';i.onchange=()=>{const f=i.files[0];if(!f||f.size>15000000)return;const u=URL.createObjectURL(f),im=new Image();im.onload=()=>{const c=document.createElement('canvas');c.width=c.height=96;const x=c.getContext('2d');const scale=Math.max(96/im.width,96/im.height);x.drawImage(im,(96-im.width*scale)/2,(96-im.height*scale)/2,im.width*scale,im.height*scale);window.castelionyxPhotoReady(c.toDataURL('image/jpeg',0.78));URL.revokeObjectURL(u);};im.src=u;};i.click();})();",true)
 else:
  var dialog=FileDialog.new()
  dialog.file_mode=FileDialog.FILE_MODE_OPEN_FILE
  dialog.access=FileDialog.ACCESS_FILESYSTEM
  dialog.add_filter("*.png,*.jpg,*.jpeg,*.webp","Imagens")
  add_child(dialog)
  dialog.file_selected.connect(func(path):
   var image=Image.load_from_file(path)
   if image!=null:
    image.resize(96,96,Image.INTERPOLATE_LANCZOS)
    profile_photo="data:image/png;base64,"+Marshalls.raw_to_base64(image.save_png_to_buffer())
    notify("Foto selecionada")
   dialog.queue_free()
  )
  dialog.popup_centered(Vector2i(600,400))

func show_stats() -> void:
 var s=persistence.data.stats
 var col=begin_page("stats","Estatísticas","Seu histórico local do reino")
 label(card(col),"Partidas: %d\nOndas concluídas: %d\nChefes derrotados: %d\nTempo de combate: %s\nMelhor: %d ondas\nPior: %s\nAventura: %d/5 · %d tentativas" % [s.total,s.waves,s.bosses,time_string(s.time),s.best,"nenhuma partida" if s.worst<0 else str(s.worst)+" ondas",s.adventure_best,s.adventure_attempts],20)
 label(col,"Pior partida significa a menor quantidade de ondas completas, inclusive zero. Não é a onda onde ocorreu a derrota.",15)
 if not s.last.is_empty():
  var last=s.last
  label(card(col),"Última partida\n%d ondas completas · %d chefes\nTempo %s · %d gemas" % [last.get("completed",0),last.get("bosses",0),time_string(last.get("time",0)),last.get("gems",0)],18)
 back(col)

func time_string(seconds:float) -> String:
 return "%dm %02ds" % [int(seconds/60.0),int(seconds)%60]

func complete_run() -> void:
 if battle==null or battle.terminal.is_empty(): return
 AudioDirector.set_game_paused(false)
 if result_reward==-2 or result_reward==-1: result_reward=persistence.record(battle.terminal)
 var result=battle.terminal
 page="result"
 clear(ui)
 clear(overlay)
 overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE
 world.battle=battle
 if result.victory: AudioDirector.stop_music(0.5); AudioDirector.play_cue("game.victory")
 else: AudioDirector.play_music("music.defeat",0.65)
 apply_volumes()
 var col=modal("O REINO RESISTIU!" if result.victory else "A MURALHA CAIU")
 label(col,"Aventura concluída" if result.victory else "Derrota na onda %d" % result.defeat_wave,20,Color("e4bf7e"))
 art(col,"building",6 if result.victory else 7,118)
 label(col,"%d ONDAS COMPLETAS\n%d chefes derrotados · %s\n%d ouro obtido · %s gemas\nRecorde: %d ondas" % [result.completed,result.bosses,time_string(result.time),result.earned,str(maxi(0,result_reward)),persistence.data.stats.best],20)
 if not previous_result.is_empty(): label(col,"Comparação com a última: %+d ondas completas" % [result.completed-int(previous_result.get("completed",0))],16)
 if result_reward<0:
  label(col,"O salvamento falhou; a recompensa ainda não foi confirmada.",16)
  button(col,"Tentar salvar resultado",complete_run)
 button(col,"REVANCHE",func(): launch(battle_mode),true)
 button(col,"Voltar ao reino",show_menu)

func notify(message:String) -> void:
 toast.text=message
 toast_time=3.0
 toast.visible=true
 var viewport=get_viewport_rect().size
 toast.position=Vector2(18,viewport.y-24)
 toast.size=Vector2(viewport.x-36,25)

func _process(delta:float) -> void:
 if page=="intro":
  intro_time+=delta
  if intro_button!=null: intro_button.disabled=intro_time<3.0
 if toast_time>0:
  toast_time-=delta
  toast.visible=toast_time>0
 if battle==null: return
 if page=="battle":
  var move=Input.get_vector("move_left","move_right","move_up","move_down")
  if move.length()>0 and battle.hero_allowed():
   battle.hero_target=Vector2(clampf(battle.hero_target.x+move.x*140.0*delta*battle.speed,15,905),clampf(battle.hero_target.y+move.y*140.0*delta*battle.speed,70,505))
  battle.advance(delta)
  update_clock+=delta
  if update_clock>0.18:
   refresh_hud()
   update_clock=0.0
  for event in battle.events:
   play_event(event)
  battle.events.clear()
  var current=battle.boss_alive()!=null
  if current!=song_boss:
   song_boss=current
   AudioDirector.boss_intensity(current)
  if battle.state=="finished": complete_run()

func setup_audio() -> void:
 apply_volumes()

func apply_volumes() -> void:
 for pair in [["Music","music"],["SFX","sfx"],["UI","ui"]]:
  var index=AudioServer.get_bus_index(pair[0])
  if index>=0:
   var value=float(persistence.data.settings[pair[1]])
   AudioServer.set_bus_volume_db(index,linear_to_db(maxf(value,0.0001))-(7.0 if pair[0]=="Music" and battle!=null and battle.paused else 0.0))
   AudioServer.set_bus_mute(index,value<=0.001)

func play_event(event:Dictionary) -> void:
 var maps={"build":"build","upgrade":"upgrade","coin":"score.reward","cannon":"cannon","arrow":"arrow","explosion":"explosion","ice":"ice","lightning":"lightning","summon":"summon","breach":"enemy.impact","boss":"boss","boss_down":"boss_down","skill":"player.action","wave":"wave","victory":"game.victory","defeat":"game.defeat"}
 if maps.has(event.type): AudioDirector.play_cue(maps[event.type])
 if event.type=="boss": notify(event.name+" entrou no campo!")
 if event.type=="phase": notify("%s · Fase %d" % [event.name,event.phase])
