extends CanvasLayer
const Data = preload("res://trial/contracts.gd")
const GOLD := Color("d9b979")
const PALE := Color("eee6cf")
const MUTED := Color("aabcae")
var director: Node2D
var overlay: ColorRect
var panel: PanelContainer
var body: VBoxContainer
var title: Label
var subtitle: Label
var banner: VBoxContainer
var banner_time := 0.0
var journal_button: Button
var mode := ""
var cover: TextureRect
var portraits: Dictionary = {}
var letter_top: ColorRect
var letter_bot: ColorRect

func _ready() -> void:
	layer = 24
	process_mode = Node.PROCESS_MODE_ALWAYS
	for id in ["blade","archer","knight","mage"]:
		portraits[id] = load("res://assets/goblin_class_%s.png"%id)
	overlay = ColorRect.new()
	overlay.color = Color(0.008,0.018,0.018,0.86)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	cover = TextureRect.new()
	cover.texture = load("res://assets/first_expedition_cover.png")
	cover.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cover.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(cover)
	var veil := ColorRect.new()
	veil.color = Color(0.02,0.04,0.03,0.28)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cover.add_child(veil)
	panel = PanelContainer.new()
	panel.position = Vector2(176,90)
	panel.size = Vector2(800,540)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("101f1b")
	style.border_color = Color("89734c")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(30)
	panel.add_theme_stylebox_override("panel",style)
	overlay.add_child(panel)
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation",14)
	panel.add_child(body)
	overlay.hide()
	letter_top = ColorRect.new()
	letter_top.color = Color(0.01,0.02,0.02,0.82)
	letter_top.position = Vector2(0,-80)
	letter_top.size = Vector2(1152,70)
	letter_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(letter_top)
	letter_bot = ColorRect.new()
	letter_bot.color = Color(0.01,0.02,0.02,0.82)
	letter_bot.position = Vector2(0,720)
	letter_bot.size = Vector2(1152,70)
	letter_bot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(letter_bot)
	banner = VBoxContainer.new()
	banner.position = Vector2(226,215)
	banner.size.x = 700
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(banner)
	title = Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size",30)
	title.add_theme_color_override("font_color",GOLD)
	title.add_theme_color_override("font_shadow_color",Color.BLACK)
	title.add_theme_constant_override("shadow_offset_y",2)
	banner.add_child(title)
	subtitle = Label.new()
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size",15)
	subtitle.add_theme_color_override("font_shadow_color",Color.BLACK)
	subtitle.add_theme_constant_override("shadow_offset_y",2)
	banner.add_child(subtitle)
	journal_button = Button.new()
	journal_button.text = "Field journal [J]"
	journal_button.position = Vector2(918,219)
	journal_button.size = Vector2(200,32)
	journal_button.pressed.connect(func(): open("journal"))
	add_child(journal_button)

func line(text: String, size_px: int = 16, color: Color = PALE, parent: Node = null) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",size_px)
	label.add_theme_color_override("font_color",color)
	(parent if parent!=null else body).add_child(label)
	return label

func button(text: String, action: Callable, parent: Node = null, disabled: bool = false) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size.y = 40
	b.add_theme_font_size_override("font_size",15)
	b.pressed.connect(action)
	b.disabled = disabled
	(parent if parent!=null else body).add_child(b)
	return b

func open(page: String = "board") -> void:
	if not director.initialized:
		return
	mode = page
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	panel.size = Vector2(800,0)
	cover.visible = page=="welcome"
	panel.position = Vector2(40,94) if page=="welcome" else Vector2(176,90)
	panel.size.x = 510 if page=="welcome" else 800
	var panel_style := panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	panel_style.bg_color = Color(0.025,0.055,0.04,0.72) if page=="welcome" else Color("101f1b")
	panel_style.border_color = Color(0.54,0.45,0.30,0.4) if page=="welcome" else Color("89734c")
	panel.add_theme_stylebox_override("panel",panel_style)
	var game = director.game
	var active: Dictionary = director.active
	line("A   G O B L I N ' S   J O U R N E Y" if page=="welcome" else "G O B L I N D E N   /   F I R S T   E X P E D I T I O N",12,GOLD)
	match page:
		"welcome":
			line("GoblinDen",54)
			line("FIRST EXPEDITION",25,GOLD)
			line("A fire worth coming home to.",21)
			line("The humans have gone. Our supplies went with them. Follow the Thornwood trails, find what the tribe lost, and come back alive.",17,MUTED)
			line("Choose the goblin you will be.",17,GOLD)
			var rites := GridContainer.new()
			rites.columns = 2
			rites.add_theme_constant_override("h_separation",10)
			rites.add_theme_constant_override("v_separation",8)
			body.add_child(rites)
			for rite in Data.RITES:
				var chosen: bool = director.rite_id==rite.id
				var card := VBoxContainer.new()
				card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				rites.add_child(card)
				var portrait := TextureRect.new()
				portrait.texture = portraits.get(rite.id)
				portrait.custom_minimum_size = Vector2(72,80)
				portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
				card.add_child(portrait)
				line(rite.title.to_upper(),13,GOLD if chosen else PALE,card)
				var blurb := line(rite.line,12,MUTED,card)
				blurb.custom_minimum_size.y = 52
				button("Take the %s rite"%rite.title, take_rite.bind(rite.id), card)
			line("WASD  Move   ·   E  Interact   ·   J  Field journal\nSpeak to Moss beside the resting fire.",14,MUTED)
			button("Wake by the fire",func(): director.welcomed = true; close(); game._auto_save(); announce("HEARTH HALL","Find Moss beside the fire · Approach and press E"))
		"board":
			line("Moss's expedition board",32)
			line("“Bring back what you can. Leave enough strength for the road home.”",17,MUTED)
			if not active.is_empty() and not active.claimed:
				line(director.objective_text(),22,GOLD)
				line("Your contract cargo is secured. You can finish the journey, explore for more, or return early and keep your ordinary loot.")
				button("Deliver the supplies · Claim reward",director.claim,null,not active.ready or not director.home())
				button("End this expedition early",func(): open("abandon"),null,not director.home())
			else:
				var cards := HBoxContainer.new()
				cards.add_theme_constant_override("separation",14)
				body.add_child(cards)
				for i in range(3):
					var card := VBoxContainer.new()
					card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					card.add_theme_constant_override("separation",12)
					cards.add_child(card)
					var def: Dictionary = Data.CONTRACTS[i]
					line(def.tag,12,GOLD,card)
					line(def.name,21,PALE,card)
					var desc := line(def.description,15,MUTED,card)
					desc.custom_minimum_size.y = 130
					line("%d scrap  ·  %d XP"%[def.scrap,def.xp],14,GOLD,card)
					button("Take contract",director.begin.bind(i,-1),card,not director.home())
			button("Prepare · Den upgrades",func(): open("upgrades"))
			button("Back to the fire",close)
		"abandon":
			line("Live to walk another trail.",30)
			line("Ending early keeps your XP, gathered items, and ordinary loot. Unclaimed contract cargo and its reward are forfeited. Moss will offer a fresh expedition.")
			button("Return early · Close this contract",director.abandon)
			button("Keep my current expedition",func(): open("board"))
		"event":
			line(Data.EVENTS[int(active.event)],30)
			if int(active.event)==0:
				line("A young scout shivers beneath a broken cart. “I thought I knew the way.” One of your potions could get him home. Moss will remember it.",18)
				button("Give a potion · +8 scrap at home",director.resolve_event.bind(true),null,game.potions<=0)
			else:
				line("Warm stones, a sheltered hollow, and a little bloodmoss. Someone made a home here for one night. You can rest, or salvage what they left behind.",18)
				button("Rest in the sanctuary · Heal 25 HP",director.resolve_event.bind(true))
			button("Search the abandoned pack · 2 ore",director.resolve_event.bind(false))
			button("Leave it for now",close)
		"summary":
			var s: Dictionary = director.last_summary
			line("You brought something home.",34,GOLD)
			line(str(s.get("name","Expedition"))+"  /  COMPLETE",19)
			line("“That's another few nights by the fire. You did well.” — Moss",17,MUTED)
			line("%d SCRAP     +%d XP"%[s.get("scrap",0),s.get("xp",0)],30,GOLD)
			line("Trail time %02d:%02d     Enemies defeated %d     Resources %d"%[int(s.get("seconds",0))/60,int(s.get("seconds",0))%60,s.get("kills",0),s.get("resources",0)],16)
			line("Sky: %s     Best streak: %d"%[s.get("weather","Clear"),director.best_combo],16,GOLD)
			line("Discoveries: " + (", ".join(s.get("discoveries",[])) if not s.get("discoveries",[]).is_empty() else "The next trail still holds its secrets."),16,MUTED)
			button("Make it count · Choose an upgrade",func(): open("upgrades"))
			button("One more expedition",func(): open("board"))
			button("Enjoy the fire",close)
		"upgrades":
			line("Make the next journey yours.",30)
			line("%d scrap available · Training prepared by the den's craftsmen"%game.scrap,17,GOLD)
			for def in Data.UPGRADES:
				var rank := int(director.upgrades[def.id])
				var cap := 2 if def.id=="pouch" else 3
				var cost := 28+rank*18
				line(def.description,15,MUTED)
				button("%s   ·   %d/%d   ·   %s"%[def.name,rank,cap,"Complete" if rank>=cap else "%d scrap"%cost],director.buy.bind(def.id),null,rank>=cap or game.scrap<cost or not director.home())
			button("Expedition board",func(): open("board"))
			button("Back to the den",close)
		_:
			line("Your field journal",32)
			line(director.objective_text(),21,GOLD)
			line("OUTBOUND  ·  Hearth Hall → eastern tunnels → Daylight Grotto → Thornwood Hollow → eastern trail → Thornwood Expanse",16)
			line("HOMEBOUND  ·  Follow the gold compass. Once the objective is complete, Moss's hidden trail at the western forest sign takes you home. Or walk back through the caves.",16,MUTED)
			if not active.is_empty():
				line("Optional: gather bloodmoss, investigate the sheltered camp, or cross the river for the guarded Watcher's cache. No countdown. Your expedition ends when you choose.",16)
				line("Seed %d  ·  %s  ·  Expedition %d  ·  %s"%[active.seed,active.weather,active.serial,Data.weather_profile(str(active.weather)).blurb],13,MUTED)
			line("Fight with Space / click, aim with the mouse. Q uses your class special, Shift dodges, F drinks a potion. Press E near a defeated enemy to inspect its loot.",15)
			line("Mist: stand still to vanish. Rain: arrows hang in the wet. Clear: watchers see farther. Streaks raise your damage until you are hit.",14,GOLD)
			if director.home():
				button("Speak with Moss",func(): open("board"))
			button("Return to the trail",close)
	overlay.show()
	director.game.interaction_feedback.prompt.hide()
	# Keep actors and input still while reading; this UI alone processes while paused.
	get_tree().paused = true

func take_rite(class_id: String) -> void:
	director.choose_rite(class_id)
	open("welcome")

func close() -> void:
	overlay.hide()
	get_tree().paused = false

func announce(heading: String, description: String) -> void:
	title.text = heading
	subtitle.text = description
	banner_time = 5.0

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if overlay.visible and event.physical_keycode in [KEY_ESCAPE,KEY_J]:
			close()
			get_viewport().set_input_as_handled()
		elif not get_tree().paused and not director.game.rpg.input_blocked() and event.physical_keycode==KEY_J:
			open("journal")
			get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if not get_tree().paused:
		banner_time = maxf(0,banner_time-delta)
	banner.visible = banner_time>0 and not overlay.visible
	banner.modulate.a = minf(1,banner_time)*minf(1,(5-banner_time)*2)
	journal_button.visible = not get_tree().paused
	var letter := 70.0 if banner.visible else 0.0
	letter_top.position.y = lerpf(letter_top.position.y, -80.0+letter, minf(1.0,delta*8.0))
	letter_bot.position.y = lerpf(letter_bot.position.y, 720.0-letter, minf(1.0,delta*8.0))

func _exit_tree() -> void:
	if is_instance_valid(overlay) and overlay.visible:
		get_tree().paused = false
