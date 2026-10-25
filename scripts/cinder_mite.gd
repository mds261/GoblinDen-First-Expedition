extends "res://scripts/cinder_actor.gd"
## Skitters the straight heat-line between two ember vents. It does not hunt off that line.
var vent_a := Vector2.ZERO
var vent_b := Vector2.ZERO
var yard := Rect2()
var dash_target := Vector2.ZERO
var state := "idle"
var state_time := 0.6
var dash_hit := false

func setup(spec: Dictionary) -> void:
	configure_from_catalog("cinder_mite")
	use_radius(12.0)
	vent_a = spec.a
	vent_b = spec.b
	yard = spec.yard
	position = vent_a

func _ready() -> void:
	target = get_tree().get_first_node_in_group("player")
	add_to_group("enemies")
	collision_layer = 0
	collision_mask = 0

func _physics_process(delta: float) -> void:
	tick_status(delta)
	velocity = Vector2.ZERO
	if hp <= 0 or not is_instance_valid(target):
		queue_redraw()
		return
	state_time -= delta
	var stirred := yard.has_point(target.position) and target.position.distance_to(position) < 144.0
	if stun_timer > 0.0:
		state = "idle"
		slide(delta)
		queue_redraw()
		return
	if state == "idle":
		if state_time <= 0.0 and stirred:
			dash_target = vent_b if position.distance_to(vent_a) <= position.distance_to(vent_b) else vent_a
			state = "dash"
			state_time = 1.4
			dash_hit = false
			status_text = "SKITTER"
			status_text_time = 0.45
	else:
		var heading := position.direction_to(dash_target)
		velocity = heading * 250.0
		if not dash_hit and target.position.distance_to(position) < 24.0 and heading.dot(position.direction_to(target.position)) > 0.2:
			target.take_damage(damage)
			dash_hit = true
		if position.distance_to(dash_target) < 18.0 or state_time <= 0.0:
			position = dash_target
			state = "idle"
			state_time = 0.85
			velocity = Vector2.ZERO
	slide(delta)
	queue_redraw()

func _draw() -> void:
	var art = preload("res://scripts/cinder_art.gd")
	var moving := state == "dash" and hp > 0
	var frame := 3 if hp <= 0 else (1 + int(animation_time * 12.0) % 2 if moving else int(animation_time * 3.0) % 2)
	var bob := sin(animation_time * (24.0 if moving else 3.0)) * (2.0 if moving else 0.7)
	draw_set_transform(Vector2(0,bob), sin(animation_time * 20.0) * 0.05 if moving else 0.0)
	art.paint(self, art.creature(0,frame),Vector2.ZERO,Vector2(62,58),Color(1.7,1.5,1.2) if flash > 0 else Color.WHITE)
	draw_set_transform(Vector2.ZERO)
	if moving:
		for i in range(4):
			var point := -velocity.normalized() * float(8 + i * 6)
			draw_circle(point,2.5,Color(1,0.45,0.1,0.5-float(i)*0.1))
	draw_vitals(-56)
