extends Node2D
## Painted Thornveil ground, merged wall bodies, and pulsing thorn patches.
const Layout = preload("res://scripts/thornveil_layout.gd")
const Art = preload("res://scripts/thornveil_art.gd")
var room_id := 17
var walls: Array[StaticBody2D] = []
var active := false
var time := 0.0
var thorn_hits: Dictionary = {}

func _ready() -> void:
	z_index = -1
	var cols := int(Layout.SIZE.x / float(Layout.TILE))
	var rows := int(Layout.SIZE.y / float(Layout.TILE))
	for y in range(rows):
		var start := -1
		for x in range(cols + 1):
			var solid := x < cols and not Layout.walkable(Vector2(x * Layout.TILE + 32, y * Layout.TILE + 32), room_id)
			if solid and start < 0:
				start = x
			if not solid and start >= 0:
				var wall := StaticBody2D.new()
				wall.position = Vector2((start + x) * 32.0, y * Layout.TILE + 32.0)
				var shape := RectangleShape2D.new()
				shape.size = Vector2((x - start) * Layout.TILE, Layout.TILE)
				var collision := CollisionShape2D.new()
				collision.shape = shape
				wall.add_child(collision)
				add_child(wall)
				walls.append(wall)
				start = -1
	set_collision_active(false)

func set_collision_active(enabled: bool) -> void:
	active = enabled
	for wall in walls:
		wall.collision_layer = 1 if enabled else 0
		wall.collision_mask = 2 if enabled else 0
	queue_redraw()

func _thorn_clock(index: int) -> float:
	return fposmod(time + float(index) * 0.9, 2.8)

func thorn_warning(index: int) -> bool:
	var clock := _thorn_clock(index)
	return clock > 1.55 and clock <= 2.15

func thorn_hot(index: int) -> bool:
	var clock := _thorn_clock(index)
	return clock > 2.15 and clock < 2.55

func _physics_process(delta: float) -> void:
	if not active:
		return
	time += delta
	var game = get_parent().get_parent()
	if game == null or not game.has_node("BladeGoblin"):
		queue_redraw()
		return
	var player: Node2D = game.get_node("BladeGoblin")
	if player.hp <= 0 or float(player.get("invulnerability")) > 0.0:
		queue_redraw()
		return
	var thorns: Array = Layout.thorns(room_id)
	for index in range(thorns.size()):
		if not thorn_hot(index) or player.position.distance_to(thorns[index]) > 42.0:
			continue
		var stamp := int(time * 4.0)
		if int(thorn_hits.get(index, -1)) == stamp:
			continue
		thorn_hits[index] = stamp
		player.take_damage(8)
	queue_redraw()

func _draw() -> void:
	var painting := Art.painting(room_id)
	if painting != null:
		draw_texture_rect(painting, Rect2(Vector2.ZERO, Layout.SIZE), false)
	else:
		draw_rect(Rect2(Vector2.ZERO, Layout.SIZE), Color(0.09, 0.1, 0.07))
	var cols := int(Layout.SIZE.x / float(Layout.TILE))
	var rows := int(Layout.SIZE.y / float(Layout.TILE))
	var materials := Art.materials()
	for y in range(rows):
		for x in range(cols):
			var center := Vector2(x * Layout.TILE + 32, y * Layout.TILE + 32)
			if Layout.walkable(center, room_id):
				continue
			if materials != null:
				draw_texture_rect_region(materials, Rect2(center - Vector2(32, 32), Vector2(Layout.TILE, Layout.TILE)), Art.material_uv(1 if (x + y) % 3 == 0 else 2), Color(0.22, 0.2, 0.16, 0.55))
			else:
				draw_rect(Rect2(center - Vector2(32, 32), Vector2(Layout.TILE, Layout.TILE)), Color(0.05, 0.06, 0.04, 0.7))
	var thorns: Array = Layout.thorns(room_id)
	for index in range(thorns.size()):
		var local: Vector2 = thorns[index]
		var pulse := 0.18 if thorn_warning(index) else (0.42 if thorn_hot(index) else 0.08)
		for spoke in range(12):
			var angle := float(spoke) / 12.0 * TAU + sin(time * 2.0 + index) * 0.08
			var inner := local + Vector2.from_angle(angle) * 10.0
			var length := 30.0 + (12.0 if thorn_hot(index) else 0.0) * sin(time * 8.0 + spoke)
			draw_line(inner, local + Vector2.from_angle(angle) * length, Color(0.28, 0.5, 0.14, pulse + 0.24), 3.0, true)
		draw_circle(local, 38.0, Color(0.2, 0.45, 0.12, pulse))
		draw_arc(local, 27.0 + sin(time * 5.0 + index) * 5.0, 0, TAU, 24, Color(0.55, 0.95, 0.3, pulse + 0.2), 2.0, true)
	for spec in Layout.props(room_id):
		var glow := 0.82 + sin(time * 1.7 + int(spec.cell)) * 0.08
		Art.paint_prop(self, int(spec.cell), spec.point + Vector2(0, sin(time * 1.2 + int(spec.cell)) * 2.0), float(spec.scale), Color(glow, glow, glow))
	# Floating spores keep the large painted rooms alive without obscuring combat.
	for index in range(24):
		var seed := float(index * 97 + room_id * 43)
		var point := Vector2(fposmod(seed * 7.0 + time * (7.0 + index % 3), Layout.SIZE.x), fposmod(seed * 3.0 - time * (4.0 + index % 4), Layout.SIZE.y))
		if Layout.walkable(point, room_id):
			var alpha := 0.12 + 0.12 * sin(time * 2.1 + seed)
			draw_circle(point, 1.8 + float(index % 3), Color(0.56, 0.9, 0.3, alpha))
