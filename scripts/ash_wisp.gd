extends "res://scripts/cinder_actor.gd"
## A charcoal-nave spirit. It only breathes inside its leash, then sinks back into its trunk.
const Projectile = preload("res://scripts/projectile.gd")
const LEASH := 150.0
var home := Vector2.ZERO
var grove := Rect2()
var state := "rest"
var state_time := 0.4
var aim := 0.0

func setup(spec: Dictionary) -> void:
	configure_from_catalog("ash_wisp")
	use_radius(14.0)
	home = spec.at
	grove = spec.grove
	position = home

func _ready() -> void:
	target = get_tree().get_first_node_in_group("player")
	add_to_group("enemies")
	collision_layer = 0
	collision_mask = 0

func _leashed() -> bool:
	return is_instance_valid(target) and grove.has_point(target.position) and target.position.distance_to(home) <= LEASH

func _physics_process(delta: float) -> void:
	tick_status(delta)
	velocity = Vector2.ZERO
	if hp <= 0:
		for shot in get_tree().get_nodes_in_group("cinder_wisp_embers"):
			if shot.owner_actor == self:
				shot.queue_free()
		queue_redraw()
		return
	if not is_instance_valid(target):
		queue_redraw()
		return
	state_time -= delta
	if stun_timer > 0.0:
		state = "rest"
		slide(delta)
		queue_redraw()
		return
	match state:
		"rest":
			velocity = _route_to(home) * speed * 0.45
			if position.distance_to(home) < 10.0:
				velocity = Vector2.ZERO
			if state_time <= 0.0 and _leashed():
				state = "approach"
				state_time = 1.3
		"approach":
			if not _leashed():
				state = "retreat"
				state_time = 1.2
			elif position.distance_to(target.position) < 112.0 or state_time <= 0.0:
				state = "exhale"
				state_time = 0.72
				windup = state_time
				aim = position.direction_to(target.position).angle()
				status_text = "CINDER BREATH"
				status_text_time = 0.7
			else:
				velocity = _route_to(target.position) * speed
		"exhale":
			windup = maxf(0.0, state_time)
			if state_time <= 0.0:
				_exhale()
				state = "retreat"
				state_time = 1.35
				windup = 0.0
		"retreat":
			velocity = _route_to(home) * speed * 1.15
			if position.distance_to(home) < 12.0 or state_time <= 0.0:
				state = "rest"
				state_time = 1.45
				velocity = Vector2.ZERO
	slide(delta)
	queue_redraw()

func _exhale() -> void:
	get_tree().call_group("game_audio", "play_sfx", "magic")
	for i in range(5):
		var shot := Projectile.new()
		var angle := aim + (float(i) - 2.0) * 0.2
		shot.position = position + Vector2.from_angle(angle) * 18.0
		shot.velocity = Vector2.from_angle(angle) * 145.0
		shot.damage = damage
		shot.from_player_team = false
		shot.style = "fire"
		shot.owner_actor = self
		shot.lifetime = 0.9
		shot.add_to_group("cinder_wisp_embers")
		get_parent().add_child(shot)

func _draw() -> void:
	var art = preload("res://scripts/cinder_art.gd")
	var frame := 3 if hp <= 0 else (2 if state == "exhale" else int(animation_time * 3.0) % 2)
	var alpha := 1.0 if _leashed() or state != "rest" else 0.65
	var bob := sin(animation_time * 3.0) * 4.0 if hp > 0 else 0.0
	draw_circle(Vector2(0,4),21,Color(0.04,0.02,0.02,0.35))
	if state == "exhale" and hp > 0:
		var heading := Vector2.from_angle(aim)
		draw_colored_polygon(PackedVector2Array([Vector2.ZERO,heading.rotated(-0.45)*90,heading.rotated(0.45)*90]),Color(1,0.4,0.08,0.24))
	art.paint(self,art.creature(1,frame),Vector2(0,-8+bob),Vector2(90,100),Color(1.5,1.4,1.2,alpha) if flash>0 else Color(1,1,1,alpha))
	draw_vitals(-98)
