extends Control
## Compact vitals, quiet location text, and only useful combat status.
var game: Node2D
var portraits: Dictionary = {}
var face: Font
const GOLD = Color("ad9360")
const PALE = Color("e9dec4")
const MUTED = Color("b4b7a4")
var clock := 0.0
var objective_label: Label
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	face = SystemFont.new()
	face.font_names = PackedStringArray(["Georgia", "DejaVu Serif", "serif"])
	objective_label = Label.new()
	objective_label.position = Vector2(372,62)
	objective_label.size = Vector2(324,42)
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_label.clip_text = true
	objective_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	objective_label.add_theme_font_size_override("font_size",13)
	objective_label.add_theme_color_override("font_color",MUTED)
	add_child(objective_label)
	for id in ["blade", "archer", "knight", "mage"]:
		portraits[id] = load("res://assets/goblin_class_%s.png" % id)
func _process(delta: float) -> void:
	clock += delta
	visible = not get_tree().paused
	objective_label.text = game.expedition.hud_objective_text() if game.get("expedition") != null and game.expedition.is_inside_tree() else game.objective.text
	queue_redraw()
func text_at(value: String, point: Vector2, size_px: int = 12, color: Color = PALE, width: float = -1, serif: bool = false) -> void:
	draw_string(face if serif else ThemeDB.fallback_font,point+Vector2(0,1),value,HORIZONTAL_ALIGNMENT_LEFT,width,size_px,Color(0,0,0,0.9))
	draw_string(face if serif else ThemeDB.fallback_font,point,value,HORIZONTAL_ALIGNMENT_LEFT,width,size_px,color)
func bar(at: Vector2, width: float, height: float, value: float, maximum: float, color: Color) -> void:
	draw_rect(Rect2(at-Vector2.ONE,Vector2(width+2,height+2)),GOLD.darkened(0.55))
	draw_rect(Rect2(at,Vector2(width,height)),Color("0c1110"))
	var fill := clampf(value/maxf(1,maximum),0,1)*width
	if fill > 0:
		draw_rect(Rect2(at,Vector2(fill,height)),color.darkened(0.15))
		draw_line(at,at+Vector2(fill,0),color.lightened(0.3),1)
func frame() -> StyleBoxFlat:
	return preload("res://trial/look.gd").hud_frame()
func ability(at: Vector2, key: String, title: String, detail: String, ready: bool) -> void:
	draw_style_box(frame(),Rect2(at,Vector2(58,43)))
	text_at(key,at+Vector2(8,15),11,GOLD)
	text_at(detail,at+Vector2(8,33),12,PALE if ready else MUTED)
	text_at(title,at+Vector2(1,-6),10,MUTED)
func vignette() -> void:
	var w := size.x
	var h := size.y
	if w < 32.0 or h < 32.0:
		return
	var hurt := 0.0
	if game.player.max_hp > 0 and game.player.hp > 0:
		var ratio := float(game.player.hp) / float(game.player.max_hp)
		if ratio < 0.34:
			hurt = (0.34 - ratio) / 0.34 * (0.45 + 0.55 * absf(sin(clock * 3.2)))
	for i in 12:
		var fade := float(12 - i) / 12.0
		var alpha := 0.045 * fade + hurt * 0.11 * fade
		var band := 11.0
		var tint := Color(0.28, 0.02, 0.02, alpha) if hurt > 0.05 else Color(0, 0, 0, alpha)
		draw_rect(Rect2(0, i * band, w, band), tint)
		draw_rect(Rect2(0, h - (i + 1) * band, w, band), tint)
		draw_rect(Rect2(i * band * 0.7, 0, band, h), Color(0, 0, 0, alpha * 0.65))
		draw_rect(Rect2(w - (i + 1) * band * 0.7, 0, band, h), Color(0, 0, 0, alpha * 0.65))
func _draw() -> void:
	if game == null or not is_instance_valid(game.player):
		return
	vignette()
	var p = game.player
	var r = game.rpg
	draw_style_box(frame(),Rect2(20,18,318,96))
	var center := Vector2(57,58)
	draw_circle(center,28,Color("111a14"))
	draw_arc(center,28,0,TAU,48,GOLD,1,true)
	var portrait: Texture2D = portraits.get(p.class_id)
	if portrait != null:
		draw_texture_rect(portrait,Rect2(33,27,48,56),false)
	text_at("%s  ·  %d" % [p.get_class_title(),p.level],Vector2(96,37),14,PALE,220,true)
	bar(Vector2(96,47),214,13,p.hp,p.max_hp,Color("9e453d"))
	text_at("%d / %d" % [p.hp,p.max_hp],Vector2(168,58),10)
	if r != null:
		bar(Vector2(96,67),103,6,r.mana,r.max_mana(),Color("41768b"))
		bar(Vector2(207,67),103,6,r.stamina,100,Color("bd793d") if r.stamina < p.DODGE_STAMINA_COST else Color("768951"))
		text_at("Mana %d" % r.mana,Vector2(96,87),10,MUTED)
		text_at("STA %d / 100" % r.stamina,Vector2(207,87),10,Color("efbb77") if r.stamina < p.DODGE_STAMINA_COST else MUTED)
	bar(Vector2(96,100),214,3,p.xp,p.xp_to_next,Color("aa8b50"))
	text_at("Lv %d" % p.level,Vector2(43,108),11,GOLD)
	var place: String = str(game.room_label.text).to_upper()
	draw_style_box(frame(),Rect2(354,18,360,96))
	text_at(place,Vector2(372,44),18,PALE,324,true)
	draw_line(Vector2(372,54),Vector2(696,54),Color(0.61,0.52,0.33,0.55),1)
	var special_ready: bool = p.special_cooldown <= 0 and (r == null or r.stamina >= p.SPECIAL_STAMINA_COST)
	var dodge_ready: bool = p.dodge_cooldown <= 0 and (r == null or r.stamina >= p.DODGE_STAMINA_COST)
	ability(Vector2(24,653),"Q","Special","%.1fs" % p.special_cooldown if p.special_cooldown > 0 else ("Ready" if special_ready else "No STA"),special_ready)
	ability(Vector2(90,653),"Shift","Dodge","%.1fs" % p.dodge_cooldown if p.dodge_cooldown > 0 else ("Ready" if dodge_ready else "No STA"),dodge_ready)
	var potion_left: float = float(r.cooldowns.get("potion_use",0)) if r != null else 0.0
	ability(Vector2(156,653),"F","Potion","%.1fs" % potion_left if potion_left > 0 else str(game.potions),game.potions>0 and potion_left<=0)
