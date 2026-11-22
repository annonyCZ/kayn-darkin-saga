extends Node
## Autoload "GameState": campaign-wide state. Ported from the original
## character_choice.gd concept: Kayn's path is chosen once and is permanent per save.

enum KaynPath { HUMAN, SHADOW_ASSASSIN, RHAAST }

signal path_chosen(path: KaynPath)

var kayn_path: KaynPath = KaynPath.HUMAN
var path_locked: bool = false

## Returns true if the choice was accepted. Permanent once confirmed.
func choose_path(path: KaynPath) -> bool:
	if path_locked or path == KaynPath.HUMAN:
		return false
	kayn_path = path
	path_locked = true
	path_chosen.emit(path)
	return true

func reset_campaign() -> void:
	kayn_path = KaynPath.HUMAN
	path_locked = false
