extends Node

const SAVE_PATH := "user://levels.save"
const MAX_LEVELS := 100

var unlocked_level := 1

func _ready() -> void:
	load_progress()

func load_progress() -> void:
	unlocked_level = 1
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null or file.get_length() < 4:
		return

	var saved_level := file.get_32()
	if saved_level >= 1 and saved_level <= MAX_LEVELS:
		unlocked_level = saved_level

func save_progress() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_32(clampi(unlocked_level, 1, MAX_LEVELS))

func unlock_next_level(current: int) -> void:
	if current >= unlocked_level and unlocked_level < MAX_LEVELS:
		unlocked_level = current + 1
		save_progress()

func get_target_score(level: int) -> int:
	return 100 + (level * 50) + int(pow(level, 1.2) * 10)

# ── Level Starting Piece Patterns ─────────────────────────────────────────────
# Generates a balanced, fun starting layout of pieces for each level.
# Guarantees no pre-cleared lines (max 6 blocks per row/col) and ample open space.
func get_level_pattern(level: int) -> Array[Vector2i]:
	var pattern: Array[Vector2i] = []

	match level:
		1:
			# Gentle introductory corner notch
			pattern = [Vector2i(1,1), Vector2i(2,1), Vector2i(1,2), Vector2i(6,6), Vector2i(5,6)]
		2:
			# Four Corners anchor dots
			pattern = [
				Vector2i(1,1), Vector2i(1,2), Vector2i(2,1),
				Vector2i(6,6), Vector2i(5,6), Vector2i(6,5),
				Vector2i(1,6), Vector2i(6,1)
			]
		3:
			# Central Crossroads motif
			pattern = [
				Vector2i(3,2), Vector2i(4,2),
				Vector2i(3,5), Vector2i(4,5),
				Vector2i(2,3), Vector2i(2,4),
				Vector2i(5,3), Vector2i(5,4)
			]
		4:
			# Diamond Vault
			pattern = [
				Vector2i(3,1), Vector2i(4,1),
				Vector2i(2,2), Vector2i(5,2),
				Vector2i(1,3), Vector2i(6,3),
				Vector2i(2,5), Vector2i(5,5),
				Vector2i(3,6), Vector2i(4,6)
			]
		5:
			# Twin Pillars
			pattern = [
				Vector2i(2,2), Vector2i(2,3), Vector2i(2,4), Vector2i(2,5),
				Vector2i(5,2), Vector2i(5,3), Vector2i(5,4), Vector2i(5,5),
				Vector2i(0,1), Vector2i(7,6)
			]
		6:
			# Castle Ramparts
			pattern = [
				Vector2i(0,0), Vector2i(2,0), Vector2i(5,0), Vector2i(7,0),
				Vector2i(0,7), Vector2i(2,7), Vector2i(5,7), Vector2i(7,7),
				Vector2i(3,3), Vector2i(4,3), Vector2i(3,4), Vector2i(4,4)
			]
		7:
			# Stardust Constellation
			pattern = [
				Vector2i(1,1), Vector2i(3,1), Vector2i(6,2),
				Vector2i(2,3), Vector2i(5,4), Vector2i(1,5),
				Vector2i(4,6), Vector2i(6,6), Vector2i(3,4), Vector2i(4,3)
			]
		8:
			# Stepped Pyramids
			pattern = [
				Vector2i(3,1), Vector2i(4,1),
				Vector2i(2,2), Vector2i(5,2),
				Vector2i(1,3), Vector2i(6,3),
				Vector2i(1,4), Vector2i(6,4),
				Vector2i(2,5), Vector2i(5,5),
				Vector2i(3,6), Vector2i(4,6)
			]
		9:
			# Stylized Heart
			pattern = [
				Vector2i(2,2), Vector2i(3,1), Vector2i(4,1), Vector2i(5,2),
				Vector2i(1,3), Vector2i(6,3),
				Vector2i(2,4), Vector2i(5,4),
				Vector2i(3,5), Vector2i(4,5),
				Vector2i(3,6), Vector2i(4,6)
			]
		10:
			# Milestone Crown
			pattern = [
				Vector2i(1,2), Vector2i(3,1), Vector2i(4,1), Vector2i(6,2),
				Vector2i(2,3), Vector2i(5,3),
				Vector2i(1,4), Vector2i(2,4), Vector2i(5,4), Vector2i(6,4),
				Vector2i(2,5), Vector2i(3,5), Vector2i(4,5), Vector2i(5,5)
			]
		11:
			# Hourglass of Time
			pattern = [
				Vector2i(1,1), Vector2i(2,1), Vector2i(5,1), Vector2i(6,1),
				Vector2i(2,2), Vector2i(5,2),
				Vector2i(3,3), Vector2i(4,3),
				Vector2i(3,4), Vector2i(4,4),
				Vector2i(2,5), Vector2i(5,5),
				Vector2i(1,6), Vector2i(2,6), Vector2i(5,6), Vector2i(6,6)
			]
		12:
			# Pinwheel Spiral
			pattern = [
				Vector2i(3,1), Vector2i(3,2), Vector2i(3,3),
				Vector2i(4,4), Vector2i(5,4), Vector2i(6,4),
				Vector2i(4,6), Vector2i(4,5),
				Vector2i(1,3), Vector2i(2,3),
				Vector2i(1,6), Vector2i(6,1)
			]
		13:
			# Iron Anchor
			pattern = [
				Vector2i(3,1), Vector2i(4,1),
				Vector2i(3,2), Vector2i(4,2),
				Vector2i(3,3), Vector2i(4,3),
				Vector2i(1,4), Vector2i(6,4),
				Vector2i(1,5), Vector2i(3,5), Vector2i(4,5), Vector2i(6,5),
				Vector2i(2,6), Vector2i(5,6)
			]
		14:
			# Octagonal Fortress
			pattern = [
				Vector2i(2,1), Vector2i(3,1), Vector2i(4,1), Vector2i(5,1),
				Vector2i(1,2), Vector2i(6,2),
				Vector2i(1,5), Vector2i(6,5),
				Vector2i(2,6), Vector2i(3,6), Vector2i(4,6), Vector2i(5,6),
				Vector2i(3,3), Vector2i(4,4)
			]
		15:
			# Dragon Wings Chevron
			pattern = [
				Vector2i(0,1), Vector2i(1,2), Vector2i(2,3),
				Vector2i(7,1), Vector2i(6,2), Vector2i(5,3),
				Vector2i(0,6), Vector2i(1,5), Vector2i(2,4),
				Vector2i(7,6), Vector2i(6,5), Vector2i(5,4),
				Vector2i(3,2), Vector2i(4,2)
			]
		_:
			# Procedural archetype generator for levels 16 to 100
			pattern = _generate_procedural_pattern(level)

	# Safety check: enforce <= 6 cells in any single row or column
	return _validate_pattern(pattern)

func _generate_procedural_pattern(p_level: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = p_level * 1337 + 42

	var archetype: int = p_level % 8
	match archetype:
		0:
			# Concentric Ring corners
			for coord in [
				Vector2i(1,1), Vector2i(2,1), Vector2i(1,2),
				Vector2i(6,1), Vector2i(5,1), Vector2i(6,2),
				Vector2i(1,6), Vector2i(2,6), Vector2i(1,5),
				Vector2i(6,6), Vector2i(5,6), Vector2i(6,5),
				Vector2i(3,3), Vector2i(4,4)
			]:
				result.append(coord)
		1:
			# Symmetric Cross Lattice
			for i in range(2, 6):
				if i != 3:
					result.append(Vector2i(i, 2))
					result.append(Vector2i(i, 5))
			result.append(Vector2i(2, 3))
			result.append(Vector2i(5, 4))
			result.append(Vector2i(0, 0))
			result.append(Vector2i(7, 7))
		2:
			# Diagonal Wave
			for i in range(1, 7):
				if i % 2 == 0:
					result.append(Vector2i(i, i))
					result.append(Vector2i(7 - i, i))
			result.append(Vector2i(1, 3))
			result.append(Vector2i(6, 4))
			result.append(Vector2i(3, 6))
			result.append(Vector2i(4, 1))
		3:
			# Castle Bastions
			for coord in [
				Vector2i(0,2), Vector2i(0,5), Vector2i(2,0), Vector2i(5,0),
				Vector2i(7,2), Vector2i(7,5), Vector2i(2,7), Vector2i(5,7),
				Vector2i(2,2), Vector2i(5,5), Vector2i(2,5), Vector2i(5,2)
			]:
				result.append(coord)
		4:
			# Quad Pillars
			for p in [Vector2i(2,2), Vector2i(5,2), Vector2i(2,5), Vector2i(5,5)]:
				result.append(p)
				result.append(p + Vector2i(1, 0) if p.x == 2 else p - Vector2i(1, 0))
			result.append(Vector2i(3,0))
			result.append(Vector2i(4,7))
		5:
			# Checker Constellation
			for x in range(1, 7, 2):
				for y in range(1, 7, 2):
					if rng.randf() > 0.35:
						result.append(Vector2i(x, y))
			result.append(Vector2i(2, 3))
			result.append(Vector2i(4, 5))
		6:
			# Chevron Vanes
			for i in range(1, 4):
				result.append(Vector2i(i, i + 1))
				result.append(Vector2i(7 - i, i + 1))
				result.append(Vector2i(i, 6 - i))
				result.append(Vector2i(7 - i, 6 - i))
		7:
			# Diamond Core & Sentinels
			for coord in [
				Vector2i(3,2), Vector2i(4,2), Vector2i(2,3), Vector2i(5,3),
				Vector2i(2,4), Vector2i(5,4), Vector2i(3,5), Vector2i(4,5),
				Vector2i(0,3), Vector2i(7,4), Vector2i(3,7), Vector2i(4,0)
			]:
				result.append(coord)

	return result

func _validate_pattern(pattern: Array[Vector2i]) -> Array[Vector2i]:
	var validated: Array[Vector2i] = []
	var row_counts := {}
	var col_counts := {}
	for i in 8:
		row_counts[i] = 0
		col_counts[i] = 0

	for pt in pattern:
		if pt.x < 0 or pt.x >= 8 or pt.y < 0 or pt.y >= 8:
			continue
		if pt in validated:
			continue
		if row_counts[pt.y] >= 6 or col_counts[pt.x] >= 6:
			continue
		row_counts[pt.y] += 1
		col_counts[pt.x] += 1
		validated.append(pt)

	return validated
