extends Control
## Main menu: start the mission, open the movement test arena, or quit.

const ARENA_SCENE: String = "res://scenes/levels/test_arena.tscn"

@onready var _start_button: Button = $Center/VBox/StartButton
@onready var _arena_button: Button = $Center/VBox/ArenaButton
@onready var _quit_button: Button = $Center/VBox/QuitButton


func _ready() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_start_button.pressed.connect(Game.load_scene.bind(Game.MISSION_SCENE))
	_arena_button.pressed.connect(Game.load_scene.bind(ARENA_SCENE))
	_quit_button.pressed.connect(get_tree().quit)
	_start_button.grab_focus()
