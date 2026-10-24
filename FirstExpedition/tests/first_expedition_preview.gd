extends SceneTree
var game: Node2D
var folder := ""
func _initialize() -> void:
	call_deferred("run")
func capture(name: String) -> void:
	game.player.get_node("Camera2D").reset_smoothing()
	game.player.get_node("Camera2D").force_update_scroll()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder+"/"+name+".png")
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshots="):
			folder = arg.trim_prefix("--screenshots=")
	if folder.is_empty():
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(folder)
	var save = load("res://scripts/save_data.gd")
	save.SAVE_PATH = folder+"/preview-test.cfg"
	save.delete_save()
	root.size = Vector2i(1152,720)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.player.set_physics_process(false)
	game.player.invulnerability = 99999
	await capture("01-welcome")
	game.expedition.ui.close()
	game.player.position = game.expedition.moss_position()+Vector2(0,55)
	game.expedition.ui.open("board")
	await capture("02-contracts")
	game.expedition.begin(0,42)
	game.expedition.ui.close()
	game.enter_room(6,Vector2(1060,950),true)
	game.expedition.ui.banner_time = 0
	game.notice_time = 0
	await capture("03-thornwood")
	for entry in game.expedition.objects():
		if entry.kind=="cache":
			game.player.position = entry.point
			game.expedition.interact_object(entry.id)
	game.enter_room(0,game.expedition.moss_position()+Vector2(0,55),true)
	game.expedition.claim()
	await capture("04-homecoming")
	game.expedition.ui.open("upgrades")
	await capture("05-upgrades")
	game.expedition.ui.close()
	game.queue_free()
	await process_frame
	quit()
