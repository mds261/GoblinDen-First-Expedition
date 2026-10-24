extends SceneTree
var failures := 0
var game: Node2D
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	# Runner supplies an isolated APPDATA; no normal save is touched.
	if not "--trial-test" in OS.get_cmdline_user_args():
		quit(2)
		return
	var save = load("res://scripts/save_data.gd")
	save.delete_save()
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.expedition.ui.close()
	game.player.set_physics_process(false)
	for class_id in ["blade","archer","knight","mage"]:
		game.enter_room(0,game.Starting.START,true)
		game.select_goblin_class(class_id)
		game.enter_room(6,Vector2(500,760),true)
		var distance := 160.0 if class_id in ["archer","mage"] else 55.0
		game.spawn_enemy_ext(6,Vector2(500+distance,760),"COMBAT FIXTURE",70,0,0,0,"knight",0,"","",true)
		var enemy = game.rooms[6].get_child(game.rooms[6].get_child_count()-1)
		enemy.set_physics_process(false)
		game.player.facing = Vector2.RIGHT
		await physics_frame
		for strike in range(8):
			game.player.attack_cooldown = 0
			game.player.attack()
			await create_timer(0.5).timeout
			if enemy.hp<=0:
				break
		if enemy.hp>0:
			failures += 1
			push_error(class_id+" cannot defeat the fixture using actual attacks/projectiles")
		else:
			print(class_id+": actual attack/projectile defeat passed")
		enemy.queue_free()
		await process_frame
	game.queue_free()
	await process_frame
	print("Trial class combat failures: %d"%failures)
	quit(failures)
