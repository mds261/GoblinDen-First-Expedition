extends SceneTree
const Save = preload("res://scripts/save_data.gd")
const Data = preload("res://trial/contracts.gd")
var game: Node2D
var failures := 0
var assertions := 0
func _initialize() -> void:
	call_deferred("run")
func check(value: bool, message: String) -> void:
	assertions += 1
	if not value:
		failures += 1
		push_error(message)
func fresh() -> void:
	if is_instance_valid(game):
		game.expedition.ui.close()
		game.queue_free()
		await process_frame
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.expedition.ui.close()
	game.player.set_physics_process(false)
	game.player.invulnerability = 99999
	await physics_frame
	await process_frame
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
func go(room: int, pos: Vector2) -> void:
	game.enter_room(room,pos,true)
	await physics_frame
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
func at_moss() -> void:
	await go(0,game.expedition.moss_position()+Vector2(0,55))
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
	check(Data.weather_profile("Mist").notice < Data.weather_profile("Clear").notice, "Mist shortens watch notice")
	check(Data.weather_profile("Rain").arrow < Data.weather_profile("Clear").arrow, "Rain slows arrows")
	check(bool(Data.weather_profile("Mist").conceal), "Mist conceals a still goblin")
	check(Data.generate(0,42,1).weather == Data.generate(0,42,1).weather, "Weather stays on seed")
	await fresh()
	await at_moss()
	check(game.expedition.choose_rite("archer"), "Class rite can be taken at the fire")
	check(game.player.class_id=="archer", "Rite switches the living class")
	check(game.expedition.rite_id=="archer", "Rite is remembered")
	check(game.expedition.begin(0,42), "Contract still starts after a rite")
	game.expedition.ui.close()
	var mist_notice := float(Data.weather_profile(str(game.expedition.active.weather)).notice)
	for enemy in get_nodes_in_group("enemies"):
		if enemy.has_meta("expedition_id") and enemy.dungeon_awareness != null:
			check(is_equal_approx(enemy.dungeon_awareness.notice_scale, mist_notice), "Guards inherit the sky")
			break
	await go(6, game.EXPANSE_SPAWN)
	check(absf(game.player._trial_arrow_scale() - float(game.expedition.weather_profile().arrow)) < 0.001, "Player arrows read the weather")
	game.expedition.combo = 3
	var with_streak: int = game.player.get_effective_damage()
	game.expedition.on_player_hit()
	check(game.expedition.combo==0, "A hit breaks the streak")
	check(game.player.get_effective_damage()==with_streak-3, "Streak bonus is +1 damage per stack, capped in the live swing")
	# The live formula caps at 4; combo 3 should have added 3.
	var shot: Dictionary = game.expedition.snapshot()
	check(shot.rite_id=="archer" and shot.has("best_combo"), "Snapshot keeps the rite")
	game.expedition.restore(shot)
	check(game.expedition.rite_id=="archer", "Restore keeps the rite")
	game.expedition.ui.close()
	game.queue_free()
	await process_frame
	print("TRIAL PRESENTATION: %d assertions, %d failures"%[assertions,failures])
	quit(1 if failures else 0)
