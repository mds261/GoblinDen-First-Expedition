extends SceneTree
const Save = preload("res://scripts/save_data.gd")
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func count_numbers(node: Node) -> int:
	var count := 0
	if node.get_script() == load("res://scripts/floating_text.gd") and str(node.text_value).is_valid_int():
		count += 1
	for child in node.get_children():
		count += count_numbers(child)
	return count
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
	game.rpg.set_process(false)
	var player = game.player
	var rpg = game.rpg
	check(rpg.hotbar.get_children().filter(func(b): return b.visible).size() == 1, "Empty hotbar slots are hidden before any refresh")
	for id in ["blade","archer","knight","mage"]:
		player.apply_class_and_gear(id)
		player.reset_motion()
		player.dodge_cooldown = 0
		player.special_cooldown = 0
		rpg.refill_stamina()
		player.start_dodge()
		check(rpg.stamina == 70 and player.dodge_time > 0, id + " dodge spends 30")
		player.start_dodge()
		check(rpg.stamina == 70, "Rejected dodge does not spend stamina")
		player.reset_motion()
		player.use_special()
		check(rpg.stamina == 50 and player.special_cooldown > 0, id + " special spends 20")
		player.reset_motion()
		player.dodge_cooldown = 0
		player.special_cooldown = 0
		rpg.stamina = 0
		player.start_dodge()
		player.use_special()
		check(player.dodge_time == 0 and player.special_cooldown == 0, "Exhaustion blocks dodge and special without consuming cooldown")
		player.attack_cooldown = 0
		player.attack()
		check(player.attack_cooldown > 0 and rpg.stamina == 0, "Basic attacks remain free at zero stamina")
		rpg.stamina = 50
		rpg.stamina_recovery_delay = 0.9
		rpg.recover_stamina(0.5)
		check(rpg.stamina == 50, "Recovery delay holds stamina")
		rpg.recover_stamina(0.9)
		check(is_equal_approx(rpg.stamina,60), "Only time after the delay regenerates stamina")
		rpg.recover_stamina(20)
		check(rpg.stamina == 100, "Recovery caps at 100")
	player.hp = 0
	player.dodge_cooldown = 0
	player.dodge_time = 0
	player.start_dodge()
	check(rpg.stamina == 100, "Dead players cannot spend stamina")
	player.hp = player.max_hp
	rpg.stamina = 23
	rpg.stamina_recovery_delay = 0.7
	Save.save(game)
	var cfg := ConfigFile.new()
	cfg.load(Save.SAVE_PATH)
	var state: Dictionary = cfg.get_value("rpg","state")
	check(state.stamina == 23 and is_equal_approx(state.stamina_recovery_delay,0.7), "Resource state persists")
	rpg.restore(state)
	check(rpg.stamina == 23, "Stamina restores")
	game.enter_room(6,Vector2(500,760),true)
	player.apply_class_and_gear("blade")
	player.reset_motion()
	player.attack_cooldown = 0
	player.facing = Vector2.RIGHT
	game.spawn_enemy_ext(6,Vector2(540,760),"Feedback fixture",500,0,0,0,"knight",0,"","",true)
	var enemy = game.rooms[6].get_child(game.rooms[6].get_child_count()-1)
	enemy.set_physics_process(false)
	var before := count_numbers(game)
	player.attack()
	check(count_numbers(game) == before + 1 and enemy.hp < 500, "Melee hit displays actual damage once")
	var shot = load("res://scripts/projectile.gd").new()
	shot.owner_actor = player
	shot.damage = 13
	game.rooms[6].add_child(shot)
	before = count_numbers(game)
	shot._apply_to_enemy(enemy)
	check(count_numbers(game) == before + 1, "Projectile hit displays damage once")
	shot.queue_free()
	game.enter_room(0,game.expedition.moss_position(),true)
	for page in ["welcome","board","hunts","journal","upgrades"]:
		game.expedition.ui.open(page)
		await process_frame
		await process_frame
		var bounds: Rect2 = game.expedition.ui.panel.get_global_rect()
		check(bounds.position.y >= 0 and bounds.end.y <= 720, "Panel remains on screen: " + page)
		game.expedition.ui.close()
	game.queue_free()
	await process_frame
	Save.delete_save()
	print("Stamina and presentation checks; failures: ",failures)
	quit(1 if failures else 0)
