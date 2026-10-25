extends Node2D
## Registers the optional Cinder Orchard: entrance, hazards live on the floor, creatures spawn here.
const Layout = preload("res://scripts/cinder_orchard_layout.gd")
const Floor = preload("res://scripts/cinder_orchard_floor.gd")
const Crack = preload("res://scripts/cinder_crack.gd")
const Mite = preload("res://scripts/cinder_mite.gd")
const Wisp = preload("res://scripts/ash_wisp.gd")
const Boss = preload("res://scripts/kilnheart.gd")
var game: Node2D
var floor_node: Node2D
var defeated: Array = []
var cache_taken := false
var boss_defeated := false
var bonus_started := false
var bonus_completed := false
var populated := false
var boss: CharacterBody2D

func _ready() -> void:
	floor_node = Floor.new()
	game.rooms[Layout.ROOM].add_child(floor_node)
	# Paint dressing at authored landmarks and inside existing solid walls.
	_add_dressing(Layout.EXIT, 4, Vector2(150,130))
	_add_dressing(Layout.CACHE, 3, Vector2(88,78))
	for point in Layout.PILLARS:
		_add_dressing(point, 1, Vector2(68,110))
	for point in [Vector2(1120,224),Vector2(1632,224),Vector2(2144,224),Vector2(2528,544),Vector2(2240,832),Vector2(2592,1184),Vector2(1120,1760),Vector2(2464,2208),Vector2(3456,832)]:
		_add_dressing(point, 0, Vector2(90,150))
	var crack := Crack.new()
	crack.position = Layout.HOLLOW_ENTRANCE
	game.rooms[5].add_child(crack)

func populate() -> void:
	if populated:
		return
	populated = true
	for spec in Layout.MITES:
		if spec.id in defeated:
			continue
		var mite := Mite.new()
		mite.setup(spec)
		_place(mite, spec.id)
	for spec in Layout.WISPS:
		if spec.id in defeated:
			continue
		var wisp := Wisp.new()
		wisp.setup(spec)
		_place(wisp, spec.id)
	if not boss_defeated:
		boss = Boss.new()
		boss.position = Layout.BOSS
		game.rooms[Layout.ROOM].add_child(boss)
		boss.defeated.connect(_remember.bind("kilnheart"))
		boss.defeated.connect(game.on_enemy_defeated.bind(boss, Layout.ROOM))

func accessible() -> bool:
	return bonus_started and game.rpg.boss_hunts.main_complete()

func begin_bonus() -> void:
	if bonus_started or not game.rpg.boss_hunts.main_complete():
		return
	bonus_started = true
	bonus_completed = false
	boss_defeated = false
	defeated.clear()
	# An old early clear remains in quest history; the bonus gets a fresh encounter.
	for child in game.rooms[Layout.ROOM].get_children():
		if child is CharacterBody2D:
			child.collision_layer = 0
			child.collision_mask = 0
			child.remove_from_group("enemies")
			game.rooms[Layout.ROOM].remove_child(child)
			child.queue_free()
	boss = null
	populated = false
	populate()

func reset_boss_on_exit() -> void:
	if is_instance_valid(boss) and not boss_defeated:
		boss.reset_abandoned_encounter()

func _place(actor: CharacterBody2D, id: String) -> void:
	game.rooms[Layout.ROOM].add_child(actor)
	var active: bool = int(game.get("current_room")) == Layout.ROOM
	actor.collision_layer = 2 if active and actor.hp > 0 else 0
	actor.collision_mask = 3 if active and actor.hp > 0 else 0
	actor.defeated.connect(_remember.bind(id))
	actor.defeated.connect(game.on_enemy_defeated.bind(actor, Layout.ROOM))

func _remember(id: String) -> void:
	if id == "kilnheart":
		boss_defeated = true
		bonus_completed = bonus_started
	elif not defeated.has(id):
		defeated.append(id)

func interaction_candidates() -> Array:
	if game.current_room == 5:
		return [{"point": Layout.HOLLOW_ENTRANCE, "radius": 90.0, "label": "Descend into Cinder Orchard · Final bonus challenge" if accessible() else "Cinder Orchard sealed · Finish nine hunts and accept Moss's bonus quest", "ready": accessible(), "action": enter_orchard}]
	if game.current_room != Layout.ROOM:
		return []
	var options: Array = [{"point": Layout.EXIT, "radius": 90.0, "label": "Climb back to Thornwood Hollow", "action": leave_orchard}]
	if not cache_taken:
		options.append({"point": Layout.CACHE, "radius": 80.0, "label": "Rake warm scrap from the ash", "action": take_cache})
	return options

func enter_orchard() -> void:
	if game.current_room != 5 or game.player.position.distance_to(Layout.HOLLOW_ENTRANCE) > 100.0:
		return
	if not accessible():
		game.show_notice("Cinder Orchard is the final bonus. Finish Moss's nine boss hunts, then accept his bonus quest.")
		return
	game.enter_room(Layout.ROOM, Layout.SPAWN)
	game.show_notice("FINAL BONUS · Cinder Orchard. Prepare for lethal heat. Kilnheart recovers if you abandon its arena.")

func leave_orchard() -> void:
	if game.current_room != Layout.ROOM or game.player.position.distance_to(Layout.EXIT) > 100.0:
		return
	game.enter_room(5, Layout.HOLLOW_RETURN)
	game.show_notice("Thornwood Hollow. East still leads into the forest.")

func take_cache() -> void:
	if cache_taken or game.current_room != Layout.ROOM or game.player.position.distance_to(Layout.CACHE) > 90.0:
		return
	cache_taken = true
	game.scrap += 8
	game.show_notice("Warm scrap in the ash. Lingering in the drift still burns.")
	game._auto_save()

func snapshot() -> Dictionary:
	return {"defeated": defeated.duplicate(), "cache": cache_taken, "boss": boss_defeated, "bonus_started":bonus_started, "bonus_completed":bonus_completed}

func restore(state: Dictionary) -> void:
	defeated = state.get("defeated", []).duplicate()
	cache_taken = bool(state.get("cache", false))
	boss_defeated = bool(state.get("boss", false))
	bonus_started = bool(state.get("bonus_started",false))
	bonus_completed = bool(state.get("bonus_completed",false))

func _add_dressing(point: Vector2, kind: int, box: Vector2) -> void:
	var prop := preload("res://scripts/cinder_dressing.gd").new()
	prop.position = point
	prop.kind = kind
	prop.box = box
	prop.orchard = self
	game.rooms[Layout.ROOM].add_child(prop)
