extends Node2D
## Northern hollow marker. The eastern trail and southern heat-crack stay where they are.
const Art = preload("res://scripts/thornveil_art.gd")
var time := 0.0

func _process(delta: float) -> void:
	time += delta
	queue_redraw()

func _draw() -> void:
	Art.paint_prop(self, 4, Vector2(0, 48), 0.82)
	var glow := 0.35 + 0.2 * sin(time * 3.0)
	draw_circle(Vector2(0, -10), 13.0, Color(0.45, 0.85, 0.3, glow))
	draw_arc(Vector2(0, -10), 22.0 + sin(time * 2.0) * 3.0, 0, TAU, 24, Color(0.65, 1.0, 0.4, glow * 0.7), 2.0, true)
