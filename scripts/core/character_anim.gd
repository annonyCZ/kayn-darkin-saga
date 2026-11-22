class_name CharacterAnim
extends Node
## Procedural locomotion animation for the primitive-built humanoids:
## leg/arm swing from velocity, idle breathing, cape trailing, air tuck.
## Replace with AnimationTree + skeletal animations when real character assets arrive.

@export var body_path: NodePath
@export var leg_l_path: NodePath
@export var leg_r_path: NodePath
@export var arm_l_path: NodePath
@export var cape_path: NodePath
@export var head_path: NodePath
@export var torso_path: NodePath
@export var stride: float = 1.0
@export var hunch: float = 0.0     # enemies lean forward

var _phase: float = 0.0
var _t: float = 0.0
var _body: CharacterBody3D
var _leg_l: Node3D
var _leg_r: Node3D
var _arm_l: Node3D
var _cape: Node3D
var _head: Node3D
var _torso: Node3D
var _torso_base_y: float = 1.0

func _ready() -> void:
	_body = get_node_or_null(body_path) as CharacterBody3D
	_leg_l = get_node_or_null(leg_l_path) as Node3D
	_leg_r = get_node_or_null(leg_r_path) as Node3D
	_arm_l = get_node_or_null(arm_l_path) as Node3D
	_cape = get_node_or_null(cape_path) as Node3D
	_head = get_node_or_null(head_path) as Node3D
	_torso = get_node_or_null(torso_path) as Node3D

func _process(delta: float) -> void:
	if _body == null:
		return
	_t += delta
	var v := Vector3(_body.velocity.x, 0.0, _body.velocity.z)
	var sp := v.length()
	var move := clampf(sp / 6.5, 0.0, 1.5)
	_phase += delta * (3.0 + sp * 1.25)
	var swing := sin(_phase) * 0.85 * minf(move, 1.0) * stride
	var airborne := not _body.is_on_floor()
	if airborne:
		swing = 0.5
	if _leg_l: _leg_l.rotation.x = swing
	if _leg_r: _leg_r.rotation.x = -swing
	if _arm_l: _arm_l.rotation.x = -swing * 0.8 + (0.0 if move > 0.1 else sin(_t * 1.7) * 0.05)
	if _torso:
		_torso.rotation.x = -hunch - move * 0.12
		_torso.scale.y = 1.0 + sin(_t * 2.2) * 0.012
	if _head:
		_head.position.y = _head_base() + absf(sin(_phase)) * 0.03 * minf(move, 1.0) + sin(_t * 2.2) * 0.004
	if _cape:
		var lag := clampf(sp * 0.07, 0.0, 0.7)
		_cape.rotation.x = lerpf(_cape.rotation.x, 0.12 + lag + sin(_t * 3.0 + _phase * 0.5) * 0.05, clampf(8.0 * delta, 0.0, 1.0))

var _head_y: float = -1.0
func _head_base() -> float:
	if _head_y < 0.0:
		_head_y = _head.position.y
	return _head_y
