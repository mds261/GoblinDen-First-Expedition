extends Node2D
## Optional heat-crack in the south of Thornwood Hollow. The eastern trail does not pass over it.
var time := 0.0

func _process(delta: float) -> void:
	time += delta
	queue_redraw()

func _draw() -> void:
	var art = preload("res://scripts/cinder_art.gd")
	art.paint(self,art.prop(4),Vector2(0,12),Vector2(120,100))
	for i in range(9):
		var phase := fposmod(time*0.35+float(i)*0.17,1.0)
		draw_circle(Vector2(sin(float(i)*2.1+phase)*24,-phase*55),1.5,Color(1,0.6,0.2,sin(phase*PI)*0.8))