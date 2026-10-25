extends "res://scripts/cinder_actor.gd"
## Antlered grove tyrant. Charges, rakes, and bursts thorns. Bark holds until it commits.
const Layout = preload("res://scripts/thornveil_layout.gd")
const Thorn = preload("res://scripts/bramble_thorn.gd")
const Root = preload("res://scripts/bramble_root.gd")
var boss_state := "dormant"
var state_time := 0.0
var state_total := 1.0
var attack_index := 0
var phase_two := false
var gore_from := Vector2.ZERO
var gore_to := Vector2.ZERO
var gore_hit := false
var rake_facing := 0.0
var rake_hit := false
var burst_hit := false
var walk_goal := Vector2.ZERO
var volley_fired := false

func reset_abandoned_encounter() -> void:
	if hp <= 0 or boss_state == "dormant":
		return
	hp = max_hp
	position = Layout.BOSS
	boss_state = "dormant"
	state_time = 0.0
	attack_index = 0
	phase_two = false
	windup = 0.0
	stun_timer = 0.0
	slow_timer = 0.0
	bleed_dps = 0
	poison_dps = 0
	dot_timer = 0.0
	flash = 0.0
	velocity = Vector2.ZERO
	knockback = Vector2.ZERO
	_clear_adds()
	_clear_hazards()
	remove_from_group("enemies")
	collision_layer = 0
	collision_mask = 0
	queue_redraw()

func _ready() -> void:
	configure_from_catalog("bramble_crown")
	death_burst = "boss"
	role = "bramble_crown"
	use_radius(36.0)
	target = get_tree().get_first_node_in_group("player")
	collision_layer = 0
	collision_mask = 0

func awaken() -> void:
	if boss_state != "dormant":
		return
	add_to_group("enemies")
	collision_layer = 2
	collision_mask = 1
	boss_state = "wake"
	state_time = 1.1
	state_total = state_time
	get_tree().call_group("game_audio", "play_sfx", "boss")
	status_text = "THE CROWN STIRS"
	status_text_time = 1.1
	var game = get_parent().get_parent()
	if game != null and game.has_method("show_notice"):
		game.show_notice("The Bramble Crown lowers its antlers. Sidestep the gore, then cut the hide.")

func take_damage(amount: int, direction: Vector2 = Vector2.ZERO) -> void:
	if boss_state == "dormant" or hp <= 0:
		return
	var dealt := amount
	if boss_state in ["wake", "gore", "rake", "burst", "root_snare", "volley", "call"]:
		var game = get_parent().get_parent()
		var cracked: bool = game != null and game.rpg != null and game.rpg.thornveil.collar_cracked()
		dealt = maxi(1, int(round(amount * (0.65 if cracked else 0.45))))
		status_text = "COLLAR CRACKED" if cracked else "BARK"
		status_text_time = 0.3
	super.take_damage(dealt, direction * 0.25)
	if hp > 0 and hp <= int(max_hp * 0.55) and not phase_two:
		phase_two = true
		status_text = "THE ANTLERS SPLIT"
		status_text_time = 1.0
	if hp <= 0:
		boss_state = "dying"
		_clear_adds()
		_clear_hazards()

func _physics_process(delta: float) -> void:
	tick_status(delta)
	velocity = Vector2.ZERO
	if not is_instance_valid(target):
		queue_redraw()
		return
	if boss_state == "dormant":
		if hp > 0 and Layout.ARENA.has_point(target.position):
			awaken()
		queue_redraw()
		return
	if hp <= 0:
		queue_redraw()
		return
	if stun_timer > 0.0:
		boss_state = "stagger"
		state_time = maxf(state_time, 0.55)
		windup = 0.0
	state_time -= delta
	match boss_state:
		"wake":
			if state_time <= 0.0:
				_begin_prowl()
		"prowl":
			_prowl_tick()
			if state_time <= 0.0:
				_next_attack()
		"gore":
			windup = maxf(0.0, state_time)
			if state_time <= 0.0:
				_begin_gore_dash()
		"gore_dash":
			_gore_dash_tick(delta)
		"rake":
			windup = maxf(0.0, state_time)
			_rake_tick()
			if state_time <= 0.0:
				_begin_stagger(0.85 if phase_two else 1.05)
		"burst":
			windup = maxf(0.0, state_time)
			_burst_tick()
			if state_time <= 0.0:
				_begin_stagger(0.7 if phase_two else 0.9)
		"root_snare":
			windup = maxf(0.0, state_time)
			if state_time <= 0.0:
				_begin_stagger(0.55 if phase_two else 0.75)
		"volley":
			windup = maxf(0.0, state_time)
			if not volley_fired and state_time <= state_total * 0.42:
				volley_fired = true
				_spawn_volley()
			if state_time <= 0.0:
				_begin_stagger(0.48 if phase_two else 0.65)
		"call":
			if state_time <= 0.0:
				_spawn_adds()
				_begin_stagger(0.6)
		"stagger":
			if state_time <= 0.0:
				_begin_prowl()
	slide(delta)
	position = position.clamp(Layout.ARENA.position + Vector2(70, 70), Layout.ARENA.end - Vector2(70, 70))
	queue_redraw()

func _next_attack() -> void:
	attack_index += 1
	var kind := attack_index % (6 if phase_two else 5)
	if kind == 1:
		_begin_gore()
	elif kind == 2:
		_begin_rake()
	elif kind == 3:
		_begin_root_snare()
	elif kind == 4:
		_begin_volley()
	elif kind == 5:
		_begin_call()
	else:
		_begin_burst()

func _begin_prowl() -> void:
	boss_state = "prowl"
	state_time = 0.85 if phase_two else 1.15
	state_total = state_time
	windup = 0.0
	walk_goal = target.position if is_instance_valid(target) else position

func _prowl_tick() -> void:
	if not is_instance_valid(target):
		return
	velocity = _route_to(target.position) * speed * 0.55
	if position.distance_to(target.position) < 48.0 and cooldown <= 0.0:
		target.take_damage(maxi(8, damage - 18))
		cooldown = 0.9

func _begin_gore() -> void:
	boss_state = "gore"
	state_time = 0.7 if phase_two else 0.9
	state_total = state_time
	windup = state_time
	gore_from = position
	gore_to = target.position if is_instance_valid(target) else position + Vector2(220, 0)
	var heading := gore_from.direction_to(gore_to)
	if heading.length_squared() < 0.01:
		heading = Vector2.RIGHT
	gore_to = gore_from + heading * 280.0
	gore_hit = false
	status_text = "GORE — SIDESTEP"
	status_text_time = state_time

func _begin_gore_dash() -> void:
	boss_state = "gore_dash"
	state_time = 0.38
	state_total = state_time
	get_tree().call_group("game_audio", "play_sfx", "boss")

func _gore_dash_tick(_delta: float) -> void:
	var heading := gore_from.direction_to(gore_to)
	velocity = heading * (520.0 if phase_two else 430.0)
	if is_instance_valid(target) and not gore_hit:
		var offset := target.position - position
		var along := heading.dot(offset)
		var side := absf(heading.orthogonal().dot(offset))
		if along > -20.0 and along < 90.0 and side < 36.0:
			target.take_damage(damage + 6)
			gore_hit = true
	if state_time <= 0.0 or position.distance_to(gore_to) < 24.0:
		_begin_stagger(0.75 if phase_two else 0.95)

func _begin_rake() -> void:
	boss_state = "rake"
	state_time = 0.8 if phase_two else 1.0
	state_total = state_time
	windup = state_time
	rake_facing = position.direction_to(target.position).angle() if is_instance_valid(target) else 0.0
	rake_hit = false
	status_text = "RAKE — GET BEHIND"
	status_text_time = state_time

func _rake_tick() -> void:
	if rake_hit or not is_instance_valid(target):
		return
	var progress := 1.0 - state_time / maxf(0.1, state_total)
	if progress < 0.45:
		return
	var offset := target.position - position
	if offset.length() > 210.0 or absf(wrapf(offset.angle() - rake_facing, -PI, PI)) > 0.72:
		return
	target.take_damage(damage)
	rake_hit = true

func _begin_burst() -> void:
	boss_state = "burst"
	state_time = 0.95 if phase_two else 1.15
	state_total = state_time
	windup = state_time
	burst_hit = false
	status_text = "CROWN BURST — STEP IN"
	status_text_time = state_time

func _burst_tick() -> void:
	if burst_hit or not is_instance_valid(target):
		return
	var progress := 1.0 - state_time / maxf(0.1, state_total)
	if progress < 0.55:
		return
	var radius := lerpf(70.0, 210.0, clampf((progress - 0.55) / 0.45, 0.0, 1.0))
	var dist := position.distance_to(target.position)
	if dist > 48.0 and dist < radius:
		target.take_damage(damage + 2)
		burst_hit = true

func _begin_call() -> void:
	boss_state = "call"
	state_time = 0.55
	state_total = state_time
	status_text = "THE THICKET ANSWERS"
	status_text_time = 0.7

func _begin_root_snare() -> void:
	boss_state = "root_snare"
	state_time = 1.3
	state_total = state_time
	windup = state_time
	status_text = "ROOT SNARE — KEEP MOVING"
	status_text_time = 1.1
	get_tree().call_group("game_audio", "play_sfx", "thorn_root")
	if not is_instance_valid(target):
		return
	var heading := position.direction_to(target.position)
	if heading.length_squared() < 0.01:
		heading = Vector2.RIGHT
	var side := heading.orthogonal()
	var points: Array[Vector2] = [target.position, target.position + side * 92.0, target.position - side * 92.0]
	if phase_two:
		points.append(target.position + heading * 105.0)
		points.append(target.position - heading * 82.0)
	for point in points:
		var root := Root.new()
		root.position = point.clamp(Layout.ARENA.position + Vector2(70, 70), Layout.ARENA.end - Vector2(70, 70))
		root.target = target
		root.damage = 30 if phase_two else 24
		get_parent().add_child(root)

func _begin_volley() -> void:
	boss_state = "volley"
	state_time = 0.9 if phase_two else 1.05
	state_total = state_time
	windup = state_time
	volley_fired = false
	status_text = "THORN VOLLEY — CUT SIDEWAYS"
	status_text_time = state_time

func _spawn_volley() -> void:
	if not is_instance_valid(target):
		return
	get_tree().call_group("game_audio", "play_sfx", "thorn_volley")
	var heading := position.direction_to(target.position)
	if heading.length_squared() < 0.01:
		heading = Vector2.RIGHT
	var count := 7 if phase_two else 5
	var spread := 0.16 if phase_two else 0.19
	for index in range(count):
		var thorn := Thorn.new()
		thorn.position = position + heading * 42.0
		thorn.velocity = heading.rotated((float(index) - float(count - 1) * 0.5) * spread) * (430.0 if phase_two else 370.0)
		thorn.damage = 24 if phase_two else 19
		thorn.target = target
		get_parent().add_child(thorn)

func _spawn_adds() -> void:
	var room := get_parent()
	if room == null:
		return
	for offset in [Vector2(-160, 80), Vector2(150, -70)]:
		var spawn: Vector2 = (position + offset).clamp(Layout.ARENA.position + Vector2(80, 80), Layout.ARENA.end - Vector2(80, 80))
		var add := preload("res://scripts/thornling.gd").new()
		add.position = spawn
		room.add_child(add)

func _clear_adds() -> void:
	var room := get_parent()
	if room == null:
		return
	for child in room.get_children():
		if child.get_script() == preload("res://scripts/thornling.gd") and child.hp > 0:
			child.take_damage(999)

func _clear_hazards() -> void:
	var room := get_parent()
	for hazard in get_tree().get_nodes_in_group("thornveil_hazards"):
		if is_instance_valid(hazard) and hazard.get_parent() == room:
			hazard.queue_free()

func _begin_stagger(duration: float) -> void:
	boss_state = "stagger"
	state_time = duration
	state_total = duration
	windup = 0.0
	status_text = "HIDE OPEN"
	status_text_time = duration

func _draw() -> void:
	if boss_state == "gore" or boss_state == "gore_dash":
		var local_to := to_local(gore_to)
		var warn := 0.16 if boss_state == "gore" else 0.32
		draw_line(Vector2.ZERO, local_to, Color(0.7, 0.95, 0.35, warn), 18.0, true)
	if boss_state == "rake":
		var points := PackedVector2Array([Vector2.ZERO])
		for i in range(7):
			points.append(Vector2.from_angle(rake_facing - 0.7 + float(i) * 0.23) * 200.0)
		draw_colored_polygon(points, Color(0.45, 0.8, 0.2, 0.22))
	if boss_state == "burst":
		var progress := 1.0 - state_time / maxf(0.1, state_total)
		var radius := lerpf(70.0, 210.0, clampf((progress - 0.2) / 0.8, 0.0, 1.0))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color(0.55, 0.95, 0.3, 0.7), 3.0, true)
		draw_circle(Vector2.ZERO, 46.0, Color(0.2, 0.55, 0.15, 0.16))
	if boss_state == "volley":
		var facing := position.direction_to(target.position).angle() if is_instance_valid(target) else 0.0
		for index in range(5):
			var angle := facing + (float(index) - 2.0) * 0.19
			draw_line(Vector2.from_angle(angle) * 45.0, Vector2.from_angle(angle) * 240.0, Color(0.55, 0.9, 0.28, 0.22), 3.0, true)
	if phase_two and hp > 0:
		draw_arc(Vector2.ZERO, 52.0 + sin(animation_time * 5.0) * 4.0, 0, TAU, 28, Color(0.48, 0.9, 0.24, 0.36), 3.0, true)
	var art = preload("res://scripts/thornveil_art.gd")
	draw_circle(Vector2.ZERO, 40, Color(0.03, 0.02, 0.015, 0.5))
	art.paint_creature(self, "crown", _sprite_frame(), flash > 0.0, hp <= 0, _sprite_flip())
	if hp > 0:
		draw_vitals(-168)

func _sprite_frame() -> Vector2i:
	var cadence := int(animation_time * (8.0 if phase_two else 6.0)) % 4
	if hp <= 0:
		return Vector2i(3, 4)
	match boss_state:
		"dormant": return Vector2i(2, 4)
		"wake": return Vector2i(cadence, 0)
		"prowl":
			if absf(velocity.x) > absf(velocity.y) * 0.75:
				return Vector2i(cadence, 2)
			return Vector2i(cadence, 1 if velocity.y < 0.0 else 0)
		"gore": return Vector2i(1, 3)
		"gore_dash": return Vector2i(cadence, 2)
		"rake": return Vector2i(clampi(1 + int((1.0 - state_time / maxf(0.1, state_total)) * 3.0), 1, 3), 3)
		"burst": return Vector2i(0, 3)
		"root_snare": return Vector2i(1, 3)
		"volley": return Vector2i(3, 3)
		"call": return Vector2i(3, 3)
		"stagger": return Vector2i(1, 4)
	return Vector2i(0, 0)

func _sprite_flip() -> bool:
	if boss_state == "prowl" and absf(velocity.x) > 1.0:
		return velocity.x < 0.0
	return is_instance_valid(target) and target.position.x < position.x
