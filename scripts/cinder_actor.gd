extends CharacterBody2D
## Shared hit, status, and loot contract for the Cinder Orchard. Attacks stay on each creature.
signal defeated
const FloatingText = preload("res://scripts/floating_text.gd")
const HitSpark = preload("res://scripts/hit_spark.gd")
const DeathEffect = preload("res://scripts/death_effect.gd")

var max_hp := 40
var hp := 40
var speed := 80.0
var damage := 8
var display_name := "CINDER"
var scrap_reward := 2
var xp_reward := 12
var loot_drop_id := ""
var role := "cinder"
var target: Node2D
var cooldown := 0.8
var windup := 0.0
var knockback := Vector2.ZERO
var flash := 0.0
var stun_timer := 0.0
var slow_timer := 0.0
var bleed_dps := 0
var poison_dps := 0
var dot_timer := 0.0
var dot_tick_accum := 0.0
var status_text := ""
var status_text_time := 0.0
var animation_time := 0.0
var death_burst := "enemy"

func configure_from_catalog(id: String) -> void:
	var definition: Dictionary = preload("res://scripts/design_catalog.gd").record("monsters", id)
	display_name = str(definition.name)
	max_hp = int(definition.hp)
	hp = max_hp
	speed = float(definition.speed)
	damage = int(definition.damage)
	scrap_reward = int(definition.scrap)
	xp_reward = int(definition.xp)
	loot_drop_id = str(definition.get("loot", ""))
	role = str(definition.get("role", "cinder"))

func use_radius(radius: float) -> void:
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = radius
	collision.shape = shape
	add_child(collision)

func tick_status(delta: float) -> void:
	animation_time += delta
	flash = maxf(0.0, flash - delta)
	status_text_time = maxf(0.0, status_text_time - delta)
	cooldown = maxf(0.0, cooldown - delta)
	slow_timer = maxf(0.0, slow_timer - delta)
	stun_timer = maxf(0.0, stun_timer - delta)
	z_index = int(position.y)
	if hp <= 0:
		return
	dot_timer = maxf(0.0, dot_timer - delta)
	dot_tick_accum += delta
	if dot_tick_accum >= 0.5 and (bleed_dps > 0 or poison_dps > 0):
		dot_tick_accum -= 0.5
		take_damage(maxi(1, int((bleed_dps + poison_dps) * 0.5)))
	if dot_timer <= 0.0:
		bleed_dps = 0
		poison_dps = 0

func apply_status(add_bleed: int, add_poison: int, add_slow: float) -> void:
	bleed_dps = maxi(bleed_dps, add_bleed)
	poison_dps = maxi(poison_dps, add_poison)
	if add_bleed > 0 or add_poison > 0:
		dot_timer = maxf(dot_timer, 3.0)
	if add_slow > 0.0:
		slow_timer = maxf(slow_timer, add_slow * 0.65)

func apply_stun(duration: float) -> void:
	stun_timer = maxf(stun_timer, duration * 0.45)
	windup = 0.0
	status_text = "STAGGERED"
	status_text_time = 0.75

func take_damage(amount: int, direction: Vector2 = Vector2.ZERO) -> void:
	if hp <= 0:
		return
	hp = maxi(0, hp - amount)
	flash = 0.14
	if direction != Vector2.ZERO:
		knockback = direction * 120.0
	var parent_node := get_parent()
	if is_instance_valid(parent_node):
		FloatingText.spawn_damage(parent_node, global_position + Vector2(0, -36), amount, amount >= 30)
		HitSpark.melee_hit(parent_node, global_position, amount >= 30)
	if hp == 0:
		collision_layer = 0
		collision_mask = 0
		windup = 0.0
		remove_from_group("enemies")
		if is_instance_valid(parent_node):
			if death_burst == "boss":
				DeathEffect.burst_boss(parent_node, global_position)
			else:
				DeathEffect.burst_enemy(parent_node, global_position)
		defeated.emit()
	queue_redraw()

func slide(delta: float) -> void:
	if slow_timer > 0.0:
		velocity *= 0.65
	velocity += knockback
	knockback = knockback.move_toward(Vector2.ZERO, 900.0 * delta)
	move_and_slide()

func draw_vitals(top: float) -> void:
	if hp <= 0:
		return
	draw_rect(Rect2(-48, top, 96, 15), Color(0.05, 0.02, 0.015, 0.88))
	draw_string(ThemeDB.fallback_font, Vector2(-44, top + 11), display_name, HORIZONTAL_ALIGNMENT_LEFT, 88, 10, Color("f0c99d"))
	draw_rect(Rect2(-44, top + 14, 88, 4), Color("38242a"))
	draw_rect(Rect2(-44, top + 14, 88.0 * float(hp) / maxf(1, max_hp), 4), Color("e07030"))
	if status_text_time > 0.0:
		draw_string(ThemeDB.fallback_font, Vector2(-46, top - 6), status_text, HORIZONTAL_ALIGNMENT_LEFT, 96, 11, Color("ffd27d"))

func reset_encounter_motion() -> void:
	velocity = Vector2.ZERO
	knockback = Vector2.ZERO
	windup = 0.0

func _route_to(destination: Vector2) -> Vector2:
	var cave = get_parent().get_parent().get_node_or_null("Cave")
	if is_instance_valid(cave) and cave.has_method("route_direction"):
		var heading: Vector2 = cave.route_direction(global_position, destination)
		if heading.length_squared() > 0.01:
			return heading
	return global_position.direction_to(destination)
