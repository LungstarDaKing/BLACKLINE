extends Node3D
## Mission 01 wiring: connects this level's objects to the MissionManager.
## Steal the vault data: keycard -> vault door -> terminal download -> extract.

@onready var _mission: MissionManager = $MissionManager
@onready var _player: PlayerController = $Player
@onready var _vault_door: Door = $Doors/VaultDoor
@onready var _terminal: DataTerminal = $Objects/DataTerminal
@onready var _extraction: ZoneTrigger = $Objects/ExtractionZone


func _ready() -> void:
	_mission.add_objective(&"keycard", "Find the vault keycard")
	_mission.add_objective(&"vault", "Open the vault door")
	_mission.add_objective(&"download", "Download the data")
	_mission.add_objective(&"extract", "Reach the extraction point")

	_player.inventory.item_added.connect(_on_item_added)
	_vault_door.opened.connect(_mission.complete_objective.bind(&"vault"))
	_terminal.download_completed.connect(_mission.complete_objective.bind(&"download"))
	_extraction.player_entered.connect(_on_extraction_entered)

	_mission.start()
	Game.show_message("Steal the data from the vault. Crouch (C) to stay quiet.", 5.0)


func _on_item_added(id: StringName, _count: int) -> void:
	if id == &"keycard":
		_mission.complete_objective(&"keycard")


func _on_extraction_entered(_body: Node) -> void:
	if _mission.is_objective_done(&"download"):
		_mission.complete_objective(&"extract")
	else:
		Game.show_message("Extraction is ready, but the data has not been downloaded yet.")
