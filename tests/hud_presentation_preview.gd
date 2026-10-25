extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var output := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):
			output = arg.trim_prefix("--output=")
	if output.is_empty():
		quit(2)
		return
	var save = load("res://scripts/save_data.gd")
	save.SAVE_PATH = output.path_join("hud-preview-work.cfg")
	save.delete_save()
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.expedition.ui.close()
	game.player.set_physics_process(false)
	game.rpg.boss_hunts.claimed = game.rpg.boss_hunts.quests().filter(func(q): return not q.get("bonus",false)).map(func(q): return str(q.id))
	game.enter_room(0,game.expedition.moss_position(),true)
	game.rpg.boss_hunts.accept()
	game.enter_room(16,Vector2(3100,1070),true)
	for actor in get_nodes_in_group("enemies"):
		actor.set_physics_process(false)
	game.rpg.orchard.boss.set_physics_process(false)
	game.rpg.orchard.boss.boss_state = "exposed"
	game.hint.text = ""
	game.notice_time = 0
	game.expedition.ui.banner_time = 0
	for compact in [true,false]:
		game.expedition.journal_hidden = compact
		await create_timer(0.2).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output.path_join("compact-hud.png" if compact else "expanded-hud.png"))
	game.game_menu.open()
	game.game_menu.restart_visible = true
	game.game_menu._rebuild()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join("start-over.png"))
	game.game_menu.close()
	game.queue_free()
	await process_frame
	save.delete_save()
	print("HUD and start-over screens rendered")
	quit()
