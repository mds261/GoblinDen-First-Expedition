extends Node2D
## Weather, motes, breathing lanterns, tangible caches, ember trail and compass.
const GOLD := Color("ebc884")
const Art = preload("res://scripts/descent_art.gd")
var director: Node2D
var time := 0.0
var compass: Node2D
var glow: Texture2D
var markers: Array = []
var tick := 0.0
var grade: CanvasModulate
var dust: Array = []

func _ready() -> void:
	z_index = -1
	grade = CanvasModulate.new()
	add_child(grade)
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
	var room: int = director.game.current_room
	var weather := str(director.active.get("weather","Clear")) if not director.active.is_empty() else "Clear"
	if room==0:
		grade.color = Color(1.08,0.94,0.78).lerp(Color(1.18,0.98,0.72), clampf(director.hearth_bloom/8.0,0,1))
	elif weather=="Mist" and room in [5,6]:
		grade.color = Color(0.74,0.84,0.9)
	elif weather=="Rain" and room in [5,6]:
		grade.color = Color(0.68,0.76,0.88)
	elif room==6:
		grade.color = Color(1.04,1.0,0.86)
	else:
		grade.color = Color(0.92,0.9,0.86)
	var player = director.game.player
	if player.animation_velocity.length()>40:
		dust.append({"at":player.position+Vector2(0,12),"life":0.35,"dir":-player.animation_velocity.normalized()})
	for mote in dust:
		mote.life -= delta
		mote.at += mote.dir*40*delta
	dust = dust.filter(func(m): return float(m.life)>0)
	queue_redraw()
	compass.queue_redraw()

func light(at: Vector2, radius: float, color: Color) -> void:
	draw_texture_rect(glow,Rect2(at-Vector2.ONE*radius,Vector2.ONE*radius*2),false,color)

func _draw() -> void:
	var game = director.game
	var room: int = game.current_room
	var player_at: Vector2 = game.player.position
	var weather := str(director.active.get("weather","Clear")) if not director.active.is_empty() else "Clear"
	# Motes occupy a bounded camera neighborhood, with deterministic movement.
	for i in range(38):
		var at := player_at + Vector2(fposmod(i*137.5+sin(time*0.18+i)*34,1100)-550, fposmod(i*97.3-time*(7+i%5),700)-350)
		var alpha := 0.2+0.25*sin(time*1.2+i)
		var color := Color(0.65,0.88,0.58,maxf(0.06,alpha)) if room in [5,6] else Color(0.9,0.62,0.28,maxf(0.04,alpha*0.5))
		draw_circle(at,1.2+i%2,color)
	if weather=="Rain" and room in [5,6]:
		for i in range(90):
			var drop := player_at + Vector2(fposmod(i*73.1+time*220,1200)-600, fposmod(i*51.7+time*520,760)-380)
			draw_line(drop, drop+Vector2(-6,18), Color(0.55,0.72,0.9,0.28), 1.2, true)
	if weather=="Mist" and room in [5,6]:
		for i in range(12):
			var cloud := player_at + Vector2(sin(time*0.2+i)*180+i*20-120, cos(time*0.13+i)*90)
			light(cloud, 140+sin(time+i)*20, Color(0.72,0.84,0.9,0.08))
	if game.player.stealth_ambush:
		light(player_at, 70+sin(time*4)*8, Color(0.4,0.85,0.62,0.28))
		draw_arc(player_at, 36, 0, TAU, 32, Color(0.55,0.95,0.7,0.7), 2, true)
	if director.living.smoke_time>0:
		light(player_at,100,Color(0.7,0.8,0.75,0.24))
		draw_arc(player_at,48,0,TAU,40,Color(0.65,0.9,0.8,0.7),2,true)
	if room==0:
		var clan_colors := [Color("9fba79"),Color("d1ad79"),Color("b5a2d0")]
		var clan_index := 0
		for faction in director.living.reputation:
			if int(director.living.reputation[faction])>=20:
				var post: Vector2 = director.moss_position()+Vector2(-90+clan_index*90,-65)
				draw_line(post,post+Vector2(0,-65),Color("8a7757"),4,true)
				draw_colored_polygon(PackedVector2Array([post+Vector2(2,-63),post+Vector2(35,-56),post+Vector2(29,-27),post+Vector2(2,-35)]),clan_colors[clan_index])
			clan_index += 1
		var bloom: float = 180.0+sin(time*3)*8.0 + director.hearth_bloom*10.0
		light(game.REST,bloom,Color(1,0.47,0.13,0.4+director.hearth_bloom*0.02))
		for p in [Vector2(1260,1320),Vector2(2290,1320),Vector2(3500,1320),Vector2(4230,1330)]:
			light(p,80,Color(0.35,0.85,0.65,0.28))
			for j in range(3):
				var at: Vector2 = p+Vector2(-14+j*14,0)
				draw_line(at+Vector2(-4,-5),at,Color(0.63,0.79,0.57,0.6),2,true)
				draw_line(at,at+Vector2(-4,5),Color(0.63,0.79,0.57,0.6),2,true)
	var shadow: PackedVector2Array = PackedVector2Array()
	for i in 14:
		var angle := TAU * float(i) / 14.0
		shadow.append(player_at + Vector2(cos(angle) * 16.0, 18.0 + sin(angle) * 6.0))
	draw_colored_polygon(shadow, Color(0, 0, 0, 0.38))
	for mote in dust:
		draw_circle(mote.at, 2.4, Color(0.55,0.48,0.32,mote.life))
	var target: Vector2 = director.target_point()
	if player_at.distance_to(target)>80:
		for n in range(6):
			var t := (n/6.0 + fposmod(time*0.15,1.0))
			var bead: Vector2 = player_at.lerp(target, t)
			if bead.distance_to(player_at)<520:
				draw_circle(bead, 3, Color(GOLD, 0.35*(1.0-t)))
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy.get_parent()!=game.rooms[room] or enemy.hp<=0:
			continue
		if bool(enemy.get_meta("expedition_elite",false)):
			light(enemy.position, 90+sin(time*2)*10, Color("d5a1ed",0.35))
			draw_arc(enemy.position, 48, 0, TAU, 40, Color("d5a1ed"), 2, true)
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
		if player_at.distance_to(p)<240:
			var caption := "OPTIONAL" if entry.kind in ["bonus","event"] else "SUPPLIES" if entry.kind=="cache" else "DISCOVERY"
			if entry.id=="event" and director.living.is_story(): caption = "CLAN STORY"
			var width := ThemeDB.fallback_font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
			var plate := Rect2(p + Vector2(-width * 0.5 - 8, -58), Vector2(width + 16, 18))
			draw_rect(plate, Color(0.03, 0.05, 0.04, 0.86))
			draw_rect(plate, Color(tint, 0.8), false, 1.0)
			draw_string(ThemeDB.fallback_font, p + Vector2(-width * 0.5, -44), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, tint)

func draw_compass() -> void:
	if director.ui.overlay.visible:
		return
	var game = director.game
	var plate := Rect2(20, 126, 318, 46)
	compass.draw_style_box(preload("res://trial/look.gd").hud_frame(),plate)
	var point := Vector2(48, 149)
	var direction: Vector2 = game.player.position.direction_to(director.target_point())
	compass.draw_circle(point, 16, Color(0.02, 0.05, 0.04, 0.92))
	compass.draw_arc(point, 16, 0, TAU, 32, Color("8f7951"), 1.2, true)
	var side := direction.orthogonal()
	compass.draw_colored_polygon(PackedVector2Array([point+direction*12, point-direction*7+side*4, point-direction*3, point-direction*7-side*4]), GOLD)
	var weather := str(director.active.get("weather","Clear")) if not director.active.is_empty() and not director.active.get("claimed",false) else "Haven"
	if game.rpg.boss_hunts.accepted:
		weather = "Boss hunt"
	compass.draw_string(ThemeDB.fallback_font, Vector2(74, 142), "%d paces  ·  %s  ·  %d scrap" % [director.paces(), weather.to_upper(), director.game.scrap], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("f3e6c8"))
	var extra := "Streak %d" % director.combo if director.combo >= 2 else "Follow the gold needle"
	compass.draw_string(ThemeDB.fallback_font, Vector2(74, 160), extra, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, GOLD)
