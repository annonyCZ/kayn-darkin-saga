# Known Issues
- Placeholder capsule characters; procedural swing animation only.
- Enemies have no navigation mesh (walk straight toward player; will snag on rocks). Rock models have no collision yet.
- Gamepad bindings defined but never tested on hardware.
- No pause menu: Esc only releases the mouse.
- Rock/material .tscn files reference old UIDs (harmless warnings; Godot falls back to paths).
- Not tested in the Godot 4.7 editor (verified on 4.5).
- Ability/block visuals are minimal (sword raise only); no VFX or sound.
