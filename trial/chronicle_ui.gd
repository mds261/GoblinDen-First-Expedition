extends RefCounted
const Data = preload("res://trial/chronicle_data.gd")

static func render(ui: CanvasLayer, page: String) -> void:
	var director = ui.director
	var world = director.living
	var game = director.game
	match page:
		"chronicle":
			ui.line("The Three Fires",32,ui.GOLD)
			ui.line("A story in six expeditions · Choices persist across journeys",16,ui.MUTED)
			ui.line(world.camp_description(),17)
			ui.line("Goblin marks: %d    ·    Reedclaw %+d    Stonekin %+d    Moonroot %+d" % [world.marks,world.reputation.Reedclaw,world.reputation.Stonekin,world.reputation.Moonroot],16,ui.GOLD)
			if world.chapter>=Data.CHAPTERS.size():
				ui.line(world.ending,26,ui.GOLD)
				ui.line("Your story remains in the journal. Repeatable contracts and Moss's boss hunts continue after the ending.")
			elif not world.running:
				ui.line("Follow a stolen clan relic from a trapped scout to a final treaty. Each chapter combines a full expedition with a decision on the trail. There is no time limit.")
				ui.line("Name your world seed",15,ui.GOLD)
				var entry := LineEdit.new()
				entry.text = world.seed_name
				entry.max_length = 64
				entry.placeholder_text = "The Three Fires"
				ui.body.add_child(entry)
				ui.button("Begin the chronicle",func(): world.start(entry.text); ui.open("chronicle"),null,not director.home() or not director.active.is_empty() and not director.active.get("claimed",false))
			else:
				var chapter: Dictionary = Data.CHAPTERS[world.chapter]
				ui.line("CHAPTER %d / 6 · %s" % [world.chapter+1,chapter.title],23,ui.GOLD)
				if world.is_story():
					var theme: Dictionary = director.active.biome
					ui.line("%s · %s territory\n%s" % [theme.name,theme.faction,theme.lore],16,ui.MUTED)
					ui.line("Decision recorded. Return to Moss to finish this chapter." if world.choice_done() else ("Your cargo is secured. Find the story encounter at the sheltered cart in Thornwood Expanse; follow the compass." if director.active.ready else "Finish the expedition objective, then investigate the sheltered cart in Thornwood Expanse."))
					ui.button("Report to Moss · Finish chapter",director.claim,null,not director.home() or not director.active.ready or not world.choice_done())
				else:
					ui.line("World seed: "+world.seed_name,15,ui.MUTED)
					ui.button("Take chapter expedition",world.begin_chapter,null,not director.home() or not director.active.is_empty() and not director.active.get("claimed",false))
			for record in world.history:
				ui.line("%d. %s\n%s" % [int(record.chapter)+1,record.title,record.result],15,ui.MUTED)
			ui.button("Workshop & clan market",func(): ui.open("workshop"))
			ui.button("Expedition board",func(): ui.open("board"))
			ui.button("Return to the trail",ui.close)
		"choice":
			if not world.is_story() or world.chapter>=Data.CHAPTERS.size():
				ui.line("This trail's story is complete.")
			else:
				var chapter: Dictionary = Data.CHAPTERS[world.chapter]
				ui.line(chapter.title,30,ui.GOLD)
				ui.line(chapter.text,19)
				if world.choice_done():
					ui.line("Your choice has been recorded. Return to Moss.",17)
				else:
					if not director.active.ready: ui.line("Secure the expedition objective before committing the clan's future.",16,ui.MUTED)
					for choice in chapter.choices:
						ui.button(str(choice.label),world.choose.bind(str(choice.id)),null,not world.can_choose(choice))
			ui.button("Leave for now",ui.close)
		"workshop":
			ui.line("Hearth workshop",30,ui.GOLD)
			ui.line("Craft at Moss's fire. Tools have their own pouch and persist between expeditions. Bosses resist the talisman.",16,ui.MUTED)
			for id in Data.RECIPES:
				var recipe: Dictionary = Data.RECIPES[id]
				var costs: Array = []
				var affordable: bool = director.home()
				for item in recipe.ingredients:
					costs.append("%d %s" % [recipe.ingredients[item],item])
					if game.rpg.backpack.count_item(item)<int(recipe.ingredients[item]): affordable = false
				ui.line(recipe.description,16,ui.MUTED)
				ui.button("%s · owned %d · %s" % [recipe.name,world.tools[id],", ".join(costs)],func(): world.craft(id); ui.open("workshop"),null,not affordable)
			ui.line("CLAN MARKET · %d marks" % world.marks,20,ui.GOLD)
			ui.line("Earn marks through story choices and helping stranded scouts. Befriend any clan (+20 reputation) to open the market.",16,ui.MUTED)
			ui.button("Ward charm · half damage from biome hazards · 5 marks" if not world.ward else "Ward charm equipped",func(): world.buy_ward(); ui.open("workshop"),null,not director.home() or not world.market_open() or world.ward or world.marks<5)
			ui.button("Chronicle",func(): ui.open("chronicle"))
			ui.button("Back to the fire",ui.close)
		"world_settings":
			ui.line("Journey settings",30,ui.GOLD)
			ui.line("These options apply to expedition patrols and the new biome hazards. Authored boss fights keep their own balance.",16,ui.MUTED)
			for setting in [{"name":"Story · 65% patrol damage & health","value":0.65},{"name":"Standard · 100%","value":1.0},{"name":"Hard · 130% patrol damage & health","value":1.3}]:
				ui.button(str(setting.name)+(" · selected" if is_equal_approx(world.danger,float(setting.value)) else ""),func(): world.danger = float(setting.value); game._auto_save(); ui.open("world_settings"))
			ui.line("Difficulty changes apply to your next expedition.",14,ui.MUTED)
			ui.button("Reduced new hazard animation: "+("On" if world.reduced_effects else "Off"),func(): world.reduced_effects = not world.reduced_effects; game._auto_save(); ui.open("world_settings"))
			ui.line("Legacy mode: on death, lose personal levels and 20% of unspent scrap. Choose a different class as your heir. The den's upgrades, clan memory, marks, story and boss progression remain. Backpack and equipped items are lost. Standard mode keeps normal corpse recovery.",16)
			ui.button("Legacy mode: "+("On" if world.legacy_mode else "Off"),func(): world.legacy_mode = not world.legacy_mode; game._auto_save(); ui.open("world_settings"),null,not director.home())
			ui.button("Return",ui.close)
		"legacy":
			ui.line("The fire outlives you.",32,ui.GOLD)
			ui.line("You fell as %s. A new goblin inherits %d scrap, %d marks and the clans' memory." % [world.fallen_class.capitalize(),game.scrap,world.marks],19)
			ui.line("Legacy %d · Marked by the hunters: patrol detection is 15%% wider on the next trails. Choose a different class." % world.deaths,16,ui.MUTED)
			for rite in preload("res://trial/contracts.gd").RITES:
				if rite.id!=world.fallen_class:
					ui.button("Continue as "+str(rite.title),world.select_heir.bind(str(rite.id)))
