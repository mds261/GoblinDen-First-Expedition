extends Node2D
## Three connected Thornveil rooms north of the hollow, plus the Bramble Crown hunt.
const Layout = preload("res://scripts/thornveil_layout.gd")
const Floor = preload("res://scripts/thornveil_floor.gd")
const Gate = preload("res://scripts/thornveil_gate.gd")
const Boss = preload("res://scripts/bramble_crown.gd")
const Guard = preload("res://scripts/thornveil_guard.gd")
const Awareness = preload("res://scripts/dungeon_awareness.gd")
var game: Node2D
var floors: Dictionary = {}
var defeated: Array = []
var cache_taken := false
var boss_defeated := false
var memories: Array = []
var populated := false
var boss: CharacterBody2D

func _ready() -> void:
	for room in range(Layout.FIRST, Layout.LAST + 1):
		var floor_node := Floor.new()
		floor_node.room_id = room
		game.rooms[room].add_child(floor_node)
		floors[room] = floor_node
	var gate := Gate.new()
	gate.position = Layout.HOLLOW_GATE
	game.rooms[5].add_child(gate)

func populate() -> void:
	if populated:
		return
	populated = true
	for spec in Layout.ENEMIES:
		if spec.id in defeated:
			continue
		var actor := Guard.new()
		actor.configure(spec.monster, spec.kind)
		actor.position = spec.pos
		game.rooms[int(spec.room)].add_child(actor)
		actor.set_meta("thornveil_id", spec.id)
		actor.dungeon_awareness = Awareness.new()
		actor.dungeon_awareness.configure(actor)
		actor.defeated.connect(_remember.bind(spec.id))
		actor.defeated.connect(game.on_enemy_defeated.bind(actor, int(spec.room)))
	if not boss_defeated:
		boss = Boss.new()
		boss.position = Layout.BOSS
		game.rooms[Layout.GLADE].add_child(boss)
		boss.set_meta("boss_hunt_id", "bramble_crown")
		boss.defeated.connect(_remember.bind("bramble_crown"))
		boss.defeated.connect(game.on_enemy_defeated.bind(boss, Layout.GLADE))

func reset_room_on_exit(room: int) -> void:
	for hazard in get_tree().get_nodes_in_group("thornveil_hazards"):
		if is_instance_valid(hazard) and hazard.get_parent() == game.rooms[room]:
			hazard.queue_free()
	if room == Layout.GLADE and is_instance_valid(boss) and not boss_defeated:
		boss.reset_abandoned_encounter()

func _actor_at(room: int, point: Vector2) -> Node2D:
	for child in game.rooms[room].get_children():
		if child is CharacterBody2D and child.position.distance_to(point) < 8.0:
			return child
	return null

func _remember(id: String) -> void:
	if id == "bramble_crown":
		boss_defeated = true
	elif not defeated.has(id):
		defeated.append(id)

func interaction_candidates() -> Array:
	if game.current_room == 5:
		return [{
			"point": Layout.HOLLOW_GATE,
			"radius": 88.0,
			"label": "Enter Thornveil Antler Ring · Northern grove",
			"action": enter_from_hollow
		}]
	if not Layout.is_thornveil(game.current_room):
		return []
	var options: Array = []
	for memory in Layout.MEMORIES:
		if int(memory.room) == game.current_room and not memories.has(memory.id):
			options.append({"point": memory.point, "radius": 72.0, "label": memory.label, "action": discover_memory.bind(memory.id)})
	if game.current_room == Layout.APPROACH:
		options.append({"point": Layout.APPROACH_TO_HOLLOW, "radius": 80.0, "label": "Return to Thornwood Hollow", "action": leave_to_hollow})
		options.append({"point": Layout.APPROACH_TO_SHRINE, "radius": 80.0, "label": "Follow the trail to the Root Shrine", "action": enter_shrine})
	elif game.current_room == Layout.SHRINE:
		options.append({"point": Layout.SHRINE_TO_APPROACH, "radius": 80.0, "label": "Back to the Approach", "action": enter_approach_from_shrine})
		options.append({"point": Layout.SHRINE_TO_GLADE, "radius": 80.0, "label": "Climb into the Crown Glade", "action": enter_glade})
		if not cache_taken:
			options.append({"point": Layout.SHRINE_CACHE, "radius": 70.0, "label": "Pry hunter iron from the roots", "action": take_cache})
	else:
		options.append({"point": Layout.GLADE_TO_SHRINE, "radius": 80.0, "label": "Descend to the Root Shrine", "action": leave_glade})
	return options

func enter_from_hollow() -> void:
	if game.current_room != 5 or game.player.position.distance_to(Layout.HOLLOW_GATE) > 100.0:
		return
	game.enter_room(Layout.APPROACH, Layout.APPROACH_SPAWN)
	game.show_notice("THORNVEIL APPROACH — the old hunting road ends in thorns.")

func leave_to_hollow() -> void:
	if game.current_room != Layout.APPROACH or game.player.position.distance_to(Layout.APPROACH_TO_HOLLOW) > 100.0:
		return
	game.enter_room(5, Layout.HOLLOW_RETURN)
	game.show_notice("Thornwood Hollow. South still cracks with orchard heat.")

func enter_shrine() -> void:
	if game.current_room != Layout.APPROACH or game.player.position.distance_to(Layout.APPROACH_TO_SHRINE) > 100.0:
		return
	game.enter_room(Layout.SHRINE, Layout.SHRINE_SPAWN)
	game.show_notice("THORNVEIL SHRINE — roots remember every collar they swallowed.")

func enter_approach_from_shrine() -> void:
	if game.current_room != Layout.SHRINE or game.player.position.distance_to(Layout.SHRINE_TO_APPROACH) > 100.0:
		return
	game.enter_room(Layout.APPROACH, Layout.APPROACH_TO_SHRINE)

func enter_glade() -> void:
	if game.current_room != Layout.SHRINE or game.player.position.distance_to(Layout.SHRINE_TO_GLADE) > 100.0:
		return
	game.enter_room(Layout.GLADE, Layout.GLADE_SPAWN)
	game.show_notice("CROWN GLADE — do not stand in the gore line.")

func leave_glade() -> void:
	if game.current_room != Layout.GLADE or game.player.position.distance_to(Layout.GLADE_TO_SHRINE) > 100.0:
		return
	game.enter_room(Layout.SHRINE, Layout.SHRINE_TO_GLADE)

func take_cache() -> void:
	if cache_taken or game.current_room != Layout.SHRINE or game.player.position.distance_to(Layout.SHRINE_CACHE) > 90.0:
		return
	cache_taken = true
	game.scrap += 10
	game.show_notice("Rusted hunter iron. The collar on the Crown matches this make.")
	game._auto_save()

func discover_memory(id: String) -> void:
	if memories.has(id):
		return
	var memory: Dictionary = {}
	for entry in Layout.MEMORIES:
		if str(entry.id) == id:
			memory = entry
			break
	if memory.is_empty() or game.current_room != int(memory.room) or game.player.position.distance_to(memory.point) > 90.0:
		return
	memories.append(id)
	game.gain_xp(35)
	game.audio_system.play_sfx("thorn_memory")
	var stories := {
		"oath": "The hunters chained the grove from the inside. Their oath points toward the Crown.",
		"shrine": "The roots remember a guardian forced into an iron collar. The Crown was made, not born.",
		"collar": "The collar-sigil cracks. The Crown's bark will open wider when it commits."
	}
	game.show_notice("ROOT MEMORY %d/3 — %s  +35 XP" % [memories.size(), stories.get(id, "The grove remembers.")])
	game.refresh_objective()
	game._auto_save()

func memory_progress() -> String:
	return "%d/3" % memories.size()

func collar_cracked() -> bool:
	return memories.size() >= 3

func snapshot() -> Dictionary:
	return {"defeated": defeated.duplicate(), "cache": cache_taken, "boss": boss_defeated, "memories": memories.duplicate()}

func restore(state: Dictionary) -> void:
	defeated = state.get("defeated", []).duplicate()
	cache_taken = bool(state.get("cache", false))
	boss_defeated = bool(state.get("boss", false))
	memories = state.get("memories", []).duplicate()
