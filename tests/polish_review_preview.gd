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
	save.SAVE_PATH = output.path_join("polish-preview-work.cfg")
	save.delete_save()
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.expedition.ui.close()
	game.player.set_physics_process(false)
	for page in ["welcome","board","hunts","journal","upgrades"]:
		game.expedition.ui.open(page)
		await create_timer(0.2).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output.path_join("review-"+page+".png"))
		game.expedition.ui.close()
	for page in ["menu","controls","audio"]:
		game.game_menu.open()
		game.game_menu.controls_visible = page == "controls"
		game.game_menu.audio_visible = page == "audio"
		game.game_menu._rebuild()
		await create_timer(0.2).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output.path_join("review-"+page+".png"))
		game.game_menu.close()
	game.rpg.stamina = 10
	game.rpg.stamina_recovery_delay = 0.9
	game.rpg.set_process(false)
	await create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join("review-stamina.png"))
	game.queue_free()
	await process_frame
	save.delete_save()
	print("Opening, journals, menus, and stamina HUD rendered")
	quit()
