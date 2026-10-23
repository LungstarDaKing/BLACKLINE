extends Node
## Silent audio hooks. Assign AudioStream resources later under res://assets/audio/.
## Expected later files (optional, not required to play):
##   ui_click.ogg, footstep.ogg, gunfire.ogg, reload.ogg, engine.ogg

var _players: Dictionary = {}


func _ready() -> void:
	for key in ["ui", "footstep", "gunfire", "reload", "engine"]:
		var player := AudioStreamPlayer.new()
		player.name = key
		add_child(player)
		_players[key] = player


func play_ui() -> void:
	_play("ui")


func play_footstep() -> void:
	_play("footstep")


func play_gunfire() -> void:
	_play("gunfire")


func play_reload() -> void:
	_play("reload")


func play_engine() -> void:
	_play("engine")


func _play(key: String) -> void:
	var player: AudioStreamPlayer = _players.get(key)
	if player == null or player.stream == null:
		return
	player.play()
