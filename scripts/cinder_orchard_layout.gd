extends RefCounted
## Charcoal grove under Thornwood Hollow. Optional branch, about five times the first grove.
const ROOM := 16
const SIZE := Vector2(3840, 2560)
const ENTRY := Rect2(128, 1024, 512, 384)
const LANE := Rect2(640, 1088, 384, 256)
const COURT := Rect2(1024, 640, 1152, 1024)
const ROWS := Rect2(1024, 128, 1664, 512)
const ROW_LINK := Rect2(2176, 640, 512, 128)
const GALLERY := Rect2(1024, 1664, 1664, 640)
const NAVE := Rect2(2176, 768, 512, 512)
const NORTH_BRIDGE := Rect2(2688, 384, 256, 256)
const MAIN_BRIDGE := Rect2(2688, 896, 256, 256)
const SOUTH_BRIDGE := Rect2(2688, 1920, 384, 256)
const EAST := Rect2(2944, 256, 640, 512)
const KILN := Rect2(2944, 768, 512, 640)
const STAIR := Rect2(3072, 1408, 384, 896)
const OPEN: Array[Rect2] = [ENTRY, LANE, COURT, ROWS, ROW_LINK, GALLERY, NAVE, NORTH_BRIDGE, MAIN_BRIDGE, SOUTH_BRIDGE, EAST, KILN, STAIR]
const PILLARS: Array[Vector2] = [Vector2(3168, 928), Vector2(3360, 928), Vector2(3168, 1248), Vector2(3360, 1248)]
const VENTS: Array[Vector2] = [
	Vector2(1312, 928), Vector2(1952, 928), Vector2(1312, 1312), Vector2(1952, 1312),
	Vector2(1632, 1120), Vector2(1632, 1504),
	Vector2(1440, 1952), Vector2(2080, 1952), Vector2(2080, 2144),
	Vector2(3232, 480), Vector2(3488, 480),
	Vector2(2848, 2016), Vector2(3040, 2016)
]
const MITES: Array[Dictionary] = [
	{"id": "mite_a", "a": Vector2(1312, 928), "b": Vector2(1952, 928), "yard": COURT},
	{"id": "mite_b", "a": Vector2(1312, 928), "b": Vector2(1312, 1312), "yard": COURT},
	{"id": "mite_c", "a": Vector2(1952, 928), "b": Vector2(1952, 1312), "yard": COURT},
	{"id": "mite_d", "a": Vector2(1312, 1312), "b": Vector2(1952, 1312), "yard": COURT},
	{"id": "mite_e", "a": Vector2(1632, 1120), "b": Vector2(1632, 1504), "yard": COURT},
	{"id": "mite_f", "a": Vector2(1440, 1952), "b": Vector2(2080, 1952), "yard": GALLERY},
	{"id": "mite_g", "a": Vector2(2080, 1952), "b": Vector2(2080, 2144), "yard": GALLERY},
	{"id": "mite_h", "a": Vector2(3232, 480), "b": Vector2(3488, 480), "yard": EAST},
	{"id": "mite_i", "a": Vector2(2848, 2016), "b": Vector2(3040, 2016), "yard": SOUTH_BRIDGE}
]
const WISPS: Array[Dictionary] = [
	{"id": "wisp_nave_a", "at": Vector2(2336, 928), "grove": NAVE},
	{"id": "wisp_nave_b", "at": Vector2(2528, 1056), "grove": NAVE},
	{"id": "wisp_row_a", "at": Vector2(1312, 352), "grove": ROWS},
	{"id": "wisp_row_b", "at": Vector2(1824, 288), "grove": ROWS},
	{"id": "wisp_row_c", "at": Vector2(2336, 416), "grove": ROWS},
	{"id": "wisp_east_a", "at": Vector2(3104, 416), "grove": EAST},
	{"id": "wisp_east_b", "at": Vector2(3488, 352), "grove": EAST},
	{"id": "wisp_gallery", "at": Vector2(1184, 1824), "grove": GALLERY}
]
const COLUMNS: Array[Rect2] = [
	Rect2(1544, 320, 48, 100), Rect2(2056, 320, 48, 100), Rect2(2440, 256, 48, 100),
	Rect2(2376, 960, 48, 112), Rect2(2248, 1088, 48, 96),
	Rect2(3272, 320, 48, 96), Rect2(1800, 1792, 48, 96), Rect2(1160, 768, 48, 96)
]
const DRIFTS: Array[Rect2] = [
	Rect2(1152, 1536, 512, 128),
	Rect2(1536, 1728, 512, 128),
	Rect2(3072, 576, 384, 128),
	Rect2(3136, 2048, 256, 128)
]
const SPITS: Array[Rect2] = [
	Rect2(768, 1088, 128, 256),
	Rect2(2752, 896, 128, 256),
	Rect2(2752, 384, 128, 256),
	Rect2(2880, 1920, 128, 256),
	Rect2(3072, 1664, 384, 128),
	Rect2(2368, 768, 64, 512),
	Rect2(3328, 256, 64, 512),
	Rect2(1728, 640, 64, 1024)
]
const DROPS: Array[Vector2] = [
	Vector2(1184, 288), Vector2(1440, 288), Vector2(1568, 416), Vector2(1696, 480),
	Vector2(1952, 416), Vector2(2080, 288), Vector2(2208, 480), Vector2(2464, 352),
	Vector2(2592, 224), Vector2(1440, 544)
]
const BOSS := Vector2(3232, 1056)
const CACHE := Vector2(1696, 2144)
const EXIT := Vector2(288, 1248)
const SPAWN := Vector2(416, 1248)
const HOLLOW_ENTRANCE := Vector2(560, 590)
const HOLLOW_RETURN := Vector2(640, 500)
const FISSURE := Rect2(2688, 256, 128, 1664)

static func _cell(world_point: Vector2) -> Vector2:
	return (world_point / 64.0).floor() * 64.0 + Vector2(32, 32)

static func is_pillar(world_point: Vector2) -> bool:
	var cell := _cell(world_point)
	for pillar in PILLARS:
		if cell.distance_to(pillar) < 40.0:
			return true
	return false

static func walkable(world_point: Vector2) -> bool:
	var cell := _cell(world_point)
	if is_pillar(cell):
		return false
	for rect in OPEN:
		if rect.has_point(cell):
			return true
	return false

static func is_fissure(world_point: Vector2) -> bool:
	var cell := _cell(world_point)
	return not walkable(cell) and FISSURE.has_point(cell)

static func in_drift(world_point: Vector2) -> bool:
	for drift in DRIFTS:
		if drift.has_point(world_point):
			return true
	return false
