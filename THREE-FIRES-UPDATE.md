# The Three Fires

Adds a six-chapter branching chronicle to the existing First Expedition game. Speak to Moss and choose **The Three Fires · Story & clan journal**, or open it from the journal with **J**.

## Gameplay

- Six full expeditions with persistent story decisions and three endings.
- Reedclaw, Stonekin, and Moonroot reputation, clan banners, a mark currency, and a ward market.
- Named seeds select biome profiles over the current authored maps, varying weather, patrol roles, lore, and telegraphed terrain hazards.
- Burning a nest adds retaliatory fire hazards on later expeditions.
- Craft smoke bombs (2 herbs + 1 wood, **G**) and screeching talismans (2 ore + 1 wood, **V**) at Moss's hearth. Smoke conceals for 10 seconds until attacking; talismans stun nearby ordinary expedition guards for 5 seconds. Bosses resist these patrol-control effects.
- Human boss commanders accept surrender at 20% health or less. Approach and press **E** to offer quarter, earning marks and completing the hunt without ordinary kill loot or XP.
- Optional legacy mode resets personal levels and carried equipment on death, carries over 80% of unspent scrap and the den's memory, and requires a different class as heir.
- Expedition difficulty settings and reduced animation for the new hazards.

The chronicle uses the existing save file with backward-compatible defaults. Story choices, rewards, and heir selection persist; repeated claims and early returns cannot duplicate story rewards. Existing saves do not need to be deleted.

## Browser build

The updated Godot Web export is committed in `docs/`, including `index.html`, JavaScript, WebAssembly, audio worklets, icons, and `index.pck`. Serve the directory over HTTP/HTTPS. The export uses the existing non-threaded web template.

The game package is 50,014,048 bytes. The exported HTML's declared file sizes match the generated package and WebAssembly files. Publishing depends on the repository's configured Pages branch; pushing an export to a feature branch does not by itself change a Pages deployment sourced from another branch.

## Validation

- Chronicle integration: 140 assertions, 0 failures, covering all endings, persistence, reward idempotence, crafting, tools, retaliation, inheritance, and surrender.
- Existing expedition suite: 2,502 assertions, 0 failures.
- Boss progression and combat balance checks: 0 failures.
- Rendered journal, decisions, workshop, and biome presentation inspected at 1152 × 720.
- Windows and web game packages passed headless startup checks. This does not substitute for a full browser playthrough.

Rapid headless shutdown still reports audio playback resources in use; no gameplay assertions failed. The supplied documents' larger optional proposals, including multiplayer, generated map geometry, new 3D models, and a full political simulation, are not part of this update. Session duration has not been measured.
