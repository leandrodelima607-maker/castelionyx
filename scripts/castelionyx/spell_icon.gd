class_name CxSpellIcon
extends Control

var spell_index:int=0
var pulse:float=0.0

func _ready() -> void:
	custom_minimum_size=Vector2(64,64)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST

func setup(index:int) -> CxSpellIcon:
	spell_index=index
	queue_redraw()
	return self

func _process(delta:float) -> void:
	pulse+=delta
	queue_redraw()

func _draw() -> void:
	var c=[Color("e88b50"),Color("8fd9ef"),Color("83c8df"),Color("e2c45f"),Color("d9d9e8"),Color("7caed0"),Color("e3a65c"),Color("8a7961"),Color("e6bb63"),Color("79b46f")][clampi(spell_index,0,9)]
	var dark=c.darkened(0.45)
	draw_rect(Rect2(8,8,48,48),Color("13262d"))
	draw_rect(Rect2(11,11,42,42),Color("203d45"))
	match spell_index:
		0:
			draw_colored_polygon(PackedVector2Array([Vector2(32,8),Vector2(42,26),Vector2(36,26),Vector2(47,45),Vector2(29,34),Vector2(24,47),Vector2(21,29),Vector2(15,29)]),c)
			draw_rect(Rect2(28,17,6,25),Color("fff0a6"))
		1:
			draw_colored_polygon(PackedVector2Array([Vector2(32,12),Vector2(43,27),Vector2(37,48),Vector2(25,48),Vector2(20,27)]),c)
			for x in [23,32,41]: draw_rect(Rect2(x,25,3,12),Color("e4fbff"))
		2:
			draw_rect(Rect2(17,17,30,30),dark)
			draw_rect(Rect2(21,21,22,22),c)
			draw_rect(Rect2(27,27,10,16),Color("203d45"))
			draw_arc(Vector2(32,25),17,PI,TAU,12,Color("e9f4ee"),3)
		3:
			for p in [Vector2(19,18),Vector2(36,18),Vector2(28,32),Vector2(44,35)]: draw_circle(p,6,c)
			draw_line(Vector2(19,18),Vector2(36,18),Color("fff1a2"),3)
			draw_line(Vector2(36,18),Vector2(28,32),Color("fff1a2"),3)
			draw_line(Vector2(28,32),Vector2(44,35),Color("fff1a2"),3)
		4:
			for x in [20,32,44]:
				draw_rect(Rect2(x-4,25,8,20),c)
				draw_rect(Rect2(x-7,19,14,8),Color("dce8ed"))
				draw_rect(Rect2(x-8,44,16,4),dark)
		5:
			draw_arc(Vector2(32,32),19,0,TAU,16,c,5)
			draw_rect(Rect2(29,14,6,36),Color("e7f3ff"))
			draw_rect(Rect2(14,29,36,6),Color("e7f3ff"))
		6:
			for i in range(3):
				draw_line(Vector2(18+i*13,45),Vector2(25+i*13,20),c,3)
				draw_colored_polygon(PackedVector2Array([Vector2(25+i*13,16),Vector2(20+i*13,25),Vector2(30+i*13,25)]),Color("f2e3a0"))
		7:
			draw_circle(Vector2(32,33),15,dark)
			draw_rect(Rect2(27,15,10,27),c)
			draw_rect(Rect2(20,29,24,9),c)
			draw_rect(Rect2(25,42,14,5),Color("e6d19a"))
		8:
			draw_circle(Vector2(32,32),17,Color("9d5c39"))
			draw_rect(Rect2(26,14,12,32),c)
			draw_colored_polygon(PackedVector2Array([Vector2(32,9),Vector2(44,28),Vector2(35,24)]),Color("ffe09a"))
		9:
			draw_rect(Rect2(24,17,16,30),dark)
			draw_rect(Rect2(17,28,30,8),c)
			draw_rect(Rect2(28,10,8,42),Color("d8f2a7"))
			draw_rect(Rect2(14,25,36,5),Color("d8f2a7"))
