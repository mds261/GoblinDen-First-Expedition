extends SceneTree
var output := ""
var game: Node2D
func _initialize() -> void:
	call_deferred("run")
func capture(label: String) -> void:
	game.notice_time = 0
	game.expedition.ui.banner_time = 0
	await create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label+".png"))
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):
			output = arg.trim_prefix("--output=")
	if output.is_empty():
		quit(2)
		return
	var save = load("res://scripts/save_data.gd")
	save.SAVE_PATH = output.path_join("uniform-preview-work.cfg")
	save.delete_save()
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.expedition.ui.close()
	game.player.set_physics_process(false)
	game.player.invulnerability = 999999
	await capture("uniform-hud-journal-hidden")
	game.expedition.ui.toggle_journal_shortcut()
	await capture("uniform-hud-journal-shown")
	game.enter_room(0,game.expedition.moss_position(),true)
	game.expedition.begin(0,42)
	game.expedition.ui.close()
	game.enter_room(6,game.expedition.active.sites[0],true)
	for actor in get_nodes_in_group("enemies"):
		actor.set_physics_process(false)
	await capture("uniform-hud-guarded-supplies")
	game.enter_room(0,game.expedition.moss_position(),true)
	var hunts = game.rpg.boss_hunts
	hunts.claimed = hunts.quests().filter(func(q): return not q.get("bonus",false)).map(func(q): return str(q.id))
	hunts.accept()
	game.enter_room(16,Vector2(3100,1070),true)
	for actor in get_nodes_in_group("enemies"):
		actor.set_physics_process(false)
	game.rpg.orchard.boss.set_physics_process(false)
	game.rpg.orchard.boss.boss_state = "exposed"
	await capture("uniform-hud-cinder")
	game.expedition.ui.open("journal")
	await capture("uniform-field-journal")
	game.expedition.ui.close()
	game.game_menu.open()
	await capture("uniform-pause-menu")
	game.game_menu.close()
	game.expedition.ui.open("welcome")
	await capture("uniform-opening")
	game.expedition.ui.close()
	game.queue_free()
	await process_frame
	save.delete_save()
	print("Uniform HUD, guarded objectives, and menus rendered")
	quit()
