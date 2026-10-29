extends SceneTree
var game: Node2D
var output := ""
func _initialize() -> void:
	call_deferred("run")
func capture(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output+"/"+name+".png")
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
	if output.is_empty(): quit(2); return
	preload("res://scripts/save_data.gd").SAVE_PATH = "C:/Users/mds88/Documents/Codex/2026-10-27/usi/work/preview-save.cfg"
	preload("res://scripts/save_data.gd").delete_save()
	root.size = Vector2i(1152,720)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.expedition.ui.close()
	game.player.set_physics_process(false)
	game.player.invulnerability = 99999
	game.enter_room(0,game.expedition.moss_position()+Vector2(0,55),true)
	game.expedition.ui.open("chronicle")
	await capture("three-fires-journal")
	game.expedition.ui.close()
	game.expedition.living.start("The Three Fires")
	game.expedition.living.begin_chapter()
	game.expedition.ui.close()
	game.enter_room(6,Vector2(780,790),true)
	game.expedition.active.ready = true
	for actor in get_nodes_in_group("enemies"): actor.set_physics_process(false)
	game.expedition.ui.open("choice")
	await capture("three-fires-choice")
	game.expedition.ui.open("workshop")
	await capture("three-fires-workshop")
	game.expedition.ui.close()
	game.expedition.ui.banner_time = 0
	game.notice_time = 0
	game.player.position = game.expedition.active.sites[0]+Vector2(0,110)
	game.player.get_node("Camera2D").reset_smoothing()
	game.player.get_node("Camera2D").force_update_scroll()
	await capture("three-fires-biome")
	game.queue_free()
	await process_frame
	quit()
