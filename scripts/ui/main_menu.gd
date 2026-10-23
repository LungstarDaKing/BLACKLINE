extends Control


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$Center/VBox/Continue.visible = Game.has_save()
	$Center/VBox/Title.text = "BLACKLINE"
	$Center/VBox/Subtitle.text = "THE PRICE OF POWER"


func _on_new_game() -> void:
	AudioHooks.play_ui()
	Game.start_new_game()


func _on_continue() -> void:
	AudioHooks.play_ui()
	Game.continue_or_restart()


func _on_quit() -> void:
	AudioHooks.play_ui()
	Game.quit_game()
