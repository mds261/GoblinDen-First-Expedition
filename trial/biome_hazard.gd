extends Node2D
## Reused, telegraphed terrain effect; never blocks the navigation mesh.
var director: Node2D
var kind := "poison"
var time := 0.0
var cooldown := 0.0
var room := 6
func _ready() -> void:
	add_to_group("expedition_hazards")
	z_index = 1
func _process(delta: float) -> void:
	if director.game.current_room!=room or director.active.is_empty() or director.active.get("claimed",false): return
	time += delta
	cooldown = maxf(0,cooldown-delta)
	var player = director.game.player
	var armed := fmod(time,3.5)>2.0
	if armed and cooldown<=0 and player.hp>0 and player.position.distance_to(position)<42:
		cooldown = 1.0
		var world = director.living
		var damage := int((8 if kind=="fire" else 5)*float(director.active.get("difficulty",1.0)))
		player.take_damage(maxi(1,int(damage*(0.5 if world.ward else 1.0))))
		if kind=="hex": director.game.rpg.mana = maxf(0,director.game.rpg.mana-3)
	queue_redraw()
func _draw() -> void:
	var color := Color("b6c873") if kind=="poison" else (Color("e4a17a") if kind=="fire" else (Color("b3a8dc") if kind=="hex" else Color("c7b89a")))
	var armed := fmod(time,3.5)>2.0
	var pulse := 1.0 if director.living.reduced_effects else 0.8+0.2*sin(time*3)
	draw_circle(Vector2.ZERO,42,Color(color,0.17 if armed else 0.06))
	draw_arc(Vector2.ZERO,42,0,TAU,40,Color(color,0.9 if armed else 0.4),2,true)
	for i in range(5):
		var point := Vector2.from_angle(i*TAU/5)*24
		draw_circle(point, (6 if armed else 3)*pulse,color)
	draw_string(ThemeDB.fallback_font,Vector2(-48,-50),"FIRE" if kind=="fire" else ("FALLING ROCK" if kind=="rock" else ("HEX WARD" if kind=="hex" else "POISON VENT")),HORIZONTAL_ALIGNMENT_LEFT,-1,12,color)
