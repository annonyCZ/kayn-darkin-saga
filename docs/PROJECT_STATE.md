# Project State (updated 2026-11-24)

**Engine:** Godot 4.5 (verified headless). Original project targeted 4.7; `config/features` set to 4.5 so it opens in 4.5+.

## Done and verified (135 automated checks pass)
- Phase 0: project initialised, folder structure, git, docs.
- Milestone 1 playable prototype: third-person over-the-shoulder camera (collision, lock-on framing, shake),
  camera-relative movement (run/sprint/jump), stamina, dodge with i-frames, 3-hit light combo + heavy with
  buffering and dodge-cancel, hitbox/health/poise/stagger, hit-stop, lock-on + target switching,
  melee enemy AI with red-glow telegraph, death/respawn, HUD, rebindable inputs (saved to user://settings.cfg),
  permanent Kayn path choice logic (GameState).
- v0.2.0: block (reduced damage, guard break when out of stamina), parry window, two cooldown abilities (Shadow Step dash with i-frames, Ground Slam AoE) with HUD cooldown bars.
- v0.3.0 (Phase 5, first pass): Kayn's permanent path choice. Altar in the arena (press G) opens a choice screen showing pros/cons and a confirmation step; Shadow Assassin (fast, fragile, short Shadow Step cooldown) and Rhaast (tanky, hard-hitting, lifesteal, short Ground Slam cooldown) change stats, colour and weapon shape. Choice autosaves to user://save_singleplayer.cfg and reloads on start.
- Rocks in the arena are solid (wrapped in StaticBody3D - the demo scenes only carried a shape). Navmesh baked at load; enemies use NavigationAgent3D to path around obstacles. Pause menu (Esc).
- Visual pass 1: procedural terrain (flat arena plateau + hills, slope-blended grass/rock shader), 420 low-poly pines with trunk colliders, ~16k wind-swayed grass clumps, golden-hour lighting, ACES tonemap, bloom, SSAO, fog + volumetric fog. Navmesh now baked from terrain; rocks carve holes via NavigationObstacle3D.
- Visual pass 2: humanoid Kayn (white hair, visor, plate, cape, crescent scythe) and horned Husk enemies built from primitives with procedural locomotion animation (scripts/core/character_anim.gd); Husk Brute variant (bigger, tougher).
- Visual pass 3: procedurally synthesized SFX + ambient wind/drone (scripts/core/sfx.gd), sparks/dust/shockwave/damage numbers (vfx.gd), scythe trail, lock-on marker, sprint FOV kick.
- HUD polish: gold-framed bars, cinematic screen overlay (vignette, grain, hurt flash, low-health pulse). Prompts and pipeline for creating an original hero model with AI: docs/CHARACTER_AI_PROMPTS.md.
- v0.5.0 main menu: Czech menu scene (`scenes/ui/main_menu.tscn`, scripts in `scripts/ui/menu/`) is the start scene. Continue / New game / Load (3 slots) / Settings (graphics, audio, controls) / Gallery / Credits / Quit with confirmation. Settings are applied live and saved; save slots live in GameState. Visual verification: software-GL screenshots (xvfb) plus end-to-end flow check menu -> game -> pause -> menu.
- v0.6.0 village: supplied Japanese pack + Chinese pavilion placed as a village at the north edge of the plateau (world centre (0,0,-36)); collision, navmesh carving, forest clearing. Licences of both packs are unverified (see ASSET_REGISTER).
- Test arena: real scene using CC0 rock models and ground texture from the Terrain3D demo.
- Rendering verified with xvfb + OpenGL (screenshot looked correct).

## Placeholder / not done
- All characters are capsule placeholders; animation is procedural tweening (no skeletal animation).
- No recorded audio/music, full save/load (saves only hold the Kayn path choice; no position/inventory yet), inventory, quests, NPCs, bosses.
- Phases 3 (partial: gamepad untested, no walk toggle), 4 (partial: charged attacks missing), 5-14 not started.
- Terrain3D addon is NOT in the repo (gitignored); install it for Phase 7 world terrain.
- Kayn paths differ by stat multipliers only; unique movesets, abilities, animations and VFX per path are still to do. Path-specific narrative consequences not written.
- No co-op networking yet.

## Original files
Your first attempt (`kayn.zip`) is preserved in `legacy_original/` (ignored by Godot). Its scripts were not valid
GDScript (stray string "docstrings", mixed indentation) and its project.godot input section was malformed, so
they were rewritten rather than patched; the path-choice idea lives on in `scripts/core/game_state.gd`.
