extends Node
## Global tuning, mission flags, and save data for BLACKLINE.

## --- Easy tuning (edit these) ---
var mouse_sensitivity := 0.12
var move_speed := 5.0
var sprint_speed := 8.2
var jump_velocity := 4.5
var vehicle_max_speed := 22.0
var vehicle_acceleration := 16.0
var enemy_damage := 7.0
var player_gun_damage := 34.0
var difficulty := 1.0

signal health_changed(current: float, maximum: float)
signal ammo_changed(mag: int, reserve: int)
signal objective_changed(text: String)
signal wanted_changed(active: bool)
signal prompt_changed(text: String)
signal dialogue_started(speaker: String, text: String)
signal dialogue_finished
signal mission_failed(reason: String)
signal mission_completed
signal feedback_message(text: String)

var player: Node3D = null
var wanted := false
var input_locked := false
var current_objective := ""
var mission_01_complete := false

const SAVE_PATH := "user://blackline_save.cfg"


func _ready() -> void:
	load_progress()


func register_player(node: Node3D) -> void:
	player = node


func set_wanted(active: bool) -> void:
	if wanted == active:
		return
	wanted = active
	wanted_changed.emit(wanted)


func set_objective(text: String) -> void:
	current_objective = text
	objective_changed.emit(text)


func set_prompt(text: String) -> void:
	prompt_changed.emit(text)


func notify_feedback(text: String) -> void:
	feedback_message.emit(text)


func load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	mission_01_complete = bool(cfg.get_value("progress", "mission_01_complete", false))


func save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "mission_01_complete", mission_01_complete)
	cfg.save(SAVE_PATH)


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func start_new_game() -> void:
	wanted = false
	input_locked = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().change_scene_to_file("res://scenes/missions/mission_01.tscn")


func continue_or_restart() -> void:
	start_new_game()


func restart_mission() -> void:
	start_new_game()


func return_to_menu() -> void:
	wanted = false
	input_locked = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func quit_game() -> void:
	get_tree().paused = false
	get_tree().quit()
