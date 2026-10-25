# Combat balance update

This pass raises combat pressure while retaining the existing telegraphs, dodge windows, routes, class choices, and quest rewards. Stop and rerun the game to load the updated scripts and data.

## Trail encounters

Opening trail enemies now have **85 HP and 12 damage**, instead of 55 HP and 7 damage. The optional Watcher has **160 HP and 18 damage**, instead of 105 HP and 12 damage. A fresh character defeats an opening enemy in 3–4 actual basic attacks across the four classes.

Repeat expeditions gain a bounded danger rank from completed expeditions and boss hunts. Each two completed expeditions add one rank; each three rewarded boss hunts add another, capped at five increases. Standard enemies gain 14 HP, 2 damage, and 3 movement speed per rank; Watchers gain 22 HP, 2 damage, and 2 movement speed. The danger rank is fixed when the expedition starts, saved with that expedition, and shown as **Trail danger 1–6** in the field journal. Reloading does not reroll it.

## Boss durability

| Boss | HP before | HP now | Damage now |
|---|---:|---:|---:|
| Iron Captain | 180 | 300 | 25 |
| Rootvein Giant Spider | 320 | 380 | 24 |
| Thornwood Wolf Rider | 370 | 460 | 30 |
| Kilnheart | 320 | 620 | 23 |
| Shield Vanguard | 155 | 580 | 28 |
| Huntmaster Vane | 290 | 680 | 34 |
| Cave-Mouth Ogre | 480 | 820 | 38 |
| Gilded Hunger | 900 | 1,100 | 28 |
| Grand Paladin Aurelius | 400 | 1,050 | 42 |
| Dawn Hero | 540 | 1,400 | 48 |

Cinder Mites now have 72 HP / 12 damage; Ash Wisps have 92 HP / 11 damage. Human bosses resist stun duration, slow duration, and knockback so they cannot be controlled as easily as ordinary guards. Their attacks remain interruptible.

## Player power and recovery

- Level growth is **+6 HP and +2 base damage**, down from +10 HP and +4 damage. Attribute allocation, equipment, and purchased upgrades still contribute normally. Level-up healing is 10 HP, down from 25.
- Ranged primary attacks deal damage through their projectiles. They no longer also deliver a free melee hit at close range. Equipping an actual melee weapon still enables its melee attack.
- Potions retain their 35 HP heal and venom effect, with a **1.5-second cooldown** shown on the HUD.
- Class specials have longer cooldowns. Base-class cooldowns are Blade 4.8s, Archer 4.6s, Knight 5.8s, and Mage 5s. Evolution cooldowns range from 5.5s to 9s.
- Knight, Warlord, and Guardian defensive buffs have downtime. Guardian's shield lasts 4s on a 9s cooldown, with a 20 HP self-heal. Shaman's self-heal is 30 HP on an 8s cooldown.
- Berserker and Warlock lifesteal is 10% of actual damage; damage beyond the target's remaining health cannot inflate healing. Their offensive specials require a hit to heal, and that healing is capped. Archer volley side arrows deal 45% of the central arrow's damage instead of 72%.
- Den upgrade ranks cost **40, 64, and 88 scrap**. Potion-pouch upgrades use the first two costs. Existing purchases remain earned; no currency is taken retroactively.

## Validation

The new balance suite verifies actual attacks/projectiles for all four base classes, close-range ranged damage, potion cooldown, overkill lifesteal, missed-special healing, defensive-buff downtime, boss control resistance, danger caps, danger persistence across reload, and upgrade affordability. It passes with zero failures.

The existing full boss quest, Cinder Orchard, stamina/presentation, and HUD/restart suites also pass. The First Expedition regression suite passes **2,481 assertions with zero failures**. These are automated gameplay checks; further tuning can still benefit from a full human playthrough.
