extends RefCounted
const Data = preload("res://trial/chronicle_data.gd")
var director: Node2D
var chapter := 0
var running := false
var seed_name := "The Three Fires"
var history: Array = []
var reputation := {"Reedclaw":0,"Stonekin":0,"Moonroot":0}
var flags: Array = []
var marks := 0
var tools := {"smoke":0,"talisman":0}
var ward := false
var ending := ""
var legacy_mode := false
var deaths := 0
var fallen_class := ""
var pending_heir := false
var smoke_time := 0.0
var grace_time := 0.0
var danger := 1.0
var reduced_effects := false

func snapshot() -> Dictionary:
	return {"chapter":chapter,"running":running,"seed_name":seed_name,"history":history.duplicate(true),"reputation":reputation.duplicate(),"flags":flags.duplicate(),"marks":marks,"tools":tools.duplicate(),"ward":ward,"ending":ending,"legacy_mode":legacy_mode,"deaths":deaths,"fallen_class":fallen_class,"pending_heir":pending_heir,"danger":danger,"reduced_effects":reduced_effects}

func restore(state: Dictionary) -> void:
	chapter = clampi(int(state.get("chapter",0)),0,Data.CHAPTERS.size())
	running = bool(state.get("running",false)) and chapter<Data.CHAPTERS.size()
	seed_name = str(state.get("seed_name","The Three Fires")).left(64)
	history = state.get("history",[]).duplicate(true)
	for faction in reputation:
		reputation[faction] = clampi(int(state.get("reputation",{}).get(faction,0)),-100,100)
	flags = state.get("flags",[]).duplicate()
	marks = maxi(0,int(state.get("marks",0)))
	for id in tools:
		tools[id] = maxi(0,int(state.get("tools",{}).get(id,0)))
	ward = bool(state.get("ward",false))
	ending = str(state.get("ending",""))
	legacy_mode = bool(state.get("legacy_mode",false))
	deaths = maxi(0,int(state.get("deaths",0)))
	fallen_class = str(state.get("fallen_class",""))
	pending_heir = bool(state.get("pending_heir",false))
	danger = clampf(float(state.get("danger",1.0)),0.65,1.3)
	reduced_effects = bool(state.get("reduced_effects",false))

func start(named_seed: String) -> bool:
	if running or chapter>=Data.CHAPTERS.size() or not director.home() or not director.active.is_empty() and not director.active.get("claimed",false):
		return false
	seed_name = named_seed.strip_edges().left(64)
	if seed_name.is_empty(): seed_name = "The Three Fires"
	running = true
	director.game._auto_save()
	return true

func begin_chapter() -> bool:
	if not running or chapter>=Data.CHAPTERS.size(): return false
	return director.begin(chapter%3, posmod((seed_name.to_lower()+str(chapter)).hash(),2147483647))

func prepare(active: Dictionary) -> void:
	active["difficulty"] = danger
	if not running and history.is_empty(): return
	var theme := Data.biome(seed_name+str(chapter if running else director.serial))
	if running: active["chronicle_chapter"] = chapter
	active["biome"] = theme
	active["weather"] = theme.weather
	active["roles"] = theme.roles.duplicate()
	active["story_choice"] = ""

func is_story() -> bool:
	return running and director.active.has("chronicle_chapter") and not director.active.get("claimed",false)

func choice_done() -> bool:
	return not str(director.active.get("story_choice","")).is_empty()

func can_choose(choice: Dictionary) -> bool:
	if not is_story() or choice_done() or not director.active.ready or director.game.current_room!=6 or director.game.player.position.distance_to(Vector2(780,790))>100:
		return false
	if director.game.scrap<int(choice.get("cost",0)) or director.game.potions<int(choice.get("potion",0)): return false
	if str(choice.id)=="treaty":
		var friendly := 0
		for value in reputation.values():
			if int(value)>=20: friendly += 1
		return "relic_returned" in flags and friendly>=2
	return true

func choose(id: String) -> bool:
	if chapter>=Data.CHAPTERS.size(): return false
	for choice in Data.CHAPTERS[chapter].choices:
		if choice.id!=id or not can_choose(choice): continue
		# Commit the choice and its rewards together before any autosave.
		director.active.story_choice = id
		director.game.scrap += int(choice.get("scrap",0))-int(choice.get("cost",0))
		director.game.potions -= int(choice.get("potion",0))
		marks += int(choice.get("marks",0))
		flags.append(str(choice.flag))
		for faction in reputation:
			if str(choice.get("faction","")) in ["all",faction]:
				reputation[faction] = clampi(int(reputation[faction])+int(choice.get("rep",0)),-100,100)
		history.append({"chapter":chapter,"title":Data.CHAPTERS[chapter].title,"choice":choice.label,"result":choice.result})
		if choice.has("ending"): ending = str(choice.ending)
		director.game._auto_save()
		director.ui.open("chronicle")
		director.game.show_notice(str(choice.result))
		return true
	return false

func claimed() -> void:
	if not is_story() or not choice_done(): return
	chapter += 1
	if chapter>=Data.CHAPTERS.size(): running = false

func camp_description() -> String:
	if "treaty_signed" in flags: return "Three clan banners hang over a shared hearth. The goblin market is thriving."
	if "nest_burned" in flags: return "Moss has built firebreaks. Moonroot scouts watch the eastern tunnel."
	if market_open(): return "Clan traders share the fire. Ward charms are available at the market."
	return "The clans are listening. Kindness can open their market."

func market_open() -> bool:
	for value in reputation.values():
		if int(value)>=20: return true
	return false

func craft(id: String) -> bool:
	if not director.home() or not Data.RECIPES.has(id): return false
	var pack = director.game.rpg.backpack
	var recipe: Dictionary = Data.RECIPES[id].ingredients
	for item in recipe:
		if pack.count_item(item)<int(recipe[item]): return false
	for item in recipe: pack.remove(item,int(recipe[item]))
	tools[id] += 1
	director.game._auto_save()
	return true

func buy_ward() -> bool:
	if not director.home() or ward or marks<5 or not market_open(): return false
	marks -= 5
	ward = true
	director.game._auto_save()
	return true

func use_tool(id: String) -> bool:
	var game = director.game
	if game.rpg.input_blocked() or game.player.hp<=0 or not tools.has(id) or int(tools[id])<=0 or game.is_den_room(): return false
	tools[id] -= 1
	if id=="smoke": smoke_time = 10.0
	for enemy in director.get_tree().get_nodes_in_group("enemies"):
		if enemy.get_parent()!=game.rooms[game.current_room] or not enemy.has_meta("expedition_id"): continue
		if id=="smoke" and enemy.get("dungeon_awareness")!=null: enemy.dungeon_awareness.reset(enemy)
		if id=="talisman" and enemy.position.distance_to(game.player.position)<240 and not enemy.get_meta("expedition_elite",false): enemy.apply_stun(5.0)
	game.audio_system.play_sfx("interact")
	game.show_notice("Concealed for 10 seconds. Attacking breaks cover." if id=="smoke" else "The talisman scatters nearby patrols for 5 seconds.")
	game._auto_save()
	return true

func on_death() -> void:
	smoke_time = 0
	deaths += 1
	fallen_class = director.game.player.class_id
	if legacy_mode:
		pending_heir = true
		# A new goblin inherits the clan memory and 80% of unspent scrap.
		director.game.scrap = int(director.game.scrap*0.8)
		director.clear_encounters()
		director.active = {}
		director.game.player.level = 1
		director.game.player.xp = 0
		director.game.player.xp_to_next = 100
		director.game.player.evolution_id = ""
		director.game.player.attack_damage = 25
		director.game.player.trap_bonus_damage = 0
		director.game.player.ranged_bonus_damage = 0
		director.game.player.magic_bonus_damage = 0
		# A resolved story choice remains binding if death precedes homecoming.
		if history.size()>chapter:
			chapter += 1
			if chapter>=Data.CHAPTERS.size(): running = false
	director.game._auto_save()

func select_heir(class_id: String) -> bool:
	if not pending_heir or class_id==fallen_class or not director.choose_rite(class_id): return false
	pending_heir = false
	director.game._auto_save()
	director.ui.close()
	return true

func tick(delta: float) -> void:
	smoke_time = maxf(0,smoke_time-delta)
	grace_time = maxf(0,grace_time-delta)

func surrender_candidates() -> Array:
	var hunts = director.game.rpg.boss_hunts
	var actor = hunts.actor
	if not hunts.accepted or not is_instance_valid(actor) or not str(actor.get_meta("boss_hunt_id","")).begins_with("campaign_") or actor.hp<=0 or actor.hp>int(actor.max_hp*0.2) or actor.get_parent()!=director.game.rooms[director.game.current_room]: return []
	return [{"point":actor.position,"radius":100.0,"label":"Offer quarter · Spare the wounded commander","action":spare_commander}]

func spare_commander() -> bool:
	var options := surrender_candidates()
	if options.is_empty() or director.game.player.position.distance_to(options[0].point)>100: return false
	var hunts = director.game.rpg.boss_hunts
	var actor = hunts.actor
	var id := str(actor.get_meta("boss_hunt_id",""))
	if "spared_"+id in flags: return false
	flags.append("spared_"+id)
	marks += 3
	hunts.record_defeat(actor)
	actor.hp = 0
	actor.remove_from_group("enemies")
	actor.collision_layer = 0
	actor.collision_mask = 0
	actor.queue_free()
	director.game._auto_save()
	director.game.show_notice("The commander surrenders. +3 goblin marks. Report to Moss for the hunt reward.")
	return true
