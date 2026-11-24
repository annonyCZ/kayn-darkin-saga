extends Node
## Headless integration tests. Run:
##   godot --headless --path . res://tests/test_runner.tscn
## Exits with code 0 on success, 1 on any failure.

var _fails := 0
var _checks := 0
var main: Node
var player: Player
var rig: CameraRig
var dummy: Enemy

func check(cond: bool, label: String) -> void:
	_checks += 1
	if cond:
		print("  PASS  ", label)
	else:
		_fails += 1
		print("  FAIL  ", label)

func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame

func press(action: String, frames_held: int = 2) -> void:
	Input.action_press(action)
	await frames(frames_held)
	Input.action_release(action)

## Sends a real InputEventAction (reaches _unhandled_input, unlike Input.action_press).
func tap_event(action: String) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	Input.parse_input_event(e)
	await frames(2)
	var r := InputEventAction.new()
	r.action = action
	r.pressed = false
	Input.parse_input_event(r)
	await frames(1)

func reset_player(pos: Vector3) -> void:
	player.global_position = pos
	player.velocity = Vector3.ZERO
	player.model.rotation = Vector3.ZERO     # facing -Z
	player.stamina = player.max_stamina
	player.health.health = player.health.max_health
	player.health.poise = player.health.max_poise
	player.health.dead = false
	player._set_state(Player.State.LOCOMOTION)

func _ready() -> void:
	await get_tree().process_frame
	get_node("/root/GameState").save_path = "user://test_save.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_save.cfg"))
	main = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	add_child(main)
	await frames(30)
	player = get_tree().get_first_node_in_group("player") as Player
	rig = get_tree().get_first_node_in_group("camera_rig") as CameraRig

	print("== Scene integrity")
	check(player != null, "player exists")
	check(rig != null and rig.follow_target == player, "camera rig follows player")
	check(get_tree().get_nodes_in_group("enemy").size() == 4, "4 enemies spawned")
	check(player.is_on_floor(), "player rests on arena floor (collision works)")
	for n in get_tree().get_nodes_in_group("enemy"):
		(n as Enemy).aggressive = false
	dummy = main.get_node("Enemy0") as Enemy

	print("== World collision and navigation")
	var space: PhysicsDirectSpaceState3D = main.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(Vector3(-22, 1.0, -14), Vector3(-4, 1.0, -14))
	q.collision_mask = 1
	var rh: Dictionary = space.intersect_ray(q)
	check(not rh.is_empty() and rh.position.x < -8.0, "rock blocks a horizontal ray (rocks have collision)")
	var nav_map: RID = main.get_world_3d().navigation_map
	check(not NavigationServer3D.map_get_regions(nav_map).is_empty(), "navigation region baked at load")
	await frames(3)
	var path: PackedVector3Array = NavigationServer3D.map_get_path(nav_map, Vector3(6, 0, -10), Vector3(22, 0, -10), true)
	var plen := 0.0
	for i in range(1, path.size()):
		plen += path[i].distance_to(path[i - 1])
	check(path.size() >= 2 and plen > 16.5, "navmesh path detours around a rock (len %.1f > 16)" % plen)

	print("== Movement")
	var start := player.global_position
	rig.yaw = 0.0
	Input.action_press("move_forward")
	await frames(40)
	Input.action_release("move_forward")
	check(start.z - player.global_position.z > 3.0, "move_forward travels along camera forward (-Z)")
	rig.yaw = PI / 2.0
	reset_player(Vector3(0, 0.1, 10))
	Input.action_press("move_forward")
	await frames(30)
	Input.action_release("move_forward")
	check(player.global_position.x < -2.0, "movement is camera-relative (yaw 90deg -> -X)")
	rig.yaw = 0.0
	await frames(30)
	reset_player(Vector3(0, 0.1, 10))
	await frames(20)    # let the player settle on the floor
	await tap_event("jump")
	await frames(2)
	check(player.global_position.y > 0.5 or not player.is_on_floor(), "jump leaves the ground")
	await frames(60)

	print("== Dodge")
	reset_player(Vector3(0, 0.1, 10))
	await frames(5)
	var s0 := player.stamina
	var p0 := player.global_position
	Input.action_press("move_right")
	await frames(2)
	await press("dodge", 2)
	await frames(2)
	check(player.state == Player.State.DODGE, "dodge enters DODGE state")
	check(player.health.invulnerable, "i-frames active at dodge start")
	check(player.stamina < s0, "dodge costs stamina")
	await frames(30)
	Input.action_release("move_right")
	check(absf(player.global_position.x - p0.x) > 2.0, "dodge displaces player")
	check(player.state != Player.State.DODGE and not player.health.invulnerable, "dodge ends, i-frames expire")

	print("== Light attack hits dummy")
	await frames(20)
	reset_player(Vector3(dummy.global_position.x, 0.1, dummy.global_position.z + 2.2))
	var hp0 := dummy.health.health
	await press("light_attack", 2)
	await frames(2)
	check(player.state == Player.State.ATTACK, "light attack enters ATTACK state")
	await frames(30)
	check(dummy.health.health < hp0, "light attack damages the dummy")
	check(dummy.health.health == hp0 - Player.ATTACKS["light1"]["dmg"], "damage applied exactly once per swing")

	print("== Combo chain")
	dummy.health.health = dummy.health.max_health
	reset_player(Vector3(dummy.global_position.x, 0.1, dummy.global_position.z + 2.0))
	await frames(40)
	await press("light_attack", 2)
	await frames(6)
	await press("light_attack", 2)    # buffered during first attack
	await frames(30)
	check(player._combo_index >= 2 or player._attack_name != "light1", "second light press chains into next combo hit")

	print("== Heavy attack breaks poise")
	await frames(60)
	dummy.health.health = dummy.health.max_health
	dummy.health.poise = dummy.health.max_poise
	reset_player(Vector3(dummy.global_position.x, 0.1, dummy.global_position.z + 2.0))
	await frames(10)
	await press("heavy_attack", 2)
	await frames(60)
	check(dummy.health.max_health - dummy.health.health >= 34.0, "heavy attack deals heavy damage")
	check(dummy.state == Enemy.State.STAGGER or dummy.health.poise > 0.0, "poise break staggers (or poise reset after stagger)")

	print("== Lock-on")
	await frames(90)
	reset_player(Vector3(dummy.global_position.x, 0.1, dummy.global_position.z + 5.0))
	rig.yaw = 0.0
	await tap_event("lock_on")
	check(player.lock_target != null, "Tab locks onto nearest enemy")
	check(rig.lock_target == player.lock_target, "camera receives lock target")
	await tap_event("lock_on")
	check(player.lock_target == null, "Tab again releases lock")

	print("== Enemy AI telegraph and damage")
	var foe := main.get_node("Enemy1") as Enemy
	foe.aggressive = true
	foe.windup_time = 0.5
	foe.global_position = Vector3(30, 0.1, 30)
	reset_player(Vector3(30, 0.1, 33))
	var php := player.health.health
	var saw_windup := false
	for i in 240:
		await frames(1)
		if foe.state == Enemy.State.WINDUP:
			saw_windup = true
		if player.health.health < php:
			break
	check(saw_windup, "enemy telegraphs (WINDUP) before striking")
	check(player.health.health < php, "enemy strike damages player")
	foe.aggressive = false
	foe._set_state(Enemy.State.IDLE)

	print("== Block, parry, guard break")
	var foe2 := main.get_node("Enemy3") as Enemy
	foe2.global_position = Vector3(30, 0.1, 0)
	reset_player(Vector3(30, 0.1, 2.0))     # player faces -Z toward foe2
	await frames(20)
	player.blocking = true
	player._block_t = 1.0                    # held guard (not a parry)
	var hp_b := player.health.health
	foe2.hitbox.attacker = foe2
	player.health.take_damage(20.0, 10.0, foe2)
	check(is_equal_approx(hp_b - player.health.health, 3.0), "held block reduces damage to 15%")
	player.stamina = 5.0
	player.health.poise = player.health.max_poise
	player.health.take_damage(10.0, 30.0, foe2)
	check(player.stamina == 0.0 and player.state == Player.State.STAGGER, "insufficient stamina -> guard break stagger")
	reset_player(Vector3(30, 0.1, 2.0))
	await frames(20)
	player.blocking = true
	player._block_t = 0.05                   # fresh block = parry window
	var hp_p := player.health.health
	foe2.health.poise = foe2.health.max_poise
	var staggers := [0]
	foe2.health.staggered.connect(func() -> void: staggers[0] += 1)
	player.health.take_damage(20.0, 10.0, foe2)
	check(player.health.health == hp_p, "parry negates damage")
	check(staggers[0] == 1, "parry staggers the attacker")
	player.blocking = false
	reset_player(Vector3(30, 0.1, 2.0))
	await frames(20)
	player.blocking = true
	player._block_t = 1.0
	hp_p = player.health.health
	player.model.rotation.y = PI               # facing away: guard doesn't cover
	player.health.take_damage(20.0, 0.0, foe2)
	check(hp_p - player.health.health == 20.0, "block does not cover hits from behind")
	player.blocking = false

	print("== Abilities and cooldowns")
	reset_player(Vector3(0, 0.1, 10))
	await frames(20)
	var p_ab := player.global_position
	await tap_event("ability_1")
	await frames(2)
	check(player.state == Player.State.ATTACK and player.cooldown_left("dashslash") > 5.0, "Shadow Step starts and goes on cooldown")
	await frames(40)
	check(p_ab.z - player.global_position.z > 2.5, "Shadow Step dashes forward")
	player.stamina = 100.0
	await tap_event("ability_1")
	check(player.state != Player.State.ATTACK, "ability refused while on cooldown")
	var targets: Array = [main.get_node("Enemy0"), main.get_node("Enemy1")]
	for t: Enemy in targets:
		t.health.health = t.health.max_health
		t.global_position = Vector3(-30 + targets.find(t) * 2.0, 0.1, 30)
	reset_player(Vector3(-29, 0.1, 30))
	await frames(10)
	player.stamina = 100.0
	await tap_event("ability_2")
	await frames(30)
	check(targets.all(func(t: Enemy) -> bool: return t.health.health < t.health.max_health), "Ground Slam hits every enemy in radius")

	print("== Dodge i-frames avoid damage")
	reset_player(Vector3(0, 0.1, 10))
	player.health.invulnerable = true
	var before := player.health.health
	player.health.take_damage(50.0, 0.0, null)
	check(player.health.health == before, "invulnerable ignores damage")
	player.health.invulnerable = false

	print("== Death and respawn")
	player.respawn_time = 0.3
	player.spawn_point = Vector3(0, 0.1, 10)
	reset_player(Vector3(5, 0.1, 5))
	player.health.take_damage(9999.0, 0.0, null)
	await frames(3)
	check(player.state == Player.State.DEAD, "lethal damage -> DEAD")
	await frames(40)
	check(player.state == Player.State.LOCOMOTION and player.health.health == player.health.max_health, "respawns with full health")
	check(player.global_position.distance_to(Vector3(0, 0.1, 10)) < 1.5, "respawns at spawn point")

	print("== Enemy death")
	var victim := main.get_node("Enemy2") as Enemy
	victim.health.take_damage(9999.0, 0.0, null)
	await frames(2)
	check(victim.state == Enemy.State.DEAD and not victim.is_in_group("enemy"), "enemy dies and leaves targeting group")

	print("== Settings / rebinding")
	var st := get_node("/root/Settings")
	st.rebind("jump", _key(KEY_J))
	var evs := InputMap.action_get_events("jump")
	check(evs.size() == 1 and (evs[0] as InputEventKey).physical_keycode == KEY_J, "rebind replaces jump binding")
	st.reset_bindings()
	check(InputMap.action_get_events("jump").size() >= 2, "reset restores defaults")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://settings.cfg"))

	print("== Kayn path permanence and effects")
	var gs := get_node("/root/GameState")
	gs.reset_campaign()
	player.apply_path(KaynPaths.Path.HUMAN)
	var base_hp := player.health.max_health
	check(gs.choose_path(KaynPaths.Path.RHAAST), "can choose a path once")
	check(not gs.choose_path(KaynPaths.Path.SHADOW_ASSASSIN), "second choice rejected (permanent)")
	check(not gs.choose_path(KaynPaths.Path.HUMAN), "cannot 'choose' human form")
	check(player.path == KaynPaths.Path.RHAAST, "player receives path via GameState signal")
	check(is_equal_approx(player.health.max_health, base_hp * 1.3), "Rhaast: +30% max health")
	var sc: Dictionary = player._scaled_attack("light1")
	check(is_equal_approx(sc["dmg"], 12.0 * 1.35) and is_equal_approx(sc["recover"], 0.26 * 1.15), "Rhaast: stronger, slower attacks")
	check(is_equal_approx(player._cd_max["slam"], 6.0), "Rhaast: Ground Slam cooldown -40%")
	player.health.health = 50.0
	player._on_hit_landed(dummy, 20.0)
	check(is_equal_approx(player.health.health, 53.0), "Rhaast: heals 15% of damage dealt")
	check(FileAccess.file_exists("user://test_save.cfg"), "choice autosaved")
	gs.reset_campaign()
	check(gs.load_game() and gs.path_locked and gs.kayn_path == KaynPaths.Path.RHAAST, "save/load restores locked path")
	player.apply_path(KaynPaths.Path.SHADOW_ASSASSIN)
	check(is_equal_approx(player._cd_max["dashslash"], 3.6) and player.profile["speed_mult"] == 1.2, "Shadow Assassin: faster, Shadow Step cooldown -40%")
	var sa: Dictionary = player._scaled_attack("light1")
	check(is_equal_approx(sa["recover"], 0.26 * 0.8), "Shadow Assassin: faster attacks")

	print("== Path choice UI and altar")
	gs.reset_campaign()
	player.apply_path(KaynPaths.Path.HUMAN)
	var altar := main.get_node("PathAltar") as PathAltar
	player.global_position = altar.global_position
	await frames(10)
	check(altar.try_open(), "altar opens choice screen when player is near")
	var ui: PathChoice = null
	for c in get_tree().root.get_children():
		if c is PathChoice:
			ui = c
	check(ui != null and get_tree().paused, "choice UI is up and game paused")
	ui.select(KaynPaths.Path.SHADOW_ASSASSIN)
	check(ui._confirm.visible and not ui._cards.visible, "confirmation prompt shown before committing")
	ui.cancel()
	check(not gs.path_locked, "backing out does not commit")
	ui.select(KaynPaths.Path.SHADOW_ASSASSIN)
	ui.confirm()
	await frames(2)
	check(gs.path_locked and gs.kayn_path == KaynPaths.Path.SHADOW_ASSASSIN and not get_tree().paused, "confirm commits, unpauses")
	check(not altar.try_open(), "altar cannot be reused after choice")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_save.cfg"))
	gs.reset_campaign()

	print("== Audio and VFX")
	for sn in ["swing", "hit", "parry", "block", "slam", "growl", "death", "dodge", "wind", "drone", "ui_move", "ui_click"]:
		var w := Sfx.get_stream(sn)
		check(w != null and w.data.size() > 1000, "synthesized sound '%s' has audio data" % sn)
	var before_fx := get_tree().root.get_child_count()
	Vfx.spark(Vector3(0, 1, 0))
	Vfx.shockwave(Vector3.ZERO, 4.0)
	Vfx.damage_number(Vector3(0, 2, 0), 12.0)
	check(get_tree().root.get_child_count() == before_fx + 3, "VFX helpers spawn effect nodes")
	var hud_fx := main.get_node("Hud")._fx as ColorRect
	check(hud_fx != null and hud_fx.material is ShaderMaterial, "HUD has the screen FX overlay")

	print("== Pause menu")
	var pm := main.get_node("PauseMenu") as PauseMenu
	pm.toggle()
	check(pm.is_open() and get_tree().paused, "pause menu opens and pauses the tree")
	pm.toggle()
	check(not pm.is_open() and not get_tree().paused, "pause menu closes and resumes")

	await _village_tests()
	await _menu_tests()

	print("\n%d checks, %d failed" % [_checks, _fails])
	get_tree().quit(1 if _fails > 0 else 0)

func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	return e

# ------------------------------------------------------------------ main menu
func _new_menu() -> MainMenu:
	var m := (load("res://scenes/ui/main_menu.tscn") as PackedScene).instantiate() as MainMenu
	m.dry_run = true
	m.fade_time = 0.05
	add_child(m)
	return m

func _menu_tests() -> void:
	print("== Main menu")
	var gs := get_node("/root/GameState")
	var st := get_node("/root/Settings")
	var old_prefix: String = gs.save_prefix
	var old_path: String = gs.save_path
	gs.save_prefix = "user://test_menu_"
	var wipe := func() -> void:
		for i in range(1, 4):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(gs.slot_path(i)))
	wipe.call()
	gs.reset_campaign()
	check(ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/ui/main_menu.tscn", "project starts on the main menu scene")
	check(ResourceLoader.exists(MainMenu.GAME_SCENE), "game scene targeted by the menu exists")

	var m := _new_menu()
	await frames(5)
	check(m.items.size() == 7, "menu has 7 entries")
	var labels: Array = []
	for id: String in m.items:
		labels.append((m.items[id] as MenuItem).label_text)
	check(labels == ["Pokračovat", "Nová hra", "Načíst hru", "Nastavení", "Galerie", "Autoři", "Ukončit hru"], "menu entries are Czech and in order")
	check((m.items["continue"] as MenuItem).disabled and (m.items["load"] as MenuItem).disabled, "Continue/Load disabled without saves")
	check(m._art.texture != null and m._art.texture.get_width() > 1000, "key art texture loaded")

	# --- New game
	var got: Array = []
	m.game_requested.connect(func(slot: int, new_game: bool) -> void: got.append([slot, new_game]))
	m.activate("new")
	check(got == [[1, true]], "New game requests slot 1 as a fresh campaign")
	check(FileAccess.file_exists(gs.slot_path(1)) and gs.slot == 1 and not gs.path_locked, "New game creates a fresh save in slot 1")
	m.queue_free()
	await frames(2)

	# --- Continue / Load with several slots
	gs.set_slot(2)
	gs.kayn_path = KaynPaths.Path.RHAAST
	gs.path_locked = true
	gs.save_game()
	gs.reset_campaign()
	m = _new_menu()
	await frames(3)
	check(not (m.items["continue"] as MenuItem).disabled and not (m.items["load"] as MenuItem).disabled, "Continue/Load enabled once saves exist")
	check(gs.latest_slot() in [1, 2], "latest_slot finds a save")
	got.clear()
	m.game_requested.connect(func(slot: int, new_game: bool) -> void: got.append([slot, new_game]))
	m.activate("load")
	await frames(3)
	check(m.panel is LoadPanel, "Load opens the slot list")
	var lp := m.panel as LoadPanel
	check(not lp.cards[0].disabled and not lp.cards[1].disabled and lp.cards[2].disabled, "occupied slots enabled, empty slot disabled")
	check("Rhaast" in LoadPanel.describe(gs.slot_info(2)), "slot card describes the chosen path")
	lp.cards[1].pressed.emit()
	check(got == [[2, false]] and gs.slot == 2 and gs.kayn_path == KaynPaths.Path.RHAAST and gs.path_locked, "loading slot 2 restores Rhaast path")
	m.queue_free()
	await frames(2)

	# --- New game with all slots full asks before overwriting
	gs.set_slot(3)
	gs.reset_campaign()
	gs.save_game()
	gs.reset_campaign()
	m = _new_menu()
	await frames(3)
	got.clear()
	m.game_requested.connect(func(slot: int, new_game: bool) -> void: got.append([slot, new_game]))
	m.activate("new")
	check(m.confirm_open and got.is_empty(), "New game with full slots asks for confirmation")
	(m._confirm_host.find_child("No", true, false) as Button).pressed.emit()
	await frames(2)
	check(not m.confirm_open and got.is_empty() and FileAccess.file_exists(gs.slot_path(2)), "cancelling keeps all saves untouched")
	m.activate("new")
	(m._confirm_host.find_child("Yes", true, false) as Button).pressed.emit()
	check(got.size() == 1 and got[0][1] == true and not gs.path_locked, "confirming overwrites the oldest slot with a new campaign")
	m.queue_free()
	await frames(2)
	wipe.call()

	# --- Quit confirmation
	m = _new_menu()
	await frames(3)
	var quits: Array = []
	m.quit_requested.connect(func() -> void: quits.append(1))
	m.activate("quit")
	check(m.confirm_open and quits.is_empty(), "Quit asks for confirmation first")
	await tap_event("ui_cancel")
	check(not m.confirm_open and quits.is_empty(), "Esc dismisses the quit dialog")
	m.activate("quit")
	(m._confirm_host.find_child("No", true, false) as Button).pressed.emit()
	check(quits.is_empty(), "'Stay' does not quit")
	m.activate("quit")
	(m._confirm_host.find_child("Yes", true, false) as Button).pressed.emit()
	check(quits.size() == 1, "'Quit' confirms and requests quit")
	m.queue_free()
	await frames(2)

	# --- Gallery, credits
	m = _new_menu()
	await frames(3)
	m.activate("gallery")
	await frames(3)
	var gp := m.panel as GalleryPanel
	check(gp != null and GalleryPanel.ITEMS.all(func(it: Dictionary) -> bool: return load(it["path"]) is Texture2D), "gallery opens and all images load")
	gp.show_index(1, true)
	check(gp.index == 1, "gallery moves to next image")
	await tap_event("ui_cancel")
	check(m.panel == null, "Esc closes the gallery")
	m.activate("credits")
	await frames(3)
	check(m.panel is CreditsPanel and "annonyCZ" in CreditsPanel.TEXT and "Riot" in CreditsPanel.TEXT, "credits show author and fan-project notice")
	m.close_panel()
	await frames(2)

	# --- Settings are real
	m.activate("settings")
	await frames(3)
	var sp := m.panel as SettingsPanel
	check(sp != null, "Settings panel opens")
	var rows: Array = sp._content.get_children().filter(func(n: Node) -> bool: return n is ChoiceRow)
	check(rows.size() == 6, "graphics tab has 6 options")
	var msaa_row := rows[3] as ChoiceRow
	msaa_row.set_index(0)
	msaa_row.step(2)
	check(st.msaa == 2 and get_tree().root.msaa_3d == Viewport.MSAA_4X, "MSAA option changes the viewport")
	var scale_row := rows[4] as ChoiceRow
	scale_row.set_index(5)
	scale_row.step(-2)
	check(is_equal_approx(st.render_scale, 0.8) and is_equal_approx(get_tree().root.scaling_3d_scale, 0.8), "3D scale option changes the viewport")
	var fps_row := rows[5] as ChoiceRow
	fps_row.set_index(0)
	fps_row.step(2)
	check(st.fps_cap == 60 and Engine.max_fps == 60, "FPS cap option applies")
	var vs_row := rows[2] as ChoiceRow
	vs_row.step(1)
	check(st.vsync == false, "V-Sync option stored")
	sp._set_tab(1)
	await frames(2)
	var sliders: Array = sp._content.get_children().filter(func(n: Node) -> bool: return n is SliderRow)
	check(sliders.size() == 3, "audio tab has 3 volume sliders")
	(sliders[0] as SliderRow).slider.value = 0.5
	check(is_equal_approx(st.vol_master, 0.5) and is_equal_approx(AudioServer.get_bus_volume_db(0), linear_to_db(0.5)), "master volume slider drives the Master bus")
	(sliders[1] as SliderRow).slider.value = 0.25
	var sfx_bus := AudioServer.get_bus_index("SFX")
	check(sfx_bus != -1 and is_equal_approx(AudioServer.get_bus_volume_db(sfx_bus), linear_to_db(0.25)), "effects slider drives the SFX bus")
	(sliders[2] as SliderRow).slider.value = 0.0
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Ambience")), "ambience slider at 0 mutes the Ambience bus")
	var cfg := ConfigFile.new()
	check(cfg.load("user://settings.cfg") == OK and is_equal_approx(float(cfg.get_value("audio", "master", -1.0)), 0.5)
		and int(cfg.get_value("graphics", "msaa", -1)) == 2, "settings persisted to disk")
	sp._set_tab(2)
	await frames(2)
	var sens := (sp._content.get_children().filter(func(n: Node) -> bool: return n is SliderRow)[0] as SliderRow)
	sens.slider.value = 1.75
	check(is_equal_approx(st.mouse_sensitivity, 1.75), "mouse sensitivity slider applies")
	# Rebinding keeps the gamepad binding and swaps conflicts.
	var jump_old: InputEventKey = null
	for e in InputMap.action_get_events("jump"):
		if e is InputEventKey:
			jump_old = e
	sp.begin_capture("jump")
	var swapped: String = sp.apply_capture(_key(KEY_J))
	var has_pad := InputMap.action_get_events("jump").any(func(e: InputEvent) -> bool: return e is InputEventJoypadButton)
	var has_j := InputMap.action_get_events("jump").any(func(e: InputEvent) -> bool: return e is InputEventKey and e.physical_keycode == KEY_J)
	check(swapped == "" and has_j and has_pad, "rebinding jump to J keeps the gamepad button")
	check(st.binding_text("jump") == "J", "binding label shows the new key")
	var dodge_old: String = st.binding_text("dodge")
	sp.begin_capture("dodge")
	swapped = sp.apply_capture(_key(KEY_J))
	check(swapped == "jump" and st.binding_text("dodge") == "J" and st.binding_text("jump") == dodge_old, "conflicting key is swapped between actions")
	sp.reset_defaults()
	check(st.vol_master == 0.8 and st.msaa == 0 and st.fps_cap == 0 and Engine.max_fps == 0 and st.binding_text("jump") == jump_old.as_text_physical_keycode(), "reset restores defaults")
	m.queue_free()
	await frames(2)
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://settings.cfg"))
	get_tree().root.msaa_3d = Viewport.MSAA_DISABLED
	get_tree().root.scaling_3d_scale = 1.0
	wipe.call()
	gs.save_prefix = old_prefix
	gs.save_path = old_path
	gs.reset_campaign()

# ------------------------------------------------------------------ village
func _village_tests() -> void:
	print("== Village (supplied Japanese pack + Chinese pavilion)")
	var v := main.get_node_or_null("TestArena/Village") as Village
	check(v != null, "village is part of the arena")
	if v == null:
		return
	check(v.prop_count >= 50, "village placed %d props" % v.prop_count)
	check(v.collider_count >= 20, "village props have colliders (%d)" % v.collider_count)
	check(v.pavilion != null and v.pavilion.unmatched_parts.is_empty(), "pavilion parts all got a material")
	check(v.pavilion.find_children("*", "MeshInstance3D", true, false).size() > 50, "pavilion model loaded")
	var missing := 0
	for e: Array in Village.LAYOUT:
		if not ResourceLoader.exists(Village.MODELS + e[0] + ".gltf"):
			missing += 1
	check(missing == 0, "every model in the village layout exists")
	var space: PhysicsDirectSpaceState3D = main.get_world_3d().direct_space_state
	# A ray from the side hits the first house (solid), a ray through the gate opening does not.
	var house_pos: Vector3 = Village.CENTER + Vector3(-11.0, 1.5, -3.0)
	var q := PhysicsRayQueryParameters3D.create(house_pos + Vector3(-8, 0, 0), house_pos + Vector3(8, 0, 0))
	q.collision_mask = 1
	check(not space.intersect_ray(q).is_empty(), "village house blocks a ray (has collision)")
	var gate_z: float = Village.CENTER.z + 11.5
	var q2 := PhysicsRayQueryParameters3D.create(Vector3(0, 1.2, gate_z + 4.0), Vector3(0, 1.2, gate_z - 4.0))
	q2.collision_mask = 1
	check(space.intersect_ray(q2).is_empty(), "tori gate opening is walkable")
	var nav_map: RID = main.get_world_3d().navigation_map
	var p := NavigationServer3D.map_get_path(nav_map, Village.CENTER + Vector3(0, 0, 16), Village.CENTER + Vector3(0, 0, -4), true)
	check(p.size() >= 2, "navmesh connects the arena to the village centre")
	var closest := NavigationServer3D.map_get_closest_point(nav_map, house_pos)
	check(Vector2(closest.x - house_pos.x, closest.z - house_pos.z).length() > 2.0, "navmesh is carved around houses")
	check(Village.contains_xz(Village.CENTER.x, Village.CENTER.z) and not Village.contains_xz(0.0, 0.0), "forest clearing covers the village only")
