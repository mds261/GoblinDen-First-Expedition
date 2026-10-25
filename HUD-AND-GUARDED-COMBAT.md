# Journal control, consistent HUD, and aggressive combat

Restart the running game to load this update. It is applied to both Godot project copies, with save progress retained.

## HUD

- **H now hides only the journal button.** Health, stamina, abilities, objectives, compass, and map are not affected. J still opens the journal at any time during ordinary play.
- The floating “HUD + [H]” box is removed. The journal button is hidden by default and can be shown with H or the pause menu.
- Journal, Map, Pack, and Menu buttons share a single aligned row, matching font sizes, heights, colors, borders, spacing, and hover styles.
- Location and vital panels align. Long objectives use a short HUD summary; the journal retains full routes and tactics.
- HUD frames share the same visual treatment. Central cinematic banners and their black bars stay off the playfield.
- The map remains independently controlled with M. Existing journal and map preferences are kept separately.
- The journal no longer repeats the full boss route twice, and unrelated expedition danger ratings are hidden while following a boss hunt.

## Combat and aggro

Normal detection is now **300 pixels**, twice the briefly reduced value. Weather modifies it to about 324 in clear weather, 198 in mist, and 258 in rain. Walls still block sight, and attacking a guard still alerts it. An engaged enemy can pursue up to 440 pixels from home while tracking a target up to 520 pixels away, and it searches for 3.5 seconds after losing sight.

Challenge now comes from defended objectives:

- Each of the three supply bundles has a nearby defender. The bundle cannot be claimed until that defender is defeated.
- The ledger camp has two close defenders; both must be defeated before the ledger can be taken. The contract is now named **Break the Watch**, with its description matching the required fight.
- Guarded pickups show a prompt explaining how many defenders remain.
- Hunter's Tracks still requires defeating all three targets. The optional Watcher's cache still requires defeating its Watcher.
- Defeated guards and already-collected objectives stay recorded across reloads. Older in-progress expeditions retain their collected cargo and completed kills.

Travel routes remain open, but the much wider detection and pursuit ranges make slipping past visible patrols unreliable. Combat is also required at mission objectives. The extreme final Cinder bonus remains after all nine main hunts.

## Verification

Checks cover journal-only hiding, independent map controls, shared toolbar dimensions and typography, saved preferences, restart, boosted detection and pursuit, blocked sight, retreat, guarded pickups, all contract types across three seeds, and reload behavior. Screenshots of the HUD with the journal hidden/shown, guarded supplies, Cinder, the field journal, pause menu, and opening selection were rendered and inspected.
