extends SceneTree
const Save = preload("res://scripts/save_data.gd")
const Layout = preload("res://scripts/cinder_orchard_layout.gd")
var failures := 0
var game: Node2D
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func fresh() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.expedition.ui.close()
	game.player.set_physics_process(false)
	game.player.invulnerability = 999999
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
	var hunts = game.rpg.boss_hunts
	check(hunts.quests().size() == 10 and hunts.quests().back().id == "bonus_cinder", "Cinder follows all nine main hunts")
	game.enter_room(16,Layout.SPAWN,true)
	check(game.current_room == 5 and not game.rpg.orchard.accessible(), "Early room entry and old room resumes cannot bypass the bonus gate")
	game.player.position = Layout.HOLLOW_ENTRANCE
	game.rpg.orchard.enter_orchard()
	check(game.current_room == 5, "Heat crack remains sealed before the main hunts")
	hunts.restore({"accepted":true,"claimed":["hunt_iron_captain","hunt_spider","hunt_wolf_rider"],"defeated":[]})
	check(not hunts.accepted and hunts.current().id == "hunt_vanguard", "Old accepted Cinder hunt does not silently accept a different boss")
	hunts.restore({"accepted":true,"claimed":["hunt_iron_captain","hunt_spider","hunt_wolf_rider","hunt_kilnheart","hunt_vanguard"],"defeated":[]})
	check(hunts.accepted and hunts.current().id == "hunt_huntmaster", "Old active ordinary hunt remains accepted")
	game.rpg.orchard.restore({"boss":true,"cache":true,"defeated":["mite_a"]})
	hunts.restore({"accepted":false,"claimed":hunts.LEGACY_ORDER.duplicate(),"defeated":[]})
	check(hunts.main_complete() and hunts.completed_count() == 9 and hunts.current().id == "bonus_cinder", "Old completed chain gains an unclaimed final bonus without losing credit")
	check(not hunts.is_complete(hunts.current()), "Old easy Kilnheart victory cannot complete the new bonus")
	game.enter_room(0,game.expedition.moss_position(),true)
	hunts.accept()
	check(game.rpg.orchard.accessible() and game.rpg.orchard.bonus_started, "Accepting the bonus opens the orchard")
	check(game.rpg.orchard.cache_taken and game.rpg.orchard.defeated.is_empty(), "Bonus rematch refreshes creatures without duplicating the old salvage reward")
	var bodies: int = game.rooms[16].get_children().filter(func(n): return n is CharacterBody2D).size()
	check(bodies == Layout.MITES.size()+Layout.WISPS.size()+1, "Bonus rematch creates exactly one set of creatures")
	game.enter_room(16,Layout.BOSS + Vector2(-80,0),true)
	var boss = game.rpg.orchard.boss
	boss.set_physics_process(false)
	boss.awaken()
	boss.boss_state = "exposed"
	boss.take_damage(1300)
	check(boss.max_hp == 3000 and boss.phase_two, "Superboss has endgame health and an earlier second phase")
	game.player.position = Layout.SPAWN
	boss._physics_process(2.6)
	check(boss.boss_state == "dormant" and boss.hp == boss.max_hp and not boss.phase_two, "Leaving the kiln resets the boss instead of allowing chip-and-retreat kills")
	game.player.position = Layout.BOSS + Vector2(-80,0)
	boss.awaken()
	boss.boss_state = "exposed"
	boss.take_damage(300)
	game.enter_room(5,Layout.HOLLOW_RETURN,true)
	check(boss.hp == boss.max_hp and boss.boss_state == "dormant", "Leaving the orchard immediately resets a living boss")
	game._auto_save()
	game.queue_free()
	await process_frame
	await fresh()
	hunts = game.rpg.boss_hunts
	check(hunts.accepted and hunts.current().id == "bonus_cinder" and game.rpg.orchard.accessible(), "Accepted bonus and unlocked entrance survive reload")
	game.enter_room(16,Layout.BOSS + Vector2(-80,0),true)
	boss = game.rpg.orchard.boss
	boss.set_physics_process(false)
	boss.awaken()
	boss.boss_state = "exposed"
	boss.take_damage(999999)
	check(game.rpg.orchard.bonus_completed and hunts.is_complete(hunts.current()), "Hard rematch records new bonus completion")
	game.enter_room(0,game.expedition.moss_position(),true)
	var before: int = game.scrap
	hunts.claim()
	game.expedition.ui.close()
	check(hunts.completed_count() == 10 and game.scrap == before + 220, "Final bonus pays its own reward exactly once despite legacy credit")
	hunts.claim()
	check(game.scrap == before + 220, "Bonus reward cannot be claimed twice")
	check(game.rpg.orchard.accessible(), "Finished bonus stays open for exploration")
	game.queue_free()
	await process_frame
	Save.delete_save()
	print("Cinder final bonus and save migration checks; failures: ",failures)
	quit(1 if failures else 0)
