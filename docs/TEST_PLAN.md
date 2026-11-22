# Test Plan
Run: `godot --headless --path . res://tests/test_runner.tscn` (exit code 0 = pass). 62 checks cover scene integrity,
movement, camera-relative control, dodge/i-frames, attacks, combo, poise, lock-on, enemy telegraph, death/respawn,
rebinding, and path permanence. Visual check: `SHOT_PATH=out.png xvfb-run godot --rendering-driver opengl3 res://tests/screenshot.tscn`.
Rebuild scenes after editing `tools/build_scenes.gd`: `godot --headless --path . --script res://tools/build_scenes.gd`.
