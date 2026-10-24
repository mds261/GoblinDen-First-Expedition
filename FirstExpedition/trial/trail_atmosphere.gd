extends Node2D
## Restrained world-space motes, breathing lanterns, tangible caches and a compass.
const GOLD := Color("ebc884")
const Art = preload("res://scripts/descent_art.gd")
var director: Node2D
var time := 0.0
var compass: Node2D
var glow: Texture2D
var markers: Array = []
var tick := 0.0

func _ready() -> void:
	z_index = -1
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(1,1,1,0.45),Color(1,1,1,0)])
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.width = 128
	tex.height = 128
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5,0.5)
	tex.fill_to = Vector2(1,0.5)
	glow = tex
	var layer := CanvasLayer.new()
	layer.layer = 3
	add_child(layer)
	compass = Node2D.new()
	layer.add_child(compass)
	compass.draw.connect(draw_compass)

func _process(delta: float) -> void:
	time += delta
	tick -= delta
	if tick<=0:
		markers = director.objects()
		tick = 0.2
	queue_redraw()
	compass.queue_redraw()

func light(at: Vector2, radius: float, color: Color) -> void:
	draw_texture_rect(glow,Rect2(at-Vector2.ONE*radius,Vector2.ONE*radius*2),false,color)

func _draw() -> void:
	var game = director.game
	var room: int = game.current_room
	var player_at: Vector2 = game.player.position
	# Motes occupy a bounded camera neighborhood, with deterministic movement.
	for i in range(38):
		var at := player_at + Vector2(fposmod(i*137.5+sin(time*0.18+i)*34,1100)-550, fposmod(i*97.3-time*(7+i%5),700)-350)
		var alpha := 0.2+0.25*sin(time*1.2+i)
		var color := Color(0.65,0.88,0.58,maxf(0.06,alpha)) if room in [5,6] else Color(0.9,0.62,0.28,maxf(0.04,alpha*0.5))
		draw_circle(at,1.2+i%2,color)
	if room==0:
		light(game.REST,180+sin(time*3)*8,Color(1,0.47,0.13,0.4))
		for p in [Vector2(1260,1320),Vector2(2290,1320),Vector2(3500,1320),Vector2(4230,1330)]:
			light(p,80,Color(0.35,0.85,0.65,0.28))
			for j in range(3):
				var at: Vector2 = p+Vector2(-14+j*14,0)
				draw_line(at+Vector2(-4,-5),at,Color(0.63,0.79,0.57,0.6),2,true)
				draw_line(at,at+Vector2(-4,5),Color(0.63,0.79,0.57,0.6),2,true)
	for entry in markers:
		if int(entry.room)!=room or entry.id in director.active.get("taken",[]) or player_at.distance_to(entry.point)>750:
			continue
		var p: Vector2 = entry.point
		var tint := Color("87d4b0") if entry.kind in ["event","herbs"] else GOLD
		if entry.kind=="bonus":
			tint = Color("d5a1ed")
		light(p,60+sin(time*2)*4,Color(tint,0.45))
		if entry.kind in ["cache","bonus"]:
			var chest: Texture2D = Art.prop(4)
			draw_texture_rect(chest,Art.fitted(chest,p,Vector2(74,68),0.80),false)
		elif entry.kind=="herbs":
			for j in range(5):
				var at := p+Vector2(j*8-16,sin(j*2)*6)
				draw_line(at,at+Vector2(3,-16),Color("83ad67"),2)
				draw_circle(at+Vector2(3,-17),4,Color("bf7977"))
		elif entry.kind=="clue":
			draw_line(p+Vector2(0,12),p+Vector2(0,-25),Color("7d6849"),3)
			draw_colored_polygon(PackedVector2Array([p+Vector2(0,-25),p+Vector2(26,-21),p+Vector2(18,-9),p+Vector2(0,-12)]),Color("937353"))
		else:
			for j in range(7):
				draw_circle(p+Vector2.from_angle(j*TAU/7)*20,5,Color("727c6e"))
			light(p,45,Color(1,0.62,0.24,0.6))
		if player_at.distance_to(p)<190:
			draw_string(ThemeDB.fallback_font,p+Vector2(-48,-40),"OPTIONAL" if entry.kind in ["bonus","event"] else "SUPPLIES" if entry.kind=="cache" else "DISCOVERY",HORIZONTAL_ALIGNMENT_LEFT,-1,11,tint)

func draw_compass() -> void:
	if director.ui.overlay.visible:
		return
	var game = director.game
	var point := Vector2(866,112)
	var direction: Vector2 = game.player.position.direction_to(director.target_point())
	compass.draw_circle(point,23,Color(0.02,0.05,0.04,0.9))
	compass.draw_arc(point,23,0,TAU,40,Color("8f7951"),1,true)
	var side := direction.orthogonal()
	compass.draw_colored_polygon(PackedVector2Array([point+direction*17,point-direction*10+side*6,point-direction*5,point-direction*10-side*6]),GOLD)
	compass.draw_string(ThemeDB.fallback_font,Vector2(828,151),"TRAIL GUIDE",HORIZONTAL_ALIGNMENT_LEFT,-1,10,GOLD)
