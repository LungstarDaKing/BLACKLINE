extends CanvasLayer
## In-game pause overlay. Keeps processing while the tree is paused.

const MAIN_MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"

@onready var _panel: Control = $Panel
@onready var _resume_button: Button = $Panel/Center/VBox/ResumeButton
@onready var _menu_button: Button = $Panel/Center/VBox/MainMenuButton
@onready var _quit_button: Button = $Panel/Center/VBox/QuitButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel.hide()
	_resume_button.pressed.connect(_set_paused.bind(false))
	_menu_button.pressed.connect(_on_main_menu_pressed)
	_quit_button.pressed.connect(get_tree().quit)


func _unhandled_input(event: InputEvent) -> void:
	# The mission end screen owns the pause state while it is showing.
	if Game.end_screen_active:
		return
	if event.is_action_pressed("pause"):
		_set_paused(not get_tree().paused)
		get_viewport().set_input_as_handled()


func _set_paused(value: bool) -> void:
	get_tree().paused = value
	_panel.visible = value
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if value else Input.MOUSE_MODE_CAPTURED
	if value:
		_resume_button.grab_focus()


func _on_main_menu_pressed() -> void:
	Game.go_to_main_menu()
