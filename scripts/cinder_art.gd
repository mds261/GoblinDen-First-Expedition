extends RefCounted
## Painted atlases share trimmed regions; state animation is driven by combat.
const CREATURES = preload("res://assets/cinder/creatures.png")
const SCENERY = preload("res://assets/cinder/scenery.png")
static var cache: Dictionary = {}

static func region(sheet: Texture2D, index: int, columns: int, rows: int, key: String) -> AtlasTexture:
	if cache.has(key):
		return cache[key]
	var cell := Vector2i(sheet.get_size()) / Vector2i(columns, rows)
	var origin := Vector2i(index % columns, index / columns) * cell
	var used := sheet.get_image().get_region(Rect2i(origin, cell)).get_used_rect()
	var texture := AtlasTexture.new()
	texture.atlas = sheet
	texture.region = Rect2(origin + used.position, used.size)
	texture.filter_clip = true
	cache[key] = texture
	return texture

static func creature(row: int, frame: int) -> Texture2D:
	var key := "creature_%d_%d" % [row, frame]
	if cache.has(key):
		return cache[key]
	# The painted rows have unequal heights. Use their actual transparent gutters
	# so the wisp frames never include the Kilnheart crowns beneath them.
	var width := int(CREATURES.get_width() / 4)
	var split := 720 if frame == 2 else (780 if frame == 3 else 735)
	var top := 0 if row == 0 else (360 if row == 1 else split)
	var bottom := 360 if row == 0 else (split if row == 1 else CREATURES.get_height())
	var cell := Rect2i(frame * width, top, width, bottom - top)
	var used := CREATURES.get_image().get_region(cell).get_used_rect()
	var texture := AtlasTexture.new()
	texture.atlas = CREATURES
	texture.region = Rect2(cell.position + used.position, used.size)
	texture.filter_clip = true
	cache[key] = texture
	return texture

static func prop(index: int) -> Texture2D:
	return region(SCENERY, index, 4, 2, "scenery_%d" % index)

static func paint(canvas: Node2D, texture: Texture2D, point: Vector2, size: Vector2, tint: Color = Color.WHITE, anchor: float = 0.75) -> void:
	var factor := minf(size.x / texture.get_width(), size.y / texture.get_height())
	var fitted := texture.get_size() * factor
	canvas.draw_texture_rect(texture, Rect2(point - Vector2(fitted.x * 0.5, fitted.y * anchor), fitted), false, tint)
