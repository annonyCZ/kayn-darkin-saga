class_name Hitbox
extends Area3D
## Melee hitbox. Enabled for a swing's active window; polls overlaps each physics
## frame (deterministic) and damages each target at most once per swing.

var damage: float = 10.0
var poise_damage: float = 10.0
var attacker: Node = null
var _active: bool = false
var _hit: Array[Node] = []

signal hit_landed(target: Node, amount: float)

func _ready() -> void:
	monitoring = false
	monitorable = false

func begin_swing(dmg: float, poise_dmg: float) -> void:
	damage = dmg
	poise_damage = poise_dmg
	_hit.clear()
	_active = true
	monitoring = true

func is_active() -> bool:
	return _active

func end_swing() -> void:
	_active = false
	monitoring = false

func _physics_process(_delta: float) -> void:
	if not _active:
		return
	for body in get_overlapping_bodies():
		if body == attacker or _hit.has(body):
			continue
		var h := body.get_node_or_null("Health") as HealthComponent
		if h == null:
			continue
		_hit.append(body)
		if h.take_damage(damage, poise_damage, attacker):
			hit_landed.emit(body, damage)
