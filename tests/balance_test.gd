extends SceneTree
const Save = preload("res://scripts/save_data.gd")
const Data = preload("res://trial/contracts.gd")
const Catalog = preload("res://scripts/design_catalog.gd")
var failures := 0
var game: Node2D
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func fixture(hp: int, role: String = "knight") -> Node2D:
	game.spawn_enemy_ext(6,Vector2(540,760),"Balance fixture",hp,0,0,0,role,0,"","",true)
	var enemy = game.rooms[6].get_child(game.rooms[6].get_child_count()-1)
	enemy.set_physics_process(false)
	return enemy
func clear_shots() -> void:
	for child in game.rooms[6].get_children():
		if child.get_script() == load("res://scripts/projectile.gd"):
			child.queue_free()
func fresh() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.expedition.ui.close()
	game.player.set_physics_process(false)
	game.player.invulnerability = 99999
	await process_frame
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--test-save=") and arg.contains("work"):
			Save.SAVE_PATH = arg.trim_prefix("--test-save=")
	if not Save.SAVE_PATH.contains("work"):
		quit(2)
		return
	Save.delete_save()
	await fresh()
	game.enter_room(6,Vector2(500,760),true)
	for id in ["blade","archer","knight","mage"]:
		var player = game.player
		player.level = 1
		player.apply_class_and_gear(id,"",false)
		player.reset_motion()
		player.swing_counter = 0
		player.facing = Vector2.RIGHT
		var enemy = fixture(int(Data.encounter_stats(0,false).hp))
		var strikes := 0
		while enemy.hp > 0 and strikes < 6:
			player.attack_cooldown = 0
			var before: int = enemy.hp
			player.attack()
			if id in ["archer","mage"]:
				check(enemy.hp == before, id + " has no extra close-range melee hit")
			await create_timer(0.16).timeout
			check(enemy.hp < before, id + " actual attack connects")
			strikes += 1
		check(enemy.hp == 0 and strikes >= 3 and strikes <= 5, id + " opening enemy takes a fair number of hits")
		print(id," opening encounter: ",strikes," attacks")
		enemy.queue_free()
		clear_shots()
		await process_frame
	var player = game.player
	player.hp = 10
	game.potions = 3
	game.rpg.cooldowns.erase("potion_use")
	game.use_potion()
	var healed: int = player.hp
	game.use_potion()
	check(game.potions == 2 and player.hp == healed, "Potion spam is blocked")
	game.rpg.cooldowns.potion_use = 0
	game.use_potion()
	check(game.potions == 1 and player.hp > healed, "Potion becomes available after recovery")
	var enemy = fixture(5)
	player.hp = 10
	var shot = load("res://scripts/projectile.gd").new()
	shot.damage = 100
	shot.owner_actor = player
	shot.lifesteal_ratio = 0.1
	game.rooms[6].add_child(shot)
	shot._apply_to_enemy(enemy)
	check(player.hp == 11, "Lifesteal uses actual damage and cannot farm overkill")
	shot.queue_free()
	enemy.queue_free()
	await process_frame
	for evolution in ["berserker","warlock"]:
		player.apply_class_and_gear("blade" if evolution == "berserker" else "mage",evolution,false)
		player.reset_motion()
		player.special_cooldown = 0
		game.rpg.refill_stamina()
		player.hp = 10
		player.use_special()
		check(player.hp == 10, evolution + " cannot heal by missing every target")
	for evolution in ["guardian","warlord",""]:
		player.apply_class_and_gear("knight",evolution,false)
		player.reset_motion()
		player.special_cooldown = 0
		game.rpg.refill_stamina()
		player.use_special()
		check(player.bulwark_timer < player.special_cooldown, "Defensive buff has a downtime: " + evolution)
	enemy = fixture(300,"boss")
	enemy.apply_stun(2.0)
	enemy.apply_status(0,0,2.0)
	enemy.take_damage(10,Vector2.RIGHT)
	check(enemy.stun_timer < 1 and enemy.slow_timer < 1.2 and enemy.knockback.length() < 100, "Boss resists permanent control and knockback")
	enemy.queue_free()
	await process_frame
	for quest in game.rpg.boss_hunts.quests():
		var boss := Catalog.record("monsters",str(quest.boss_id))
		check(int(boss.hp) >= 300 and int(boss.hp) <= (3000 if quest.get("bonus",false) else 1400), "Boss health budget: " + str(quest.boss_id))
	game.enter_room(0,game.expedition.moss_position(),true)
	game.expedition.completions = 0
	game.expedition.begin(0,42)
	game.expedition.ui.close()
	check(game.expedition.active.threat == 0, "New expedition begins at lowest danger")
	game.expedition.completions = 12
	game._auto_save()
	game.queue_free()
	await process_frame
	await fresh()
	check(game.expedition.active.threat == 0, "Saved expedition keeps its danger after reload")
	game.enter_room(0,game.expedition.moss_position(),true)
	game.expedition.abandon()
	game.expedition.ui.close()
	game.expedition.begin(0,42)
	check(game.expedition.active.threat == 5, "Later expeditions reach the bounded danger cap")
	check(Data.encounter_stats(99,false) == Data.encounter_stats(5,false), "Difficulty never scales without a cap")
	game.expedition.ui.close()
	game.scrap = int(Data.CONTRACTS[0].scrap)
	check(not game.expedition.buy("edge"), "Bare supply delivery cannot instantly buy an upgrade")
	game.queue_free()
	await process_frame
	Save.delete_save()
	print("Balance checks; failures: ",failures)
	quit(1 if failures else 0)
