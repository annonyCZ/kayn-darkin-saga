# KAYN: The Darkin Saga

Open-source 3D third-person action RPG built with **Godot 4** (GDScript). Fan project, MIT-licensed code - see [NOTICE.md](NOTICE.md).
*(CZ: open-source akční RPG ve 3. osobě pro Godot 4; kód pod MIT licencí, fanouškovský projekt bez vazby na Riot Games.)*

## Status: early prototype (v0.3.0)
Playable test arena: over-the-shoulder camera, lock-on, run/sprint/jump, dodge with i-frames, light combo + heavy,
block and parry, two abilities with cooldowns, Kayn's permanent Shadow Assassin / Rhaast choice at an altar (press G), poise/stagger, telegraphed melee enemies, HUD, rebindable controls.
Characters are placeholders; no audio, story, inventory, saves or co-op yet. See [docs/DEVELOPMENT_ROADMAP.md](docs/DEVELOPMENT_ROADMAP.md).

## Run
1. Install Godot 4.5 or newer (standard build, not .NET).
2. Open `project.godot`, press F5.

| Action | Keyboard / mouse | Gamepad |
|---|---|---|
| Move / camera | WASD / mouse | left / right stick |
| Sprint, jump, dodge | Shift, Space, Ctrl | L3, A, B |
| Light / heavy attack | LMB / RMB | X / Y |
| Block (tap just before a hit = parry) | F | LB |
| Abilities (Shadow Step, Ground Slam) | Q, E | RB, D-pad down |
| Lock-on, switch target | Tab, mouse wheel | R3, D-pad left/right |
| Interact (altar) | G | D-pad up |
| Pause | Esc | Start |

## Tests
```
godot --headless --path . res://tests/test_runner.tscn
```
Exit code 0 means all checks passed. CI runs this on every push (`.github/workflows/ci.yml`).
Scenes in `scenes/` are produced by `tools/build_scenes.gd`:
`godot --headless --path . --script res://tools/build_scenes.gd` (you can also edit them in the editor).

## Contributing
See [CONTRIBUTING.md](CONTRIBUTING.md). Do not submit Riot Games assets or other content you lack rights to.

## License
MIT for code and docs (see [LICENSE](LICENSE)); third-party items listed in [NOTICE.md](NOTICE.md) and `docs/ASSET_REGISTER.md`.
