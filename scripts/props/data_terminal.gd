class_name DataTerminal
extends Interactable
## Terminal that "downloads" data over a few seconds after being used.

signal download_started
signal download_completed

@export var download_time: float = 3.0

var is_downloading: bool = false
var is_done: bool = false


func _ready() -> void:
	super._ready()
	interacted.connect(_on_interacted)


func can_interact(_actor: Node) -> bool:
	return enabled and not is_downloading and not is_done


func _on_interacted(_actor: Node) -> void:
	is_downloading = true
	Game.show_message("Downloading data... stay alert (%d s)" % int(download_time), download_time)
	download_started.emit()
	await get_tree().create_timer(download_time).timeout
	is_downloading = false
	is_done = true
	Game.show_message("Download complete!")
	download_completed.emit()
