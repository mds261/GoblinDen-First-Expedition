extends SceneTree
const Save = preload("res://scripts/save_data.gd")
const Data = preload("res://trial/contracts.gd")
var game: Node2D
var failures := 0
var assertions := 0
func _initialize() -> void:
	call_deferred("run")
func check(value: bool, message: String) -> void:
	assertions += 1
	if not value:
		failures += 1
		push_error(message)
func fresh() -> void:
	if is_instance_valid(game):
		game.expedition.ui.close()
		game.queue_free()
		await process_frame
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.expedition.ui.close()
	game.player.set_physics_process(false)
	game.player.invulnerability = 99999
	await physics_frame
	await process_frame
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
func go(room: int, pos: Vector2) -> void:
	game.enter_room(room,pos,true)
	await physics_frame
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
func at_moss() -> void:
	await go(0,game.expedition.moss_position()+Vector2(0,55))
func route_to(point: Vector2, message: String) -> void:
	var cave = game.get_node("Cave")
	var nearest: Vector2i = cave._nearest_open_cell(point)
	var destination: Vector2 = cave.navigation.get_point_position(nearest)
	check(destination.distance_to(point)<40,message+" destination on open floor")
	var route: PackedVector2Array = cave.navigation.get_point_path(cave._nearest_open_cell(game.player.position),nearest)
	check(not route.is_empty(),message+" connected route")
	# Check real physical movement along the route, separately from movable enemies.
	game.player.collision_mask = 1
	for step in route:
		game.player.move_and_collide(step-game.player.position)
		check(game.player.position.distance_to(step)<2,message+" physical floor clearance")
	game.player.collision_mask = 3
func run() -> void:
	var save_path := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--test-save="):
			save_path = arg.trim_prefix("--test-save=")
	if save_path.is_empty() or not save_path.contains("work"):
		push_error("Tests require --test-save=<workspace/work/isolated.cfg>")
		quit(2)
		return
	Save.SAVE_PATH = save_path
	Save.delete_save()
	await fresh()
	check(game.current_room==0,"Fresh trial starts at home")
	check(game.expedition.active.is_empty(),"No contract auto accepted")
	check(Data.generate(0,42,1)==Data.generate(0,42,1),"Seed is deterministic")
	check(Data.generate(0,42,1)!=Data.generate(0,43,1),"Seeds vary situations")
	await at_moss()
	game.expedition.begin(0,42)
	game.expedition.ui.close()
	route_to(game.Starting.EXIT,"Connected cave route")
	for kind in range(3):
		for seed_value in [11,42,99]:
			await at_moss()
			game.expedition.abandon()
			game.expedition.ui.close()
			check(game.expedition.begin(kind,seed_value),"Start mission %d seed %d"%[kind,seed_value])
			game.expedition.ui.close()
			check(not game.expedition.begin(kind,seed_value),"Cannot replace active contract")
			await go(5,Vector2(215,365))
			route_to(Vector2(460,460),"Hollow gathering")
			check(game.expedition.interact_object("herbs"),"Gather real inventory items")
			check(not game.expedition.interact_object("herbs"),"Gather only once")
			await go(6,game.EXPANSE_SPAWN)
			for site in game.expedition.active.sites:
				route_to(site,"Mission site")
			for entry in game.expedition.objects():
				if entry.room==6:
					route_to(entry.point,"Optional/objective "+entry.id)
			# All enemy spawns must sit on navigable floor too.
			for enemy in get_nodes_in_group("enemies"):
				if enemy.get_parent()==game.rooms[6] and enemy.hp>0:
					var c = game.get_node("Cave")
					check(c.navigation.get_point_position(c._nearest_open_cell(enemy.position)).distance_to(enemy.position)<40,"Enemy spawn floor: "+str(enemy.get_meta("expedition_id","")))
			if kind==1:
				for enemy in get_nodes_in_group("enemies"):
					if str(enemy.get_meta("expedition_id","")).begins_with("target_"):
						enemy.take_damage(9999)
			else:
				for entry in game.expedition.objects():
					if entry.kind=="cache":
						game.player.position = entry.point
						check(not game.expedition.interact_object(entry.id),"Cannot sneak past objective defenders")
						for guard_id in game.expedition.defenders_for(str(entry.id)):
							for enemy in get_nodes_in_group("enemies"):
								if str(enemy.get_meta("expedition_id","")) == str(guard_id):
									enemy.take_damage(9999)
									if not game.expedition.defenders_for(str(entry.id)).is_empty():
										check(not game.expedition.interact_object(entry.id),"Every camp defender must be defeated")
						check(game.expedition.interact_object(entry.id),"Resolve objective")
			check(game.expedition.active.ready,"Contract complete")
			check(not game.expedition.claim(),"Cannot claim reward remotely")
			# Real optional encounter and exactly-once reward.
			game.player.position = Data.BONUS
			check(not game.expedition.interact_object("bonus"),"Bonus requires surviving guard")
			for enemy in get_nodes_in_group("enemies"):
				if enemy.get_meta("expedition_id","")=="bonus_watch":
					enemy.take_damage(9999)
			check(game.expedition.interact_object("bonus"),"Bonus cache unlocked")
			check(not game.expedition.interact_object("bonus"),"No bonus farming")
			var before: Dictionary = game.expedition.snapshot()
			check(Save.save(game),"Atomic save succeeds")
			await fresh()
			check(game.expedition.active.ready and game.expedition.active.bonus,"In-flight progress survives reload")
			check(game.current_room==6,"Position and room restored")
			check(game.expedition.active.defeated==before.active.defeated,"Killed targets stay killed")
			game.player.position = Vector2(700,350)
			check(game.expedition.shortcut(),"Earned home shortcut")
			await at_moss()
			var scrap_before: int = game.scrap
			check(game.expedition.claim(),"Claim at Moss")
			game.expedition.ui.close()
			check(game.scrap==scrap_before+Data.CONTRACTS[kind].scrap+18,"Exact advertised reward")
			check(not game.expedition.claim(),"No duplicate claim")
			await fresh()
			await at_moss()
			check(not game.expedition.claim(),"No duplicate after reload")
	# Observable upgrade effects across all four classes.
	game.scrap = 500
	await at_moss()
	for class_id in ["blade","archer","knight","mage"]:
		game.select_goblin_class(class_id)
		check(game.player.class_id==class_id,"Class switching "+class_id)
	var damage_before: int = game.player.get_effective_damage()
	check(game.expedition.buy("edge"),"Purchase offense")
	game.expedition.ui.close()
	check(game.player.get_effective_damage()==damage_before+3,"Offense adds exactly 3")
	var hp_before: int = game.player.max_hp
	check(game.expedition.buy("ward"),"Purchase health")
	game.expedition.ui.close()
	check(game.player.max_hp==hp_before+10,"Health adds exactly 10")
	var capacity_before: int = game.max_potions
	check(game.expedition.buy("pouch"),"Purchase utility")
	game.expedition.ui.close()
	check(game.max_potions==capacity_before+1,"Potion capacity increases")
	game.expedition.begin(0,170)
	game.expedition.ui.close()
	await go(5,Vector2(460,460))
	var pack: Array = game.rpg.backpack.slots.duplicate(true)
	game.rpg.backpack.slots.clear()
	for i in range(game.rpg.backpack.capacity):
		game.rpg.backpack.add("rust_sword")
	check(not game.expedition.interact_object("herbs"),"Full inventory rejects gathering")
	check(not "herbs" in game.expedition.active.taken,"Full inventory does not consume resource")
	game.rpg.backpack.restore(pack)
	check(game.expedition.interact_object("herbs"),"Can retry gathering after clearing space")
	var active_seed: int = game.expedition.active.seed
	game.player.invulnerability = 0
	game.player.take_damage(99999)
	await process_frame
	await physics_frame
	check(game.current_room==0 and game.player.hp>0,"Death respawns safely")
	check(game.expedition.active.seed==active_seed,"Death preserves active mission")
	check(not game.rpg.corpses.is_empty(),"Death uses existing corpse recovery")
	if not game.rpg.corpses.is_empty():
		var corpse: Dictionary = game.rpg.corpses[-1]
		await go(int(corpse.room),corpse.position)
		game.rpg._recover_corpse(corpse)
		check(not game.rpg.backpack.slots.is_empty(),"Corpse equipment can be recovered")
	game.expedition.ui.close()
	game.queue_free()
	await process_frame
	print("FIRST EXPEDITION: %d assertions, %d failures; 3 archetypes x 3 seeds, save/reload, reward idempotence, terrain, upgrades, inventory, classes, death/recovery."%[assertions,failures])
	quit(1 if failures else 0)
