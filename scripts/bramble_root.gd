extends Node2D
## Telegraphs a root eruption, then strikes once. Used by the Crown's snare pattern.
var target: Node2D
var damage := 26
var warning := 0.85
var active_time := 0.42
var radius := 52.0
var age := 0.0
var hit := false

func _ready() -> void:
	z_index = int(position.y) + 1
	add_to_group("thornveil_hazards")

func _physics_process(delta: float) -> void:
	age += delta
	if age >= warning and age < warning + active_time and not hit and is_instance_valid(target) and target.hp > 0:
		if global_position.distance_to(target.global_position) <= radius:
			target.take_damage(damage)
			hit = true
	if age >= warning + active_time:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	if age < warning:
		var progress := clampf(age / warning, 0.0, 1.0)
		draw_circle(Vector2.ZERO, radius, Color(0.25, 0.5, 0.12, 0.08 + progress * 0.12))
		draw_arc(Vector2.ZERO, radius * (1.0 - progress * 0.22), 0, TAU, 28, Color(0.65, 0.95, 0.35, 0.35 + progress * 0.45), 3.0, true)
		for index in range(8):
			var angle := float(index) / 8.0 * TAU
			draw_line(Vector2.from_angle(angle) * 12.0, Vector2.from_angle(angle) * (18.0 + progress * 20.0), Color(0.32, 0.55, 0.18, 0.5), 3.0, true)
		return
	var burst := 1.0 - clampf((age - warning) / active_time, 0.0, 1.0)
	draw_circle(Vector2.ZERO, radius, Color(0.38, 0.7, 0.18, 0.12 * burst))
	for index in range(12):
		var angle := float(index) / 12.0 * TAU
		var length := 34.0 + 30.0 * burst
		draw_line(Vector2.from_angle(angle) * 8.0, Vector2.from_angle(angle) * length, Color(0.23, 0.34, 0.12, 0.9 * burst), 6.0, true)
