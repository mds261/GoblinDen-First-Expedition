extends Node
## Persistent authored boss quests, independent of repeatable expedition contracts.
const Catalog = preload("res://scripts/design_catalog.gd")
const Starting = preload("res://scripts/starting_caves.gd")
var game: Node2D
var accepted := false
var defeated: Array = []
var claimed: Array = []
var actor: Node2D
const LEGACY_ORDER := ["hunt_iron_captain","hunt_spider","hunt_wolf_rider","hunt_kilnheart","hunt_vanguard","hunt_huntmaster","hunt_ogre","hunt_vault","hunt_paladin","hunt_dawn"]

func quests() -> Array:
	return Catalog.entries("quests").filter(func(q): return q.get("boss_hunt", false))

func current() -> Dictionary:
	for quest in quests():
		if not quest.id in claimed:
			return quest
	return {}

func main_complete() -> bool:
	for quest in quests():
		if not quest.get("bonus",false) and not str(quest.id) in claimed:
			return false
	return true

func completed_count() -> int:
	var total := 0
	for quest in quests():
		if str(quest.id) in claimed:
			total += 1
	return total

func is_complete(quest: Dictionary) -> bool:
	if quest.get("bonus",false):
		return game.rpg.orchard.bonus_completed
	if str(quest.boss_id) == "kilnheart" and game.rpg.orchard.boss_defeated:
		return true
	if str(quest.boss_id) == "vault_hunger" and game.rpg.dungeon.boss_defeated:
		return true
	return str(quest.boss_id) in defeated

func accept() -> void:
	if current().is_empty() or not game.expedition.home() or accepted:
		return
	accepted = true
	ensure_encounter()
	game._auto_save()
	game.expedition.ui.close()
	game.show_notice("Moss: " + str(current().description))
	game.refresh_objective()

func claim() -> void:
	var quest := current()
	if quest.is_empty() or not accepted or not is_complete(quest) or not game.expedition.home():
		return
	claimed.append(str(quest.id))
	accepted = false
	actor = null
	# Save the claim before gain_xp can trigger another save.
	game.scrap += int(quest.reward_scrap)
	game.gain_xp(int(quest.reward_xp))
	game._auto_save()
	game.expedition.ui.open("hunts")
	game.refresh_objective()

func record_defeat(enemy: Node2D) -> void:
	var id := str(enemy.get_meta("boss_hunt_id", ""))
	if id.is_empty() or id in defeated:
		return
	defeated.append(id)
	game.show_notice("Boss hunt complete: %s. Report to Moss by the hearth." % enemy.display_name)
	game.refresh_objective()

func ensure_encounter() -> void:
	var quest := current()
	if not accepted or quest.is_empty() or is_complete(quest) or is_instance_valid(actor):
		return
	var id := str(quest.boss_id)
	if quest.get("bonus",false):
		game.rpg.orchard.begin_bonus()
		return
	if id in ["kilnheart", "vault_hunger"]:
		return
	var room := int(quest.room)
	var point := Vector2(float(quest.x), float(quest.y))
	if id in ["spider", "ogre", "wolf_rider"]:
		actor = preload("res://scripts/large_enemy.gd").new()
		actor.configure(id)
		actor.position = point
		var collision := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = 34.0
		collision.shape = shape
		actor.add_child(collision)
		game.rooms[room].add_child(actor)
		actor.defeated.connect(game.on_enemy_defeated.bind(actor, room))
	else:
		game.spawn_enemy_ext(room, point, "", 100, 90, 10, 8, "boss", 100, "", id, true)
		actor = game.rooms[room].get_child(game.rooms[room].get_child_count() - 1)
	actor.set_meta("boss_hunt_id", id)
	actor.remove_meta("opening_key")
	actor.dungeon_awareness = preload("res://scripts/dungeon_awareness.gd").new()
	actor.dungeon_awareness.configure(actor)
	var active_room: bool = game.current_room == room
	actor.collision_layer = 2 if active_room else 0
	actor.collision_mask = 3 if active_room else 0

func objective() -> String:
	var quest := current()
	if quest.is_empty():
		return "All boss hunts complete · The den remembers your deeds"
	if not accepted:
		return ("Moss has a final bonus quest: " if quest.get("bonus",false) else "Moss has a boss hunt: ") + str(quest.name)
	if is_complete(quest):
		return str(quest.name) + " · Return to Moss for your reward"
	return str(quest.name) + " · " + str(quest.destination)

func target_point() -> Vector2:
	var quest := current()
	if quest.is_empty():
		return game.expedition.moss_position()
	var room: int = game.current_room
	var returning := is_complete(quest)
	var destination := 0 if returning else int(quest.room)
	if room == destination:
		return game.expedition.moss_position() if returning else Vector2(quest.x, quest.y)
	match room:
		0: return Starting.EXIT
		5: return game.LEFT_GATE if destination == 0 else (preload("res://scripts/cinder_orchard_layout.gd").HOLLOW_ENTRANCE if destination == 16 else game.RIGHT_GATE)
		6: return game.rpg.BOG_TRAIL_POINT if destination >= 11 and destination != 16 else game.EXPANSE_RETURN_GATE
		11: return Vector2(1000,365) if destination >= 12 and destination != 16 else Vector2(145,365)
		12: return Vector2(1000,365) if destination == 15 else Vector2(145,365)
		13, 14:
			var layout = preload("res://scripts/dungeon_layout.gd")
			if destination != 15:
				return layout.entry(room)
			for index in range(2):
				if not game.rpg.dungeon.seals.has("%d_%d" % [room,index]):
					return layout.seals(room)[index]
			return layout.stairs(room)
		15: return preload("res://scripts/dungeon_layout.gd").entry(15)
		16: return preload("res://scripts/cinder_orchard_layout.gd").EXIT
	return Vector2(145,365)

func snapshot() -> Dictionary:
	return {"accepted": accepted, "active_quest_id": str(current().get("id","")) if accepted else "", "defeated": defeated.duplicate(), "claimed": claimed.duplicate()}

func restore(state: Dictionary) -> void:
	accepted = bool(state.get("accepted", false))
	defeated = state.get("defeated", []).duplicate()
	claimed = state.get("claimed", []).duplicate()
	# Older saves only stored an accepted flag. Recover the old active quest
	# before changing the order, so it cannot silently accept a different hunt.
	var previous_id := str(state.get("active_quest_id",""))
	if accepted and previous_id.is_empty():
		for id in LEGACY_ORDER:
			if not id in claimed:
				previous_id = id
				break
	if accepted and previous_id != str(current().get("id","")):
		accepted = false
	actor = null
