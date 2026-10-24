extends Node2D
const Data = preload("res://trial/contracts.gd")
const Starting = preload("res://scripts/starting_caves.gd")
const Awareness = preload("res://scripts/dungeon_awareness.gd")
var game: Node2D
var active: Dictionary = {}
var serial := 0
var completions := 0
var upgrades := {"edge":0,"ward":0,"pouch":0}
var last_summary: Dictionary = {}
var welcomed := false
var rite_id := "blade"
var combo := 0
var best_combo := 0
var hearth_bloom := 0.0
var ui: CanvasLayer
var scenery: Node2D
var save_clock := 0.0
var initialized := false

func _ready() -> void:
	ui = preload("res://trial/expedition_ui.gd").new()
	ui.director = self
	add_child(ui)
	scenery = preload("res://trial/trail_atmosphere.gd").new()
	scenery.director = self
	add_child(scenery)
	initialized = true
	if not active.is_empty() and not active.claimed:
		populate()
	if not welcomed:
		game.potions = game.max_potions
		if not "--trial-test" in OS.get_cmdline_user_args():
			ui.open("welcome")
	else:
		ui.announce("HEARTH HALL", "A fire worth coming home to")

func snapshot() -> Dictionary:
	return {"version":2,"active":active.duplicate(true),"serial":serial,"completions":completions,"upgrades":upgrades.duplicate(),"last_summary":last_summary.duplicate(true),"welcomed":welcomed,"rite_id":rite_id,"best_combo":best_combo}

func restore(state: Dictionary) -> void:
	active = state.get("active",{}).duplicate(true)
	serial = int(state.get("serial",0))
	completions = int(state.get("completions",0))
	upgrades.merge(state.get("upgrades",{}),true)
	last_summary = state.get("last_summary",{}).duplicate(true)
	welcomed = bool(state.get("welcomed",false))
	rite_id = str(state.get("rite_id","blade"))
	best_combo = int(state.get("best_combo",0))
	combo = 0

func moss_position() -> Vector2:
	var npc = game.rpg.npc_nodes.get("den_keeper")
	return npc.position if is_instance_valid(npc) else Vector2(640,1300)

func home() -> bool:
	return game.current_room == 0 and game.player.position.distance_to(moss_position()) < 115

func weather_profile() -> Dictionary:
	if active.is_empty() or active.get("claimed",false) or game.current_room == 0:
		return Data.weather_profile("Clear")
	return Data.weather_profile(str(active.get("weather","Clear")))

func encounter_weather() -> Dictionary:
	if active.is_empty() or active.get("claimed",false):
		return Data.weather_profile("Clear")
	return Data.weather_profile(str(active.get("weather","Clear")))

func choose_rite(class_id: String) -> bool:
	var allowed := false
	for rite in Data.RITES:
		if rite.id == class_id:
			allowed = true
	if not allowed or not game.is_den_room() or game.player.hp <= 0:
		return false
	rite_id = class_id
	game.select_goblin_class(class_id)
	game.audio_system.play_sfx("level_up")
	return true

func begin(kind: int, seed_override: int = -1) -> bool:
	if kind < 0 or kind >= Data.CONTRACTS.size() or not home() or not active.is_empty() and not active.get("claimed",false):
		return false
	clear_encounters()
	serial += 1
	combo = 0
	hearth_bloom = 0.0
	var chosen_seed := seed_override if seed_override >= 0 else 68471 + serial*7919
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--expedition-seed="):
			chosen_seed = int(arg.get_slice("=",1)) + serial - 1
	active = Data.generate(kind, chosen_seed, serial)
	welcomed = true
	game.potions = game.max_potions
	game.player.heal(game.player.max_hp)
	populate()
	game._auto_save()
	ui.close()
	var weather_line: String = Data.weather_profile(str(active.weather)).blurb
	ui.announce(Data.CONTRACTS[kind].name.to_upper(), "Follow the eastern tunnels into Thornwood · %s"%weather_line)
	game.refresh_objective()
	return true

func clear_encounters() -> void:
	for npc in get_tree().get_nodes_in_group("expedition_npcs"):
		npc.get_parent().remove_child(npc)
		npc.queue_free()
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.has_meta("expedition_id"):
			enemy.get_parent().remove_child(enemy)
			enemy.queue_free()

func spawn(id: String, room: int, at: Vector2, role: String, elite: bool = false) -> void:
	if id in active.defeated:
		return
	var hp := 105 if elite else 55 + mini(completions,4)*8
	var title := "THORNWOOD WATCHER" if elite else "TRAIL " + role.to_upper()
	game.spawn_enemy_ext(room,at,title,hp,82 if elite else 92,12 if elite else 7,7 if elite else 3,role,25,"","",true)
	var enemy = game.rooms[room].get_child(game.rooms[room].get_child_count()-1)
	enemy.set_meta("expedition_id",id)
	enemy.set_meta("expedition_elite",elite)
	enemy.remove_meta("opening_key")
	enemy.dungeon_awareness = Awareness.new()
	enemy.dungeon_awareness.configure(enemy)
	var profile := encounter_weather()
	enemy.dungeon_awareness.notice_scale = float(profile.notice)
	enemy.speed = float(enemy.speed) * float(profile.move)

func populate() -> void:
	clear_encounters()
	spawn("tunnel_watch",0,Vector2(1932,1200),"rogue")
	spawn("hollow_watch",5,Vector2(750,280),"ranger")
	var sites: Array = active.sites
	if int(active.kind)==1:
		for i in range(3):
			spawn("target_%d"%i,6,sites[i],active.roles[i])
	elif int(active.kind)==2:
		var flank := -1.0 if int(active.flank)==0 else 1.0
		spawn("camp_watch_a",6,sites[0]+Vector2(110*flank,70),"knight")
		spawn("camp_watch_b",6,sites[0]+Vector2(200*flank,-65),"ranger")
	else:
		spawn("cache_watch",6,sites[1]+Vector2(100,45),active.roles[0])
	spawn("bonus_watch",6,Data.BONUS+Vector2(90,-25),"knight",true)
	if int(active.event)==0 and not "event" in active.taken:
		var scout = preload("res://scripts/friendly_npc.gd").new()
		scout.game = game
		scout.definition = {"id":"lost_trial_scout","name":"Bram · Lost Scout","class":"archer","room":6}
		scout.position = Vector2(790,745)
		game.rooms[6].add_child(scout)
		scout.add_to_group("expedition_npcs")
		scout.set_physics_process(false)
	game.enter_room(game.current_room,game.player.position,true)

func record_defeat(enemy: Node2D) -> void:
	if active.is_empty() or active.claimed:
		return
	var id := str(enemy.get_meta("expedition_id",""))
	if id.is_empty() or id in active.defeated:
		return
	active.defeated.append(id)
	active.kills += 1
	combo += 1
	best_combo = maxi(best_combo, combo)
	if id=="tunnel_watch":
		ui.announce("FIRST BLOOD", "The mouth of the den is yours. Daylight waits east.")
	elif bool(enemy.get_meta("expedition_elite",false)):
		ui.announce("THE WATCHER FALLS", "Its cache is unguarded. Take it, or leave the greed behind.")
	elif combo>=3:
		ui.announce("BLOOD IN THE LEAVES", "A %d-strike streak. Do not let them recover."%combo)
	update_ready()

func on_player_hit() -> void:
	combo = 0

func update_ready() -> void:
	if active.is_empty():
		return
	var ready := false
	match int(active.kind):
		0: ready = "cache_0" in active.taken and "cache_1" in active.taken and "cache_2" in active.taken
		1: ready = "target_0" in active.defeated and "target_1" in active.defeated and "target_2" in active.defeated
		2: ready = "ledger" in active.taken
	if ready and not active.ready:
		active.ready = true
		ui.announce("THE WAY HOME IS OPEN", "Return with your haul — or cross the bridge for the Watcher's cache")
		game.audio_system.play_sfx("interact")
	game.refresh_objective()

func objects() -> Array:
	var result: Array = []
	if active.is_empty() or active.claimed:
		return result
	result.append({"id":"clue","room":0,"point":Vector2(2316,1332),"label":"Read the torn banner","kind":"clue"})
	if int(active.kind)==0:
		for i in range(3):
			result.append({"id":"cache_%d"%i,"room":6,"point":active.sites[i],"label":"Recover supply bundle","kind":"cache"})
	if int(active.kind)==2:
		result.append({"id":"ledger","room":6,"point":active.sites[0],"label":"Take the scouting ledger","kind":"cache"})
	result.append({"id":"event","room":6,"point":Vector2(780,790),"label":Data.EVENTS[int(active.event)],"kind":"event"})
	result.append({"id":"herbs","room":5,"point":Vector2(460,460),"label":"Gather bloodmoss · 3 herbs","kind":"herbs"})
	result.append({"id":"bonus","room":6,"point":Data.BONUS,"label":"Open the Watcher's cache · optional danger","kind":"bonus"})
	return result

func candidates() -> Array:
	var result: Array = []
	for entry in objects():
		if entry.room==game.current_room and not entry.id in active.taken:
			result.append({"point":entry.point,"radius":85.0,"label":entry.label,"action":interact_object.bind(entry.id)})
	if not active.is_empty() and active.ready and not active.claimed and game.current_room==6:
		result.append({"point":Vector2(700,350),"radius":85.0,"label":"Take Moss's hidden trail home","action":shortcut})
	return result

func interact_object(id: String) -> bool:
	if active.is_empty() or active.claimed or id in active.taken:
		return false
	var entry: Dictionary = {}
	for item in objects():
		if item.id==id:
			entry = item
	if entry.is_empty() or entry.room!=game.current_room or game.player.position.distance_to(entry.point)>90:
		return false
	if id=="bonus" and not "bonus_watch" in active.defeated:
		game.show_notice("The Watcher holds this cache. Defeat it, or return with your secured supplies.")
		return false
	if id=="event":
		ui.open("event")
		return true
	if id=="herbs":
		if not game.rpg.backpack.add("herb",3):
			game.show_notice("Your pack is full. Make room; the bloodmoss will stay here.")
			return false
		active.resources += 3
	if id=="clue":
		active.discoveries.append("The torn banner")
		ui.announce("SOMEONE SURVIVED", "Three cuts in the cloth. A goblin trail sign pointing toward daylight.")
	elif id=="bonus":
		active.bonus = true
		active.discoveries.append("The Watcher's cache")
		ui.announce("A LITTLE GREED, WELL EARNED", "+18 scrap and +45 XP secured for your homecoming")
	else:
		game.show_notice("Recovered: " + entry.label + ". Contract cargo is secured separately from your backpack.")
		if id.begins_with("cache"):
			active.resources += 1
	active.taken.append(id)
	update_ready()
	game._auto_save()
	return true

func resolve_event(help: bool) -> bool:
	if active.is_empty() or "event" in active.taken or game.current_room!=6 or game.player.position.distance_to(Vector2(780,790))>100:
		return false
	var event_kind := int(active.event)
	if help and event_kind==0:
		if game.potions<=0:
			game.show_notice("You need a potion to help. You can return later.")
			return false
		game.potions -= 1
		active.discoveries.append("Saved a lost scout")
		active.resources += 2
	elif help:
		game.player.heal(25)
		active.discoveries.append("A quiet place in Thornwood")
	else:
		if not game.rpg.backpack.add("ore",2):
			game.show_notice("Make room for two ore before searching the camp.")
			return false
		active.resources += 2
		active.discoveries.append("Salvaged the abandoned camp")
	active.taken.append("event")
	for npc in get_tree().get_nodes_in_group("expedition_npcs"):
		npc.queue_free()
	game._auto_save()
	ui.close()
	ui.announce("THE FOREST REMEMBERS", str(active.discoveries[-1]))
	return true

func shortcut() -> bool:
	if active.is_empty() or not active.ready or active.claimed or game.current_room!=6 or game.player.position.distance_to(Vector2(700,350))>90:
		return false
	game.enter_room(0,Starting.START,true)
	game._auto_save()
	ui.announce("HOME, WITH SOMETHING TO SHOW", "Moss is waiting. Your contract reward has not been claimed yet.")
	return true

func claim() -> bool:
	if not home() or active.is_empty() or not active.ready or active.claimed:
		return false
	var contract: Dictionary = Data.CONTRACTS[int(active.kind)]
	var reward := int(contract.scrap) + (18 if active.bonus else 0) + (8 if "Saved a lost scout" in active.discoveries else 0)
	var xp := int(contract.xp) + (45 if active.bonus else 0)
	active.claimed = true
	completions += 1
	hearth_bloom = 12.0
	combo = 0
	last_summary = {"name":contract.name,"seconds":active.elapsed,"kills":active.kills,"resources":active.resources,"discoveries":active.discoveries.duplicate(),"scrap":reward,"xp":xp,"seed":active.seed,"weather":active.weather}
	# Currency, claimed flag and progression share one atomic save file.
	game.scrap += reward
	game.gain_xp(xp)
	game._auto_save()
	clear_encounters()
	ui.open("summary")
	game.audio_system.play_sfx("interact")
	game.refresh_objective()
	return true

func abandon() -> bool:
	if not home() or active.is_empty() or active.claimed:
		return false
	clear_encounters()
	active = {}
	combo = 0
	game._auto_save()
	ui.open("board")
	return true

func buy(id: String) -> bool:
	if not home() or not upgrades.has(id):
		return false
	var rank := int(upgrades[id])
	var cost := 28 + rank*18
	if rank >= (2 if id=="pouch" else 3) or game.scrap<cost:
		return false
	game.scrap -= cost
	upgrades[id] = rank+1
	if id=="pouch":
		game.max_potions += 1
		game.potions = game.max_potions
	game.player.apply_class_and_gear(game.player.class_id,game.player.evolution_id,true)
	game._auto_save()
	ui.open("upgrades")
	return true

func target_point() -> Vector2:
	if active.is_empty() or active.claimed:
		return moss_position() if game.current_room==0 else game._left_gate_position()
	if game.current_room==0:
		return moss_position() if active.ready else Starting.EXIT
	if game.current_room==5:
		return game.LEFT_GATE if active.ready else game.RIGHT_GATE
	if game.current_room!=6:
		return Vector2(145,365)
	if active.ready:
		return Vector2(700,350)
	if int(active.kind)==2:
		return active.sites[0]
	for i in range(3):
		if not ("target_%d"%i in active.defeated if int(active.kind)==1 else "cache_%d"%i in active.taken):
			return active.sites[i]
	return Vector2(700,350)

func paces() -> int:
	return int(game.player.position.distance_to(target_point()) / 10.0)

func objective_text() -> String:
	if active.is_empty() or active.claimed:
		return "Speak to Moss · Choose your next expedition [J]"
	if active.ready:
		return "Supplies secured · Return to Moss, or seek the bonus cache"
	var progress := 0
	for i in range(3):
		if "cache_%d"%i in active.taken or "target_%d"%i in active.defeated:
			progress += 1
	return "%s · %s"%[Data.CONTRACTS[int(active.kind)].name,"Find the scouting ledger" if int(active.kind)==2 else "%d / 3 recovered"%progress]

func on_room_entered() -> void:
	if initialized:
		# Resolve authored guard offsets against the active room's real navigation.
		# Never move the objective or change terrain; keep guards near their post.
		var cave = game.get_node("Cave")
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if enemy.has_meta("expedition_id") and enemy.get_parent()==game.rooms[game.current_room] and enemy.hp>0:
				var cell: Vector2i = cave._nearest_open_cell(enemy.position)
				var floor_point: Vector2 = cave.navigation.get_point_position(cell)
				if enemy.position.distance_to(floor_point)>18:
					enemy.position = floor_point
					enemy.dungeon_awareness.configure(enemy)
					var profile := encounter_weather()
					enemy.dungeon_awareness.notice_scale = float(profile.notice)
		var heading: String = str(game.room_label.text).to_upper()
		var line := "The fire is still burning"
		if game.current_room==5:
			line = "The hollow remembers every rider who passed"
		elif game.current_room==6:
			line = str(active.get("weather","Clear"))+" over Thornwood · "+str(weather_profile().blurb)
		elif game.current_room!=0:
			line = "Stay low. Humans still mark these stones."
		ui.announce(heading, line)

func _process(delta: float) -> void:
	if get_tree().paused or ui.overlay.visible:
		return
	hearth_bloom = maxf(0.0, hearth_bloom-delta)
	if not active.is_empty() and not active.claimed:
		active.elapsed += delta
		save_clock += delta
		if save_clock>20:
			save_clock = 0
			game._auto_save()
