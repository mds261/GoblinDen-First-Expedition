extends SceneTree
const Save = preload("res://scripts/save_data.gd")
const Catalog = preload("res://scripts/design_catalog.gd")
const Layout = preload("res://scripts/cinder_orchard_layout.gd")
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
	check(errors.is_empty(), "Catalog accepts the orchard records: %s" % " ".join(errors))
	check(Catalog.record("monsters", "cinder_mite").name == "CINDER MITE", "Cinder mite is registered")
	check(Catalog.record("monsters", "ash_wisp").name == "ASH WISP", "Ash wisp is registered")
	check(Catalog.record("monsters", "kilnheart").name == "KILNHEART", "Kilnheart is registered")
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.expedition.ui.close()
	paused = false
	game.rpg.boss_hunts.claimed = game.rpg.boss_hunts.quests().filter(func(q): return not q.get("bonus",false)).map(func(q): return str(q.id))
	game.enter_room(0,game.expedition.moss_position(),true)
	game.rpg.boss_hunts.accept()
	game.player.set_physics_process(false)
	await physics_frame
	check(game.rooms.size() == 20 and game.ROOM_NAMES[16] == "CINDER ORCHARD", "Orchard is room 16 and older rooms stay numbered")
	check(game.ROOM_NAMES[15].contains("SEALED DESCENT"), "Sealed Descent remains the previous area")
	check(game.current_room == 0, "Demo still starts in the den")
	check(Layout.HOLLOW_ENTRANCE.distance_to(game.RIGHT_GATE) > 200.0, "Heat-crack is off the eastern gate")
	game.enter_room(5, game.RIGHT_GATE)
	await physics_frame
	game.interact()
	check(game.current_room == 6, "Eastern hollow gate still opens Thornwood")
	game.enter_room(5, Layout.HOLLOW_ENTRANCE)
	await physics_frame
	check(not blocked(game, Layout.HOLLOW_ENTRANCE), "Heat-crack stands on open hollow floor")
	var prompt: Dictionary = game.interaction_feedback.choose(game.interaction_feedback.candidates())
	check(str(prompt.get("label", "")).contains("Cinder Orchard"), "Hollow offers the final bonus descent")
	game.interact()
	await physics_frame
	check(game.current_room == Layout.ROOM, "Heat-crack enters the orchard")
	check(game.player.position.distance_to(Layout.SPAWN) < 2.0, "Arrival uses the orchard spawn")
	var camera: Camera2D = game.player.get_node("Camera2D")
	check(camera.limit_right == int(Layout.SIZE.x) and camera.limit_bottom == int(Layout.SIZE.y), "Camera uses the orchard bounds")
	var cave = game.get_node("Cave")
	check(cave.world_size_for_room() == Layout.SIZE, "Cave world size follows the orchard")
	check(Layout.SIZE.x * Layout.SIZE.y >= 1792.0 * 1088.0 * 5.0, "The orchard covers at least five times the first grove")
	check(Layout.MITES.size() >= 8 and Layout.WISPS.size() >= 8, "The larger grove keeps more of its own creatures")
	check(Layout.VENTS.size() >= 10 and Layout.SPITS.size() >= 6 and Layout.DROPS.size() >= 8 and Layout.DRIFTS.size() >= 3 and Layout.COLUMNS.size() >= 6, "Vents, jets, drops, drifts, and columns fill the new ground")
	for point in [Layout.SPAWN, Layout.EXIT, Layout.CACHE, Layout.BOSS, Layout.VENTS[0], Layout.VENTS[9], Layout.VENTS[11], Layout.WISPS[0].at, Layout.WISPS[2].at, Layout.DROPS[0]]:
		check(Layout.walkable(point) and not blocked(game, point), "Open point is walkable: %s" % point)
		var path: PackedVector2Array = cave.navigation.get_point_path(cave._nearest_open_cell(Layout.SPAWN), cave._nearest_open_cell(point))
		check(not path.is_empty(), "Route from the entrance: %s" % point)
	var mites := 0
	var wisps := 0
	var boss: Node = null
	for child in game.rooms[Layout.ROOM].get_children():
		if child.get_script() == load("res://scripts/cinder_mite.gd"):
			mites += 1
		if child.get_script() == load("res://scripts/ash_wisp.gd"):
			wisps += 1
		if child.get_script() == load("res://scripts/kilnheart.gd"):
			boss = child
	check(mites == Layout.MITES.size() and wisps == Layout.WISPS.size() and boss != null, "Orchard spawns every mite, every wisp, and Kilnheart")
	check(not boss.is_in_group("enemies") and boss.boss_state == "dormant", "Kilnheart sleeps until the kiln")
	var knight_script = load("res://scripts/knight.gd")
	check(boss.get_script() != knight_script and boss.get_script() != load("res://scripts/dungeon_boss.gd") and boss.get_script() != load("res://scripts/iron_captain.gd"), "Kilnheart is not an existing boss script")
	var mite: Node = null
	for child in game.rooms[Layout.ROOM].get_children():
		if child.get_script() == load("res://scripts/cinder_mite.gd"):
			mite = child
			break
	var far_before: Vector2 = mite.position
	game.player.position = Vector2(200, 200)
	mite.state_time = 0.0
	await physics_frame
	await physics_frame
	check(mite.state == "idle", "Mites do not chase off the ember court")
	game.player.position = mite.position + Vector2(30, 0)
	mite.state_time = 0.0
	for _i in range(8):
		await physics_frame
	check(mite.state == "dash" and mite.position.distance_to(far_before) > 4.0, "Mite skitters its vent line when you crowd it")
	var wisp: Node = null
	for child in game.rooms[Layout.ROOM].get_children():
		if child.get_script() == load("res://scripts/ash_wisp.gd"):
			wisp = child
			break
	game.player.position = Layout.SPAWN
	wisp.state = "rest"
	wisp.state_time = 0.0
	await physics_frame
	await physics_frame
	check(wisp.state == "rest", "Ash wisp stays at its trunk outside the nave")
	game.player.position = wisp.home + Vector2(40, 10)
	wisp.state = "rest"
	wisp.state_time = 0.0
	for _i in range(6):
		await physics_frame
	check(wisp.state == "approach" or wisp.state == "exhale", "Ash wisp breathes only inside its leash")
	game.player.position = Layout.BOSS + Vector2(40, 0)
	for _i in range(4):
		await physics_frame
	check(boss.boss_state != "dormant" and boss.is_in_group("enemies"), "Kilnheart wakes in its kiln")
	check(not ["bite", "coins", "slam", "lunging"].has(str(boss.boss_state)), "Kilnheart does not reuse the vault boss attacks")
	boss.boss_state = "exposed"
	boss.hp = 1
	var before: int = int(game.player.hp)
	game.player.position = Layout.VENTS[0]
	game.player.invulnerability = 0.0
	var floor_node = game.rpg.orchard.floor_node
	floor_node.time = 2.9
	await physics_frame
	check(game.player.hp < before, "Standing on a hot vent deals damage")
	var after_vent: int = int(game.player.hp)
	game.player.position = Layout.SPITS[0].get_center()
	game.player.invulnerability = 0.0
	floor_node.time = 2.4
	await physics_frame
	check(game.player.hp < after_vent, "A heat jet across the lane deals damage")
	var after_spit: int = int(game.player.hp)
	game.player.position = Layout.DROPS[0]
	game.player.invulnerability = 0.0
	floor_node.time = 3.9
	await physics_frame
	check(game.player.hp < after_spit, "A falling ember in the rows deals damage")
	boss.take_damage(80)
	check(game.rpg.orchard.boss_defeated, "Defeating Kilnheart is recorded once")
	var scrap_before: int = int(game.scrap)
	game.player.position = Layout.CACHE
	game.interaction_feedback.activation_cooldown = 0.0
	game.interact()
	check(game.scrap == scrap_before + 8 and game.rpg.orchard.cache_taken, "Ash cache pays once")
	game.interaction_feedback.activation_cooldown = 0.0
	game.interact()
	check(game.scrap == scrap_before + 8, "Ash cache does not pay twice")
	game.player.position = Layout.EXIT
	game.interaction_feedback.activation_cooldown = 0.0
	game.interact()
	check(game.current_room == 5 and game.player.position.distance_to(Layout.HOLLOW_RETURN) < 2.0, "The orchard returns to the hollow")
	game.player.position = game.RIGHT_GATE
	game.interaction_feedback.activation_cooldown = 0.0
	game.interact()
	check(game.current_room == 6, "After the side trip, the eastern trail still opens")
	game.queue_free()
	await process_frame
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.expedition.ui.close()
	paused = false
	await physics_frame
	check(game.rpg.orchard.boss_defeated and game.rpg.orchard.boss == null, "Kilnheart does not respawn from the save")
	check(game.rpg.orchard.cache_taken, "Ash cache stays collected")
	game.queue_free()
	await process_frame
	Save.delete_save()
	print("Cinder Orchard checks; failures: ", failures)
	quit(1 if failures else 0)
