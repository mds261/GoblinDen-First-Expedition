extends RefCounted
## Room paintings and tiled moss/thorn materials for the Thornveil branch.
static var _sheets: Dictionary = {}

static func _sheet(path: String) -> Texture2D:
	if _sheets.has(path):
		return _sheets[path]
	var texture: Texture2D = load(path) if ResourceLoader.exists(path) else null
	_sheets[path] = texture
	return texture

static func materials() -> Texture2D:
	return _sheet("res://assets/thornveil/materials.png")

static func crown_sheet() -> Texture2D:
	return _sheet("res://assets/thornveil/bramble_crown_sheet.png")

static func thornling_sheet() -> Texture2D:
	return _sheet("res://assets/thornveil/thornling_sheet.png")

static func guardians() -> Texture2D:
	return _sheet("res://assets/thornveil/guardians.png")

static func props() -> Texture2D:
	return _sheet("res://assets/thornveil/props.png")

static func painting(room: int) -> Texture2D:
	if room == 17:
		return _sheet("res://assets/thornveil/approach.png")
	if room == 18:
		return _sheet("res://assets/thornveil/shrine.png")
	return _sheet("res://assets/thornveil/glade.png")

static func material_uv(kind: int) -> Rect2:
	var sheet := materials()
	var half: Vector2 = (sheet.get_size() if sheet != null else Vector2(256, 256)) * 0.5
	return Rect2(Vector2(kind % 2, kind / 2) * half, half)

static func paint_creature(canvas: Node2D, kind: String, frame, flash: bool, dead: bool, flip := false) -> void:
	var tint := Color(1.55, 1.4, 1.15) if flash else Color.WHITE
	if kind == "thornling":
		_thornling(canvas, int(frame), tint, dead, flip)
	else:
		_crown(canvas, frame if frame is Vector2i else Vector2i(int(frame), 0), tint, dead, flip)

static func _grid_region(texture: Texture2D, column: int, row: int, columns: int, rows: int) -> Rect2:
	var cell := texture.get_size() / Vector2(columns, rows)
	return Rect2(Vector2(column, row) * cell, cell)

static func _crown(canvas: Node2D, frame: Vector2i, tint: Color, dead: bool, flip: bool) -> void:
	var texture := crown_sheet()
	if texture == null:
		canvas.draw_circle(Vector2(0, -38), 46, Color(0.18, 0.16, 0.1) * tint)
		return
	var row := clampi(frame.y, 0, 4)
	var column := clampi(frame.x, 0, 3)
	var size := Vector2(184, 206)
	var squash := 0.72 if dead else 1.0
	canvas.draw_set_transform(Vector2(0, 34), 0.0, Vector2(-1 if flip else 1, squash))
	canvas.draw_circle(Vector2(0, 5), 45, Color(0.01, 0.015, 0.008, 0.42))
	canvas.draw_texture_rect_region(texture, Rect2(-size.x * 0.5, -size.y, size.x, size.y), _grid_region(texture, column, row, 4, 5), tint)
	canvas.draw_set_transform(Vector2.ZERO)

static func _thornling(canvas: Node2D, frame: int, tint: Color, dead: bool, flip: bool) -> void:
	var texture := thornling_sheet()
	if texture == null:
		canvas.draw_circle(Vector2.ZERO, 16, Color(0.16, 0.2, 0.1) * tint)
		return
	var column := 3 if dead else clampi(frame, 0, 2)
	var hop := 0.0 if dead else sin(Time.get_ticks_msec() * 0.012) * 2.5
	var size := Vector2(92, 98)
	canvas.draw_set_transform(Vector2(0, 28 + hop), 0.0, Vector2(-1 if flip else 1, 1))
	canvas.draw_circle(Vector2(0, 2), 22, Color(0.01, 0.02, 0.008, 0.35))
	canvas.draw_texture_rect_region(texture, Rect2(-size.x * 0.5, -size.y, size.x, size.y), _grid_region(texture, column, 0, 4, 1), tint)
	canvas.draw_set_transform(Vector2.ZERO)

static func paint_prop(canvas: Node2D, cell: int, point: Vector2, scale: float = 1.0, tint: Color = Color.WHITE) -> void:
	var texture := props()
	if texture == null:
		return
	var size := Vector2(150, 150) * scale
	canvas.draw_texture_rect_region(texture, Rect2(point - Vector2(size.x * 0.5, size.y), size), _grid_region(texture, cell % 4, cell / 4, 4, 2), tint)

static func paint_guard(canvas: Node2D, kind: String, frame: int, flash: bool, flip: bool) -> void:
	var texture := guardians()
	if texture == null:
		return
	var row: int = int({"warden": 0, "poacher": 1, "seer": 2}.get(kind, 0))
	var column := clampi(frame, 0, 3)
	var tint := Color(1.55, 1.35, 1.1) if flash else Color.WHITE
	var size := Vector2(132, 140)
	canvas.draw_set_transform(Vector2(0, 31), 0.0, Vector2(-1 if flip else 1, 1))
	canvas.draw_circle(Vector2(0, 1), 26.0, Color(0.01, 0.015, 0.008, 0.4))
	canvas.draw_texture_rect_region(texture, Rect2(-size.x * 0.5, -size.y, size.x, size.y), _grid_region(texture, column, row, 4, 3), tint)
	canvas.draw_set_transform(Vector2.ZERO)
