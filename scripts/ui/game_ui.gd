extends CanvasLayer
## In-mission HUD, pause, dialogue, and result screens.

var _paused := false

@onready var health_bar: ColorRect = $HUD/HealthBar
@onready var health_text: Label = $HUD/HealthText
@onready var ammo_text: Label = $HUD/AmmoText
@onready var objective: Label = $HUD/Objective
@onready var prompt: Label = $HUD/Prompt
@onready var feedback: Label = $HUD/Feedback
@onready var wanted: Label = $HUD/Wanted
@onready var escape_text: Label = $HUD/Escape
@onready var dialogue: Control = $Dialogue
@onready var speaker: Label = $Dialogue/Speaker
@onready var body: Label = $Dialogue/Body
@onready var pause_panel: Control = $Pause
@onready var result_panel: Control = $Result
@onready var result_title: Label = $Result/Title
@onready var result_body: Label = $Result/Body


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	pause_panel.visible = false
	result_panel.visible = false
	dialogue.visible = false
	Game.health_changed.connect(_on_health)
	Game.ammo_changed.connect(_on_ammo)
	Game.objective_changed.connect(func(t: String) -> void: objective.text = t)
	Game.prompt_changed.connect(func(t: String) -> void: prompt.text = t)
	Game.wanted_changed.connect(_on_wanted)
	Game.feedback_message.connect(func(t: String) -> void: feedback.text = t)
	_on_wanted(Game.wanted)


func _unhandled_input(event: InputEvent) -> void:
	if result_panel.visible:
		return
	if event.is_action_pressed("pause"):
		toggle_pause()
		get_viewport().set_input_as_handled()


func toggle_pause() -> void:
	if dialogue.visible:
		return
	_paused = not _paused
	get_tree().paused = _paused
	pause_panel.visible = _paused
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if _paused else Input.MOUSE_MODE_CAPTURED
	AudioHooks.play_ui()


func show_dialogue(who: String, text: String) -> void:
	dialogue.visible = true
	speaker.text = who
	body.text = text + "\n\n[E / click] continue"


func hide_dialogue() -> void:
	dialogue.visible = false


func set_escape_progress(progress: float, elapsed: float, limit: float) -> void:
	var remain := maxf(limit - elapsed, 0.0)
	var m := int(remain / 60.0)
	var s := int(remain) % 60
	escape_text.text = "ESCAPE %d%%   %02d:%02d" % [int(progress * 100.0), m, s]


func show_result(success: bool, title: String, text: String) -> void:
	get_tree().paused = false
	pause_panel.visible = false
	dialogue.visible = false
	result_panel.visible = true
	result_title.text = title
	result_title.modulate = Color(0.85, 0.75, 0.35) if success else Color(0.85, 0.25, 0.22)
	result_body.text = text
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_health(current: float, maximum: float) -> void:
	health_text.text = "HP %d/%d" % [int(current), int(maximum)]
	var ratio := 0.0 if maximum <= 0.0 else current / maximum
	health_bar.scale.x = clampf(ratio, 0.02, 1.0)
	health_bar.color = Color(0.7, 0.15, 0.12) if ratio < 0.3 else Color(0.72, 0.18, 0.16)


func _on_ammo(mag: int, reserve: int) -> void:
	ammo_text.text = "VALERI MK-2  %d / %d" % [mag, reserve]


func _on_wanted(active: bool) -> void:
	wanted.visible = active
	wanted.text = "WANTED — SECTOR 4"


func _on_resume() -> void:
	if _paused:
		toggle_pause()


func _on_restart() -> void:
	get_tree().paused = false
	AudioHooks.play_ui()
	Game.restart_mission()


func _on_menu() -> void:
	AudioHooks.play_ui()
	Game.return_to_menu()


func _on_quit() -> void:
	AudioHooks.play_ui()
	Game.quit_game()
