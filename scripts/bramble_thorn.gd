extends Node2D
## A fast, readable Bramble Crown projectile with a short leaf trail.
var velocity := Vector2.RIGHT * 380.0
var damage := 20
var lifetime := 1.8
var target: Node2D
var trail: Array[Vector2] = []

func _ready() -> void:
	add_to_group("thornveil_hazards")

func _physics_process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	var next := global_position + velocity * delta
	var ray := PhysicsRayQueryParameters2D.create(global_position, next, 1)
	if not get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
		queue_free()
		return
	trail.push_front(position)
	if trail.size() > 6:
		trail.pop_back()
	global_position = next
	z_index = int(position.y) + 2
	if is_instance_valid(target) and target.hp > 0 and global_position.distance_to(target.global_position) <= 24.0:
		target.take_damage(damage)
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	for index in range(trail.size() - 1):
		draw_line(to_local(trail[index]), to_local(trail[index + 1]), Color(0.4, 0.75, 0.2, 0.3 - index * 0.035), 3.0, true)
	draw_set_transform(Vector2.ZERO, velocity.angle(), Vector2.ONE)
	draw_line(Vector2(-14, 0), Vector2(10, 0), Color("4d642a"), 4.0, true)
	draw_colored_polygon(PackedVector2Array([Vector2(15, 0), Vector2(4, -7), Vector2(6, 0), Vector2(4, 7)]), Color("9ad64f"))
	draw_line(Vector2(-8, 0), Vector2(-15, -7), Color("718f3b"), 2.0, true)
	draw_line(Vector2(-8, 0), Vector2(-15, 7), Color("718f3b"), 2.0, true)
	draw_set_transform(Vector2.ZERO)
