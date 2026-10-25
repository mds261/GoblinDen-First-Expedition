extends Node2D
const Art = preload("res://scripts/cinder_art.gd")
var kind := 0
var box := Vector2(100, 140)
var time := 0.0
var orchard: Node2D

func _ready() -> void:
	z_index = int(position.y)

func _process(delta: float) -> void:
	time += delta
	queue_redraw()

func _draw() -> void:
	var tint := Color.WHITE
	if kind == 3 and orchard != null and orchard.cache_taken:
		tint = Color(0.38, 0.36, 0.34)
	draw_set_transform(Vector2.ZERO, sin(time * 1.2 + position.x) * 0.008 if kind == 0 else 0.0)
	Art.paint(self, Art.prop(kind), Vector2.ZERO, box, tint)
	draw_set_transform(Vector2.ZERO)
	if kind == 3 and (orchard == null or not orchard.cache_taken):
		for i in range(4):
			var phase := fposmod(time * 0.5 + float(i) * 0.25, 1.0)
			draw_circle(Vector2(sin(float(i) * 2.3) * 18, -10 - phase * 35), 1.6, Color(1, 0.78, 0.35, sin(phase * PI)))
