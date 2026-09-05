extends Node

const GRID_SIZE := 8
const CELL_SIZE := 60

# ── Candy-color block palette ─────────────────────────────────────────────────
const COLORS: Array[Color] = [
	Color(1.00, 0.38, 0.47),   # 🌸 Rose pink
	Color(0.25, 0.72, 0.98),   # 🩵 Sky blue
	Color(0.35, 0.95, 0.60),   # 🌿 Mint green
	Color(1.00, 0.78, 0.24),   # 🌟 Warm gold
	Color(0.82, 0.42, 1.00),   # 💜 Lavender purple
	Color(1.00, 0.58, 0.22),   # 🍊 Tangerine orange
]

const SHAPES := {
	"single": [Vector2i(0,0)],
	"domino_h": [Vector2i(0,0), Vector2i(1,0)],
	"domino_v": [Vector2i(0,0), Vector2i(0,1)],
	"line3_h": [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0)],
	"line3_v": [Vector2i(0,0), Vector2i(0,1), Vector2i(0,2)],
	"line4_h": [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0)],
	"line4_v": [Vector2i(0,0), Vector2i(0,1), Vector2i(0,2), Vector2i(0,3)],
	"line5_h": [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), Vector2i(4,0)],
	"square2": [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)],
	"square3": [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2)],
	"l_shape1": [Vector2i(0,0), Vector2i(0,1), Vector2i(0,2), Vector2i(1,2)],
	"l_shape2": [Vector2i(0,0), Vector2i(1,0), Vector2i(1,1), Vector2i(1,2)],
	"t_shape": [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(1,1)],
	"s_shape": [Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(1,1)],
	"z_shape": [Vector2i(0,0), Vector2i(1,0), Vector2i(1,1), Vector2i(2,1)],
	"plus_shape": [Vector2i(1,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(1,2)],
	"corner": [Vector2i(0,0), Vector2i(0,1), Vector2i(1,1)]
}

# ── High Score Persistence ───────────────────────────────────────────────────
var high_score: int = 0
const SAVE_PATH := "user://highscore.cfg"

# ── Fruit & Gem Single-Color Themes for Tray Clear ────────────────────────────
const FRUIT_GEMS: Array[Dictionary] = [
	{
		"name": "Ruby Strawberry 🍓",
		"main": Color(0.96, 0.22, 0.38),
		"accent": Color(1.00, 0.50, 0.65),
		"bg": Color(0.28, 0.06, 0.12, 0.95)
	},
	{
		"name": "Golden Mango 🥭",
		"main": Color(1.00, 0.72, 0.15),
		"accent": Color(1.00, 0.88, 0.45),
		"bg": Color(0.28, 0.18, 0.04, 0.95)
	},
	{
		"name": "Emerald Kiwi 🥝",
		"main": Color(0.18, 0.88, 0.48),
		"accent": Color(0.45, 1.00, 0.68),
		"bg": Color(0.04, 0.25, 0.12, 0.95)
	},
	{
		"name": "Sapphire Blueberry 🫐",
		"main": Color(0.22, 0.58, 0.98),
		"accent": Color(0.55, 0.78, 1.00),
		"bg": Color(0.05, 0.14, 0.28, 0.95)
	},
	{
		"name": "Amethyst Plum 🍇",
		"main": Color(0.72, 0.28, 0.98),
		"accent": Color(0.88, 0.55, 1.00),
		"bg": Color(0.22, 0.06, 0.28, 0.95)
	}
]

func _ready() -> void:
	load_high_score()

func load_high_score() -> int:
	var config := ConfigFile.new()
	var err := config.load(SAVE_PATH)
	if err == OK:
		high_score = config.get_value("game", "high_score", 0)
	else:
		high_score = 0
	return high_score

func save_high_score(new_score: int) -> void:
	if new_score > high_score:
		high_score = new_score
		var config := ConfigFile.new()
		config.set_value("game", "high_score", high_score)
		config.save(SAVE_PATH)

func get_random_fruit_theme() -> Dictionary:
	return FRUIT_GEMS[randi() % FRUIT_GEMS.size()]
