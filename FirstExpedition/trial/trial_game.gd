extends "res://scripts/main.gd"
## The original scene and systems are inherited, with bounded trial encounters.
var expedition = preload("res://trial/expedition.gd").new()

func _ready() -> void:
	super._ready()
	expedition.game = self
	add_child(expedition)
	if has_meta("trial_resume"):
		var resume: Dictionary = get_meta("trial_resume")
		enter_room(int(resume.room),resume.position,true)
		player.hp = clampi(int(resume.hp),1,player.max_hp)
		update_health(player.hp,player.max_hp)
	show_notice("Moss is waiting by the fire. Approach him and press E. [J] opens your field journal.")
	refresh_objective()

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
	if event.is_action_pressed("restart"):
		show_notice("Your expedition is persistent. Speak to Moss to return early or choose another contract.")
		return
	super._unhandled_input(event)

func enter_room(index: int, spawn_point: Vector2, world_spawn: bool = false) -> void:
	super.enter_room(index,spawn_point,world_spawn)
	if expedition.is_inside_tree():
		expedition.on_room_entered()
