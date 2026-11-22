# TECHNICAL STANDARDS — KAYN: THE DARKIN SAGA

Godot 4.7 + GDScript — Last updated: 2026

---

## 1. GDScript Konvence (GDScript Conventions)

### 1.1 Proměnné a proměnné typu (Variables & Type Hints)

**Zlaté pravidlo:** Vždy typ-hintovat každé `var` deklaraci, parameter, návratovou hodnotu a signal.

```gdscript
# Správně
var player: Node3D = get_node("Player")
var speed: float = 300.0
var is_alive: bool = true

# Špatně (vyhněte se)
var player = get_node("Player")  # Typ neznámý
var speed = 300.0  # Je to int nebo float?
```

**Constants ( Konstanty):** Nepotřebují type annotation, alevel uppercase s underscoreem:

```gdscript
const MAX_SPEED = 300.0
const GRAVITY = 9.8
```

**Function return types:** Vždy specifikovat:

```gdscript
func calculate_damage(attack: float, defense: float) -> float:
	return max(0, attack - defense)
```

### 1.2 Function Parameters

```gdscript
func move(direction: Vector3, delta: float) -> void:
	position += direction * speed * delta
```

### 1.3 Signals

**Definice signálů** vždy na začátku scriptu, před hlavní logikou:

```gdscript
signal health_changed(new_value: int, old_value: int)
signal enemy_died(killer: Node3D)
signal attack_landed(target: Node3D, damage: float)

# Použití signálu
func _ready():
	health_changed.connect(_on_health_changed)
```

**Naming convention:** snake_case pro signály:

```gdscript
signal player_entered_area(area: Node3D)  # Dobré
signal PlayerEnteredArea(area)  # Zbytečná capitalizace
```

### 1.4 Node Naming

- **Classes:** `class_name Player` nahoře v souboru
- **Node names:** PascalCase pro scény, které exportujeme, jinak camelCase nebo snake_case podle kontextu
- **Component names:** descriptive aabb, například `collision_shape`, `camera_pivot`, `armature`

### 1.5 Commenting

```gdscript
# špatně
# this function moves the player

# lépe
# Moves the player in the given direction.
# delta is the time since the last frame in seconds.
func move_player(direction: Vector3, delta: float):
	pass
```

---

## 2. Struktura Projektu (Project Structure)

```
res://
├── .gitignore              # Git ignore pro Godot
├── project.godot           # Konfigurace projektu
├── icon.svg                # Ikona aplikace
├── scenes/                 # Scény hry
│   ├── Main.tscn           # Hlavní scéna (bootstrap)
│   ├── Player.tscn         # Scéna hráče
│   ├── Enemy*.tscn         # Scény nepřátel (prefix pro grouping)
│   └── UI/*.tscn           # UI scény
├── scripts/                # GDScript soubory
│   ├── player.gd           # Hlavní skript hráče
│   ├── combat.gd           # Kampf systém
│   ├── progression.gd      # Vývojárství, runy, inventář
│   ├── world.gd            # Svět, NPC, frakce
│   └── *.gd                # Doprovodné skripty
├── resources/              # Resources (.tres, .json atd.)
│   ├── player_profile.tres # Uložení profilu hráče
│   └── quest_data.json     # Datové úkoly
├── assets/                 # Grafické a audio assets
│   ├── textures/           # Textury (.png, .jpeg)
│   ├── models/             # 3D modely (.glb, .obj)
│   ├── animations/         # Animace
│   │   ├── character/      # Animace postav
│   │   └── environment/    # Animace prostředí
│   ├── audio/              # Zvukové soubory
│   │   ├── music/          # Hudba
│   │   ├── sfx/            # Sound effects
│   │   └── ui/             # UI zvuky
│   └── generated/          # AI generované assets
├── UI/                     # UI komponenty a skripty
│   ├── HUD.tscn            # Head-Up Display
│   ├── Inventory.tscn      # Inventář
│   └── SkillTree.tscn      # Strom dovedností
├── tests/                  # Testovací skripty
│   ├── player_test.gd      # Testy pro hráče
│   └── combat_test.gd      # Testy pro combat systém
└── docs/                   # Dokumentace
	├── TECHNICAL_STANDARDS.md  # Aktuální soubor
	├── GDD.md              # Game Design Document
	└── design_notes/       # Návrhové poznámky
```

---

## 3. Signálové vzory (Signal Patterns)

### 3.1 Player → Main Communication

```gdscript
# player.gd
signal attack_pressed(attack_type: String)
signal take_damage(amount: float, source: Node3D)

func _process(_delta):
	if Input.is_action_pressed("ui_attack"):
		attack_pressed.emit("light")  # nebo "heavy"

# main.gd (nebo GameManager)
func _on_player_attack_pressed(attack_type):
	# Zpracování útoku
	pass
```

### 3.2 Node → Parent Communication

Používejte signály pro komunikaci mezi uzly a jejich rodiči. Vyhněte se přímým voláním funkcí na sibling nodes.

```gdscript
# Špatně (direct call)
get_parent().take_damage(10)

# Dobře (signal)
func take_damage(amount: float):
	pass

func _ready():
	take_damage.connect(parent.take_damage)
```

### 3.3 Event-Driven Architecture

Hra by měla být co nejvíce event-driven. Používejte signály namísto polling (dotazování) stavu.

---

## 4. Pojmenování (Naming Conventions)

### 4.1 GDScript Soubory

- **Hlavní skripty:** `lowercase snake_case` — `player.gd`, `combat_manager.gd`
- **UI komponenty:** `PascalCase` s prefixem — `HUD.gd`, `Inventory.gd`, `SkillTree.gd`
- **Utility skripty:** `utils_` prefix — `utils_random.gd`, `utils_math.gd`

### 4.2 Node Names v Scene

- **Player-related:** `Player`, `Camera`, `CameraPivot`, `Armature`
- **Enemy-related:** `Enemy`, `EnemySpawn`, `PatrolPoint`
- **UI elements:** `HUD`, `HealthBar`, `StaminaBar`, `ScoreText`
- **Physics:** `CollisionShape`, `CollisionArea`, `Area3D`
- **Avoid:** `Node`, `Target`, `Object1`, `Thing` — buďte specifický

### 4.3 Input Actions

- **Prefixy:** `ui_` pro built-in Godot inputy, vlastní akce používejte popisné názvy
- **Examples:** `ui_accept`, `ui_right`, `ui_up`, `ui_down`, `ui_left`, `ui_cancel`
- **Custom actions:** `attack_light`, `attack_heavy`, `dodge`, `interact`, `open_inventory`, `pause_game`

### 4.4 Animation Names

- **Prefixy podle stavu:** `idle`, `run`, `jump`, `fall`, `attack_light`, `attack_heavy`, `dodge`, `death`
- **Character-specific:** `knight_idle`, `knight_run`, `knight_attack_light`, `knight_dodge`
- **Procedural/Blend:** `blend_`, `trans_`

---

## 5. Testování (Testing)

### 5.1 Testovací struktura

Všechny testovací soubory patří do `res://tests/` adresáře.

```gdscript
# player_test.gd - Example
extends TestCase

func test_player_initial_health():
	var player = Player.new()
	assert_equal(player.health, 100)

func test_player_takes_damage():
	var player = Player.new()
	player.take_damage(25)
	assert_equal(player.health, 75)
```

### 5.2 Spuštění testů

```bash
# From project root
godot --headless -t run_tests -s res://tests/player_test.gd
```

### 5.3 Test coverage cíle

- Minimálně 80% cover pro hlavní gameplay skripty
- Testy pro: inicializace, základní funkce, error handling, edge cases
- Integrační testy pro scény a signály

### 5.4 Continuous Integration

Přidete do `.github/workflows/` CI pipeline pro automatické testování při pushnutí:

```yaml
# .github/workflows/godot-tests.yml
name: Godot Tests
on: [push, pull_request]
jobs:
  test:
	runs-on: ubuntu-latest
	steps:
	  - uses: actions/checkout@v4
	  - name: Run Godot tests
		run: godot --headless -t run_tests -s res://tests/*.gd
```

---

## 6. Import a Nastavení Posed (Import Settings)

### 6.1 Textury

- **Compression:** Lossy pro PNG textury, Lossless pro UI ikony
- **SRGB:** Zapnuté pro většinu textur
- **sRGB:** Zapnuté pro barevné textury
- **HDR:** Pro high dynamic range textury

### 6.2 3D Modely

- **Up Axis:** Z-up pro majority modelů
- **Flip Units:** True pro conversion z metrů na Godot jednotky
- **Generate Tangents:** True pro lighting

### 6.3 Audio

- **Loop:** Zapnuté pro ambience a hudbu
- **Bus:** Přiřaďte k příslušnému audio busu (music, sfx, ui)

---

## 7. Ukládání a Serializace (Saving & Serialization)

### 7.1 Resource Files (.tres)

Používejte `.tres` pro datové uložení které potřebuje být editoovatelné v editoru:

```gdscript
# player_profile.tres - uložené ručně nebo přes ResourceSaver
[ext_resource path="res://scripts/player.gd" type="Script" id=1]
[resource]
class_name PlayerProfile
member health: int = 100
member max_health: int = 100
member experience: int = 0
```

### 7.2 JSON Data

Pro složitější data používejte JSON s `parse_json` / `parse_native`:

```gdscript
func load_quest_data() -> void:
	var data = load("res://resources/quest_data.json").get_text()
	var quests = JSON.parse_inspect(data)
	# ... processed data
```

### 7.3 Player Save Data

Vždy ukládejte essential data:
- Úroveň postavy
- Health/Stamina aktuální hodnoty
- Odemčené schopnosti/techniky
- Rune slots a jejich hodnoty
- Proměna stav (human, shadow_assassin, rhaast)
- CO-OP character assignment
- Current scene position

---

## 8. Performance Guidelines (Performance)

### 8.1 Physics

- **Fixed process:** Používejte `_physics_process(delta)` pro fyziku, nikoliv `_process`
- **Collision layers:** Pečlivě nakonfigurované collision layers a masks
- **RigidBody:** Nepřidávejte neustálé force, pokud není nutné
- **CharacterBody3D:** Používejte `move_and_collide()` nebo `move_and_slide()`

### 8.2 Memory

- **Object pooling:** Pro časté instantiation/deinstruction (projectile, particle effects)
- **Resource caching:** `load()` volat jednou a cacheovat referenci
- **Unused resources:** `ResourceLoader.unload()`.

### 8.3 Drawing

- **Batch drawing:** Seskupujte podobné objekty do jediného DrawCall kde possível
- **Material instances:** Opakovaně používejte `Material.instance()` namísto vytváření nových
- **Transparency:** Minimalizujte transparentní materiály v cílených scénách

---

## 9. Debugging a Logging (Logging)

### 9.1 Debug Levels

```gdscript
enum DebugLevel:
	NONE = 0
	ERRORS = 1
	WARNINGS = 2
	INFO = 3
	DEBUG = 4

var debug_level: DebugLevel = DebugLevel.INFO

func debug_print(level: DebugLevel, message: String):
	if level >= debug_level:
		print("[DEBUG #${level}] ${message}")
```

### 9.2 Logging Patterns

```gdscript
# Vstupní bod
debug_print(DebugLevel.INFO, "Player spawned at ${position}")

# Error handling
try:
	var data = load(path)
except Err as e:
	debug_print(DebugLevel.ERROR, "Failed to load ${path}: ${e}")
	push_error(e)
```

### 9.3 Výstup v produkci

Výstup logů lze filtrovat podle `debug_level` pro produkční buildy. Vypínání logů v release buildu přes preprocessor defines.

---

## 10. Multiplayer Considerations (I když multiplayer není cílem hned)

I pro singleplayer architekturu mějte na paměti:

- **Authority:** Všchny změny stavu by měly jít přes autoritu servera (i když je to singleplayer s locally controlled character)
- **Replication:** Signály a by neměly záviset na pořadí příkazů
- **State sync:** Definujte clear state snapshot pro uložení a obnovu

---

## 11. Common Pitfalls (Běžné chyby)

| Chyba | Řešení |
|-------|--------|
| `var x` bez typu | Vždy typ-hintovat |
| `queue_free()` bez kontroly | `if not is_queued_free()` nebo `if is_instance_valid()` |
| Direct node access z libovolné úrovně | Používejte signály místo `get_parent().get_node()` |
| Unbounded arrays | Kontrolujte velikost/prazdnost před iterací |
| Forgetting to unsubscribe od signálů | `signal_name.disconnect()` v `_exit_tree()` |
| Hardcoded cesty k souborům | Používejte `res://` prefixy a konstanty |

---

**Konec dokumentu.** Tento standard platí pro všechny GDScript soubory v projektu KAYN: THE DARKIN SAGA. Pro jakékoli dotazy nebo úpravy kontaktujte vývojový tým.
