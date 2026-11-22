class_name Enemy
extends CharacterBody3D
## Melee enemy with readable telegraph: idle -> chase -> windup (red glow) ->
## strike -> recover. Poise break staggers it. `aggressive=false` makes a dummy.

enum State { IDLE, CHASE, WINDUP, ATTACK, RECOVER, STAGGER, DEAD }

signal state_changed(state: State)
signal killed(enemy: Enemy)

@export var display_name: String = "Husk Soldier"
@export var aggressive: bool = true
@export var move_speed: float = 3.6
@export var detect_range: float = 14.0
@export var attack_range: float = 2.3
@export var attack_damage: float = 14.0
@export var attack_poise_damage: float = 20.0
@export var windup_time: float = 0.65
@export var active_time: float = 0.15
@export var recover_time: float = 0.8
@export var stagger_time: float = 0.9

const GRAVITY := 22.0

var state: State = State.IDLE
var _t: float = 0.0
var _player: Node3D
var _tween: Tween

@onready var health: HealthComponent = $Health
@onready var model: Node3D = $Model
@onready var body_mesh: MeshInstance3D = $Model/Body
@onready var weapon_pivot: Node3D = $Model/WeaponPivot
@onready var hitbox: Hitbox = $Model/Hitbox
var _mat: StandardMaterial3D

func _ready() -> void:
	add_to_group("enemy")
	hitbox.attacker = self
	health.damaged.connect(_on_damaged)
	health.staggered.connect(_on_staggered)
	health.died.connect(_on_died)
	_mat = (body_mesh.get_active_material(0) as StandardMaterial3D).duplicate() as StandardMaterial3D
	body_mesh.material_override = _mat
	_rest_weapon()

func _set_state(s: State) -> void:
	state = s
	_t = 0.0
	state_changed.emit(s)

func _find_player() -> Node3D:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node3D
	return _player

func _flat_to_player() -> Vector3:
	var p := _find_player()
	if p == null:
		return Vector3.ZERO
	var d := p.global_position - global_position
	d.y = 0.0
	return d

func _player_alive() -> bool:
	var p := _find_player()
	if p == null:
		return false
	var h := p.get_node_or_null("Health") as HealthComponent
	return h != null and not h.dead

func _face(dir: Vector3, delta: float, rate: float = 10.0) -> void:
	if dir.length() > 0.01:
		model.rotation.y = lerp_angle(model.rotation.y, atan2(-dir.x, -dir.z), clampf(rate * delta, 0.0, 1.0))

func _physics_process(delta: float) -> void:
	_t += delta
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	var to_p := _flat_to_player()
	var dist := to_p.length()
	match state:
		State.IDLE:
			_brake(delta)
			if aggressive and _player_alive() and dist < detect_range:
				_set_state(State.CHASE)
		State.CHASE:
			if not _player_alive() or dist > detect_range * 1.8:
				_set_state(State.IDLE)
			elif dist > attack_range * 0.9:
				var d := to_p.normalized()
				velocity.x = d.x * move_speed
				velocity.z = d.z * move_speed
				_face(d, delta)
			else:
				_brake(delta)
				_face(to_p, delta)
				_start_windup()
		State.WINDUP:
			_brake(delta)
			if _t < windup_time * 0.6:
				_face(to_p, delta, 8.0)   # tracks the player, then commits
			if _t >= windup_time:
				_strike()
		State.ATTACK:
			var f := -model.global_transform.basis.z
			velocity.x = f.x * 5.0
			velocity.z = f.z * 5.0
			if _t >= active_time:
				hitbox.end_swing()
				_set_state(State.RECOVER)
		State.RECOVER:
			_brake(delta)
			if _t >= recover_time:
				_rest_weapon()
				_set_state(State.CHASE)
		State.STAGGER:
			_brake(delta)
			if _t >= stagger_time:
				_set_state(State.CHASE)
		State.DEAD:
			_brake(delta)
	move_and_slide()

func _brake(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 30.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 30.0 * delta)

func _start_windup() -> void:
	_set_state(State.WINDUP)
	# Telegraph: weapon raised + red glow ramping up
	if _tween: _tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(weapon_pivot, "rotation_degrees", Vector3(120.0, 0.0, 0.0), windup_time)
	_mat.emission_enabled = true
	_mat.emission = Color(1.0, 0.15, 0.05)
	_tween.tween_property(_mat, "emission_energy_multiplier", 2.5, windup_time).from(0.0)

func _strike() -> void:
	_set_state(State.ATTACK)
	hitbox.begin_swing(attack_damage, attack_poise_damage)
	if _tween: _tween.kill()
	_tween = create_tween()
	_tween.tween_property(weapon_pivot, "rotation_degrees", Vector3(-20.0, 0.0, 0.0), active_time)
	_mat.emission_energy_multiplier = 0.0

func _rest_weapon() -> void:
	if _tween: _tween.kill()
	weapon_pivot.rotation_degrees = Vector3(0.0, 30.0, 0.0)
	_mat.emission_energy_multiplier = 0.0

func _on_damaged(_amount: float, _source: Node) -> void:
	if state == State.DEAD:
		return
	# Being hit during windup does not cancel it unless poise breaks (readable trade).
	_mat.emission_enabled = true
	_mat.emission = Color(1, 1, 1)
	_mat.emission_energy_multiplier = 1.5
	var tw := create_tween()
	tw.tween_property(_mat, "emission_energy_multiplier", 0.0, 0.15)
	# knockback away from the player
	var away := -_flat_to_player().normalized()
	velocity.x += away.x * 3.0
	velocity.z += away.z * 3.0

func _on_staggered() -> void:
	if state == State.DEAD:
		return
	hitbox.end_swing()
	_rest_weapon()
	_set_state(State.STAGGER)

func _on_died() -> void:
	hitbox.end_swing()
	_rest_weapon()
	_set_state(State.DEAD)
	remove_from_group("enemy")
	$CollisionShape3D.set_deferred("disabled", true)
	var t := create_tween()
	t.tween_property(model, "rotation_degrees:x", -85.0, 0.4)
	t.tween_interval(2.5)
	t.tween_callback(queue_free)
	killed.emit(self)
