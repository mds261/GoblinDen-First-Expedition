extends "res://scripts/cinder_actor.gd"
## Short-lived bramble add. Hops at the player, then dies or times out.
const Layout = preload("res://scripts/thornveil_layout.gd")
var life := 12.0
var attack_time := 0.0

func _ready() -> void:
	configure_from_catalog("thornling")
	use_radius(10.0)
	target = get_tree().get_first_node_in_group("player")
	add_to_group("enemies")
	collision_layer = 2
	collision_mask = 3

func _physics_process(delta: float) -> void:
	tick_status(delta)
	life -= delta
	attack_time = maxf(0.0, attack_time - delta)
	velocity = Vector2.ZERO
	if hp <= 0:
		queue_redraw()
		return
	if life <= 0.0:
		take_damage(999)
		queue_redraw()
		return
	if not is_instance_valid(target) or stun_timer > 0.0:
		slide(delta)
		queue_redraw()
		return
	velocity = _route_to(target.position) * speed
	if cooldown <= 0.0 and position.distance_to(target.position) < 22.0:
		target.take_damage(damage)
		cooldown = 0.7
		attack_time = 0.28
	slide(delta)
	if not Layout.walkable(position, Layout.GLADE):
		position = position.clamp(Layout.ARENA.position + Vector2(48, 48), Layout.ARENA.end - Vector2(48, 48))
	queue_redraw()

func _draw() -> void:
	var art = preload("res://scripts/thornveil_art.gd")
	var frame := 3 if hp <= 0 else (2 if attack_time > 0.0 else (1 if velocity.length() > 20.0 else 0))
	art.paint_creature(self, "thornling", frame, flash > 0.0, hp <= 0, velocity.x < -1.0)
	draw_vitals(-42)
