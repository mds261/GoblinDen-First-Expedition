extends RefCounted
## Authored choices layered over the existing seeded expedition encounters.
const BIOMES := [
	{"name":"Drowned March", "faction":"Reedclaw", "weather":"Rain", "hazard":"poison", "roles":["rogue","ranger","mage"], "lore":"The drowned king traded his crown for one more breath."},
	{"name":"Embercrag", "faction":"Stonekin", "weather":"Clear", "hazard":"rock", "roles":["knight","knight","ranger"], "lore":"Stonekin cut their treaties into rock. Fire cannot erase a promise."},
	{"name":"Moonroot Ruins", "faction":"Moonroot", "weather":"Mist", "hazard":"hex", "roles":["mage","rogue","priest"], "lore":"The moon shrine remembers the names that its keepers forgot."}
]
const CHAPTERS := [
	{"title":"The scout beneath the cart", "text":"A Reedclaw scout is pinned under a hunter's cart. His satchel carries a map to the stolen Great Cheese. He asks you to carry word to his people.", "choices":[
		{"id":"rescue", "label":"Free the scout · 1 potion → 3 marks, Reedclaw +20", "potion":1,"marks":3,"rep":20,"faction":"Reedclaw","flag":"scout_saved", "result":"Bram marks a sheltered route. Friendly guides reduce detection on future trails."},
		{"id":"bargain", "label":"Buy the map · 10 scrap → 2 marks, Reedclaw +10", "cost":10,"marks":2,"rep":10,"faction":"Reedclaw","flag":"map_bought", "result":"Bram keeps his pride. His map points toward the old wedding grove."},
		{"id":"rob", "label":"Take the satchel · +18 scrap, Reedclaw −20", "scrap":18,"rep":-20,"faction":"Reedclaw","flag":"scout_robbed", "result":"The scout escapes, empty-handed. Reedclaw runners carry your description."}]},
	{"title":"A wedding under arrows", "text":"Stonekin families have gathered for a wedding. A hunter patrol is closing in. Their elder asks you to buy time, while a supply cache lies unguarded.", "choices":[
		{"id":"gift", "label":"Supply the escape · 12 scrap → 4 marks, Stonekin +20", "cost":12,"marks":4,"rep":20,"faction":"Stonekin","flag":"wedding_saved", "result":"The families escape through a mountain passage. A Stonekin trader will remember your gift."},
		{"id":"warn", "label":"Warn the elder · 2 marks, Stonekin +10", "marks":2,"rep":10,"faction":"Stonekin","flag":"wedding_warned", "result":"The feast becomes a quiet evacuation. The elder shares the next fragment of the relic's story."},
		{"id":"loot", "label":"Loot the wedding chest · +25 scrap, Stonekin −20", "scrap":25,"rep":-20,"faction":"Stonekin","flag":"wedding_looted", "result":"You return richer. Stonekin sentries reinforce their posts against you."}]},
	{"title":"The nest in the hunter's path", "text":"A deserted Moonroot nest blocks a hunter supply route. Burning it would expose their stores, but its shrine still carries offerings from living families.", "choices":[
		{"id":"protect", "label":"Conceal the nest · 3 marks, Moonroot +20", "marks":3,"rep":20,"faction":"Moonroot","flag":"nest_protected", "result":"The shrine survives. Moonroot traders offer a ward against the old hazards."},
		{"id":"salvage", "label":"Salvage carefully · +10 scrap, Moonroot +5", "scrap":10,"rep":5,"faction":"Moonroot","flag":"nest_salvaged", "result":"You take only abandoned iron. The name Two-Eyed One is scratched beneath the shrine."},
		{"id":"burn", "label":"Burn it for the stores · +32 scrap, Moonroot −30", "scrap":32,"rep":-30,"faction":"Moonroot","flag":"nest_burned", "result":"Smoke reveals the stores and your trail. Retaliatory fire pits appear on later expeditions."}]},
	{"title":"The scholar's missing page", "text":"A Moonroot scholar names the Two-Eyed One: a human quartermaster who stole the Great Cheese to break the clans' treaty. A prisoner knows where he hid it.", "choices":[
		{"id":"translate", "label":"Share the map · 3 marks, Moonroot +15", "marks":3,"rep":15,"faction":"Moonroot","flag":"scholar_helped", "result":"The scholar translates a warning: the relic binds every clan that accepts it."},
		{"id":"ransom", "label":"Pay the prisoner's ransom · 15 scrap → 5 marks", "cost":15,"marks":5,"rep":10,"faction":"Reedclaw","flag":"prisoner_freed", "result":"A freed courier brings evidence of the quartermaster's deception to the den."},
		{"id":"steal", "label":"Steal the page · +18 scrap, Moonroot −15", "scrap":18,"rep":-15,"faction":"Moonroot","flag":"page_stolen", "result":"You know the hiding place. The scholar refuses to forget the theft."}]},
	{"title":"The Great Cheese", "text":"Wrapped in a stolen treaty, the relic rests inside the quartermaster's chest. Its scent is ordinary. The authority the clans give it is not.", "choices":[
		{"id":"return", "label":"Return the relic · 6 marks, all clans +15", "marks":6,"rep":15,"faction":"all","flag":"relic_returned", "result":"The clans send traders to the hearth. A treaty ending is now possible."},
		{"id":"keep", "label":"Keep it as your crown · +30 scrap, all clans −10", "scrap":30,"rep":-10,"faction":"all","flag":"relic_kept", "result":"The clans see a would-be ruler. Your authority will depend on fear."},
		{"id":"sell", "label":"Sell it to the caravan · +55 scrap, all clans −20", "scrap":55,"rep":-20,"faction":"all","flag":"relic_sold", "result":"A heavy purse replaces the treaty. The clans will remember the price you chose."}]},
	{"title":"A hearth for whom?", "text":"With the stores recovered, Moss calls the clans to the fire. The hunters are still beyond the tunnels. Choose the promise that will shape this den.", "choices":[
		{"id":"treaty", "label":"Unite the clans · requires returned relic and two friendly clans", "ending":"Treaty of the Three Fires", "flag":"treaty_signed", "result":"Three banners hang above one fire. Guides and traders keep the den supplied."},
		{"id":"rule", "label":"Fortify and rule · +25 scrap, all clans −10", "scrap":25,"rep":-10,"faction":"all","ending":"The Iron Hearth", "flag":"iron_hearth", "result":"The den survives behind a wall of shields. Outside, the clans measure your strength."},
		{"id":"leave", "label":"Leave with the treasure · +40 scrap", "scrap":40,"ending":"The Long Road", "flag":"long_road", "result":"You leave a share for Moss and follow the caravan road. The hearth remains open for future journeys."}]}
]
const RECIPES := {
	"smoke":{"name":"Smoke bomb [G]", "ingredients":{"herb":2,"wood":1}, "description":"10 seconds of concealment. Breaks ordinary guards' pursuit; attacking ends it."},
	"talisman":{"name":"Screeching talisman [V]", "ingredients":{"ore":2,"wood":1}, "description":"Stuns nearby ordinary expedition guards for 5 seconds. Bosses resist it."}
}

static func biome(seed_name: String) -> Dictionary:
	return BIOMES[posmod(seed_name.strip_edges().to_lower().hash(),BIOMES.size())].duplicate(true)
