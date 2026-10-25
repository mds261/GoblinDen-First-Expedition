extends "res://scripts/cinder_actor.gd"
## Rooted charcoal heart. Bark holds until it uproots or opens; the ground, not a weapon, does the work.
const Layout = preload("res://scripts/cinder_orchard_layout.gd")
var boss_state := "dormant"
var state_time := 0.0
var state_total := 1.0
var attack_index := 0
var phase_two := false
var announced_phase := false
var lanes: Array[Rect2] = []
var lane_gap := 0
var lanes_horizontal := true
var breath_from := 0.0
var breath_to := 0.0
var breath_hit := false
var walk_goal := Vector2.ZERO
var trail: Array[Dictionary] = []
var arena_absence := 0.0

func reset_abandoned_encounter() -> void:
	if hp <= 0 or boss_state == "dormant":
		return
	hp = max_hp
	position = Layout.BOSS
	boss_state = "dormant"
	state_time = 0.0
	attack_index = 0
	phase_two = false
	announced_phase = false
	arena_absence = 0.0
	windup = 0.0
	stun_timer = 0.0
	slow_timer = 0.0
	bleed_dps = 0
	poison_dps = 0
	dot_timer = 0.0
	dot_tick_accum = 0.0
	status_text = ""
	status_text_time = 0.0
	flash = 0.0
	velocity = Vector2.ZERO
	knockback = Vector2.ZERO
	lanes.clear()
	trail.clear()
	remove_from_group("enemies")
	collision_layer = 0
	collision_mask = 0
	queue_redraw()

func _ready() -> void:
	configure_from_catalog("kilnheart")
	death_burst = "boss"
	role = "kilnheart"
	use_radius(42.0)
	target = get_tree().get_first_node_in_group("player")
	collision_layer = 0
	collision_mask = 0

func awaken() -> void:
	if boss_state != "dormant":
		return
	add_to_group("enemies")
	collision_layer = 2
	collision_mask = 1
	boss_state = "reveal"
	state_time = 1.2
	state_total = state_time
	get_tree().call_group("game_audio", "play_sfx", "boss")
	status_text = "THE KILN WAKES"
	status_text_time = 1.2
	var game = get_parent().get_parent()
	if game != null and game.has_method("show_notice"):
		game.show_notice("The kiln heart wakes. Step between the cracks, and strike when the bark splits.")

func take_damage(amount: int, direction: Vector2 = Vector2.ZERO) -> void:
	if boss_state == "dormant" or hp <= 0:
		return
	var dealt := amount
	if boss_state in ["reveal", "rooted", "lanes", "breath"]:
		dealt = maxi(1, int(round(amount * 0.4)))
		status_text = "BARK"
		status_text_time = 0.35
	super.take_damage(dealt, direction * 0.2)
	if hp > 0 and hp <= int(max_hp * 0.60) and not phase_two:
		phase_two = true
		if not announced_phase:
			announced_phase = true
			status_text = "THE HEART SPLITS"
			status_text_time = 1.1
	if hp <= 0:
		boss_state = "dying"
		lanes.clear()
		trail.clear()

func _physics_process(delta: float) -> void:
	tick_status(delta)
	velocity = Vector2.ZERO
	if not is_instance_valid(target):
		queue_redraw()
		return
	if boss_state == "dormant":
		if hp > 0 and Layout.KILN.has_point(target.position):
			awaken()
		queue_redraw()
		return
	if hp <= 0:
		queue_redraw()
		return
	arena_absence = 0.0 if Layout.KILN.has_point(target.position) else arena_absence + delta
	if arena_absence >= 2.5:
		reset_abandoned_encounter()
		return
	if stun_timer > 0.0:
		boss_state = "exposed"
		state_time = maxf(state_time, 0.6)
		windup = 0.0
	state_time -= delta
	_tick_trail(delta)
	var in_kiln := Layout.KILN.has_point(target.position)
	match boss_state:
		"reveal":
			if state_time <= 0.0:
				_begin_rooted()
		"rooted":
			if state_time <= 0.0:
				if in_kiln:
					_next_attack()
				else:
					state_time = 0.4
		"lanes":
			windup = maxf(0.0, state_time)
			if state_time <= 0.0:
				_scorch_lanes()
				_begin_exposed(0.60 if phase_two else 0.75)
		"breath":
			windup = maxf(0.0, state_time)
			_breath_tick()
			if state_time <= 0.0:
				_begin_exposed(1.05 if not phase_two else 0.80)
		"uproot":
			_uproot_tick(delta)
		"exposed":
			if state_time <= 0.0:
				_begin_rooted()
	slide(delta)
	position = position.clamp(Layout.KILN.position + Vector2(70, 70), Layout.KILN.end - Vector2(70, 70))
	queue_redraw()

func _next_attack() -> void:
	attack_index += 1
	var kind := attack_index % 3
	if kind == 1:
		_begin_lanes()
	elif kind == 2:
		_begin_breath()
	else:
		_begin_uproot()

func _begin_rooted() -> void:
	boss_state = "rooted"
	state_time = 0.28 if phase_two else 0.4
	state_total = state_time
	windup = 0.0
	lanes.clear()

func _begin_exposed(duration: float) -> void:
	boss_state = "exposed"
	state_time = duration
	state_total = duration
	windup = 0.0
	status_text = "HEART OPEN"
	status_text_time = duration

func _begin_lanes() -> void:
	boss_state = "lanes"
	state_time = 0.85 if phase_two else 1.05
	state_total = state_time
	windup = state_time
	lanes_horizontal = attack_index % 2 == 0
	var count := 3 if phase_two else 4
	lane_gap = attack_index % count
	lanes.clear()
	var inner := Layout.KILN.grow(-36)
	for i in range(count):
		if i == lane_gap:
			continue
		if lanes_horizontal:
			var band := inner.size.y / float(count)
			lanes.append(Rect2(inner.position.x, inner.position.y + band * i, inner.size.x, band - 10.0))
		else:
			var band := inner.size.x / float(count)
			lanes.append(Rect2(inner.position.x + band * i, inner.position.y, band - 10.0, inner.size.y))
	status_text = "CRACKS — FIND THE GAP"
	status_text_time = state_time

func _scorch_lanes() -> void:
	get_tree().call_group("game_audio", "play_sfx", "boss")
	if is_instance_valid(target):
		for lane in lanes:
			if lane.has_point(target.position):
				target.take_damage(damage + 4)
				break
	var game = get_parent().get_parent()
	if game != null and game.has_method("_shake_camera"):
		game._shake_camera(4.5, 0.18)
	lanes.clear()
	windup = 0.0

func _begin_breath() -> void:
	boss_state = "breath"
	state_time = 0.9 if phase_two else 1.15
	state_total = state_time
	windup = state_time
	var facing := position.direction_to(target.position).angle()
	breath_from = facing - 1.05
	breath_to = facing + 1.05
	breath_hit = false
	status_text = "HEAT SWEEP — USE THE TRUNKS"
	status_text_time = state_time

func _breath_tick() -> void:
	if breath_hit or not is_instance_valid(target) or target.hp <= 0:
		return
	var progress := 1.0 - state_time / maxf(0.1, state_total)
	var current := lerpf(breath_from, breath_to, progress)
	var offset := target.position - position
	if offset.length() > 340.0 or absf(wrapf(offset.angle() - current, -PI, PI)) > 0.24:
		return
	var ray := PhysicsRayQueryParameters2D.create(global_position, target.global_position, 1)
	if not get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
		return
	target.take_damage(damage)
	breath_hit = true

func _begin_uproot() -> void:
	boss_state = "uproot"
	state_time = 2.6 if phase_two else 3.2
	state_total = state_time
	var inner := Layout.KILN.grow(-96.0)
	var marks: Array[Vector2] = [
		inner.position + Vector2(80, 70),
		inner.end + Vector2(-90, -80),
		Vector2(inner.position.x + inner.size.x * 0.55, inner.end.y - 90.0)
	]
	walk_goal = marks[attack_index % marks.size()]
	status_text = "UPROOTED — THE TRAIL BURNS"
	status_text_time = 1.0

func _uproot_tick(delta: float) -> void:
	var pace := speed * (1.45 if phase_two else 1.0)
	if position.distance_to(walk_goal) > 20.0 and state_time > 0.0:
		velocity = _route_to(walk_goal) * pace
		if trail.is_empty() or position.distance_to(trail[trail.size() - 1].point) > 42.0:
			trail.append({"point": position, "life": 1.5})
	else:
		velocity = Vector2.ZERO
		if state_time <= 0.0 or position.distance_to(walk_goal) <= 20.0:
			_begin_exposed(0.75 if phase_two else 0.9)
	if is_instance_valid(target):
		var radius := 50.0 if phase_two else 34.0
		for mark in trail:
			if float(mark.life) > 0.0 and target.position.distance_to(mark.point) <= radius:
				target.take_damage(22)
				break

func _tick_trail(delta: float) -> void:
	for i in range(trail.size() - 1, -1, -1):
		trail[i].life = float(trail[i].life) - delta
		if float(trail[i].life) <= 0.0:
			trail.remove_at(i)

func _draw() -> void:
	for mark in trail:
		var life := float(mark.life) / 1.5
		draw_circle(to_local(mark.point), 18.0 + (1.0 - life) * 10.0, Color(1, 0.35, 0.05, 0.35 * life))
	for lane in lanes:
		var local := Rect2(to_local(lane.position), lane.size)
		var progress := 1.0 - state_time / maxf(0.1, state_total)
		draw_rect(local, Color(1, 0.28, 0.05, 0.16 + 0.2 * progress))
		draw_rect(local, Color(1, 0.72, 0.3, 0.8), false, 2.0)
	if boss_state == "breath":
		var progress := 1.0 - state_time / maxf(0.1, state_total)
		var current := lerpf(breath_from, breath_to, progress)
		draw_colored_polygon(PackedVector2Array([
			Vector2.ZERO,
			Vector2.from_angle(current - 0.22) * 300.0,
			Vector2.from_angle(current + 0.22) * 300.0
		]), Color(1, 0.45, 0.08, 0.28))
	var art = preload("res://scripts/cinder_art.gd")
	var open_heart := boss_state in ["exposed", "uproot"]
	var frame := 3 if hp <= 0 else (0 if boss_state == "dormant" else (2 if open_heart else 1))
	var pulse := sin(animation_time * (7.0 if open_heart else 2.0))
	var gait := sin(animation_time * 10.0) * 3.5 if boss_state == "uproot" else 0.0
	draw_circle(Vector2.ZERO,48,Color(0.03,0.015,0.01,0.55))
	if hp > 0:
		draw_circle(Vector2(0,-12),38 + pulse*4,Color(1,0.3,0.06,0.12 if open_heart else 0.05))
	draw_set_transform(Vector2(gait, -absf(gait)),gait*0.008,Vector2(1.0+pulse*0.015,1.0-pulse*0.012))
	art.paint(self,art.creature(2,frame),Vector2.ZERO,Vector2(172,206),Color(1.7,1.5,1.2) if flash>0 else Color.WHITE,0.82)
	draw_set_transform(Vector2.ZERO)
	if hp > 0:
		draw_vitals(-192)
