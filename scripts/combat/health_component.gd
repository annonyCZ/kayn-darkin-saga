class_name HealthComponent
extends Node
## Health + poise (stagger) + invulnerability. Attach as a child named "Health".

signal damaged(amount: float, source: Node)
signal staggered
signal died
signal changed

@export var max_health: float = 100.0
@export var max_poise: float = 40.0
@export var poise_regen_per_sec: float = 20.0
@export var poise_regen_delay: float = 1.5

var health: float
var poise: float
var invulnerable: bool = false
## Optional hook: func(amount, poise, source) -> Dictionary {cancel?, amount?, poise?}
var intercept: Callable = Callable()
var dead: bool = false
var _since_poise_hit: float = 99.0

func _ready() -> void:
	health = max_health
	poise = max_poise

func _process(delta: float) -> void:
	_since_poise_hit += delta
	if not dead and _since_poise_hit > poise_regen_delay and poise < max_poise:
		poise = minf(max_poise, poise + poise_regen_per_sec * delta)

## Returns true if damage was applied.
func take_damage(amount: float, poise_damage: float = 0.0, source: Node = null) -> bool:
	if dead or invulnerable:
		return false
	if intercept.is_valid():
		var r: Dictionary = intercept.call(amount, poise_damage, source)
		if r.get("cancel", false):
			return false
		amount = r.get("amount", amount)
		poise_damage = r.get("poise", poise_damage)
	health = maxf(0.0, health - amount)
	poise -= poise_damage
	_since_poise_hit = 0.0
	damaged.emit(amount, source)
	changed.emit()
	if health <= 0.0:
		dead = true
		died.emit()
		return true
	if poise <= 0.0:
		poise = max_poise
		staggered.emit()
	return true

func heal(amount: float) -> void:
	if dead:
		return
	health = minf(max_health, health + amount)
	changed.emit()

func fraction() -> float:
	return health / max_health
