extends CanvasLayer
## Heads-up display: health, ammo, crosshair, interaction prompt, objectives,
## timer and the mission end screen. It finds other systems through groups
## ("player", "weapon_holder", "mission") so any level that provides them works.

@onready var _flash: ColorRect = $Root/DamageFlash
@onready var _crosshair: Control = $Root/CrosshairBox
@onready var _health_bar: ProgressBar = $Root/HealthBox/HealthBar
@onready var _ammo_label: Label = $Root/AmmoLabel
@onready var _prompt_label: Label = $Root/PromptLabel
@onready var _message_label: Label = $Root/MessageLabel
@onready var _objective_box: Control = $Root/ObjectiveBox
@onready var _objective_list: Label = $Root/ObjectiveBox/ObjectiveList
@onready var _timer_label: Label = $Root/TimerLabel
@onready var _end_panel: Control = $Root/EndPanel
@onready var _end_title: Label = $Root/EndPanel/Center/VBox/Title
@onready var _end_reason: Label = $Root/EndPanel/Center/VBox/Reason
@onready var _restart_button: Button = $Root/EndPanel/Center/VBox/RestartButton
@onready var _menu_button: Button = $Root/EndPanel/Center/VBox/MenuButton

var _player: PlayerController
var _interactor: Interactor
var _weapons: Node
var _mission: Node
var _message_tween: Tween
var _flash_tween: Tween


func _ready() -> void:
	# Keep running while the tree is paused so the end screen stays usable.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_end_panel.hide()
	_prompt_label.hide()
	_ammo_label.hide()
	_objective_box.hide()
	_timer_label.hide()
	Game.end_screen_active = false
	Game.message_requested.connect(show_message)
	_restart_button.pressed.connect(Game.restart_level)
	_menu_button.pressed.connect(Game.go_to_main_menu)
	_bind.call_deferred()


func _process(_delta: float) -> void:
	if _interactor and _interactor.focused and not Game.end_screen_active:
		_prompt_label.text = "[E] " + _interactor.focused.get_prompt(_player)
		_prompt_label.show()
	else:
		_prompt_label.hide()
	if _weapons:
		_ammo_label.text = _weapons.get_hud_text()
	if _mission:
		_objective_list.text = _mission.get_objectives_text()
		_timer_label.text = _mission.get_timer_text()


func show_message(text: String, duration: float = 2.5) -> void:
	_message_label.text = text
	if _message_tween:
		_message_tween.kill()
	_message_label.modulate.a = 1.0
	_message_tween = create_tween()
	_message_tween.tween_interval(duration)
	_message_tween.tween_property(_message_label, "modulate:a", 0.0, 0.5)


func _bind() -> void:
	_player = get_tree().get_first_node_in_group("player") as PlayerController
	if _player:
		_interactor = _player.get_node_or_null("Interactor") as Interactor
		if _player.health:
			_health_bar.max_value = _player.health.max_health
			_health_bar.value = _player.health.current_health
			_player.health.health_changed.connect(_on_health_changed)
			_player.health.damaged.connect(_on_player_damaged)
	_weapons = get_tree().get_first_node_in_group("weapon_holder")
	_ammo_label.visible = _weapons != null
	_mission = get_tree().get_first_node_in_group("mission")
	_objective_box.visible = _mission != null
	_timer_label.visible = _mission != null
	if _mission:
		_mission.mission_completed.connect(_on_mission_completed)
		_mission.mission_failed.connect(_on_mission_failed)


func _on_health_changed(current: float, maximum: float) -> void:
	_health_bar.max_value = maximum
	_health_bar.value = current


func _on_player_damaged(_amount: float, _source: Node) -> void:
	if _flash_tween:
		_flash_tween.kill()
	_flash.color = Color(1.0, 0.0, 0.0, 0.4)
	_flash_tween = create_tween()
	_flash_tween.tween_property(_flash, "color:a", 0.0, 0.4)


func _on_mission_completed() -> void:
	_show_end("MISSION COMPLETE", "Objectives achieved.")


func _on_mission_failed(reason: String) -> void:
	_show_end("MISSION FAILED", reason)


func _show_end(title: String, reason: String) -> void:
	Game.end_screen_active = true
	_end_title.text = title
	_end_reason.text = reason
	_prompt_label.hide()
	_crosshair.hide()
	_end_panel.show()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_restart_button.grab_focus()
