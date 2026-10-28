extends SceneTree
const Save = preload("res://scripts/save_data.gd")
const Data = preload("res://trial/chronicle_data.gd")
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
func freeze() -> void:
	game.player.set_physics_process(false)
	game.player.invulnerability = 99999
	for enemy in get_nodes_in_group("enemies"): enemy.set_physics_process(false)
func go(room: int, point: Vector2) -> void:
	game.enter_room(room,point,true)
	freeze()
	await process_frame
func home() -> void:
	await go(0,game.expedition.moss_position()+Vector2(0,55))
func fresh() -> void:
	if is_instance_valid(game):
		game.expedition.ui.close()
		game.queue_free()
		await process_frame
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.expedition.ui.close()
	freeze()
	await process_frame
func secure() -> void:
	game.expedition.ui.close()
	for enemy in get_nodes_in_group("enemies"):
		if enemy.has_meta("expedition_id") and enemy.hp>0: enemy.take_damage(99999)
	await process_frame
	await go(6,Vector2(780,790))
	var active: Dictionary = game.expedition.active
	if int(active.kind)==0:
		for i in range(3):
			await go(6,active.sites[i])
			check(game.expedition.interact_object("cache_%d"%i),"Recover chapter supplies")
	elif int(active.kind)==2:
		await go(6,active.sites[0])
		check(game.expedition.interact_object("ledger"),"Recover chapter ledger")
	await go(6,Vector2(780,790))
	check(active.ready,"Chapter combat objective secured")
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--test-save="): Save.SAVE_PATH = arg.trim_prefix("--test-save=")
	if not Save.SAVE_PATH.contains("work"):
		push_error("Pass --test-save=<workspace/work/isolated.cfg>")
		quit(2)
		return
	Save.delete_save()
	await fresh()
	check(game.expedition.living.chapter==0,"Old save defaults support new state")
	check(Data.biome("same")==Data.biome("same"),"Named biome seed deterministic")
	await home()
	game.expedition.ui.open("chronicle")
	game.expedition.ui.close()
	check(game.expedition.living.start("A test world"),"Chronicle starts at Moss")
	var choices := ["rescue","warn","protect","translate","return","treaty"]
	for chapter in range(6):
		await home()
		check(game.expedition.living.begin_chapter(),"Start chapter %d"%chapter)
		game.expedition.ui.close()
		check(game.expedition.active.chronicle_chapter==chapter,"Correct authored chapter")
		await go(6,Vector2(780,790))
		check(not game.expedition.living.choose(choices[chapter]),"Cannot resolve before objective")
		await secure()
		check(game.expedition.target_point()==Vector2(780,790),"Compass guides player to decision")
		game.expedition.ui.open("choice")
		game.expedition.ui.close()
		check(game.expedition.living.choose(choices[chapter]),"Choice succeeds %s"%choices[chapter])
		game.expedition.ui.close()
		var balance: int = game.expedition.living.marks
		check(not game.expedition.living.choose(choices[chapter]),"Choice cannot pay twice")
		check(balance==game.expedition.living.marks,"Marks unchanged by duplicate")
		if chapter==2:
			var before: Dictionary = game.expedition.snapshot()
			check(Save.save(game),"Save story before homecoming")
			await fresh()
			check(game.expedition.living.snapshot()==before.living_world,"Reload preserves choice, history and resources")
			check(game.expedition.active.biome==before.active.biome and game.expedition.active.story_choice==before.active.story_choice,"Reload preserves active biome and committed choice")
		await home()
		check(game.expedition.claim(),"Claim chapter homecoming")
		game.expedition.ui.close()
		check(not game.expedition.claim(),"No duplicate chapter reward")
		check(game.expedition.living.chapter==chapter+1,"Advance once")
	check(game.expedition.living.ending=="Treaty of the Three Fires","Treaty branch reaches ending")
	check(not game.expedition.living.running,"Six chapter arc ends")
	check(game.expedition.living.market_open(),"Friendly clans open market")
	check(game.expedition.living.buy_ward(),"Spend marks on ward")
	check(not game.expedition.living.buy_ward(),"Ward only charged once")
	game.rpg.backpack.add("herb",8)
	check(game.expedition.living.craft("smoke"),"Craft smoke with real inventory")
	check(game.expedition.living.craft("talisman"),"Craft talisman with real inventory")
	check(not game.expedition.living.craft("missing"),"Reject invalid recipe")
	for page in ["chronicle","workshop","world_settings"]:
		game.expedition.ui.open(page)
		check(game.expedition.ui.overlay.visible,"Render "+page)
		game.expedition.ui.close()
	check(game.expedition.begin(0,42),"Postgame contracts still playable")
	game.expedition.ui.close()
	await go(6,Vector2(780,790))
	check(not game.expedition.living.craft("smoke"),"Craft only at hearth")
	check(game.expedition.living.use_tool("smoke"),"Use crafted smoke")
	check(game.expedition.living.smoke_time==10,"Smoke duration is ten seconds")
	var watcher: Node2D
	for enemy in get_nodes_in_group("enemies"):
		if enemy.get_parent()==game.rooms[6] and enemy.has_meta("expedition_id"):
			watcher = enemy
			break
	check(is_instance_valid(watcher),"Live expedition patrol for tool test")
	if is_instance_valid(watcher):
		check(not watcher.dungeon_awareness.sees(watcher,game.player.position),"Smoke hides player from patrol")
		game.player.attack()
		check(game.expedition.living.smoke_time==0,"Attack breaks smoke")
		watcher.position = game.player.position+Vector2(20,0)
		check(game.expedition.living.use_tool("talisman"),"Use talisman")
		check(watcher.stun_timer==5,"Talisman stuns nearby patrol")
	game.scrap = 100
	game.player.level = 8
	game.expedition.living.legacy_mode = true
	var rep: Dictionary = game.expedition.living.reputation.duplicate()
	game._resolve_journey_death()
	check(game.scrap==80,"Legacy inherits 80% of scrap")
	check(game.player.level==1,"Legacy resets personal level")
	check(game.expedition.living.reputation==rep,"Legacy preserves clan memory")
	check(game.expedition.living.pending_heir,"Must choose heir")
	check(game.expedition.active.is_empty(),"Death cancels expedition")
	var fallen: String = game.expedition.living.fallen_class
	check(not game.expedition.living.select_heir(fallen),"Cannot inherit as same class")
	check(Save.save(game),"Save pending heir")
	await fresh()
	check(game.expedition.living.pending_heir,"Heir choice persists across reload")
	check(game.expedition.living.select_heir("mage" if fallen!="mage" else "blade"),"Different class inherits")
	check(not game.expedition.living.pending_heir,"Heir selection commits")
	await home()
	game.expedition.living.restore({"running":true,"chapter":2})
	check(game.expedition.living.begin_chapter(),"Begin hostile branch")
	game.expedition.ui.close()
	await secure()
	check(game.expedition.living.choose("burn"),"Burning nest commits hostile branch")
	game.expedition.ui.close()
	await home()
	check(game.expedition.abandon(),"Can return early after resolved choice")
	game.expedition.ui.close()
	check(game.expedition.living.chapter==3,"Early return cannot replay paid choice")
	check(game.expedition.living.begin_chapter(),"Next expedition remembers fire")
	game.expedition.ui.close()
	for hazard in get_nodes_in_group("expedition_hazards"):
		check(hazard.kind=="fire","Burned nest creates retaliatory fire hazards")
	game.expedition.living.reputation[str(game.expedition.active.biome.faction)] = -30
	check(game.expedition.patrol_notice_scale()>1,"Hostile clan increases detection")
	await home()
	game.expedition.abandon()
	game.expedition.ui.close()
	for ending_choice in ["rule","leave"]:
		game.expedition.living.restore({"running":true,"chapter":5})
		check(game.expedition.living.begin_chapter(),"Begin alternate finale")
		game.expedition.ui.close()
		await secure()
		check(not game.expedition.living.can_choose(Data.CHAPTERS[5].choices[0]),"Treaty requires earned alliances")
		check(game.expedition.living.choose(ending_choice),"Alternate ending "+ending_choice)
		game.expedition.ui.close()
		await home()
		check(game.expedition.claim(),"Alternate finale completes")
		game.expedition.ui.close()
	var hunts = game.rpg.boss_hunts
	hunts.accept()
	freeze()
	check(is_instance_valid(hunts.actor),"Commander hunt available")
	if is_instance_valid(hunts.actor):
		var actor = hunts.actor
		check(game.expedition.living.surrender_candidates().is_empty(),"Healthy commander refuses quarter")
		actor.hp = maxi(1,int(actor.max_hp*0.2))
		check(not game.expedition.living.spare_commander(),"Cannot spare at a distance")
		await go(0,actor.position+Vector2(0,45))
		check(game.expedition.living.spare_commander(),"Wounded commander accepts quarter")
		check(hunts.is_complete(hunts.current()),"Surrender satisfies boss hunt")
		check(not game.expedition.living.spare_commander(),"Surrender reward cannot repeat")
		await home()
		hunts.claim()
		game.expedition.ui.close()
		check(hunts.completed_count()==1,"Moss rewards surrendered commander")
	print("CHRONICLE: %d assertions, %d failures" % [assertions,failures])
	game.expedition.ui.close()
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)
