# Cinder Orchard & boss quest update

Open `C:\Users\mds88\GoblinDen-First-Expedition\project.godot` in Godot and press F5. The nested `goblinden-first-expedition` project receives the same update.

## Playing the update

Speak to Moss beside the Hearth Hall fire, choose **Boss hunts · Defend the den**, and accept the current hunt. You can also open the boss hunt journal through **J**. Boss hunts run alongside the existing supply expeditions. The gold compass follows the hunt while it is active, guiding you through exits, ward seals, boss locations, and the return to Moss. Each hunt pays its listed scrap and XP once, then unlocks the next hunt. Exploration remains open.

Enter the Cinder Orchard through the heat-crack in the southern part of Thornwood Hollow. The eastern exit still leads into Thornwood Expanse. Inside the Orchard, cross the ember court, charcoal rows, ash gallery, and nave to reach Kilnheart's eastern kiln.

## Artwork and animation

- Painted Cinder Mite, Ash Wisp, and Kilnheart sprites, each with four combat poses. Runtime animation adds skittering, floating, breathing, flickering, movement, hit feedback, and defeated appearances.
- Painted ash-stone paths, charcoal and root walls, molten fissures, and a large kiln mosaic.
- Painted charred trees, solid kiln pillars, rock vents, ash drifts, stairs, salvage chest, and flame effects.
- Hazard warnings retain their readable outlines and original damage timing. Vent eruptions, flame columns, heat jets, falling embers, and ash drifts all have animated visual treatment.
- The salvage chest dims after collection. The map can discover the kiln and salvage cache. The floor renderer limits tile drawing to the visible camera area.

## Boss progression

| Order | Quest / boss | Destination |
|---|---|---|
| 1 | Break the Iron Incursion — Iron Captain | The Breach, eastern den tunnels |
| 2 | Silence the Rootvein Nest — Giant Spider | Northern Rootvein loop |
| 3 | The Rider in the Hollow — Wolf Rider | Thornwood Hollow |
| 4 | Quench the Cinder Heart — Kilnheart | Cinder Orchard, eastern kiln |
| 5 | Break the Shield Vanguard | Thornwood high overlook approach |
| 6 | The Huntmaster in the Mire — Huntmaster Vane | Bog Trail |
| 7 | The Exiled Cave-Mouth Ogre | Frostroot Cavern |
| 8 | Starve the Gilded Hunger | Sealed Descent, final vault |
| 9 | The Paladin at Frostroot — Aurelius | Frostroot Cavern |
| 10 | Keep the Fire Against the Dawn — Dawn Hero | Thornwood high overlook approach |

The Ogre now appears as an authored hunt at Frostroot. Kilnheart and the Gilded Hunger keep their existing persistent encounters; defeating either before accepting its hunt still counts. The final reliquary and Rusk's existing Sealed Descent reward remain available separately. Existing saves gain the new quest state without a reset.

## Verification

- Cinder Orchard regression suite: **0 failures**, including entrances, camera bounds, physical navigation, creature behavior, hazard damage, cache payout, and reload persistence.
- Boss hunt progression suite: **0 failures**, including all ten encounters, routes from room entrances, hunt compass destinations, accepted-hunt reload, boss defeat credit, remote claim rejection, rewards paid once, and completed progression after reload.
- Existing First Expedition suite: **2,481 assertions, 0 failures**, covering all three contract types across three seeds, terrain routes, inventory, upgrades, classes, death/recovery, rewards, and save/reload.
- Scenes and the boss board were rendered in Godot's OpenGL compatibility renderer and visually inspected.

Godot reports ObjectDB cleanup warnings on these test exits. The graphical preview also reported that its restricted test user directory could not hold a shader cache; it still rendered all screenshots successfully.

## Art source and prompt set

Generated using the built-in ImageGen tool. Assets are bundled locally under `assets/cinder/`; playing requires no network service or key.

**creatures.png:** Transparent four-column, three-row painted dark-fantasy RPG atlas. Row 1: charcoal Cinder Mite beetle, idle, skittering, attacking, defeated. Row 2: smoky Ash Wisp around a burning wood heart, curled, floating, exhaling, dissipating. Row 3: rooted Kilnheart charcoal tree creature, dormant, awakened, heart exposed with walking roots, collapsed. Consistent top-down three-quarter camera, upper-left lighting, charcoal bark, amber embers, ivory ash, isolated silhouettes, generous transparent margins, no labels or grids.

**scenery.png:** Transparent four-column, two-row environment atlas in the same painted style. Twisted charred orchard tree; basalt pillar; molten rock vent; open salvage chest; descending broken stairwell; ash mound; fire and soot plume; circular ruined kiln mosaic. Full isolated objects, no labels, UI, or backgrounds.

**materials.png:** Opaque two-by-two overhead material atlas. Ash over cracked charcoal flagstones; dark basalt wall tops with burned roots; engraved kiln mosaic paving; cooling lava crust with muted amber fissures. Flat, detailed painterly surfaces, full-bleed quadrants, no props, characters, labels, or horizon.

## Preview images

See `cinder-court.png`, `cinder-kiln.png`, `cinder-cache.png`, `cinder-nave.png`, and `boss-hunts.png` beside these notes.
