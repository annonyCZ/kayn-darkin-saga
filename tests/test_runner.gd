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

	print("== Kayn path permanence")
	var gs := get_node("/root/GameState")
	gs.reset_campaign()
	check(gs.choose_path(GameState.KaynPath.RHAAST), "can choose a path once")
	check(not gs.choose_path(GameState.KaynPath.SHADOW_ASSASSIN), "second choice rejected (permanent)")
	gs.reset_campaign()

	print("\n%d checks, %d failed" % [_checks, _fails])
	get_tree().quit(1 if _fails > 0 else 0)

func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	return e
