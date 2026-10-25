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
	await process_frame
	await physics_frame
	check(game.expedition.journal_hidden, "Journal shortcut starts hidden")
	check(not game.expedition.ui.journal_button.visible and game.rpg.exploration_map.canvas.visible, "Hiding the journal keeps the map visible")
	var journal := game.expedition.ui.journal_button as Button
	var map_button := game.rpg.exploration_map.toggle as Button
	var pack := game.find_child("PackShortcut",true,false) as Button
	var menu := game.find_child("MenuShortcut",true,false) as Button
	for shortcut in [journal,map_button,pack,menu]:
		check(shortcut.position.y == 18 and shortcut.custom_minimum_size.y == 28, "Toolbar shares a single height and alignment")
		check(shortcut.get_theme_font_size("font_size") == 12, "Toolbar typography is uniform")
	game.rpg.exploration_map._toggle()
	await physics_frame
	check(not game.rpg.exploration_map.canvas.visible and game.expedition.journal_hidden, "Map toggles independently of the journal")
	game.rpg.exploration_map._toggle()
	game.expedition.ui.open("journal")
	check(paused and game.expedition.ui.overlay.visible, "Journal opens in compact mode")
	game.expedition.ui.close()
	game.expedition.ui.toggle_journal_shortcut()
	await process_frame
	check(not game.expedition.journal_hidden and game.expedition.ui.journal_button.visible, "Journal shortcut expands")
	check(game.rpg.exploration_map.canvas.visible, "Showing journal button does not change the map")
	game.expedition.ui.toggle_journal_shortcut()
	check(not journal.visible and game.rpg.exploration_map.canvas.visible, "H hides only the journal button")
	game.expedition.ui.toggle_journal_shortcut()
	check(not game.expedition.snapshot().journal_hidden, "Journal preference is saved")
	game.scrap = 123
	game.player.level = 4
	game.expedition.upgrades.edge = 2
	game.rpg.boss_hunts.claimed = ["hunt_iron_captain"]
	game.rpg.orchard.cache_taken = true
	Save.save(game)
	var cfg := ConfigFile.new()
	cfg.load(Save.SAVE_PATH)
	check(not cfg.get_value("trial","state").journal_hidden, "Journal preference persists on disk")
	var event := InputEventAction.new()
	event.action = "restart"
	event.pressed = true
	game._unhandled_input(event)
	check(game.game_menu.restart_visible and paused, "R opens start-over confirmation")
	game.game_menu.close()
	check(game.scrap == 123 and Save.has_save(), "Cancelling keeps the journey")
	game.start_over()
	game._auto_save()
	check(not Save.has_save(), "Old autosave cannot recreate cleared progress")
	await process_frame
	await process_frame
	game = current_scene
	game.expedition.ui.close()
	check(game.player.level == 1 and game.scrap == 0, "Start over resets level and scrap")
	check(game.expedition.active.is_empty() and game.expedition.upgrades.edge == 0, "Start over resets expeditions and upgrades")
	check(game.rpg.boss_hunts.claimed.is_empty() and not game.rpg.orchard.cache_taken, "Start over resets bosses and orchard")
	check(not game.expedition.welcomed and game.expedition.journal_hidden, "New journey returns to class selection with only the journal shortcut hidden")
	cfg = ConfigFile.new()
	check(cfg.load(Save.SAVE_PATH + ".before-restart") == OK and cfg.get_value("progression","scrap") == 123, "Prior journey is backed up")
	game.queue_free()
	await process_frame
	Save.delete_save()
	DirAccess.remove_absolute(Save.SAVE_PATH + ".before-restart")
	print("HUD and restart checks; failures: ", failures)
	quit(1 if failures else 0)
