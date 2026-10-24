extends RefCounted
## Shared painted chrome for the trial menus, prompts, and cards.
const PALE := Color("f3e6c8")
const GOLD := Color("e2c07a")

static func panel(translucent: bool = false, margin: int = 20) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.055, 0.045, 0.78 if translucent else 0.96)
	style.border_color = Color(0.64, 0.51, 0.32, 0.95)
	style.set_border_width_all(1)
	style.border_width_top = 2
	style.set_corner_radius_all(6)
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 16
	style.set_content_margin_all(margin)
	return style

static func card(selected: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.16, 0.12, 0.94) if selected else Color(0.05, 0.075, 0.065, 0.9)
	style.border_color = GOLD if selected else Color(0.42, 0.35, 0.24, 0.85)
	style.set_border_width_all(2 if selected else 1)
	style.set_corner_radius_all(5)
	style.set_content_margin_all(10)
	return style

static func prompt() -> StyleBoxFlat:
	var style := panel(false)
	style.shadow_size = 8
	style.set_content_margin_all(12)
	style.content_margin_left = 16
	style.content_margin_right = 16
	return style

static func dress(button: Button) -> void:
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", PALE)
	button.add_theme_color_override("font_hover_color", Color("ffe7b0"))
	button.add_theme_color_override("font_pressed_color", GOLD)
	button.add_theme_color_override("font_disabled_color", Color("7d8478"))
	button.add_theme_stylebox_override("normal", _button_box(Color("14211b"), Color("8d7348")))
	button.add_theme_stylebox_override("hover", _button_box(Color("1d3026"), GOLD))
	button.add_theme_stylebox_override("pressed", _button_box(Color("0c1612"), Color("c6a56a")))
	button.add_theme_stylebox_override("disabled", _button_box(Color("121816"), Color("4d4638")))
	button.add_theme_stylebox_override("focus", _button_box(Color("1d3026"), GOLD))

static func _button_box(bg: Color, edge: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = edge
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	return style
