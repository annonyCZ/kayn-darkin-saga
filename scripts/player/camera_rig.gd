class_name CameraRig
extends Node3D
## Third-person over-the-shoulder camera: orbit, collision (SpringArm3D),
## lock-on framing, and trauma-based shake. Lives beside the player, not under it.

@export var follow_height: float = 1.5
@export var follow_smoothing: float = 14.0
@export var pitch_min_deg: float = -60.0
@export var pitch_max_deg: float = 55.0
@export var mouse_base_sens: float = 0.0028
@export var stick_speed: float = 2.8
@export var lock_turn_speed: float = 7.0

var yaw: float = 0.0
var pitch: float = -0.25
var follow_target: Node3D = null
var lock_target: Node3D = null
var trauma: float = 0.0
var capture_mouse_on_start: bool = true

@onready var _yaw_node: Node3D = $Yaw
@onready var _pitch_node: Node3D = $Yaw/Pitch
@onready var _arm: SpringArm3D = $Yaw/Pitch/SpringArm3D
@onready var camera: Camera3D = $Yaw/Pitch/SpringArm3D/Camera3D

func _ready() -> void:
	add_to_group("camera_rig")
	top_level = true
	if capture_mouse_on_start and DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# Autoload accessed dynamically so this script also compiles in tool/--script mode.
func _sens() -> float:
	var st := get_node_or_null("/root/Settings")
	return float(st.get("mouse_sensitivity")) if st else 1.0

func _invert_y() -> bool:
	var st := get_node_or_null("/root/Settings")
	return bool(st.get("invert_y")) if st else false

func set_follow_target(t: Node3D) -> void:
	follow_target = t
	if t is CollisionObject3D:
		_arm.add_excluded_object((t as CollisionObject3D).get_rid())
	global_position = t.global_position + Vector3.UP * follow_height

func add_trauma(amount: float) -> void:
	trauma = minf(1.0, trauma + amount)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if lock_target == null:
			var m: InputEventMouseMotion = event
			var inv: float = -1.0 if _invert_y() else 1.0
			yaw -= m.relative.x * mouse_base_sens * _sens()
			pitch -= m.relative.y * mouse_base_sens * _sens() * inv
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED \
			and DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if follow_target == null:
		return
	# Gamepad right stick
	var stick := Input.get_vector("cam_left", "cam_right", "cam_up", "cam_down")
	if lock_target == null and stick != Vector2.ZERO:
		var inv: float = -1.0 if _invert_y() else 1.0
		yaw -= stick.x * stick_speed * _sens() * delta
		pitch -= stick.y * stick_speed * _sens() * delta * inv
	# Lock-on framing: look from player toward target
	if lock_target != null and is_instance_valid(lock_target):
		var to_t := lock_target.global_position - follow_target.global_position
		var want_yaw := atan2(-to_t.x, -to_t.z)
		yaw = lerp_angle(yaw, want_yaw, clampf(lock_turn_speed * delta, 0.0, 1.0))
		var dist := Vector2(to_t.x, to_t.z).length()
		pitch = lerpf(pitch, clampf(-0.25 + dist * 0.01, -0.45, 0.0), clampf(4.0 * delta, 0.0, 1.0))
	pitch = clampf(pitch, deg_to_rad(pitch_min_deg), deg_to_rad(pitch_max_deg))
	var goal := follow_target.global_position + Vector3.UP * follow_height
	global_position = global_position.lerp(goal, clampf(follow_smoothing * delta, 0.0, 1.0))
	_yaw_node.rotation.y = yaw
	_pitch_node.rotation.x = pitch
	var want_fov := 70.0 + (8.0 if follow_target.get("is_sprinting") == true else 0.0)
	camera.fov = lerpf(camera.fov, want_fov, clampf(6.0 * delta, 0.0, 1.0))
	# Shake
	if trauma > 0.0:
		trauma = maxf(0.0, trauma - delta * 1.6)
		var s := trauma * trauma
		camera.h_offset = randf_range(-1.0, 1.0) * 0.12 * s
		camera.v_offset = randf_range(-1.0, 1.0) * 0.12 * s
	else:
		camera.h_offset = 0.0
		camera.v_offset = 0.0
