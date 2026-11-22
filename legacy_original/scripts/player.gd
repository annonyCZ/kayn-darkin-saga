# player.gd - Hlavní skript hráče pro KAYN: THE DARKIN SAGA
# Postupující standardy z TECHNICAL_STANDARDS.md

# === TŘÍDA A TYPY ===
class_name PlayerBody3D

extends CharacterBody3D

# === FYZIKA A POHYB ===

# Rychlost pohybu (exponovatelné v editoru)
@export var speed: float = 300.0

# Výška saltu (exponovatelné v editoru)
@export var jump_velocity: float = -10.0

# Gravitace (exponovatelné v editoru)
@export var gravity: float = -9.8

# === HRÁČ STAV ===

# Proměnné pro stav hráče (typ-hintované)
var health: int = 100
var max_health: int = 100

var stamina: float = 100.0
var max_stamina: float = 100.0

# Debug level pro výstup logů
var debug_level: int = 0

# === SIGNÁLY ===

# Tyto signály mohou být připojeny z UI, jiných nódů nebo scén:
# - health_changed(new_value, old_value)
# - stamina_changed(new_value, old_value)
# - attack_pressed(attack_type)
# - transform_changed(new_pos, new_rot)

signal health_changed(new_value: int, old_value: int)
signal stamina_changed(new_value: float, old_value: float)
signal attack_pressed(attack_type: String)
signal transform_changed(new_pos: Vector3, new_rot: Quaternion)

# === REFERENCE K KOMPONENTÁM ===

# Tyto uzly by měly být přidány v scene editoru:
# - CameraPivot (Node3D) jako child of Player
# - Camera (Camera3D) jako child of CameraPivot
# - AnimationTree (AnimationTree) pro řízení animací

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $Camera

# === INICIALIZACE ===

func _ready() -> void:
    "Inicializace hráče při startu scény"
	debug_print(0, "Player initialized")
	
	# Nastavení počátečních hodnot
	health = max_health
	stamina = max_stamina
	
	# Overení referencí
	if camera_pivot and camera:
		debug_print(1, "Camera setup complete")
	
	# Aplikace transformací na základě výběru postavy z začátku hry
	apply_character_transformations()

# === VSTUPNÍ OBRÁBĚNÍ ===

func _process(_delta: float) -> void:
    "Kontrola každý frame (ne fyzika)"
	handle_input()

func _physics_process(_delta: float) -> void:
    "Fyzikální aktualizace (pohyb, gravitace)"
	apply_physics(_delta)
	move_and_slide()

# === OBRÁBĚNÍ VSTUPU ===

func handle_input() -> void:
    "Zachytávání a zpracování hráčových vstupů"
	
	# Pohmov směrem (WASD nebo šipky)
	var input_dir: Vector3 = Vector3.ZERO
	
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_forward"):
		input_dir.z += 1
	if Input.is_action_pressed("move_backward"):
		input_dir.z -= 1
	
	# Normalizace směru
	if input_dir.length() > 0:
		input_dir = input_dir.normalized()
	
	# Aplikace směru (přes camera pivot)
	if input_dir != Vector3.ZERO:
		rotate_and_move(input_dir)

func rotate_and_move(direction: Vector3) -> void:
    "Otočení a pohyb směrem k camera"
	# Získání směru z kamery
	var camera_forward: Vector3 = camera.global_transform.basis.z
	camera_forward.y = 0  # Ignorovat vertikální složku
	camera_forward = camera_forward.normalized()
	
	var camera_right: Vector3 = camera.global_transform.basis.x
	camera_right.y = 0
	camera_right = camera_right.normalized()
	
	# Výpočet směru založeného na kameru
	var move_dir: Vector3 = (camera_forward * direction.z + camera_right * direction.x).normalized()
	
	# Aplikace pohybu
	velocity = move_dir * speed

# === FYZIKA ===

func apply_physics(_delta: float) -> void:
    "Aplikace gravitace a dalších fyzikálních sil"
	# Gravitace
	if not is_on_floor():
		velocity.y += gravity * _delta
	
	# Salt (pokud stisknuto a na zemi)
	if Input.is_action_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

# === UPDATE KAMERY ===

func update_camera_pivot() -> void:
    "Aktualizace pozice CameraPivot za hráčem"
	if camera_pivot:
		# CameraPivot stojí za hráčem a mírně nad ním
		# using global position so it follows the player
		camera_pivot.global_position = global_position + Vector3(0, 2, -5)

# === STATE MANAGEMENT ===

func take_damage(amount: int, source: Node3D = null) -> void:
    "Vzít poškození"
	health -= amount
	health = max(health, 0)
	
	debug_print(0, "Player took ${amount} damage, health is now ${health}")
	
	# Emitujeme signál
	health_changed.emit(health, health + amount)
	
	# Kontrola smrti
	if health <= 0:
		die()

func die() -> void:
    "Smrt hráče"
	debug_print(0, "Player died")
	if animation_tree:
		animation_tree.play("death")
	queue_free()

func recover_stamina(amount: float) -> void:
    "Obnovení styrky"
	stamina += amount
	stamina = min(stamina, max_stamina)
	stamina_changed.emit(stamina, stamina - amount)

# === DEBUG POMOCNÍKY ===

func debug_print(level: int, message: String) -> void:
    "Výpis debug informací podle úrovně"
	if level <= debug_level:
		print("[PLAYER DEBUG] ${message}")

func set_debug_level(level: int) -> void:
    "Nastavení úrovně debug výpisu"
	debug_level = level
	debug_print(0, "Debug level set to ${level}")

# === SYSTÉM VÝBĚRU CESTY PRO KAYNA ===

# Enum pro možné cesty postavy
enum CharacterPath:
	HUMAN = 0       # Lidská podoba (výchozí)
	SHADOW_ASSASSIN = 1   # Rychlý assassin - útoky Q/E/R
	RHAST = 2         # Silák - útoky LT/LB, vlastní schopnosti

# Aplikace transformací na základě zvolené cesty
func apply_character_transformations() -> void:
    "Aplikace transformací na základě vybrané cesty postavy"
	# Výchozí stav - hráč zvolení cestu při začátku nové hry
	# V praxi by tady došlo k připojení k systemu volby cesty
	# Zde jen základní logika podle statické proměnné
	
	# Výchozí chování - hráč začíná v lidské podobě
	# Transformace se aplikují později podle uvolené cesty
	debug_print(2, "Transformace postavy: výchozí lidská podoba")
	
	# Poznámka: Volba cesty (Shadow Assassin vs Rhaast)
	# by měla být provedena v systému začátku nové hry
	# a uložena pomocí Project Settings nebo Resources
	# následně by tato funkce kontrolovala zvolenou cestu

# Příprava pro budoucí integrace - proměnná pro sledování volby
var chosen_path: int = CharacterPath.HUMAN  # Výchozí: lidská podoba
EOF
echo "Player script rewritten clean"
