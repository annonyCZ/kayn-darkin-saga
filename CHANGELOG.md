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

## 0.5.0 - 2026-11-24
- Main menu (Czech) is now the start scene: Pokračovat, Nová hra, Načíst hru, Nastavení, Galerie, Autoři, Ukončit hru (with confirmation).
  Key art of the author's Kayn (right), animated mist, embers, ash, falling leaves, pulsing Darkin-arm glow, mouse parallax, fade transitions.
- Three save slots (GameState.slot_info/latest_slot/first_empty_slot); slot 1 keeps the original save file.
- Real settings: window mode, resolution, V-Sync, MSAA, 3D render scale, FPS cap; master/effects/ambience volume (new SFX and Ambience audio buses);
  mouse sensitivity, Y inversion, keyboard/mouse rebinding with conflict swap (gamepad bindings preserved). All persisted in user://settings.cfg.
- Gallery of the supplied concept art, credits screen, UI sounds (ui_move, ui_click).
- Pause menu got a "Main menu" button. Fonts Cinzel and Cormorant Garamond (OFL) added.
- 117 headless checks (43 new for the menu); tests/menu_screenshot.* and tests/menu_flow_check.* for visual and end-to-end checks (need a display).
