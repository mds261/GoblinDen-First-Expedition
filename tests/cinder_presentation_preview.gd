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
	save.SAVE_PATH = output.path_join("preview-work.cfg")
	save.delete_save()
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.expedition.ui.close()
	game.player.set_physics_process(false)
	game.rpg.boss_hunts.claimed = game.rpg.boss_hunts.quests().filter(func(q): return not q.get("bonus",false)).map(func(q): return str(q.id))
	game.enter_room(0,game.expedition.moss_position(),true)
	game.rpg.boss_hunts.accept()
	game.player.invulnerability = 99999
	game.expedition.ui.banner_time = 0
	for actor in get_nodes_in_group("enemies"):
		actor.set_physics_process(false)
	for spec in [["cinder-court",Vector2(1550,1200)],["cinder-kiln",Vector2(3100,1070)],["cinder-cache",Vector2(1670,2080)],["cinder-nave",Vector2(2420,1090)]]:
		game.enter_room(16,spec[1],true)
		var boss = game.rpg.orchard.boss
		boss.set_physics_process(false)
		boss.boss_state = "exposed"
		game.rpg.orchard.floor_node.time = 2.9
		game.expedition.ui.banner_time = 0
		await create_timer(0.3).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output.path_join(spec[0]+".png"))
	game.enter_room(0,game.expedition.moss_position(),true)
	game.expedition.ui.open("hunts")
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join("boss-hunts.png"))
	game.expedition.ui.close()
	game.queue_free()
	await process_frame
	save.delete_save()
	print("Painted Cinder scenes and boss board rendered")
	quit()
