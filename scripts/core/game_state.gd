extends Node
## Autoload "GameState": campaign-wide state. Kayn's path is chosen once and is permanent per save.

signal path_chosen(path: int)

var kayn_path: int = KaynPaths.Path.HUMAN
var path_locked: bool = false
var save_path: String = "user://save_singleplayer.cfg"

const SLOT_COUNT := 3
## Currently active save slot (1..SLOT_COUNT). Slot 1 keeps the original single-player save file.
var slot: int = 1

## Directory prefix of save files (tests point it elsewhere so real saves are never touched).
var save_prefix: String = "user://"

func slot_path(i: int) -> String:
	return save_prefix + ("save_singleplayer.cfg" if i == 1 else "save_slot_%d.cfg" % i)

func set_slot(i: int) -> void:
	slot = clampi(i, 1, SLOT_COUNT)
	save_path = slot_path(slot)

## Summary of a slot for the menu: {exists, path, kayn_path, path_locked, saved_unix}.
func slot_info(i: int) -> Dictionary:
	var info := {"exists": false, "kayn_path": KaynPaths.Path.HUMAN, "path_locked": false, "saved_unix": 0}
	var p := slot_path(i)
	var cfg := ConfigFile.new()
	if not FileAccess.file_exists(p) or cfg.load(p) != OK:
		return info
	info["exists"] = true
	info["kayn_path"] = int(cfg.get_value("campaign", "kayn_path", KaynPaths.Path.HUMAN))
	info["path_locked"] = bool(cfg.get_value("campaign", "path_locked", false))
	info["saved_unix"] = int(FileAccess.get_modified_time(p))
	return info

## Slot with the most recent save, or 0 if there is no save at all.
func latest_slot() -> int:
	var best := 0
	var best_t := -1
	for i in range(1, SLOT_COUNT + 1):
		var inf := slot_info(i)
		if inf["exists"] and int(inf["saved_unix"]) > best_t:
			best = i
			best_t = int(inf["saved_unix"])
	return best

## First empty slot, or 0 if all are used.
func first_empty_slot() -> int:
	for i in range(1, SLOT_COUNT + 1):
		if not slot_info(i)["exists"]:
			return i
	return 0

## Returns true if the choice was accepted. Permanent once confirmed; autosaves.
func choose_path(path: int) -> bool:
	if path_locked or path == KaynPaths.Path.HUMAN or not KaynPaths.PROFILES.has(path):
		return false
	kayn_path = path
	path_locked = true
	path_chosen.emit(path)
	save_game()
	return true

func reset_campaign() -> void:
	kayn_path = KaynPaths.Path.HUMAN
	path_locked = false

func save_game() -> bool:
	var cfg := ConfigFile.new()
	cfg.set_value("campaign", "version", 1)
	cfg.set_value("campaign", "kayn_path", kayn_path)
	cfg.set_value("campaign", "path_locked", path_locked)
	return cfg.save(save_path) == OK

## Loads the campaign without emitting path_chosen (the player reads kayn_path when it spawns).
func load_game() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(save_path) != OK:
		return false
	kayn_path = int(cfg.get_value("campaign", "kayn_path", KaynPaths.Path.HUMAN))
	path_locked = bool(cfg.get_value("campaign", "path_locked", false))
	return true
