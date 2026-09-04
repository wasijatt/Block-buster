extends Node

const SAVE_PATH := "user://levels.save"
const MAX_LEVELS := 100

var unlocked_level := 1

func _ready() -> void:
	load_progress()

func load_progress() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		unlocked_level = file.get_32()
	else:
		unlocked_level = 1

func save_progress() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_32(unlocked_level)

func unlock_next_level(current: int) -> void:
	if current >= unlocked_level and unlocked_level < MAX_LEVELS:
		unlocked_level = current + 1
		save_progress()

func get_target_score(level: int) -> int:
	return 100 + (level * 50) + int(pow(level, 1.2) * 10)
