extends "res://scripts/cinder_actor.gd"
## Three area-specific hunter roles: root shield, antler bow, and predictive root magic.
const Layout = preload("res://scripts/thornveil_layout.gd")
const Art = preload("res://scripts/thornveil_art.gd")
const Thorn = preload("res://scripts/bramble_thorn.gd")
const Root = preload("res://scripts/bramble_root.gd")
var guard_kind := "warden"
var attack_state := "idle"
var attack_time := 0.0
var attack_total := 0.0
var attack_fired := false
var dungeon_awareness: RefCounted

func configure(id: String, kind: String) -> void:
	guard_kind = kind
	configure_from_catalog(id)
	role = "thornveil_" + kind

func _ready() -> void:
	use_radius(18.0)
	target = get_tree().get_first_node_in_group("player")
	add_to_group("enemies")
	collision_layer = 2
	collision_mask = 3

func reset_encounter_motion() -> void:
	super.reset_encounter_motion()
	attack_state = "idle"
	attack_time = 0.0
	attack_fired = false

func show_floating_text(words: String) -> void:
	status_text = words
	status_text_time = 0.65

func take_damage(amount: int, direction: Vector2 = Vector2.ZERO) -> void:
	if dungeon_awareness != null and hp > 0:
		dungeon_awareness.alert(self)
	super.take_damage(amount, direction)

func _physics_process(delta: float) -> void:
	tick_status(delta)
	velocity = Vector2.ZERO
	if hp <= 0:
		queue_redraw()
		return
	if not is_instance_valid(target) or target.hp <= 0:
		target = get_tree().get_first_node_in_group("player")
	if not is_instance_valid(target):
		return
	if dungeon_awareness != null and not dungeon_awareness.step(self, delta):
		slide(delta)
		queue_redraw()
		return
	if stun_timer > 0.0:
		attack_state = "idle"
		attack_time = 0.0
		slide(delta)
		queue_redraw()
		return
	if attack_state != "idle":
		attack_time -= delta
		var progress := 1.0 - attack_time / maxf(0.1, attack_total)
		if not attack_fired and progress >= 0.58:
			attack_fired = true
			_release_attack()
		if attack_time <= 0.0:
			attack_state = "idle"
			cooldown = {"warden": 1.15, "poacher": 1.75, "seer": 2.2}.get(guard_kind, 1.5)
	else:
		_choose_action()
	slide(delta)
	queue_redraw()

func _choose_action() -> void:
	var offset := target.position - position
	var distance := offset.length()
	if guard_kind == "warden":
		if cooldown <= 0.0 and distance <= 66.0:
			_begin_attack("ROOT SHIELD — DODGE", 0.52)
		elif distance > 54.0:
			velocity = _route_to(target.position) * speed
	elif guard_kind == "poacher":
		if cooldown <= 0.0 and distance <= 330.0:
			_begin_attack("THORN SHOT", 0.62)
		elif distance < 145.0:
			velocity = -offset.normalized() * speed * 0.8
		elif distance > 255.0:
			velocity = _route_to(target.position) * speed * 0.75
	else:
		if cooldown <= 0.0 and distance <= 300.0:
			_begin_attack("ROOT MARK — MOVE", 0.84)
		elif distance < 125.0:
			velocity = -offset.normalized() * speed * 0.72
		elif distance > 235.0:
			velocity = _route_to(target.position) * speed * 0.62

func _begin_attack(label: String, duration: float) -> void:
	attack_state = "windup"
	attack_time = duration
	attack_total = duration
	attack_fired = false
	windup = duration
	status_text = label
	status_text_time = duration

func _release_attack() -> void:
	windup = 0.0
	if guard_kind == "warden":
		if position.distance_to(target.position) <= 78.0:
			target.take_damage(damage + 5)
		position += position.direction_to(target.position) * 18.0
		return
	if guard_kind == "poacher":
		var heading := position.direction_to(target.position)
		var thorn := Thorn.new()
		thorn.position = position + heading * 28.0
		thorn.velocity = heading * 390.0
		thorn.damage = damage
		thorn.target = target
		get_parent().add_child(thorn)
		get_tree().call_group("game_audio", "play_sfx", "thorn_volley")
		return
	var root := Root.new()
	root.position = _root_point()
	root.target = target
	root.damage = damage
	root.warning = 0.72
	root.active_time = 0.35
	root.radius = 46.0
	get_parent().add_child(root)
	get_tree().call_group("game_audio", "play_sfx", "thorn_root")

func _room_id() -> int:
	var game = get_parent().get_parent()
	return int(game.current_room) if game != null else Layout.APPROACH

func _root_point() -> Vector2:
	var point: Vector2 = (target.position + target.velocity * 0.28).clamp(Vector2(64, 64), Layout.SIZE - Vector2(64, 64))
	return point if Layout.walkable(point, _room_id()) else target.position

func _draw() -> void:
	var frame := 3 if hp <= 0 else (2 if attack_state != "idle" else (1 if velocity.length() > 8.0 else 0))
	var flip := is_instance_valid(target) and target.position.x < position.x
	Art.paint_guard(self, guard_kind, frame, flash > 0.0, flip)
	if hp > 0:
		draw_vitals(-112)
