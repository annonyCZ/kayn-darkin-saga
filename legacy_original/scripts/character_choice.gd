# character_choice.gd - Systém volby cesty pro Kayna
# Podle kontextu projektu KAYN: THE DARKIN SAGA

extends Node

# Volby postavy
enum CharacterPath:
    HUMAN = 0       # Základní lidská podoba
    SHADOW_ASSASSIN = 1   # Rychlý assassin
    RHAST = 2         # Silák s Darkinou kosou

# Statická proměnná - výchozí volba
static var chosen_path: CharacterPath = CharacterPath.HUMAN
static var choice_made: bool = false

# Signály pro notifikaci ostatních systémů
signal path_selected(path: CharacterPath)
signal game_can_start()

func _ready() -> void:
    "Inicializace při startu"
    debug_print(0, "Character Choice System ready")
    # Volba se zpracuje při prvním spuštění nebo načtení uložené hry
    # Zde jen inicializace

func choose_shadow_assassin() -> void:
    "Výběr cesty Shadow Assassin"
    if not choice_made:
        chosen_path = CharacterPath.SHADOW_ASSASSIN
        choice_made = true
        emit_signal("path_selected", CharacterPath.SHADOW_ASSASSIN)
        debug_print(1, "Vybráno: SHADOW ASSASSIN")
        save_choice()
        check_start_game()

choose_rhaast() -> void:
    "Výběr cesty Rhaast"
    if not choice_made:
        chosen_path = CharacterPath.RHAST
        choice_made = true
        emit_signal("path_selected", CharacterPath.RHAST)
        debug_print(1, "Vybráno: RHAАST")
        save_choice()
        check_start_game()

func save_choice() -> void:
    "Uložení volby do projektových nastavení"
    # V Godot 4 se uloží do project.settings nebo resource
    # Zde jen vypíšeme
    debug_print(0, "Volba uložena: ${chosen_path}")

func check_start_game() -> void:
    "Kontrola, zda můžeme začít"
    if choice_made:
        emit_signal("game_can_start()")
        debug_print(1, "Může se začít s hrou - cesta zvolena")

func get_chosen_path() -> CharacterPath:
    "Vrací zvolenou cestu"
    return chosen_path

func debug_print(level: int, message: String) -> void:
    "Výpis debug informací"
    if level <= 0:
        print("[CHARACTER_CHOICE] ${message}")
