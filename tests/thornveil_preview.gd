extends SceneTree
var output := ""
var game: Node2D

func _initialize() -> void:
	call_deferred("run")

func capture(label: String) -> void:
	game.notice_time = 0
	game.expedition.ui.banner_time = 0
	await create_timer(0.25).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label + ".png"))

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):
			output = arg.trim_prefix("--output=")
	if output.is_empty():
		quit(2)
		return
	var save = load("res://scripts/save_data.gd")
	save.SAVE_PATH = output.path_join("thornveil-preview-work.cfg")
	save.delete_save()
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.expedition.ui.close()
	game.player.set_physics_process(false)
	game.player.invulnerability = 999999
	game.enter_room(17, Vector2(1020, 672), true)
	for actor in get_nodes_in_group("enemies"):
		actor.set_physics_process(false)
	await capture("thornveil-approach")
	game.enter_room(18, Vector2(850, 610), true)
	await capture("thornveil-shrine")
	game.enter_room(19, Vector2(950, 720), true)
	var boss = game.rpg.thornveil.boss
	boss.awaken()
	boss.set_physics_process(false)
	boss.boss_state = "prowl"
	boss.velocity = Vector2.RIGHT * 80.0
	boss.queue_redraw()
	await capture("thornveil-crown-glade")
	boss._begin_root_snare()
	boss.set_physics_process(false)
	boss.queue_redraw()
	await capture("bramble-crown-root-snare")
	boss._clear_hazards()
	await process_frame
	boss._begin_volley()
	boss.state_time = boss.state_total * 0.7
	boss.queue_redraw()
	await capture("bramble-crown-thorn-volley")
	game.queue_free()
	await process_frame
	save.delete_save()
	print("Thornveil presentation rendered")
	quit()
