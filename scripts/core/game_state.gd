extends Node
## Autoload "GameState": campaign-wide state. Kayn's path is chosen once and is permanent per save.

signal path_chosen(path: int)

var kayn_path: int = KaynPaths.Path.HUMAN
var path_locked: bool = false
var save_path: String = "user://save_singleplayer.cfg"

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
