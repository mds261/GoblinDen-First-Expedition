# GoblinDen — First Expedition (trial)

Open `project.godot` in Godot 4.7 and press F5.

You wake in Hearth Hall as one small goblin. Choose a **class rite** (Blade, Archer, Knight, or Mage), speak to **Moss** by the fire, and take a contract into Thornwood. Recover what the tribe lost. Come home alive.

This trial uses the connected den, painted Thornwood, four classes, weather, loot, and the expedition loop. It is a complete first outing, not a menu demo.

## The loop

1. Wake and take a rite. Each class keeps its attack, special (`Q`), and dodge (`Shift`).
2. Press **E** on Moss. Pick **Lost Supplies**, **Hunter's Tracks**, or **Silent Raid**.
3. Follow the gold compass east through the tunnels, the hollow, and the forest.
4. Finish the contract — or explore for bloodmoss, a hidden camp, and the Watcher's cache.
5. Return to Moss (the western forest sign is a shortcut once the work is done). Spend scrap at the den.

There is no countdown. An expedition ends when you claim it, abandon it at home, or keep walking.

## Weather is a mechanic

The sky is rolled with the contract seed and stays until you come home.

- **Clear** — watchers notice you from farther away.
- **Mist** — stand still and the trail forgets you. The next strike can ambush.
- **Rain** — arrows hang in the wet; footing is a little worse.

Kill without being hit to build a **streak** (up to +4 damage). Taking a hit breaks it.

## Controls

| Input | Action |
| --- | --- |
| `WASD` | Move |
| Mouse / `Space` | Aim / attack |
| `Q` / Right click | Class special |
| `Shift` | Dodge |
| `E` | Talk, gather, loot, travel |
| `F` | Bloodmoss potion |
| `J` | Field journal |
| `Esc` | Menu, audio, training |

## Headless checks

```bash
godot --headless --path . --script res://tests/first_expedition_test.gd -- --test-save=$PWD/work/isolated.cfg --trial-test
godot --headless --path . --script res://tests/trial_presentation_test.gd -- --test-save=$PWD/work/isolated.cfg --trial-test
godot --headless --path . --script res://tests/trial_class_combat_test.gd -- --trial-test
```
