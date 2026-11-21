extends Node
## Test-support tool: prints SHA-256 of the 3C.1 backups and the current sources.

const NAMES: PackedStringArray = ["character_visual.gd", "character_visual_test.gd", "stance_modifier.gd"]


func _ready() -> void:
	for file_name in NAMES:
		var source := "res://scripts/visual/" + file_name
		var backup := "res://scripts/visual/backups/" + file_name + ".bak_20261112_before_phase3c1"
		var s := FileAccess.get_sha256(source)
		var b := FileAccess.get_sha256(backup)
		print("VERIFY %s source=%s" % [file_name, s])
		print("VERIFY %s backup=%s identical_to_current=%s" % [file_name, b, str(s == b)])
	get_tree().quit()
