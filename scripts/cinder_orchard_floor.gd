extends Node2D
## Ash paths, charcoal walls, and the orchard's three hazards. Actors stay above this layer.
const Layout = preload("res://scripts/cinder_orchard_layout.gd")
const Materials = preload("res://assets/cinder/materials.png")
const Art = preload("res://scripts/cinder_art.gd")
var walls: Array[StaticBody2D] = []
var active := false
var time := 0.0
var vent_hits: Dictionary = {}
var column_hits: Dictionary = {}
var spit_hits: Dictionary = {}
var drop_hits: Dictionary = {}
var drift_stamp := -1

func _ready() -> void:
	z_index = -1
	var cols := int(Layout.SIZE.x / 64.0)
	var rows := int(Layout.SIZE.y / 64.0)
	for y in range(rows):
		var start := -1
		for x in range(cols + 1):
			var solid := x < cols and not Layout.walkable(Vector2(x * 64 + 32, y * 64 + 32))
			if solid and start < 0:
				start = x
			if not solid and start >= 0:
				var wall := StaticBody2D.new()
				wall.position = Vector2((start + x) * 32.0, y * 64.0 + 32.0)
				var shape := RectangleShape2D.new()
				shape.size = Vector2((x - start) * 64.0, 64.0)
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

func _vent_clock(index: int) -> float:
	return fposmod(time + float(index) * 1.05, 3.4)

func vent_warning(index: int) -> bool:
	var clock := _vent_clock(index)
	return clock > 2.05 and clock <= 2.75

func vent_hot(index: int) -> bool:
	var clock := _vent_clock(index)
	return clock > 2.75 and clock < 3.2

func _column_clock(index: int) -> float:
	return fposmod(time + float(index) * 1.4, 4.2)

func column_warning(index: int) -> bool:
	var clock := _column_clock(index)
	return clock > 2.5 and clock <= 3.35

func column_hot(index: int) -> bool:
	var clock := _column_clock(index)
	return clock > 3.35 and clock < 3.75

func _spit_clock(index: int) -> float:
	return fposmod(time + float(index) * 0.73, 2.8)

func spit_warning(index: int) -> bool:
	var clock := _spit_clock(index)
	return clock > 1.7 and clock <= 2.25

func spit_hot(index: int) -> bool:
	var clock := _spit_clock(index)
	return clock > 2.25 and clock < 2.6

func _drop_clock(index: int) -> float:
	return fposmod(time + float(index) * 0.65, 4.6)

func drop_warning(index: int) -> bool:
	var clock := _drop_clock(index)
	return clock > 2.9 and clock <= 3.7

func drop_hot(index: int) -> bool:
	var clock := _drop_clock(index)
	return clock > 3.7 and clock < 4.2

func _physics_process(delta: float) -> void:
	if not active:
		return
	time += delta
	var game = get_parent().get_parent()
	if game == null or game.player.hp <= 0 or game.current_room != Layout.ROOM:
		queue_redraw()
		return
	var player: Node2D = game.player
	for i in range(Layout.VENTS.size()):
		if not vent_hot(i):
			continue
		var key := "vent_%d_%d" % [i, int(floor(time / 3.4))]
		if vent_hits.has(key):
			continue
		if player.position.distance_to(Layout.VENTS[i]) <= 54.0:
			vent_hits[key] = true
			player.take_damage(24)
	for i in range(Layout.COLUMNS.size()):
		if not column_hot(i):
			continue
		var key := "col_%d_%d" % [i, int(floor(time / 4.2))]
		if column_hits.has(key):
			continue
		if Layout.COLUMNS[i].has_point(player.position):
			column_hits[key] = true
			player.take_damage(22)
	for i in range(Layout.SPITS.size()):
		if not spit_hot(i):
			continue
		var key := "spit_%d_%d" % [i, int(floor((time + float(i) * 0.73) / 2.8))]
		if spit_hits.has(key):
			continue
		if Layout.SPITS[i].has_point(player.position):
			spit_hits[key] = true
			player.take_damage(24)
	for i in range(Layout.DROPS.size()):
		if not drop_hot(i):
			continue
		var key := "drop_%d_%d" % [i, int(floor((time + float(i) * 0.65) / 4.6))]
		if drop_hits.has(key):
			continue
		if player.position.distance_to(Layout.DROPS[i]) <= 40.0:
			drop_hits[key] = true
			player.take_damage(20)
	var drift_key := int(floor(time / 0.85))
	if drift_key != drift_stamp and Layout.in_drift(player.position):
		drift_stamp = drift_key
		player.take_damage(10)
	queue_redraw()

func _tint_for(cell: Vector2) -> Color:
	if Layout.in_drift(cell):
		return Color(0.9, 0.8, 0.72)
	if Layout.KILN.has_point(cell) or Layout.STAIR.has_point(cell):
		return Color(1.0, 0.9, 0.8)
	if Layout.EAST.has_point(cell):
		return Color(0.95, 0.84, 0.74)
	if Layout.NAVE.has_point(cell):
		return Color(0.68, 0.65, 0.64)
	if Layout.ROWS.has_point(cell):
		return Color(0.75, 0.7, 0.66)
	if Layout.GALLERY.has_point(cell):
		return Color(0.85, 0.78, 0.72)
	if Layout.COURT.has_point(cell):
		return Color(0.95, 0.88, 0.8)
	return Color(0.82, 0.8, 0.76)

func _draw() -> void:
	var half := Materials.get_size() * 0.5
	var cols := int(Layout.SIZE.x / 64.0)
	var rows := int(Layout.SIZE.y / 64.0)
	var view := Rect2(Vector2.ZERO, Layout.SIZE)
	var camera := get_viewport().get_camera_2d()
	if camera != null:
		var extent := get_viewport_rect().size / camera.zoom
		view = Rect2(camera.get_screen_center_position() - extent * 0.5, extent).grow(180)
	for y in range(clampi(int(floor(view.position.y / 64.0)), 0, rows), clampi(int(ceil(view.end.y / 64.0)), 0, rows)):
		for x in range(clampi(int(floor(view.position.x / 64.0)), 0, cols), clampi(int(ceil(view.end.x / 64.0)), 0, cols)):
			var tile := Rect2(x * 64, y * 64, 64, 64)
			var center := tile.get_center()
			var open := Layout.walkable(center) or Layout.is_pillar(center)
			var sample := Rect2(Vector2(0 if open else half.x, 0) + Vector2(x % 4, y % 4) * half / 4.0, half / 4.0)
			if Layout.is_fissure(center):
				var lava_sample := Rect2(half + Vector2(x % 4, y % 4) * half / 4.0, half / 4.0)
				var glow := 0.85 + 0.15 * sin(time * 3.0 + float(x))
				draw_texture_rect_region(Materials, tile, lava_sample, Color(glow, glow, glow))
				continue
			if open and Layout.KILN.has_point(center):
				sample = Rect2(Vector2(0, half.y) + (tile.position - Layout.KILN.position) / Layout.KILN.size * half, Vector2(64, 64) / Layout.KILN.size * half)
			var tint := _tint_for(center) if open else Color(0.42, 0.38, 0.35)
			draw_texture_rect_region(Materials, tile, sample, tint)
			if open:
				var crack := Vector2(8 + (x * 17) % 40, 12 + (y * 13) % 36)
				draw_line(tile.position + crack, tile.position + crack + Vector2(18, 8), Color(1, 0.4, 0.08, 0.28), 1.5, true)
				for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
					if not Layout.walkable(center + direction * 64.0):
						var edge := tile.position
						if direction == Vector2.UP:
							edge.y += 0
							draw_line(edge, edge + Vector2(64, 0), Color(1, 0.42, 0.1, 0.55), 3.0, true)
						elif direction == Vector2.DOWN:
							draw_line(tile.position + Vector2(0, 63), tile.position + Vector2(64, 63), Color(0.02, 0.01, 0.01, 0.8), 3.0, true)
						elif direction == Vector2.LEFT:
							draw_line(tile.position, tile.position + Vector2(0, 64), Color(1, 0.35, 0.08, 0.35), 2.0, true)
						else:
							draw_line(tile.position + Vector2(63, 0), tile.position + Vector2(63, 64), Color(0.02, 0.01, 0.01, 0.7), 2.0, true)
	for i in range(Layout.VENTS.size()):
		var vent: Vector2 = Layout.VENTS[i]
		Art.paint(self, Art.prop(2), vent, Vector2(64, 48), Color.WHITE, 0.5)
		if vent_warning(i) or vent_hot(i):
			var radius := 58.0 if vent_hot(i) else 28.0 + _vent_clock(i) * 8.0
			draw_arc(vent, radius, 0, TAU, 28, Color(1, 0.45, 0.1, 0.85), 3.0, true)
			if vent_hot(i):
				draw_circle(vent, 54, Color(1, 0.3, 0.05, 0.28))
				_flame(vent, Vector2(78, 112), float(i))
	for i in range(Layout.COLUMNS.size()):
		var column: Rect2 = Layout.COLUMNS[i]
		if column_warning(i) or column_hot(i):
			draw_rect(column, Color(1, 0.4, 0.08, 0.45 if column_hot(i) else 0.18))
			if column_hot(i):
				_flame(column.get_center(), Vector2(60, 140), float(i))
		else:
			draw_rect(column, Color(0.4, 0.18, 0.08, 0.12), false, 1.0)
	for drift in Layout.DRIFTS:
		draw_rect(drift, Color(0.55, 0.12, 0.04, 0.12 + 0.05 * sin(time * 2.0)))
		for offset in range(0, int(drift.size.x), 72):
			Art.paint(self, Art.prop(5), drift.position + Vector2(offset + 36, drift.size.y * 0.5), Vector2(100, 68), Color(1, 1, 1, 0.85), 0.5)
	for i in range(Layout.SPITS.size()):
		var spit: Rect2 = Layout.SPITS[i]
		if spit_hot(i):
			draw_rect(spit, Color(1, 0.35, 0.05, 0.42))
			for step in range(0, int(maxf(spit.size.x, spit.size.y)), 58):
				var point := spit.position + (Vector2(step, spit.size.y * 0.5) if spit.size.x > spit.size.y else Vector2(spit.size.x * 0.5, step))
				_flame(point, Vector2(70, 95), float(step + i))
		elif spit_warning(i):
			draw_rect(spit, Color(1, 0.45, 0.1, 0.2))
		else:
			draw_rect(spit, Color(0.45, 0.16, 0.05, 0.08), false, 1.0)
	for i in range(Layout.DROPS.size()):
		var drop: Vector2 = Layout.DROPS[i]
		draw_circle(drop, 6, Color(0.4, 0.12, 0.04, 0.8))
		if drop_warning(i) or drop_hot(i):
			var radius := 42.0 if drop_hot(i) else 16.0 + _drop_clock(i) * 4.0
			draw_arc(drop, radius, 0, TAU, 20, Color(1, 0.55, 0.12, 0.8), 2.0, true)
			if drop_hot(i):
				draw_circle(drop, 40, Color(1, 0.4, 0.08, 0.3))
				_flame(drop, Vector2(65, 90), float(i))
			elif drop_warning(i):
				var fall := clampf((_drop_clock(i) - 2.9) / 0.8, 0, 1)
				draw_line(drop + Vector2(0, -120 * (1.0 - fall)), drop + Vector2(0, -140 * (1.0 - fall) - 8), Color(1, 0.7, 0.3, 0.9), 3, true)
	for mote in range(40):
		var px := 160.0 + fmod(float(mote) * 90.0 + time * 18.0, Layout.SIZE.x - 240.0)
		var py := 180.0 + fmod(float(mote) * 53.0 + time * 8.0, Layout.SIZE.y - 260.0)
		if Layout.walkable(Vector2(px, py)):
			draw_circle(Vector2(px, py), 1.4, Color(1, 0.6, 0.2, 0.35))

func _flame(point: Vector2, box: Vector2, phase: float) -> void:
	var flicker := 1.0 + sin(time * 19.0 + phase) * 0.12
	Art.paint(self, Art.prop(6), point, box * Vector2(1.0 / flicker, flicker), Color(1, 1, 1, 0.82))
