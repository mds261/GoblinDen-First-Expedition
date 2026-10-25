extends SceneTree
const Save = preload("res://scripts/save_data.gd")
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--test-save=") and arg.contains("work"):
			Save.SAVE_PATH = arg.trim_prefix("--test-save=")
	if not Save.SAVE_PATH.contains("work"):
		quit(2)
		return
	Save.delete_save()
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.expedition.ui.close()
	game.player.set_physics_process(false)
	game.player.invulnerability = 99999
	var hunts = game.rpg.boss_hunts
	check(hunts.quests().size() == 11, "All authored bosses have quests")
	game.enter_room(0,game.expedition.moss_position(),true)
	hunts.accept()
	game._auto_save()
	game.queue_free()
	await process_frame
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.expedition.ui.close()
	game.player.set_physics_process(false)
	game.player.invulnerability = 99999
	hunts = game.rpg.boss_hunts
	check(hunts.accepted and is_instance_valid(hunts.actor), "Accepted hunt restores its encounter after reload")
	for quest in hunts.quests():
		game.enter_room(0,game.expedition.moss_position(),true)
		hunts.accept()
		check(hunts.accepted, "Moss accepts " + str(quest.id))
		var entrances := {0:Vector2(640,1408),5:Vector2(220,365),6:game.EXPANSE_SPAWN,11:Vector2(230,365),12:Vector2(230,365),15:preload("res://scripts/dungeon_layout.gd").entry(15),16:preload("res://scripts/cinder_orchard_layout.gd").SPAWN,19:preload("res://scripts/thornveil_layout.gd").GLADE_SPAWN}
		game.enter_room(int(quest.room),entrances[int(quest.room)],true)
		await physics_frame
		var cave = game.get_node("Cave")
		var point := Vector2(quest.x,quest.y)
		var cell: Vector2i = cave._nearest_open_cell(point)
		check(cave.navigation.get_point_position(cell).distance_to(point) < 48, "Boss stands on navigable floor: " + str(quest.id))
		var path: PackedVector2Array = cave.navigation.get_point_path(cave._nearest_open_cell(game.player.position),cell)
		check(not path.is_empty(), "Boss route exists: " + str(quest.id))
		check(hunts.target_point().distance_to(point) < 1, "Hunt compass points to boss")
		var boss = hunts.actor
		if quest.boss_id == "kilnheart":
			boss = game.rpg.orchard.boss
			boss.awaken()
			boss.boss_state = "exposed"
		elif quest.boss_id == "bramble_crown":
			boss = game.rpg.thornveil.boss
			boss.awaken()
			boss.boss_state = "stagger"
		elif quest.boss_id == "vault_hunger":
			boss = game.rpg.dungeon.boss
			boss.awaken()
		check(is_instance_valid(boss) and boss.hp > 0, "Live boss for " + str(quest.id))
		boss.take_damage(999999)
		check(hunts.is_complete(quest), "Defeat completes " + str(quest.id))
		var before: int = game.scrap
		hunts.claim()
		check(not str(quest.id) in hunts.claimed, "Cannot claim away from Moss")
		game.enter_room(0,game.expedition.moss_position(),true)
		hunts.claim()
		check(str(quest.id) in hunts.claimed and game.scrap == before + int(quest.reward_scrap), "Pays the hunt once")
		hunts.claim()
		check(game.scrap == before + int(quest.reward_scrap), "No duplicate reward")
		game.expedition.ui.close()
	check(hunts.current().is_empty(), "Full progression ends after the Thornveil hunt")
	game._auto_save()
	game.queue_free()
	await process_frame
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.expedition.ui.close()
	check(game.rpg.boss_hunts.claimed.size() == 11 and game.rpg.boss_hunts.current().is_empty(), "Completed quests survive an actual reload")
	check(game.rpg.orchard.boss == null and game.rpg.dungeon.boss == null and game.rpg.thornveil.boss == null, "Persistent bosses stay defeated")
	game.queue_free()
	await process_frame
	Save.delete_save()
	print("Boss hunt progression checks; failures: ", failures)
	quit(1 if failures else 0)
