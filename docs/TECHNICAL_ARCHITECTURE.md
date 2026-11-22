# Technical Architecture
- Autoloads: Settings (input/config), GameState (campaign state, Kayn path lock).
- Player (CharacterBody3D, state machine LOCOMOTION/ATTACK/DODGE/STAGGER/DEAD) + CameraRig (separate top-level node).
- Combat: HealthComponent (health/poise/i-frames) + Hitbox (Area3D, polled). Layers: 1 world, 2 player, 3 enemy, 4/5 hitboxes.
- Enemy: state machine with telegraphed attacks. Levels: scenes/levels. Tests: tests/.
