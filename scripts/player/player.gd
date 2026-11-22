class_name Player
extends CharacterBody3D
## Third-person action player (placeholder Kayn). Shared foundation for later
## Kayn/Aatrox variants: movement, stamina, dodge, light/heavy combo, lock-on.

enum State { LOCOMOTION, ATTACK, DODGE, STAGGER, DEAD }

signal stamina_changed
signal lock_target_changed(target: Node3D)
signal state_changed(state: State)
signal parried(attacker: Node)
signal guard_broken

const RUN_SPEED := 6.5
const SPRINT_SPEED := 9.5
const ACCEL := 45.0
const DECEL := 35.0
const AIR_CONTROL := 0.35
const JUMP_VELOCITY := 7.5
const GRAVITY := 22.0
const TURN_SPEED := 14.0
const DODGE_SPEED := 13.0
const DODGE_TIME := 0.38
const DODGE_IFRAMES := 0.24
const DODGE_COST := 22.0
const SPRINT_COST_PER_SEC := 14.0
const LOCK_RANGE := 22.0

## name -> {dmg, poise, windup, active, recover, lunge, arc:[from_y, to_y, from_x, to_x]}
const ATTACKS := {
	"light1": {"dmg": 12.0, "poise": 12.0, "windup": 0.10, "active": 0.12, "recover": 0.26, "lunge": 4.0, "arc": [75.0, -75.0, 0.0, 0.0]},
	"light2": {"dmg": 14.0, "poise": 14.0, "windup": 0.10, "active": 0.12, "recover": 0.26, "lunge": 4.0, "arc": [-75.0, 75.0, 0.0, 0.0]},
	"light3": {"dmg": 22.0, "poise": 24.0, "windup": 0.16, "active": 0.14, "recover": 0.40, "lunge": 6.0, "arc": [0.0, 0.0, 110.0, -15.0]},
	"dashslash": {"dmg": 26.0, "poise": 26.0, "windup": 0.08, "active": 0.18, "recover": 0.30, "lunge": 24.0, "arc": [80.0, -80.0, 0.0, 0.0], "cost": 20.0, "cd": 6.0, "iframes": true},
	"slam": {"dmg": 30.0, "poise": 40.0, "windup": 0.30, "active": 0.10, "recover": 0.50, "lunge": 0.0, "arc": [0.0, 0.0, 140.0, -30.0], "cost": 30.0, "cd": 10.0, "aoe": 4.5},
	"heavy": {"dmg": 34.0, "poise": 45.0, "windup": 0.42, "active": 0.16, "recover": 0.55, "lunge": 7.0, "arc": [0.0, 0.0, 130.0, -20.0]},
}
const ABILITIES := {"ability_1": "dashslash", "ability_2": "slam"}
const ABILITY_NAMES := {"dashslash": "Shadow Step", "slam": "Ground Slam"}
const PARRY_WINDOW := 0.2
const LIGHT_CHAIN := ["light1", "light2", "light3"]
const COMBO_RESET := 0.45

var state: State = State.LOCOMOTION
var stamina: float = 100.0
var max_stamina: float = 100.0
var lock_target: Node3D = null
var spawn_point: Vector3
var respawn_time: float = 2.5

var _stamina_delay: float = 0.0
var _attack_name: String = ""
var _attack_t: float = 0.0
var _attack_swing_started: bool = false
var _queued: String = ""
var _combo_index: int = 0
var _combo_timer: float = 99.0
var _state_t: float = 0.0
var _dodge_dir: Vector3 = Vector3.ZERO
var _tween: Tween
var _pose_tween: Tween
var _rig: CameraRig
var blocking: bool = false
var _block_t: float = 0.0
var _cooldowns: Dictionary = {"dashslash": 0.0, "slam": 0.0}

@onready var health: HealthComponent = $Health
@onready var model: Node3D = $Model
@onready var sword_pivot: Node3D = $Model/SwordPivot
@onready var hitbox: Hitbox = $Model/Hitbox
@onready var body_mesh: MeshInstance3D = $Model/Body

func _ready() -> void:
	add_to_group("player")
	spawn_point = global_position
	hitbox.attacker = self
	hitbox.hit_landed.connect(_on_hit_landed)
	health.damaged.connect(_on_damaged)
	health.staggered.connect(_on_staggered)
	health.died.connect(_on_died)
	health.intercept = _intercept_damage
	_reset_sword()

func _get_rig() -> CameraRig:
	if _rig == null or not is_instance_valid(_rig):
		_rig = get_tree().get_first_node_in_group("camera_rig") as CameraRig
	return _rig

func _cam_yaw() -> float:
	var r := _get_rig()
	return r.yaw if r else 0.0

func _input_dir() -> Vector3:
	var v := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	return Basis(Vector3.UP, _cam_yaw()) * Vector3(v.x, 0.0, v.y)

func _set_state(s: State) -> void:
	state = s
	_state_t = 0.0
	state_changed.emit(s)

func _unhandled_input(event: InputEvent) -> void:
	if state == State.DEAD:
		return
	if event.is_action_pressed("lock_on"):
		_toggle_lock()
	elif lock_target != null and event.is_action_pressed("target_next"):
		_switch_target(1)
	elif lock_target != null and event.is_action_pressed("target_prev"):
		_switch_target(-1)

func _physics_process(delta: float) -> void:
	_state_t += delta
	_combo_timer += delta
	_update_stamina(delta)
	for k: String in _cooldowns:
		_cooldowns[k] = maxf(0.0, _cooldowns[k] - delta)
	if lock_target != null and (not is_instance_valid(lock_target) or _target_dead(lock_target) \
			or global_position.distance_to(lock_target.global_position) > LOCK_RANGE * 1.4):
		_set_lock(null)
	match state:
		State.LOCOMOTION: _locomotion(delta)
		State.ATTACK: _attack(delta)
		State.DODGE: _dodge(delta)
		State.STAGGER: _stagger(delta)
		State.DEAD: _dead(delta)
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	move_and_slide()

# ---------------------------------------------------------------- locomotion
func _locomotion(delta: float) -> void:
	var dir := _input_dir()
	var want_block := Input.is_action_pressed("block") and is_on_floor() and stamina > 1.0
	if want_block:
		_block_t += delta
	else:
		_block_t = 0.0
	if want_block != blocking:
		blocking = want_block
		sword_pivot.rotation_degrees = Vector3(70.0, 0.0, 0.0) if blocking else Vector3(0.0, 40.0, 0.0)
	var sprinting := Input.is_action_pressed("sprint") and dir != Vector3.ZERO and stamina > 1.0 and not blocking
	var speed := SPRINT_SPEED if sprinting else RUN_SPEED
	if blocking:
		speed *= 0.5
	if sprinting:
		_spend_stamina(SPRINT_COST_PER_SEC * delta)
	var target_v := dir * speed
	var horiz := Vector3(velocity.x, 0.0, velocity.z)
	var control := 1.0 if is_on_floor() else AIR_CONTROL
	var rate := (ACCEL if dir != Vector3.ZERO else DECEL) * control
	horiz = horiz.move_toward(target_v, rate * delta)
	velocity.x = horiz.x
	velocity.z = horiz.z

	if is_on_floor() and Input.is_action_just_pressed("jump") and _spend_stamina(8.0):
		velocity.y = JUMP_VELOCITY

	_face_toward(_facing_dir(dir), delta)

	if Input.is_action_just_pressed("dodge") and is_on_floor():
		_start_dodge(dir)
	elif Input.is_action_just_pressed("ability_1"):
		_try_ability("dashslash")
	elif Input.is_action_just_pressed("ability_2"):
		_try_ability("slam")
	elif Input.is_action_just_pressed("light_attack"):
		_start_attack(_next_light())
	elif Input.is_action_just_pressed("heavy_attack"):
		_start_attack("heavy")

func _facing_dir(move_dir: Vector3) -> Vector3:
	if lock_target != null and is_instance_valid(lock_target):
		var d := lock_target.global_position - global_position
		d.y = 0.0
		return d.normalized() if d.length() > 0.01 else Vector3.ZERO
	return move_dir

func _face_toward(dir: Vector3, delta: float) -> void:
	if dir.length() < 0.01:
		return
	var want := atan2(-dir.x, -dir.z)
	model.rotation.y = lerp_angle(model.rotation.y, want, clampf(TURN_SPEED * delta, 0.0, 1.0))

func _snap_face(dir: Vector3) -> void:
	if dir.length() > 0.01:
		model.rotation.y = atan2(-dir.x, -dir.z)

func _model_forward() -> Vector3:
	return -model.global_transform.basis.z

# ---------------------------------------------------------------- stamina
func _spend_stamina(amount: float) -> bool:
	if stamina < amount:
		return false
	stamina -= amount
	_stamina_delay = 0.7
	stamina_changed.emit()
	return true

func _update_stamina(delta: float) -> void:
	_stamina_delay = maxf(0.0, _stamina_delay - delta)
	if _stamina_delay <= 0.0 and stamina < max_stamina:
		stamina = minf(max_stamina, stamina + 30.0 * delta)
		stamina_changed.emit()

# ---------------------------------------------------------------- dodge
func _start_dodge(dir: Vector3) -> void:
	if not _spend_stamina(DODGE_COST):
		return
	_dodge_dir = dir if dir != Vector3.ZERO else -_model_forward()
	_dodge_dir.y = 0.0
	_dodge_dir = _dodge_dir.normalized()
	if dir != Vector3.ZERO:
		_snap_face(_dodge_dir)
	health.invulnerable = true
	_set_state(State.DODGE)
	_pose_dodge()

func _dodge(_delta: float) -> void:
	var k := 1.0 - _state_t / DODGE_TIME           # ease-out dash
	var spd := DODGE_SPEED * clampf(k * 1.4, 0.2, 1.0)
	velocity.x = _dodge_dir.x * spd
	velocity.z = _dodge_dir.z * spd
	if _state_t >= DODGE_IFRAMES:
		health.invulnerable = false
	if _state_t >= DODGE_TIME:
		health.invulnerable = false
		_end_pose()
		_set_state(State.LOCOMOTION)

func _pose_dodge() -> void:
	if _pose_tween: _pose_tween.kill()
	_pose_tween = create_tween()
	body_mesh.scale = Vector3(1.0, 0.65, 1.0)
	_pose_tween.tween_property(body_mesh, "scale", Vector3.ONE, DODGE_TIME)

func _end_pose() -> void:
	if _pose_tween: _pose_tween.kill()
	body_mesh.scale = Vector3.ONE

# ---------------------------------------------------------------- attacks
func _next_light() -> String:
	if _combo_timer > COMBO_RESET + 0.5:
		_combo_index = 0
	var n: String = LIGHT_CHAIN[_combo_index % LIGHT_CHAIN.size()]
	return n

func cooldown_left(ability: String) -> float:
	return _cooldowns.get(ability, 0.0)

func cooldown_fraction(ability: String) -> float:
	return cooldown_left(ability) / float(ATTACKS[ability]["cd"])

func _try_ability(ability: String) -> void:
	if _cooldowns[ability] > 0.0 or stamina < float(ATTACKS[ability]["cost"]):
		return
	_cooldowns[ability] = float(ATTACKS[ability]["cd"])
	_start_attack(ability)

func _start_attack(name: String) -> void:
	var atk: Dictionary = ATTACKS[name]
	var cost: float = atk.get("cost", 12.0 if name != "heavy" else 25.0)
	if not _spend_stamina(cost):
		return
	blocking = false
	if atk.get("iframes", false):
		health.invulnerable = true
	_attack_name = name
	_attack_t = 0.0
	_attack_swing_started = false
	_queued = ""
	if name == "heavy":
		_combo_index = 0
	else:
		_combo_index = (_combo_index + 1) % LIGHT_CHAIN.size()
	var dir := _facing_dir(_input_dir())
	if dir == Vector3.ZERO:
		dir = _model_forward()
	_snap_face(dir)
	_set_state(State.ATTACK)
	_animate_swing(atk)

func _attack(delta: float) -> void:
	var atk: Dictionary = ATTACKS[_attack_name]
	_attack_t += delta
	var windup: float = atk["windup"]
	var active: float = atk["active"]
	var recover: float = atk["recover"]
	# buffer next input
	if Input.is_action_just_pressed("light_attack"):
		_queued = "light"
	elif Input.is_action_just_pressed("heavy_attack"):
		_queued = "heavy"
	# movement: lunge during active window, otherwise brake
	var fwd := _model_forward()
	if _attack_t >= windup and _attack_t < windup + active:
		velocity.x = fwd.x * float(atk["lunge"])
		velocity.z = fwd.z * float(atk["lunge"])
	else:
		velocity.x = move_toward(velocity.x, 0.0, 40.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 40.0 * delta)
	if _attack_t >= windup and not _attack_swing_started:
		_attack_swing_started = true
		hitbox.begin_swing(float(atk["dmg"]), float(atk["poise"]))
		if atk.has("aoe"):
			_apply_aoe(float(atk["aoe"]), float(atk["dmg"]), float(atk["poise"]))
	if _attack_t >= windup + active and _attack_swing_started:
		_attack_swing_started = false
		hitbox.end_swing()
		if atk.get("iframes", false):
			health.invulnerable = false
	# cancel into dodge during recovery
	if _attack_t >= windup + active and Input.is_action_just_pressed("dodge") and is_on_floor():
		_finish_attack()
		_start_dodge(_input_dir())
		return
	if _attack_t >= windup + active + recover * 0.55 and _queued != "":
		var q := _queued
		_finish_attack(false)
		_start_attack("heavy" if q == "heavy" else _next_light())
		return
	if _attack_t >= windup + active + recover:
		_finish_attack()

func _apply_aoe(radius: float, dmg: float, poise_dmg: float) -> void:
	for n in get_tree().get_nodes_in_group("enemy"):
		var e := n as Node3D
		if e and global_position.distance_to(e.global_position) <= radius:
			var h := e.get_node_or_null("Health") as HealthComponent
			if h and h.take_damage(dmg, poise_dmg, self):
				_on_hit_landed(e, dmg)

func _finish_attack(reset_state: bool = true) -> void:
	hitbox.end_swing()
	if _attack_name in ["dashslash"]:
		health.invulnerable = false
	_combo_timer = 0.0
	_reset_sword()
	if reset_state:
		_set_state(State.LOCOMOTION)

func _animate_swing(atk: Dictionary) -> void:
	if _tween: _tween.kill()
	var arc: Array = atk["arc"]
	if arc[2] != 0.0:
		sword_pivot.rotation_degrees = Vector3(arc[2] * 0.4, 0.0, 0.0)  # raise from rest
	else:
		sword_pivot.rotation_degrees = Vector3(0.0, arc[0], 0.0)
	_tween = create_tween()
	var windup: float = atk["windup"]
	var active: float = atk["active"]
	if arc[2] != 0.0:
		_tween.tween_property(sword_pivot, "rotation_degrees", Vector3(arc[2], 0.0, 0.0), windup)
		_tween.tween_property(sword_pivot, "rotation_degrees", Vector3(arc[3], 0.0, 0.0), active)
	else:
		_tween.tween_interval(windup)
		_tween.tween_property(sword_pivot, "rotation_degrees", Vector3(0.0, arc[1], 0.0), active)

func _reset_sword() -> void:
	if _tween:
		_tween.kill()
	sword_pivot.rotation_degrees = Vector3(0.0, 40.0, 0.0)

func _on_hit_landed(_target: Node, _amount: float) -> void:
	# hit-stop + camera shake for impact feedback
	var r := _get_rig()
	if r:
		r.add_trauma(0.35)
	if Engine.time_scale == 1.0:
		Engine.time_scale = 0.08
		get_tree().create_timer(0.05, true, false, true).timeout.connect(func() -> void: Engine.time_scale = 1.0)

# ---------------------------------------------------------------- block / parry
func _intercept_damage(amount: float, poise: float, source: Node) -> Dictionary:
	if state != State.LOCOMOTION or not blocking:
		return {}
	var src := source as Node3D
	if src:
		var to_src := (src.global_position - global_position)
		to_src.y = 0.0
		if to_src.length() > 0.01 and _model_forward().dot(to_src.normalized()) < 0.2:
			return {}      # hit from behind ignores the guard
	if _block_t <= PARRY_WINDOW:
		var sh := source.get_node_or_null("Health") as HealthComponent if source else null
		if sh:
			sh.take_damage(0.0, sh.max_poise, self)
		stamina = minf(max_stamina, stamina + 10.0)
		var r := _get_rig()
		if r:
			r.add_trauma(0.4)
		parried.emit(source)
		return {"cancel": true}
	var cost := poise * 0.8
	if stamina >= cost:
		_spend_stamina(cost)
		return {"amount": amount * 0.15, "poise": 0.0}
	stamina = 0.0
	guard_broken.emit()
	return {"poise": 9999.0}

# ---------------------------------------------------------------- damage states
func _on_damaged(_amount: float, _source: Node) -> void:
	var r := _get_rig()
	if r:
		r.add_trauma(0.5)
	var mat := body_mesh.get_active_material(0) as StandardMaterial3D
	if mat:
		mat.emission_enabled = true
		mat.emission = Color(1, 0.1, 0.1)
		var t := create_tween()
		t.tween_property(mat, "emission_energy_multiplier", 0.0, 0.25).from(2.0)

func _on_staggered() -> void:
	if state == State.DEAD:
		return
	hitbox.end_swing()
	_reset_sword()
	_end_pose()
	_set_state(State.STAGGER)

func _stagger(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 30.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 30.0 * delta)
	if _state_t >= 0.5:
		_set_state(State.LOCOMOTION)

func _on_died() -> void:
	hitbox.end_swing()
	_set_lock(null)
	_set_state(State.DEAD)
	model.rotation_degrees.x = -80.0

func _dead(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 30.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 30.0 * delta)
	if _state_t >= respawn_time:
		respawn()

func respawn() -> void:
	global_position = spawn_point
	velocity = Vector3.ZERO
	health.dead = false
	health.health = health.max_health
	health.poise = health.max_poise
	health.invulnerable = false
	health.changed.emit()
	stamina = max_stamina
	model.rotation_degrees.x = 0.0
	_end_pose()
	_set_state(State.LOCOMOTION)

# ---------------------------------------------------------------- lock-on
func _target_dead(t: Node) -> bool:
	var h := t.get_node_or_null("Health") as HealthComponent
	return h == null or h.dead

func _candidates() -> Array[Node3D]:
	var out: Array[Node3D] = []
	for n in get_tree().get_nodes_in_group("enemy"):
		var e := n as Node3D
		if e and not _target_dead(e) and global_position.distance_to(e.global_position) <= LOCK_RANGE:
			out.append(e)
	return out

func _angle_to(t: Node3D) -> float:
	var d := t.global_position - global_position
	var fwd := Basis(Vector3.UP, _cam_yaw()) * Vector3.FORWARD
	return fwd.signed_angle_to(Vector3(d.x, 0.0, d.z), Vector3.UP)

func _toggle_lock() -> void:
	if lock_target != null:
		_set_lock(null)
		return
	var best: Node3D = null
	var best_score := INF
	for c in _candidates():
		var score := absf(_angle_to(c)) * 8.0 + global_position.distance_to(c.global_position)
		if score < best_score:
			best_score = score
			best = c
	_set_lock(best)

func _switch_target(step: int) -> void:
	var cands := _candidates()
	if cands.size() < 2:
		return
	cands.sort_custom(func(a: Node3D, b: Node3D) -> bool: return _angle_to(a) > _angle_to(b))
	var i := cands.find(lock_target)
	_set_lock(cands[posmod(i + step, cands.size())])

func _set_lock(t: Node3D) -> void:
	lock_target = t
	var r := _get_rig()
	if r:
		r.lock_target = t
	lock_target_changed.emit(t)
