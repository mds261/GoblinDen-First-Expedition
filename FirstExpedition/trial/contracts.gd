extends RefCounted
## Authored destinations, randomized situations; never randomized world geometry.
const CONTRACTS := [
	{"id":"supplies", "name":"Lost Supplies", "tag":"EXPLORATION", "description":"Follow the torn banners. Recover three supply bundles from the Thornwood trails.", "scrap":32, "xp":85},
	{"id":"hunt", "name":"Hunter's Tracks", "tag":"COMBAT", "description":"Three human outriders are marking our trails. Break their patrol before it finds the den.", "scrap":38, "xp":100},
	{"id":"raid", "name":"Silent Raid", "tag":"RISK & REWARD", "description":"Recover the scouting ledger. Circle the watch or fight through it; the choice is yours.", "scrap":36, "xp":90}
]
const SITES := [Vector2(500,760), Vector2(1100,1000), Vector2(1400,550)]
const BONUS := Vector2(1810,790)
const EVENTS := ["A goblin in the rain", "The last campfire", "Glowleaf sanctuary"]
const UPGRADES := [
	{"id":"edge", "name":"Forge · Tempered edge", "description":"+3 damage with every class. Three ranks.", "cost":28},
	{"id":"ward", "name":"Training · Hardy constitution", "description":"+10 maximum health. Three ranks.", "cost":28},
	{"id":"pouch", "name":"Shaman · Deep medicine pouch", "description":"Carry one more healing potion. Two ranks.", "cost":28}
]
static func generate(kind: int, seed_value: int, serial: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var sites: Array = SITES.duplicate()
	# Explicit Fisher-Yates uses the expedition RNG, not the global RNG.
	for i in range(sites.size()-1,0,-1):
		var j := rng.randi_range(0,i)
		var hold: Vector2 = sites[i]
		sites[i] = sites[j]
		sites[j] = hold
	return {"kind":kind,"seed":seed_value,"serial":serial,"sites":sites,"weather":["Clear","Mist","Rain"][rng.randi_range(0,2)],"event":rng.randi_range(0,2),"roles":[["rogue","ranger","knight"],["knight","rogue","ranger"],["ranger","knight","rogue"]][rng.randi_range(0,2)],"flank":rng.randi_range(0,1),"taken":[],"defeated":[],"discoveries":[],"elapsed":0.0,"kills":0,"resources":0,"bonus":false,"ready":false,"claimed":false}
