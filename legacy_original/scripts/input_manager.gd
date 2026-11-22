# input_manager.gd - Modulární systém pro správu vstupů pro KAYN: THE DARKIN SAGA
# Postupující standardy z TECHNICAL_STANDARDS.md

# === TŘÍDA: InputManager ===
class_name InputManager

# Singleton instance
extends Node

# === POHYB ===

# Směrové vstupy (camera-relative se zpracovává v PlayerController)
var move_forward: bool = false
var move_backward: bool = false
var move_left: bool = false
var move_right: bool = false

# Sprint a další stavové proměnné
var sprint_held: bool = false
var crouch_held: bool = false
var jump_pressed: bool = false
var dodge_pressed: bool = false

# === KAMERA ===

var camera_look_delta: Vector2 = Vector2.ZERO
var camera_zoom: float = 0.0
var camera_reset_requested: bool = false
var mouse_sensitivity: float = 1.0
var mouse_invert_y: bool = false

# === BOJ ===

var light_attack_pressed: bool = false
var heavy_attack_pressed: bool = false
var ability_1_pressed: bool = false
var ability_2_pressed: bool = false
var ability_3_pressed: bool = false
var ultimate_ability_pressed: bool = false
var block_pressed: bool = false
var parry_pressed: bool = false
var lock_on_pressed: bool = false

# Target switching during aim
var target_next_pressed: bool = false
var target_previous_pressed: bool = false

# === INTERAKCE ===

var interact_pressed: bool = false
var pickup_item_pressed: bool = false
var dialogue_skip_pressed: bool = false
var dialogue_next_pressed: bool = false

# === MENU ===

var pause_pressed: bool = false
var inventory_pressed: bool = false
var character_menu_pressed: bool = false
var skills_menu_pressed: bool = false
var map_pressed: bool = false
var quest_log_pressed: bool = false
var settings_pressed: bool = false

# === GAMEPAD PARAMETRY ===

var left_stick_deadzone: float = 0.3
var right_stick_deadzone: float = 0.3

# === INICIALIZACE ===

func _ready() -> void:
    "Inicializace InputManageru"
    debug_print(0, "InputManager initialized")
    
    # Poznámka: Detekce gamepadu se řeší přes Input Map v Godot editoru
    # Tady jen zaznamenáme stav
    debug_print(2, "Gamepad detection via Input Map editor")

# === ÚVĚROVNÝ ROZHRADÍ ===

func debug_print(level: int, message: String) -> void:
    "Výpis debug informací podle úrovně"
    if level <= 1:
        print("[INPUT MANAGER] ${message}")

# === UPDATE METODA ===

func _process(_delta: float) -> void:
    "Aktualizace stavu vstupů každý frame"
    update_input_state()
    update_camera_processing()
    check_processed_actions()

# === FYZIČTÍ PROCESS ===

func _physics_process(_delta: float) -> void:
    "Fyzikální aktualizace (pro event-based vstupy)"
    pass

# === ZPRACOVÁNÍ VSTUPŮ ===

func update_input_state() -> void:
    "Aktualizace klávesnicích a myšních vstupů"
    # Pohyb
    move_forward = Input.is_action_pressed("move_forward")
    move_backward = Input.is_action_pressed("move_backward")
    move_left = Input.is_action_pressed("move_left")
    move_right = Input.is_action_pressed("move_right")
    
    # Sprint (Left Shift)
    sprint_held = Input.is_action_pressed("sprint")
    
    # Jump (Space)
    jump_pressed = Input.is_action_just_pressed("jump")
    
    # Dodge (Left Ctrl)
    dodge_pressed = Input.is_action_just_pressed("dodge")
    
    # Crouch (C)
    crouch_held = Input.is_action_pressed("crouch")
    
    # Kamera
    # Získání relativního vektoru myši
    var mouse_motion = Input.get_vector("camera_look", "", "", "")
    camera_look_delta = mouse_motion * mouse_sensitivity
    
    # Pokud je invertujeme Y osu
    if mouse_invert_y:
        # Manualně invertujeme y složku
        camera_look_delta.y = -camera_look_delta.y
    
    # Kamera zoom (Mouse Wheel)
    # Godot 4 nemusí mít přímý get_axis pro wheel, zkusíme jinou metodu
    var wheel_delta = 0.0
    if Input.is_action_just_pressed("camera_zoom_in"):
        wheel_delta = 1.0
    elif Input.is_action_just_pressed("camera_zoom_out"):
        wheel_delta = -1.0
    camera_zoom = wheel_delta
    
    # Reset kamery (Home)
    camera_reset_requested = Input.is_action_just_pressed("camera_reset")
    
    # Boj
    light_attack_pressed = Input.is_action_just_pressed("light_attack")
    heavy_attack_pressed = Input.is_action_just_pressed("heavy_attack")
    ability_1_pressed = Input.is_action_just_pressed("ability_1")
    ability_2_pressed = Input.is_action_just_pressed("ability_2")
    ability_3_pressed = Input.is_action_just_pressed("ability_3")
    ultimate_ability_pressed = Input.is_action_just_pressed("ultimate_ability")
    block_pressed = Input.is_action_pressed("block")
    parry_pressed = Input.is_action_just_pressed("parry")
    lock_on_pressed = Input.is_action_just_pressed("lock_on")
    
    # Target switching (při zaměření)
    target_next_pressed = Input.is_action_just_pressed("target_next")
    target_previous_pressed = Input.is_action_just_pressed("target_previous")
    
    # Interakce
    interact_pressed = Input.is_action_just_pressed("interact")
    pickup_item_pressed = Input.is_action_just_pressed("pickup_item")
    dialogue_skip_pressed = Input.is_action_just_pressed("dialogue_skip")
    dialogue_next_pressed = Input.is_action_just_pressed("dialogue_next")
    
    # Menu
    pause_pressed = Input.is_action_just_pressed("pause")
    inventory_pressed = Input.is_action_just_pressed("inventory")
    character_menu_pressed = Input.is_action_just_pressed("character_menu")
    skills_menu_pressed = Input.is_action_just_pressed("skills_menu")
    map_pressed = Input.is_action_just_pressed("map")
    quest_log_pressed = Input.is_action_just_pressed("quest_log")
    settings_pressed = Input.is_action_just_pressed("settings")



func update_camera_processing() -> void:
    "Zpracování camera vstupů (voláno z _process)"
    # Toto může být rozšířeno o další logiku kamery
    pass

func check_processed_actions() -> void:
    "Kontrola a vyslání signálů pro gameplay systém"
    # Toto může být připojeno k PlayerProcessoru pro další zpracování
    pass

# === PUBLIC METODY PRO OSTATNÍ SYSTÉMY ===

# Vrátí směr pohybu jako Vector3 (byl zpracován camera-relative jinde)
func get_movement_direction() -> Vector3:
    "Vrací směr pohybu pro PlayerController"
    var direction: Vector3 = Vector3.ZERO
    
    if move_forward:
        direction.z += 1
    if move_backward:
        direction.z -= 1
    if move_right:
        direction.x += 1
    if move_left:
        direction.x -= 1
    
    # Normalizace - pokud je více směrů stisknuto najednou
    if direction.length_squared() > 0:
        return direction.normalized()
    return direction

# Vrátí stav sprintu (metoda pro přístup zvenčí)
func get_sprint_held() -> bool:
    return sprint_held

# Vrátí zda byl stisknut dodge tento frame
func was_dodged() -> bool:
    return dodge_pressed

# Vrátí zda byl stisknut jump tento frame
func was_jumped() -> bool:
    return jump_pressed

# Vrátí zda je stisknuto tlačítko crouch
func is_crouching() -> bool:
    return crouch_held

# Vrátí zda byl stisknut attack_light tento frame
func was_light_attack() -> bool:
    return light_attack_pressed

# Vrátí zda byl stisknut attack_heavy tento frame
func was_heavy_attack() -> bool:
    return heavy_attack_pressed

# Vrátí zda byl stisknut ability_1 tento frame
func was_ability_1() -> bool:
    return ability_1_pressed

# Vrátí zda byl stisknut ability_2 tento frame
func was_ability_2() -> bool:
    return ability_2_pressed

# Vrátí zda byl stisknut ability_3 tento frame
func was_ability_3() -> bool:
    return ability_3_pressed

# Vrátí zda byl stisknut ultimate_ability tento frame
func was_ultimate_ability() -> bool:
    return ultimate_ability_pressed

# Vrátí zda byl stisknut block tento frame
func was_blocking() -> bool:
    return block_pressed

# Vrátí zda byl stisknut parry tento frame
func was_parried() -> bool:
    return parry_pressed

# Vrátí zda byl stisknut lock-on tento frame
func was_lock_on() -> bool:
    return lock_on_pressed

# Vrátí požadavek na target next
func should_switch_target_next() -> bool:
    return target_next_pressed

# Vrátí požadavek na target previous
func should_switch_target_previous() -> bool:
    return target_previous_pressed

# Vrátí požadavek na reset kamery
func should_reset_camera() -> bool:
    return camera_reset_requested

# Getter pro mouse sensitivity
func get_mouse_sensitivity() -> float:
    return mouse_sensitivity

# Setter pro mouse sensitivity
func set_mouse_sensitivity(sensitivity: float) -> void:
    mouse_sensitivity = max(0.1, min(5.0, sensitivity))

# Getter pro mouse invert Y
func is_mouse_invert_y() -> bool:
    return mouse_invert_y

# Setter pro mouse invert Y
func set_mouse_invert_y(invert: bool) -> void:
    mouse_invert_y = invert