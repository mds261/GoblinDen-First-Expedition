# Stronger aggro and the final Cinder bonus

Restart the running game to load the changes. Existing saves remain usable.

## Enemy awareness

Normal guards and hunt enemies now detect a visible player at **300 pixels**. Weather modifies that radius: clear weather reaches about 324 pixels, mist about 198, and rain about 258. Walls still block sight. Damaging a guard still alerts it.

Pursuit is deliberately tenacious: an enemy returns only after it moves more than 440 pixels from home, or its target moves more than 520 pixels from that home. It searches for 3.5 seconds after losing sight. Companions still avoid independently pulling idle guards.

Cinder Mites react within 144 pixels instead of 168. Ash Wisps keep to a 180-pixel home leash instead of 210.

## Final bonus quest

Complete and claim the nine main boss hunts, ending with the Dawn Hero. Then speak to Moss and accept **Cinder Orchard · The Last Ember**, marked **FINAL BONUS · EXTREME DANGER**. The southern heat-crack in Thornwood Hollow opens for this quest. The eastern forest trail stays available throughout ordinary progression.

The Cinder Orchard is now an endgame challenge:

| Enemy / hazard | New strength |
|---|---|
| Kilnheart | 3,000 HP, 52 base damage, phase two at 60% health |
| Cinder Mite | 180 HP, 24 damage |
| Ash Wisp | 240 HP, 22 damage per ember |
| Vent eruption | 24 damage |
| Fire column | 22 damage |
| Heat jet | 24 damage |
| Falling ember | 20 damage |
| Burning ash drift | 10 damage per hazard tick |

Kilnheart attacks more often and exposes its heart for shorter periods. Its burning trail deals 22 damage. Hazard warning windows remain unchanged. Armor and the normal damage-invulnerability rules still apply.

Leaving the kiln arena for 2.5 seconds, or leaving the Orchard, restores a living Kilnheart to full health and resets the encounter. The exit stays usable. Victory pays **220 scrap and 900 XP** once when reported to Moss.

## Existing saves

An old early Cinder clear and its old reward remain in quest history. The new final bonus uses its own completion record, so veterans can face the harder rematch after the nine main hunts. Accepting it refreshes Cinder creatures once; previously collected salvage is not paid twice. Existing active ordinary boss hunts remain accepted. An old accepted early Cinder quest returns to the board rather than silently accepting a different boss. Old saves inside a still-locked Cinder area resume in Thornwood Hollow.

## Checks

- Local aggro, walls blocking sight, retreat, return-to-home behavior, and companion restraint: zero failures.
- Final bonus order, entrance gating, old-save migration, rematch population, arena reset, completion, reward idempotence, and save/reload: zero failures.
- Full boss progression and Cinder area regressions: zero failures.
- Existing expedition suite: 2,481 assertions, zero failures.

The bonus quest board and sealed entrance were also rendered for visual inspection.
