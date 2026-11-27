# Changelog

## 0.1.0 - 2026-11-18
- Initial playable prototype (movement, camera, dodge, combo combat, lock-on, enemy AI, HUD, test arena, automated tests).

## 0.2.0 - 2026-11-22
- Block, parry, guard break; Shadow Step and Ground Slam abilities with cooldown HUD; 41 tests.
- Open-source setup: MIT license, README, CONTRIBUTING, NOTICE, CI workflow.

## 0.3.0 - 2026-11-22
- Kayn path choice: altar, choice/confirm UI, Shadow Assassin and Rhaast stat profiles, permanent per save, autosave/load (57 tests).

## 0.3.1 - 2026-11-22
- Rock collision fixed (rocks were non-solid), runtime navmesh + NavigationAgent3D enemy pathing, pause menu; 62 tests.

## 0.4.0 - 2026-11-22
- Visual overhaul: procedural terrain, forest, grass, cinematic environment; navmesh from terrain with rock carving.
- Humanoid placeholder models with procedural animation; Husk Brute.
- Synthesized audio, VFX, weapon trail, lock-on marker.
- HUD frames + screen FX overlay; AI character pipeline doc; 74 tests.

## 0.6.0 - 2026-11-24
- Village at the north edge of the arena plateau (`scripts/world/village.gd`): supplied Japanese village pack (tori gate, 4 houses, market stalls with goods, lanterns, fences, red plum trees, crates/barrels, roads) and the Chinese four-corner pavilion (`scripts/world/chinese_pavilion.gd`, scaled from cm, coloured by part role, pillar collision).
- Props get collision from mesh bounds; houses, stalls and trees carve the navmesh; trees/grass keep the village clear.
- Navmesh cell size 0.3 (map and mesh match): removes the "More than 2 edges tried to occupy the same map rasterization space" error and the fragmented navmesh it caused.
- One rock moved out of the village area. 128 headless checks (11 new). Tools: `tests/prop_preview.*`, `tests/village_view.*` (need a display).

## 0.5.0 - 2026-11-24
- Main menu (Czech) is now the start scene: Pokračovat, Nová hra, Načíst hru, Nastavení, Galerie, Autoři, Ukončit hru (with confirmation).
  Key art of the author's Kayn (right), animated mist, embers, ash, falling leaves, pulsing Darkin-arm glow, mouse parallax, fade transitions.
- Three save slots (GameState.slot_info/latest_slot/first_empty_slot); slot 1 keeps the original save file.
- Real settings: window mode, resolution, V-Sync, MSAA, 3D render scale, FPS cap; master/effects/ambience volume (new SFX and Ambience audio buses);
  mouse sensitivity, Y inversion, keyboard/mouse rebinding with conflict swap (gamepad bindings preserved). All persisted in user://settings.cfg.
- Gallery of the supplied concept art, credits screen, UI sounds (ui_move, ui_click).
- Pause menu got a "Main menu" button. Fonts Cinzel and Cormorant Garamond (OFL) added.
- 117 headless checks (43 new for the menu); tests/menu_screenshot.* and tests/menu_flow_check.* for visual and end-to-end checks (need a display).

## 0.7.0 - 2026-11-26
- Darker, grimmer look: dusk sun/sky/ambient, blue-grey fog, stronger contrast, darker rock/pine/grass tints, 8192 shadow atlas with soft shadows.
- Valley basin north of the arena (`TerrainGen`): flat floor around the village, hills rising around it; terrain shader blends dirt along the street and plaza.
- Village rebuilt larger (`village.gd`): tori gate, long street, house rows with fenced yards, market, plaza with pavilion, lantern lights.
- Enterable hall (`village_hall.gd`): walls with collision, door, roof, beams, furniture, banners, brazier fire, hanging lanterns, interior light.
- HUD restyle: gold-framed segmented health/stamina bars with damage trail (`hud_bar.gd`), bottom-centre ability hotbar with drawn icons, cooldown wipe and ready flash (`ability_slot.gd`); control hint fades after 24 s.
- Tests updated for the new layout; added hall, valley and goods checks (135 checks).

## 0.7.1 - 2026-11-26
- Balanced lighting and desaturated village atlas textures (less toy-like).
- Kayn model rebuilt after the concept art (still procedural primitives, same rig/animations): masked face with red eyes, layered silver hair, high red-lined collar, black coat with straps, belt, chain and pendant, spiked steel pauldron, glowing purple demonic arm with claws, buckled boots, long tattered red cape. Preview tool: `tests/character_view.tscn`.

## 0.8.0 - 2026-11-26
- Imported Stylized Nature Free Sampler and Low Poly Chinese Town Free Sample (selected GLBs + licences); `EnvProps` weathers them (desaturated/darkened) at load.
- Forest rebuilt on pack models: two pine silhouettes, dead twisted trees, bare birches, boulders, sandstone, black basalt columns, small stones and glow mushrooms, with colliders (`forest.gd`).
- Village: tea house at the plaza, guardian lions at the gate, lantern post, rice jars.
- Grass: lighter roots + cheap translucency so backlit grass is no longer black.

## 0.9.0 - 2026-11-27
- Healing gourd (R / pad Back): 3 charges, heals 45% over 1 s, only usable in locomotion and below full health; refilled on respawn and by the elder. HUD slot with charge count, rebindable in settings.
- Elder Lin (`village_elder.gd`) on the plaza with a Czech dialogue (`dialogue_box.gd`, G to advance); finishing it refills the gourd.
- Czech text for HUD hints, death/pause screens, altar prompt, path-choice screen and path profiles.
- Tests: 147 checks (gourd, elder, dialogue).
