extends Node
## Test-support tool: copies the files in COPY into scripts/visual/backups with a
## suffix (when DO_COPY) and prints SHA-256 of source and copy; also prints the
## SHA-256 of every file in HASH_ONLY (protected files, never copied or edited).

const DO_COPY: bool = true
const SUFFIX: String = ".bak_20261113_before_3d_tuning"
const COPY: PackedStringArray = [
	"res://scripts/visual/look/jack_look.gd",
	"res://scripts/visual/look/jack_presentation.gd",
	"res://scripts/visual/look/finger_curl_modifier.gd",
	"res://scripts/visual/look/jack_skin.gdshader",
	"res://scripts/visual/character_visual_test.gd",
]
const HASH_ONLY: PackedStringArray = [
	"res://assets/_incoming/Jack_Carter.fbx",
	"res://assets/_incoming/Jack_Carter_0.png",
	"res://assets/_incoming/Jack_Carter_1.png",
	"res://assets/_incoming/Jack_Carter_2.png",
	"res://assets/_incoming/Jack_Carter_3.png",
	"res://assets/_incoming/Jack_Carter_4.png",
	"res://assets/_incoming/Jack_Carter_5.png",
	"res://assets/_incoming/Jack_Carter_6.png",
	"res://assets/_incoming/Jack_Carter_7.png",
	"res://assets/_incoming/Jack_Carter_8.png",
	"res://assets/_incoming/Jack_Carter_9.png",
	"res://assets/_incoming/Jack_Carter_10.png",
	"res://project.godot",
	"res://scripts/player/player_controller.gd",
	"res://scripts/player/camera_rig.gd",
	"res://scripts/weapons/weapon_holder.gd",
	"res://scenes/levels/mission_01.tscn",
	"res://scenes/player/player.tscn",
	"res://scenes/test/character_visual_test.tscn",
	"res://scripts/visual/character_visual.gd",
	"res://scripts/visual/character_visual_test.gd",
	"res://scripts/visual/stance_modifier.gd",
	"res://scripts/visual/aim_pitch_modifier.gd",
	"res://scripts/visual/hand_align_modifier.gd",
	"res://scripts/visual/backups/character_visual.gd.bak_20261113_before_phase3d",
	"res://scripts/visual/backups/character_visual_test.gd.bak_20261113_before_phase3d",
	"res://scripts/visual/backups/character_visual_test.tscn.bak_20261113_before_phase3d",
	"res://scripts/visual/backups/stance_modifier.gd.bak_20261113_before_phase3d",
	"res://scripts/visual/backups/character_visual_test.gd.bak_20261112_before_phase3c1",
	"res://scripts/visual/look/jack_look.gd",
	"res://scripts/visual/look/jack_presentation.gd",
	"res://scripts/visual/look/finger_curl_modifier.gd",
	"res://scripts/visual/look/jack_skin.gdshader",
]
const BACKUP_DIR: String = "res://scripts/visual/backups/"


func _ready() -> void:
	if DO_COPY:
		for path in COPY:
			var target := BACKUP_DIR + path.get_file() + SUFFIX
			var before := FileAccess.get_sha256(path)
			var err := DirAccess.copy_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(target))
			var after := FileAccess.get_sha256(target)
			print("BACKUP %s -> %s copy_err=%d size=%d" % [path, target, err, FileAccess.get_file_as_bytes(path).size()])
			print("BACKUP sha_source=%s" % before)
			print("BACKUP sha_backup=%s match=%s" % [after, str(before == after and before != "")])
	for path in HASH_ONLY:
		print("HASH %s %s" % [FileAccess.get_sha256(path), path])
	print("BACKUP DONE")
	get_tree().quit()
