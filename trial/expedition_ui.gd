extends CanvasLayer
const Data = preload("res://trial/contracts.gd")
const Look = preload("res://trial/look.gd")
const GOLD := Color("d9b979")
const PALE := Color("eee6cf")
const MUTED := Color("aabcae")
var director: Node2D
var overlay: ColorRect
var panel: PanelContainer
var body: VBoxContainer
var scroll: ScrollContainer
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
	panel.add_theme_stylebox_override("panel", Look.panel(false))
	overlay.add_child(panel)
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",14)
	scroll.add_child(body)
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
	journal_button.text = "Journal [J]"
	journal_button.tooltip_text = "Field journal [J] · H hides only this button"
	journal_button.position = Vector2(742,18)
	journal_button.pressed.connect(func(): open("journal"))
	Look.toolbar(journal_button,116)
	add_child(journal_button)
	refresh_hud()

func refresh_hud() -> void:
	journal_button.visible = not get_tree().paused and not director.journal_hidden
	director.game.rpg.exploration_map.sync_visibility()

func toggle_journal_shortcut() -> void:
	director.journal_hidden = not director.journal_hidden
	refresh_hud()
	director.game._auto_save()

func line(text: String, size_px: int = 16, color: Color = PALE, parent: Node = null) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",size_px)
	label.add_theme_color_override("font_color",color)
	(parent if parent!=null else body).add_child(label)
	return label

func button(text: String, action: Callable, parent: Node = null, disabled: bool = false, height: int = 40) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size.y = height
	b.add_theme_font_size_override("font_size",15)
	b.pressed.connect(action)
	b.disabled = disabled
	Look.dress(b)
	(parent if parent!=null else body).add_child(b)
	return b

func open(page: String = "board") -> void:
	if not director.initialized:
		return
	mode = page
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	panel.size = Vector2(1080,680) if page=="welcome" else Vector2(852,592)
	scroll.scroll_vertical = 0
	cover.visible = page=="welcome"
	panel.position = Vector2(36,20) if page=="welcome" else Vector2(150,64)
	panel.add_theme_stylebox_override("panel", Look.panel(false, 16 if page=="welcome" else 20))
	body.add_theme_constant_override("separation", 6 if page=="welcome" else 12)
	var game = director.game
	var active: Dictionary = director.active
	line("A   G O B L I N ' S   J O U R N E Y" if page=="welcome" else "G O B L I N D E N   /   F I R S T   E X P E D I T I O N",12,GOLD)
	match page:
		"chronicle", "choice", "workshop", "world_settings", "legacy":
			preload("res://trial/chronicle_ui.gd").render(self,page)
		"welcome":
			line("GoblinDen",34)
			line("FIRST EXPEDITION",18,GOLD)
			line("The supplies are gone. Follow Thornwood, bring something home, and keep the fire.",14,MUTED)
			line("Choose the goblin you will be.",15,GOLD)
			var rites := GridContainer.new()
			rites.columns = 4
			rites.add_theme_constant_override("h_separation",10)
			rites.add_theme_constant_override("v_separation",8)
			body.add_child(rites)
			for rite in Data.RITES:
				var chosen: bool = director.rite_id==rite.id
				var shell := PanelContainer.new()
				shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				shell.add_theme_stylebox_override("panel", Look.card(chosen))
				rites.add_child(shell)
				var card := VBoxContainer.new()
				shell.add_child(card)
				var portrait := TextureRect.new()
				portrait.texture = portraits.get(rite.id)
				portrait.custom_minimum_size = Vector2(0,200)
				portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				card.add_child(portrait)
				line(rite.title.to_upper() + (" · SELECTED" if chosen else ""),16,GOLD if chosen else PALE,card)
				var blurb := line(rite.line,12,MUTED,card)
				blurb.custom_minimum_size.y = 62
				button("Selected" if chosen else "Choose %s"%rite.title, take_rite.bind(rite.id), card, false, 36)
			line("WASD move · E interact · Shift dodge (30 stamina) · Q special (20 stamina) · J journal",13,MUTED)
			button("Wake by the fire",func(): director.welcomed = true; close(); game._auto_save(); announce("HEARTH HALL","Find Moss beside the fire · Approach and press E"))
		"board":
			line("Moss's expedition board",32)
			line("“Bring back what you can. Leave enough strength for the road home.”",17,MUTED)
			if not active.is_empty() and not active.claimed:
				line(director.objective_text(),22,GOLD)
				line("Your objective is complete. Return to Moss for your reward, or keep exploring." if active.ready else "Your expedition is underway. Follow the trail objective, then return to Moss for your reward.")
				button("Report to Moss · Claim reward",director.claim,null,not active.ready or not director.home())
				button("End this expedition early",func(): open("abandon"),null,not director.home())
			else:
				var cards := HBoxContainer.new()
				cards.add_theme_constant_override("separation",14)
				body.add_child(cards)
				for i in range(3):
					var shell := PanelContainer.new()
					shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					shell.add_theme_stylebox_override("panel", Look.card(false))
					cards.add_child(shell)
					var card := VBoxContainer.new()
					card.add_theme_constant_override("separation",12)
					shell.add_child(card)
					var def: Dictionary = Data.CONTRACTS[i]
					line(def.tag,12,GOLD,card)
					line(def.name,21,PALE,card)
					var desc := line(def.description,15,MUTED,card)
					desc.custom_minimum_size.y = 80
					line("%d scrap  ·  %d XP"%[def.scrap,def.xp],14,GOLD,card)
					button("Take contract",director.begin.bind(i,-1),card,not director.home())
			button("The Three Fires · Story & clan journal",func(): open("chronicle"))
			button("Workshop & clan market",func(): open("workshop"))
			button("Boss hunts · Defend the den",func(): open("hunts"))
			button("Prepare · Den upgrades",func(): open("upgrades"))
			button("Back to the fire",close)
		"hunts":
			var hunts = game.rpg.boss_hunts
			var quest: Dictionary = hunts.current()
			line("Moss's boss hunts",30,GOLD)
			line("Nine hunts defend the den. Then the Cinder Orchard offers one final, brutal bonus challenge.",16,MUTED)
			line("Human commanders can surrender below 20% health. Approach and press E to offer quarter; sparing awards 3 goblin marks and completes the hunt. Creatures and supernatural bosses fight to the end.",15,MUTED)
			line("%d / %d hunts rewarded" % [hunts.completed_count(),hunts.quests().size()],16,GOLD)
			if not quest.is_empty():
				if quest.get("bonus",false):
					line("FINAL BONUS · EXTREME DANGER",16,GOLD)
				line(str(quest.name),24)
				line(str(quest.description),17)
				line(str(quest.destination),16,GOLD)
				line("%d scrap · %d XP" % [quest.reward_scrap,quest.reward_xp],16)
				if not hunts.accepted:
					button("Accept final bonus quest" if quest.get("bonus",false) else "Accept boss hunt",hunts.accept,null,not director.home())
				elif hunts.is_complete(quest):
					button("Report to Moss · Claim hunt reward",hunts.claim,null,not director.home())
				else:
					line("Hunt underway · " + str(quest.hint),16,MUTED)
			else:
				line("Every boss has fallen. The tribe will tell your story.",22)
			button("Expedition board",func(): open("board"))
			button("Return to the trail",close)
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
				var cost := Data.upgrade_cost(rank)
				line(def.description,15,MUTED)
				button("%s   ·   %d/%d   ·   %s"%[def.name,rank,cap,"Complete" if rank>=cap else "%d scrap"%cost],director.buy.bind(def.id),null,rank>=cap or game.scrap<cost or not director.home())
			button("Expedition board",func(): open("board"))
			button("Back to the den",close)
		_:
			line("Your field journal",32)
			line(director.hud_objective_text(),21,GOLD)
			line(game.rpg.boss_hunts.objective(),16,GOLD)
			button("The Three Fires · Story & clan journal",func(): open("chronicle"))
			button("Workshop & clan market",func(): open("workshop"))
			button("Boss hunt journal",func(): open("hunts"))
			if game.rpg.boss_hunts.accepted:
				line(str(game.rpg.boss_hunts.current().hint),15,MUTED)
			else:
				line("OUTBOUND  ·  Hearth Hall → eastern tunnels → Daylight Grotto → Thornwood Hollow → eastern trail → Thornwood Expanse",16)
				line("HOMEBOUND  ·  Follow the gold compass. Once the objective is complete, Moss's hidden trail at the western forest sign takes you home. Or walk back through the caves.",16,MUTED)
			if not active.is_empty() and not active.get("claimed",false) and not game.rpg.boss_hunts.accepted:
				line("Trail danger %d / 6 · Rises with completed expeditions and boss hunts." % (int(active.get("threat",0))+1),14,GOLD)
				line("Optional: gather bloodmoss, investigate the sheltered camp, or cross the river for the guarded Watcher's cache. No countdown. Your expedition ends when you choose.",16)
				line("Seed %d  ·  %s  ·  Expedition %d  ·  %s"%[active.seed,active.weather,active.serial,Data.weather_profile(str(active.weather)).blurb],13,MUTED)
			line("Fight with Space / click, aim with the mouse. Shift dodges (30 stamina), Q uses your class special (20). Stamina recovers after a short pause; basic attacks are free. F drinks a potion. E inspects loot.",15)
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
			if mode!="legacy": close()
			get_viewport().set_input_as_handled()
		elif not get_tree().paused and not director.game.rpg.input_blocked() and event.physical_keycode==KEY_J:
			open("journal")
			get_viewport().set_input_as_handled()
		elif not get_tree().paused and not director.game.rpg.input_blocked() and event.physical_keycode==KEY_H:
			toggle_journal_shortcut()
			get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if not get_tree().paused:
		banner_time = maxf(0,banner_time-delta)
	banner.visible = false
	banner.modulate.a = minf(1,banner_time)*minf(1,(5-banner_time)*2)
	refresh_hud()
	var letter := 0.0
	letter_top.position.y = lerpf(letter_top.position.y, -80.0+letter, minf(1.0,delta*8.0))
	letter_bot.position.y = lerpf(letter_bot.position.y, 720.0-letter, minf(1.0,delta*8.0))

func _exit_tree() -> void:
	if is_instance_valid(overlay) and overlay.visible:
		get_tree().paused = false
