extends SceneTree
const Save = preload("res://scripts/save_data.gd")
const Catalog = preload("res://scripts/design_catalog.gd")
const Layout = preload("res://scripts/thornveil_layout.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func blocked(game: Node2D, point: Vector2) -> bool:
	var query := PhysicsPointQueryParameters2D.new()
	query.position = point
	query.collision_mask = 1
	return not game.get_world_2d().direct_space_state.intersect_point(query).is_empty()

func run() -> void:
	var save_path := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--test-save="):
			save_path = arg.trim_prefix("--test-save=")
	if save_path.is_empty() or not save_path.contains("work"):
		push_error("Tests require --test-save=<workspace/work/isolated.cfg>")
		quit(2)
		return
	Save.SAVE_PATH = save_path
	Save.delete_save()
	var docs := {}
	for category in Catalog.CATEGORIES:
		docs[category] = Catalog.document(category)
	var errors := Catalog.validate(docs)
	check(errors.is_empty(), "Catalog accepts Thornveil records: %s" % " ".join(errors))
	var crown_sheet: Texture2D = load("res://assets/thornveil/bramble_crown_sheet.png")
	var thornling_sheet: Texture2D = load("res://assets/thornveil/thornling_sheet.png")
	var prop_sheet: Texture2D = load("res://assets/thornveil/props.png")
	var guardian_sheet: Texture2D = load("res://assets/thornveil/guardians.png")
	check(crown_sheet != null and crown_sheet.get_width() > 1000 and crown_sheet.get_height() > 1400, "Bramble Crown has a full 4x5 transparent animation sheet")
	check(thornling_sheet != null and thornling_sheet.get_width() > 2000, "Thornlings have four painted animation states")
	check(prop_sheet != null and prop_sheet.get_height() > 800, "Thornveil has a painted environmental prop atlas")
	check(guardian_sheet != null and guardian_sheet.get_width() == 1448 and guardian_sheet.get_height() == 1086, "Warden, Poacher, and Seer share a complete 4x3 painted atlas")
	check(Catalog.record("monsters", "bramble_crown").name == "BRAMBLE CROWN", "Bramble Crown is registered")
	check(Catalog.record("rooms", "room_19").name == "THORNVEIL CROWN GLADE", "Crown Glade is room 19")
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.expedition.ui.close()
	paused = false
	game.player.set_physics_process(false)
	await physics_frame
	check(game.rooms.size() == 20 and game.ROOM_NAMES[17] == "THORNVEIL APPROACH", "Thornveil rooms append after Cinder")
	check(game.ROOM_NAMES[16] == "CINDER ORCHARD", "Cinder stays room 16")
	check(Layout.HOLLOW_GATE.distance_to(preload("res://scripts/cinder_orchard_layout.gd").HOLLOW_ENTRANCE) > 200.0, "North gate is not the heat-crack")
	game.enter_room(5, Layout.HOLLOW_GATE)
	await physics_frame
	check(not blocked(game, Layout.HOLLOW_GATE), "North gate stands on open hollow floor")
	var prompt: Dictionary = game.interaction_feedback.choose(game.interaction_feedback.candidates())
	check(str(prompt.get("label", "")).contains("Thornveil"), "Hollow offers the northern grove")
	game.interact()
	await physics_frame
	check(game.current_room == Layout.APPROACH, "North gate enters the Approach")
	check(game.audio_system.mood_for_room(Layout.APPROACH) == "thornveil", "Thornveil selects its own original soundscape")
	check(game.player.position.distance_to(Layout.APPROACH_SPAWN) < 2.0, "Arrival uses the approach spawn")
	var guard_kinds: Array = []
	var poacher: Node = null
	for actor in game.rooms[Layout.APPROACH].get_children():
		if actor.get_script() == load("res://scripts/thornveil_guard.gd"):
			guard_kinds.append(actor.guard_kind)
			if actor.guard_kind == "poacher":
				poacher = actor
	check(guard_kinds.has("warden") and guard_kinds.has("poacher"), "Approach uses unique shield and thorn-bow encounters")
	poacher.set_physics_process(false)
	poacher.target = game.player
	game.player.position = poacher.position + Vector2(180, 0)
	poacher._release_attack()
	check(get_nodes_in_group("thornveil_hazards").size() == 1, "Poacher releases a dedicated painted thorn projectile")
	game.rpg.thornveil.reset_room_on_exit(Layout.APPROACH)
	await process_frame
	var camera: Camera2D = game.player.get_node("Camera2D")
	check(camera.limit_right == int(Layout.SIZE.x) and camera.limit_bottom == int(Layout.SIZE.y), "Camera uses Thornveil bounds")
	var cave = game.get_node("Cave")
	check(cave.world_size_for_room() == Layout.SIZE, "Cave world size follows Thornveil")
	for point in [Layout.APPROACH_SPAWN, Layout.APPROACH_TO_HOLLOW, Layout.APPROACH_TO_SHRINE]:
		check(Layout.walkable(point, Layout.APPROACH) and not blocked(game, point), "Approach point is walkable: %s" % point)
		var path: PackedVector2Array = cave.navigation.get_point_path(cave._nearest_open_cell(Layout.APPROACH_SPAWN), cave._nearest_open_cell(point))
		check(not path.is_empty(), "Route across the Approach: %s" % point)
	game.player.position = Layout.MEMORIES[0].point
	var xp_before: int = game.player.xp
	game.rpg.thornveil.discover_memory("oath")
	game.rpg.thornveil.discover_memory("oath")
	check(game.rpg.thornveil.memories.size() == 1 and game.player.xp == xp_before + 35, "Hunter oath is a one-time story interaction")
	game.player.position = Layout.APPROACH_TO_SHRINE
	game.interaction_feedback.activation_cooldown = 0.0
	game.interact()
	await physics_frame
	check(game.current_room == Layout.SHRINE, "East trail enters the shrine")
	for point in [Layout.SHRINE_SPAWN, Layout.SHRINE_TO_APPROACH, Layout.SHRINE_TO_GLADE, Layout.SHRINE_CACHE]:
		check(Layout.walkable(point, Layout.SHRINE) and not blocked(game, point), "Shrine point is walkable: %s" % point)
	var shrine_kinds: Array = []
	var seer: Node = null
	for actor in game.rooms[Layout.SHRINE].get_children():
		if actor.get_script() == load("res://scripts/thornveil_guard.gd"):
			shrine_kinds.append(actor.guard_kind)
			if actor.guard_kind == "seer":
				seer = actor
	check(shrine_kinds.has("warden") and shrine_kinds.has("seer"), "Shrine combines a shield line with predictive root magic")
	seer.set_physics_process(false)
	seer.target = game.player
	game.player.position = seer.position + Vector2(120, 0)
	seer._release_attack()
	check(get_nodes_in_group("thornveil_hazards").size() == 1, "Seer predicts movement with a delayed root eruption")
	game.rpg.thornveil.reset_room_on_exit(Layout.SHRINE)
	await process_frame
	game.player.position = Layout.MEMORIES[1].point
	game.rpg.thornveil.discover_memory("shrine")
	var scrap_before: int = int(game.scrap)
	game.player.position = Layout.SHRINE_CACHE
	game.interaction_feedback.activation_cooldown = 0.0
	game.interact()
	check(game.scrap == scrap_before + 10 and game.rpg.thornveil.cache_taken, "Shrine cache pays once")
	game.player.position = Layout.SHRINE_TO_GLADE
	game.interaction_feedback.activation_cooldown = 0.0
	game.interact()
	await physics_frame
	check(game.current_room == Layout.GLADE, "North climb enters the Crown Glade")
	game.player.position = Layout.MEMORIES[2].point
	game.rpg.thornveil.discover_memory("collar")
	check(game.rpg.thornveil.collar_cracked() and game.rpg.thornveil.memory_progress() == "3/3", "Three root memories crack the Crown's collar")
	var boss: Node = game.rpg.thornveil.boss
	check(boss != null and boss.get_script() == load("res://scripts/bramble_crown.gd"), "Glade spawns the Bramble Crown")
	check(not boss.is_in_group("enemies") and boss.boss_state == "dormant", "Crown sleeps until the arena")
	check(boss.get_script() != load("res://scripts/kilnheart.gd") and boss.get_script() != load("res://scripts/dungeon_boss.gd"), "Crown is not an existing boss script")
	game.player.position = Layout.BOSS + Vector2(40, 0)
	for _i in range(4):
		await physics_frame
	check(boss.boss_state != "dormant" and boss.is_in_group("enemies"), "Crown wakes in its glade")
	check(not ["lanes", "breath", "uproot", "bite", "coins"].has(str(boss.boss_state)), "Crown does not reuse kiln or vault attacks")
	check(boss._sprite_frame() is Vector2i, "Boss combat states resolve to supplied sprite-sheet frames")
	boss.boss_state = "gore"
	var crown_hp: int = boss.hp
	boss.take_damage(20)
	check(boss.hp == crown_hp - 13 and boss.status_text == "COLLAR CRACKED", "Completed environmental story improves attack-window damage without removing armor")
	boss._begin_root_snare()
	check(boss.boss_state == "root_snare" and get_nodes_in_group("thornveil_hazards").size() >= 3, "Crown telegraphs a multi-point root snare")
	boss._clear_hazards()
	await process_frame
	boss._begin_volley()
	boss.state_time = boss.state_total * 0.4
	boss._physics_process(0.0)
	check(boss.boss_state == "volley" and get_nodes_in_group("thornveil_hazards").size() == 5, "Phase-one Crown fires a five-thorn spread")
	boss._clear_hazards()
	await process_frame
	boss.boss_state = "stagger"
	var before: int = int(game.player.hp)
	game.player.position = Layout.thorns(Layout.GLADE)[0]
	game.player.invulnerability = 0.0
	var floor_node = game.rpg.thornveil.floors[Layout.GLADE]
	floor_node.set_collision_active(true)
	floor_node.time = 2.3
	floor_node._physics_process(0.016)
	check(game.player.hp < before, "Standing in a hot thorn ring deals damage")
	boss.take_damage(80)
	boss.hp = 1
	boss.take_damage(20)
	check(game.rpg.thornveil.boss_defeated, "Defeating the Crown is recorded once")
	game.player.position = Layout.GLADE_TO_SHRINE
	game.player.invulnerability = 999.0
	game.interaction_feedback.activation_cooldown = 0.0
	game.interact()
	check(game.current_room == Layout.SHRINE, "The glade returns to the shrine")
	game.player.position = Layout.SHRINE_TO_APPROACH
	game.interaction_feedback.activation_cooldown = 0.0
	game.interact()
	game.player.position = Layout.APPROACH_TO_HOLLOW
	game.interaction_feedback.activation_cooldown = 0.0
	game.interact()
	check(game.current_room == 5 and game.player.position.distance_to(Layout.HOLLOW_RETURN) < 2.0, "The ring returns to the hollow")
	game.queue_free()
	await process_frame
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.expedition.ui.close()
	paused = false
	await physics_frame
	check(game.rpg.thornveil.boss_defeated and game.rpg.thornveil.boss == null, "The Crown does not respawn from the save")
	check(game.rpg.thornveil.cache_taken, "Hunter cache stays collected")
	check(game.rpg.thornveil.memories.size() == 3 and game.rpg.thornveil.collar_cracked(), "Root memories persist across a restart")
	var hunts = game.rpg.boss_hunts
	check(hunts.is_complete({"boss_id": "bramble_crown", "bonus": true}), "Hunt completion reads the Thornveil flag")
	game.queue_free()
	await process_frame
	Save.delete_save()
	print("Thornveil area and Bramble Crown checks; failures: ", failures)
	quit(1 if failures else 0)
