# Known Issues
- Placeholder capsule characters; procedural swing animation only.
- Navigation is baked at load from static colliders (scripts/world/arena_nav.gd); fine for the test arena, large worlds need a pre-baked/tiled navmesh. Enemies do not yet avoid each other.
- Gamepad bindings defined but never tested on hardware.
- Pause menu is minimal (Resume / Quit); no settings screen yet.
- Rock/material .tscn files reference old UIDs (harmless warnings; Godot falls back to paths).
- Not tested in the Godot 4.7 editor (verified on 4.5).
- Ability/block visuals are minimal (sword raise only); no VFX or sound.
