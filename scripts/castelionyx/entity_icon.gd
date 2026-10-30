class_name CxEntityIcon
extends Control

var kind:String="hero"
var index:int=0
var size_px:float=80.0

func setup(entity_kind:String,entity_index:int,entity_size:float) -> CxEntityIcon:
	kind=entity_kind
	index=entity_index
	size_px=entity_size
	custom_minimum_size=Vector2(entity_size,entity_size)
	queue_redraw()
	return self

func _draw() -> void:
	var k=size_px/80.0
	var palettes=[Color("315c73"),Color("2f7b76"),Color("b74d3f"),Color("c66b35"),Color("59616a"),Color("435a88"),Color("6a3d86"),Color("a84543"),Color("4f8f67"),Color("d29b4e"),Color("c96d55"),Color("7b8794"),Color("82c1d1"),Color("a58bd0"),Color("b9a46c"),Color("78a878"),Color("9d664d"),Color("cc9a54"),Color("7d9b67"),Color("7c9eae")]
	var body=palettes[(index+ (0 if kind=="hero" else 10))%palettes.size()]
	var trim=body.lightened(0.42)
	draw_rect(Rect2(3,3,size_px-6,size_px-6),Color("13262d"))
	if kind=="hero":
		draw_rect(Rect2(Vector2(30,35)*k,Vector2(20,27)*k),body)
		draw_rect(Rect2(Vector2(33,22)*k,Vector2(14,14)*k),Color("d7b18a"))
		draw_rect(Rect2(Vector2(36,26)*k,Vector2(3,3)*k),Color("19272b")); draw_rect(Rect2(Vector2(43,26)*k,Vector2(3,3)*k),Color("19272b"))
		match index:
			0: draw_rect(Rect2(Vector2(24,30)*k,Vector2(32,5)*k),trim)
			1: draw_colored_polygon(PackedVector2Array([Vector2(40,7),Vector2(31,25),Vector2(49,25)]),trim)
			2: draw_rect(Rect2(Vector2(16,38)*k,Vector2(48,5)*k),Color("e08a43"))
			3: draw_rect(Rect2(Vector2(53,18)*k,Vector2(5,39)*k),trim)
			4: draw_rect(Rect2(Vector2(24,29)*k,Vector2(32,8)*k),Color("c8d0d6"))
			5: draw_circle(Vector2(58,22)*k,8*k,Color("c7ddff")); draw_rect(Rect2(Vector2(57,25)*k,Vector2(4,32)*k),trim)
			6: draw_circle(Vector2(59,22)*k,7*k,Color("c987e3")); draw_rect(Rect2(Vector2(57,25)*k,Vector2(4,32)*k),trim)
			7: draw_rect(Rect2(Vector2(12,38)*k,Vector2(18,4)*k),trim); draw_rect(Rect2(Vector2(50,38)*k,Vector2(18,4)*k),trim)
			8: draw_colored_polygon(PackedVector2Array([Vector2(49,48),Vector2(72,57),Vector2(53,65)]),Color("9b6a46"))
			9: draw_arc(Vector2(40,22)*k,16*k,0,TAU,12,trim,3*k); draw_rect(Rect2(Vector2(56,17)*k,Vector2(4,40)*k),trim)
	else:
		draw_rect(Rect2(Vector2(18,42)*k,Vector2(44,22)*k),Color("596b68"))
		match index:
			0: draw_colored_polygon(PackedVector2Array([Vector2(40,10),Vector2(20,43),Vector2(60,43)]),body)
			1: draw_circle(Vector2(40,34)*k,17*k,Color("d99a63")); draw_rect(Rect2(Vector2(34,20)*k,Vector2(12,30)*k),Color("4c3b3b"))
			2: draw_rect(Rect2(Vector2(35,10)*k,Vector2(10,45)*k),Color("a5e5f2")); draw_rect(Rect2(Vector2(20,32)*k,Vector2(40,5)*k),body)
			3: draw_arc(Vector2(40,34)*k,22*k,0,TAU,10,Color("d8c7ff"),5*k)
			4: draw_rect(Rect2(Vector2(14,20)*k,Vector2(8,44)*k),body); draw_rect(Rect2(Vector2(58,20)*k,Vector2(8,44)*k),body); draw_line(Vector2(18,20)*k,Vector2(62,20)*k,trim,4*k)
			5: draw_rect(Rect2(Vector2(37,7)*k,Vector2(6,57)*k),body); draw_circle(Vector2(40,8)*k,10*k,Color("f1d783"))
			6: draw_rect(Rect2(Vector2(35,5)*k,Vector2(10,59)*k),body); draw_colored_polygon(PackedVector2Array([Vector2(40,0),Vector2(23,22),Vector2(57,22)]),body)
			7: draw_rect(Rect2(Vector2(10,40)*k,Vector2(60,7)*k),body); draw_rect(Rect2(Vector2(34,10)*k,Vector2(12,54)*k),body)
			8: draw_rect(Rect2(Vector2(11,34)*k,Vector2(58,13)*k),body); draw_rect(Rect2(Vector2(19,20)*k,Vector2(8,27)*k),body); draw_rect(Rect2(Vector2(53,20)*k,Vector2(8,27)*k),body)
			9: draw_rect(Rect2(Vector2(38,3)*k,Vector2(4,61)*k),body); draw_rect(Rect2(Vector2(18,32)*k,Vector2(44,5)*k),body)
			10: draw_colored_polygon(PackedVector2Array([Vector2(40,7),Vector2(22,42),Vector2(58,42)]),body); draw_rect(Rect2(Vector2(27,42)*k,Vector2(26,22)*k),body)
			11: draw_rect(Rect2(Vector2(25,15)*k,Vector2(30,49)*k),body); draw_circle(Vector2(40,12)*k,9*k,Color("e8d48a"))
