extends RefCounted
## Three connected Thornveil rooms beyond the northern hollow gate.
const FIRST := 17
const LAST := 19
const APPROACH := 17
const SHRINE := 18
const GLADE := 19
const SIZE := Vector2(1920, 1280)
const TILE := 64
const HOLLOW_GATE := Vector2(560, 200)
const HOLLOW_RETURN := Vector2(560, 240)

const APPROACH_OPEN: Array[Rect2] = [
	Rect2(128, 512, 512, 320),
	Rect2(576, 544, 832, 256),
	Rect2(1152, 384, 512, 448),
	Rect2(1600, 544, 192, 256)
]
const SHRINE_OPEN: Array[Rect2] = [
	Rect2(128, 544, 384, 256),
	Rect2(448, 384, 896, 512),
	Rect2(512, 832, 384, 192),
	Rect2(768, 192, 256, 256)
]
const GLADE_OPEN: Array[Rect2] = [
	Rect2(128, 544, 448, 256),
	Rect2(512, 256, 1152, 768)
]
const ARENA := Rect2(512, 256, 1152, 768)

const APPROACH_SPAWN := Vector2(320, 672)
const APPROACH_TO_HOLLOW := Vector2(224, 672)
const APPROACH_TO_SHRINE := Vector2(1728, 672)
const SHRINE_SPAWN := Vector2(256, 672)
const SHRINE_TO_APPROACH := Vector2(224, 672)
const SHRINE_TO_GLADE := Vector2(896, 288)
const SHRINE_CACHE := Vector2(640, 928)
const GLADE_SPAWN := Vector2(288, 672)
const GLADE_TO_SHRINE := Vector2(224, 672)
const BOSS := Vector2(1088, 640)
const MEMORIES: Array[Dictionary] = [
	{"id": "oath", "room": APPROACH, "point": Vector2(1160, 570), "label": "Read the chained hunter's oath"},
	{"id": "shrine", "room": SHRINE, "point": Vector2(910, 430), "label": "Listen to the Root Shrine"},
	{"id": "collar", "room": GLADE, "point": Vector2(1510, 390), "label": "Break the Crown's collar-sigil"}
]

const THORNS: Dictionary = {
	17: [Vector2(896, 672), Vector2(1120, 736), Vector2(1344, 640)],
	18: [Vector2(576, 608), Vector2(768, 672), Vector2(1088, 800), Vector2(1216, 576)],
	19: [Vector2(704, 448), Vector2(864, 832), Vector2(1312, 480), Vector2(1472, 800)]
}
const PROPS: Dictionary = {
	17: [
		{"point": Vector2(480, 590), "cell": 4, "scale": 0.9},
		{"point": Vector2(1160, 570), "cell": 1, "scale": 0.75},
		{"point": Vector2(1560, 720), "cell": 6, "scale": 0.72}
	],
	18: [
		{"point": Vector2(620, 760), "cell": 0, "scale": 0.75},
		{"point": Vector2(910, 430), "cell": 2, "scale": 0.92},
		{"point": Vector2(1180, 760), "cell": 5, "scale": 0.65}
	],
	19: [
		{"point": Vector2(670, 390), "cell": 3, "scale": 0.8},
		{"point": Vector2(1510, 390), "cell": 6, "scale": 0.72},
		{"point": Vector2(1088, 870), "cell": 0, "scale": 0.68}
	]
}
const ENEMIES: Array[Dictionary] = [
	{"id": "warden_a", "room": APPROACH, "pos": Vector2(800, 672), "monster": "thornveil_warden", "kind": "warden"},
	{"id": "poacher_a", "room": APPROACH, "pos": Vector2(1408, 640), "monster": "thornveil_poacher", "kind": "poacher"},
	{"id": "warden_b", "room": SHRINE, "pos": Vector2(704, 576), "monster": "thornveil_warden", "kind": "warden"},
	{"id": "seer_a", "room": SHRINE, "pos": Vector2(1088, 672), "monster": "thornveil_seer", "kind": "seer"}
]

static func is_thornveil(room: int) -> bool:
	return room >= FIRST and room <= LAST

static func open_rects(room: int) -> Array[Rect2]:
	if room == APPROACH:
		return APPROACH_OPEN
	if room == SHRINE:
		return SHRINE_OPEN
	return GLADE_OPEN

static func _cell(world_point: Vector2) -> Vector2:
	return (world_point / float(TILE)).floor() * TILE + Vector2.ONE * TILE * 0.5

static func walkable(world_point: Vector2, room: int) -> bool:
	if not is_thornveil(room):
		return false
	var cell := _cell(world_point)
	for rect in open_rects(room):
		if rect.has_point(cell):
			return true
	return false

static func spawn(room: int) -> Vector2:
	if room == APPROACH:
		return APPROACH_SPAWN
	if room == SHRINE:
		return SHRINE_SPAWN
	return GLADE_SPAWN

static func thorns(room: int) -> Array:
	return THORNS.get(room, [])

static func props(room: int) -> Array:
	return PROPS.get(room, [])

static func in_thorns(world_point: Vector2, room: int) -> bool:
	for point in thorns(room):
		if world_point.distance_to(point) <= 42.0:
			return true
	return false
