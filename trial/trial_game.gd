extends "res://scripts/main.gd"
## The original scene and systems are inherited, with bounded trial encounters.
var expedition = preload("res://trial/expedition.gd").new()
var restart_pending := false

func _auto_save() -> void:
	if not restart_pending:
		super._auto_save()

func start_over() -> void:
	if restart_pending:
		return
	if not SaveData.save(self):
		return
	var backup_error := DirAccess.copy_absolute(SaveData.SAVE_PATH, SaveData.SAVE_PATH + ".before-restart")
	if backup_error != OK:
		show_notice("Could not back up the current journey. Start over cancelled.")
		return
	var error := DirAccess.remove_absolute(SaveData.SAVE_PATH)
	if error != OK:
		show_notice("Could not clear the current journey. Start over cancelled.")
		return
	# Block old-scene autosaves until the fresh scene takes over.
	restart_pending = true
	get_tree().paused = true
	call_deferred("_reload_new_journey")

func _reload_new_journey() -> void:
	var error := get_tree().reload_current_scene()
	if error != OK:
		DirAccess.copy_absolute(SaveData.SAVE_PATH + ".before-restart", SaveData.SAVE_PATH)
		restart_pending = false
		get_tree().paused = false
		show_notice("Could not restart. Your previous journey has been restored.")

func _ready() -> void:
	super._ready()
	expedition.game = self
	add_child(expedition)
	rpg.boss_hunts.ensure_encounter()
	if has_meta("trial_resume"):
		var resume: Dictionary = get_meta("trial_resume")
		enter_room(int(resume.room),resume.position,true)
		player.hp = clampi(int(resume.hp),1,player.max_hp)
		update_health(player.hp,player.max_hp)
	show_notice("Moss is waiting by the fire. Approach him and press E. [J] opens your field journal.")
	refresh_objective()
	if expedition.living.pending_heir:
		expedition.ui.open("legacy")

func _populate_campaign_enemies(_camp_idx: int) -> void:
	pass
func _spawn_large_enemies() -> void:
	pass
func _spawn_exterior_encounters() -> void:
	pass

func on_enemy_defeated(enemy: Node2D, room_index: int) -> void:
	if enemy.has_meta("reward_recorded"):
		return
	enemy.set_meta("reward_recorded",true)
	# Record defeat before any XP-triggered autosave.
	rpg.boss_hunts.record_defeat(enemy)
	expedition.record_defeat(enemy)
	audio_system.play_sfx("death")
	rpg.enemy_reward(enemy,room_index)
	gain_xp(int(enemy.xp_reward))
	_auto_save()

func refresh_objective() -> void:
	if expedition != null and expedition.is_inside_tree():
		objective.text = expedition.objective_text()
	else:
		super.refresh_objective()

func _process(delta: float) -> void:
	super._process(delta)
	if rpg != null:
		# Expedition encounters and weather own their timing; no infinite ambient waves.
		rpg.encounter_timer = 9999
		rpg.weather_timer = 9999
		if not expedition.active.is_empty() and current_room in [5,6]:
			rpg.weather = expedition.active.weather
		if current_room == 0:
			rpg.weather = "Clear"

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and not rpg.input_blocked():
		if event.physical_keycode in [KEY_G,KEY_V]:
			expedition.living.use_tool("smoke" if event.physical_keycode==KEY_G else "talisman")
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("restart"):
		if not rpg.input_blocked():
			game_menu.open()
			game_menu.restart_visible = true
			game_menu._rebuild()
		get_viewport().set_input_as_handled()
		return
	super._unhandled_input(event)

func enter_room(index: int, spawn_point: Vector2, world_spawn: bool = false) -> void:
	if current_room == 16 and index != 16 and rpg != null:
		rpg.orchard.reset_boss_on_exit()
	if index == 16 and rpg != null and not rpg.orchard.accessible():
		index = 5
		spawn_point = preload("res://scripts/cinder_orchard_layout.gd").HOLLOW_RETURN
		world_spawn = true
	super.enter_room(index,spawn_point,world_spawn)
	if expedition.is_inside_tree():
		expedition.on_room_entered()

func on_player_died() -> void:
	call_deferred("_resolve_journey_death")

func _resolve_journey_death() -> void:
	# Respawn, inheritance and corpse removal must share one save snapshot.
	restart_pending = true
	expedition.living.on_death()
	rpg.die()
	if expedition.living.legacy_mode:
		# Legacy equipment is lost, rather than recoverable from the prior body.
		if not rpg.corpses.is_empty(): rpg.corpses.pop_back()
	restart_pending = false
	_auto_save()
	if expedition.living.legacy_mode:
		expedition.ui.open("legacy")
