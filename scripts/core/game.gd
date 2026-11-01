extends Node
## Global game services (autoload "Game"): physics layer masks, HUD messages
## and scene flow. Keep this small; gameplay logic belongs in components.

signal message_requested(text: String, duration: float)

# Physics layer bit masks. Names are also set in Project Settings.
const LAYER_WORLD: int = 1
const LAYER_PLAYER: int = 2
const LAYER_ENEMY: int = 4
const LAYER_INTERACTABLE: int = 8

const MAIN_MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"
const MISSION_SCENE: String = "res://scenes/levels/mission_01.tscn"

## True while the win/fail screen is up, so the pause key is ignored.
var end_screen_active: bool = false


func show_message(text: String, duration: float = 2.5) -> void:
	message_requested.emit(text, duration)


func restart_level() -> void:
	end_screen_active = false
	get_tree().paused = false
	get_tree().reload_current_scene()


func go_to_main_menu() -> void:
	end_screen_active = false
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func load_scene(path: String) -> void:
	end_screen_active = false
	get_tree().paused = false
	get_tree().change_scene_to_file(path)
