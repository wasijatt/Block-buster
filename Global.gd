extends Node

const GRID_SIZE := 8
const CELL_SIZE := 82

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
	"line5_v": [Vector2i(0,0), Vector2i(0,1), Vector2i(0,2), Vector2i(0,3), Vector2i(0,4)],
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

# ── Difficulty Pools for Classic Mode ─────────────────────────────────────────
const SHAPES_EASY: Array[String] = [
	"single", "domino_h", "domino_v", "line3_h", "line3_v", "square2", "corner"
]

const SHAPES_MEDIUM: Array[String] = [
	"single", "domino_h", "domino_v", "line3_h", "line3_v", "square2", "corner",
	"l_shape1", "l_shape2", "t_shape"
]

const SHAPES_HARD: Array[String] = [
	"single", "domino_h", "domino_v", "line3_h", "line3_v", "square2", "corner",
	"l_shape1", "l_shape2", "t_shape", "line4_h", "line4_v", "plus_shape", "s_shape", "z_shape"
]

func get_shapes_for_score(p_score: int) -> Array[String]:
	if p_score < 500:
		return SHAPES_EASY
	elif p_score < 1200:
		return SHAPES_MEDIUM
	elif p_score < 2500:
		return SHAPES_HARD
	else:
		return SHAPES.keys()

# ── Dynamic Theme Palettes (Transform across levels & every 500 pts in Classic) ─
const THEMES: Dictionary = {
	"wood": {
		"id": "wood",
		"texture_type": "wood",
		"name": "Polished Oak Wood 🪵",
		"banner": "TIMBER REALM 🪵",
		"icon": "🪵",
		"colors": [
			Color(0.82, 0.52, 0.28),   # Honey Oak
			Color(0.68, 0.38, 0.18),   # Mahogany Timber
			Color(0.92, 0.68, 0.38),   # Golden Maple
			Color(0.55, 0.28, 0.12),   # Deep Walnut
			Color(0.78, 0.44, 0.20),   # Cherry Teak
			Color(0.88, 0.60, 0.32),   # Cedar Amber
		],
		"grid_bg": Color(0.12, 0.08, 0.05, 0.96),
		"grid_border": Color(0.52, 0.34, 0.18, 0.90),
		"tray_bg": Color(0.15, 0.09, 0.05, 0.95),
		"tray_border": Color(0.65, 0.42, 0.22, 0.88),
		"accent": Color(1.00, 0.76, 0.35),
		"corner_radius": 12,
		"border_width": 4
	},
	"ice": {
		"id": "ice",
		"texture_type": "ice",
		"name": "Glacial Ice ❄️",
		"banner": "ICE KINGDOM ❄️",
		"icon": "❄️",
		"colors": [
			Color(0.25, 0.85, 1.00),   # Cyan frost
			Color(0.48, 0.72, 1.00),   # Arctic blue
			Color(0.70, 0.92, 1.00),   # Diamond ice
			Color(0.30, 0.65, 0.95),   # Deep glacier
			Color(0.65, 0.55, 1.00),   # Aurora frost
			Color(0.15, 0.95, 0.90),   # Neon blizzard
		],
		"grid_bg": Color(0.05, 0.11, 0.18, 0.95),
		"grid_border": Color(0.25, 0.55, 0.80, 0.85),
		"tray_bg": Color(0.04, 0.10, 0.16, 0.94),
		"tray_border": Color(0.35, 0.78, 1.00, 0.85),
		"accent": Color(0.45, 0.90, 1.00),
		"corner_radius": 10,
		"border_width": 5
	},
	"marble": {
		"id": "marble",
		"texture_type": "marble",
		"name": "Ancient Marble 🏛️",
		"banner": "CARVED TEMPLE 🏛️",
		"icon": "🏛️",
		"colors": [
			Color(0.92, 0.90, 0.86),   # Carrara White
			Color(0.35, 0.78, 0.65),   # Imperial Jade
			Color(0.85, 0.75, 0.62),   # Travertine Cream
			Color(0.42, 0.58, 0.75),   # Lapis Vein
			Color(0.78, 0.68, 0.75),   # Lilac Granite
			Color(0.88, 0.80, 0.55),   # Alabaster Gold
		],
		"grid_bg": Color(0.10, 0.11, 0.12, 0.96),
		"grid_border": Color(0.55, 0.52, 0.48, 0.85),
		"tray_bg": Color(0.12, 0.13, 0.14, 0.94),
		"tray_border": Color(0.70, 0.68, 0.62, 0.85),
		"accent": Color(0.92, 0.88, 0.75),
		"corner_radius": 14,
		"border_width": 4
	},
	"bronze": {
		"id": "bronze",
		"texture_type": "bronze",
		"name": "Steampunk Bronze ⚙️",
		"banner": "BRONZE FORGE ⚙️",
		"icon": "⚙️",
		"colors": [
			Color(0.85, 0.55, 0.28),   # Polished Copper
			Color(0.72, 0.45, 0.20),   # Antique Bronze
			Color(0.95, 0.65, 0.32),   # Burnished Brass
			Color(0.58, 0.35, 0.18),   # Cast Iron Umber
			Color(0.88, 0.48, 0.22),   # Molten Solder
			Color(0.78, 0.62, 0.35),   # Gunmetal Gold
		],
		"grid_bg": Color(0.12, 0.09, 0.07, 0.96),
		"grid_border": Color(0.58, 0.40, 0.22, 0.88),
		"tray_bg": Color(0.14, 0.10, 0.08, 0.94),
		"tray_border": Color(0.78, 0.52, 0.28, 0.88),
		"accent": Color(0.95, 0.70, 0.35),
		"corner_radius": 12,
		"border_width": 5
	},
	"cloth": {
		"id": "cloth",
		"texture_type": "cloth",
		"name": "Silken Velvet 🧵",
		"banner": "ROYAL VELVET 🧵",
		"icon": "🧵",
		"colors": [
			Color(0.85, 0.28, 0.38),   # Velvet rose
			Color(0.35, 0.45, 0.85),   # Royal indigo
			Color(0.88, 0.68, 0.28),   # Gold embroidery
			Color(0.28, 0.72, 0.58),   # Emerald weave
			Color(0.68, 0.38, 0.78),   # Imperial purple
			Color(0.92, 0.55, 0.35),   # Terracotta silk
		],
		"grid_bg": Color(0.12, 0.10, 0.14, 0.95),
		"grid_border": Color(0.48, 0.38, 0.32, 0.85),
		"tray_bg": Color(0.14, 0.10, 0.12, 0.94),
		"tray_border": Color(0.78, 0.55, 0.38, 0.85),
		"accent": Color(0.95, 0.82, 0.55),
		"corner_radius": 16,
		"border_width": 4
	},
	"magma": {
		"id": "magma",
		"texture_type": "magma",
		"name": "Molten Magma 🌋",
		"banner": "VOLCANIC CORE 🌋",
		"icon": "🌋",
		"colors": [
			Color(1.00, 0.28, 0.08),   # Fiery Magma
			Color(1.00, 0.55, 0.05),   # Molten Gold
			Color(0.88, 0.12, 0.15),   # Lava Surge
			Color(1.00, 0.75, 0.15),   # Radiant Ember
			Color(0.65, 0.08, 0.18),   # Obsidian Blood
			Color(0.95, 0.42, 0.10),   # Volcanic Ash
		],
		"grid_bg": Color(0.10, 0.04, 0.04, 0.96),
		"grid_border": Color(0.75, 0.25, 0.10, 0.90),
		"tray_bg": Color(0.12, 0.04, 0.04, 0.94),
		"tray_border": Color(0.95, 0.40, 0.12, 0.90),
		"accent": Color(1.00, 0.60, 0.15),
		"corner_radius": 14,
		"border_width": 5
	},
	"chrome": {
		"id": "chrome",
		"texture_type": "chrome",
		"name": "Platinum Chrome 🪞",
		"banner": "MIRROR MATRIX 🪞",
		"icon": "🪞",
		"colors": [
			Color(0.85, 0.88, 0.95),   # Pure Platinum
			Color(0.65, 0.78, 0.92),   # Silver Ice
			Color(0.75, 0.72, 0.82),   # Titanium Lustre
			Color(0.55, 0.68, 0.85),   # Cobalt Steel
			Color(0.90, 0.82, 0.88),   # Rose Silver
			Color(0.70, 0.85, 0.95),   # Mirror Sky
		],
		"grid_bg": Color(0.08, 0.10, 0.14, 0.96),
		"grid_border": Color(0.55, 0.68, 0.82, 0.90),
		"tray_bg": Color(0.09, 0.11, 0.15, 0.94),
		"tray_border": Color(0.75, 0.88, 1.00, 0.90),
		"accent": Color(0.88, 0.94, 1.00),
		"corner_radius": 10,
		"border_width": 5
	},
	"royal_gold": {
		"id": "royal_gold",
		"texture_type": "royal_gold",
		"name": "Imperial 24K Gold 👑",
		"banner": "ROYAL TREASURE 👑",
		"icon": "👑",
		"colors": [
			Color(1.00, 0.82, 0.18),   # 24k Gold
			Color(0.95, 0.20, 0.32),   # Imperial ruby
			Color(0.15, 0.85, 0.55),   # Crown emerald
			Color(0.20, 0.52, 0.98),   # Royal sapphire
			Color(0.85, 0.45, 1.00),   # Sovereign amethyst
			Color(1.00, 0.60, 0.20),   # Topaz glow
		],
		"grid_bg": Color(0.14, 0.11, 0.06, 0.95),
		"grid_border": Color(0.75, 0.60, 0.20, 0.85),
		"tray_bg": Color(0.18, 0.14, 0.05, 0.94),
		"tray_border": Color(1.00, 0.85, 0.30, 0.85),
		"accent": Color(1.00, 0.88, 0.40),
		"corner_radius": 18,
		"border_width": 5
	},
	"diamond": {
		"id": "diamond",
		"texture_type": "diamond",
		"name": "Prismatic Diamond 💎",
		"banner": "DIAMOND CITADEL 💎",
		"icon": "💎",
		"colors": [
			Color(0.68, 0.95, 1.00),   # Diamond Brilliant
			Color(0.95, 0.65, 0.98),   # Pink Sapphire
			Color(0.40, 0.98, 0.85),   # Mint Tourmaline
			Color(1.00, 0.88, 0.45),   # Golden Citrine
			Color(0.75, 0.55, 1.00),   # Tanzanite Prismatic
			Color(0.45, 0.80, 1.00),   # Aqua Aquamarine
		],
		"grid_bg": Color(0.06, 0.08, 0.16, 0.96),
		"grid_border": Color(0.50, 0.80, 1.00, 0.90),
		"tray_bg": Color(0.06, 0.09, 0.18, 0.94),
		"tray_border": Color(0.70, 0.92, 1.00, 0.90),
		"accent": Color(0.80, 0.95, 1.00),
		"corner_radius": 8,
		"border_width": 5
	},
	"neon": {
		"id": "neon",
		"texture_type": "neon",
		"name": "Cyber Synthwave ⚡",
		"banner": "CYBER NEON ⚡",
		"icon": "⚡",
		"colors": [
			Color(1.00, 0.05, 0.65),   # Hot neon pink
			Color(0.00, 0.95, 1.00),   # Electric cyan
			Color(0.20, 1.00, 0.50),   # Laser lime
			Color(1.00, 0.85, 0.00),   # Cyber yellow
			Color(0.70, 0.15, 1.00),   # Neon violet
			Color(1.00, 0.40, 0.05),   # Radiant solar
		],
		"grid_bg": Color(0.04, 0.04, 0.09, 0.95),
		"grid_border": Color(0.65, 0.12, 0.85, 0.85),
		"tray_bg": Color(0.05, 0.03, 0.10, 0.94),
		"tray_border": Color(0.00, 0.85, 0.95, 0.85),
		"accent": Color(0.00, 0.95, 1.00),
		"corner_radius": 8,
		"border_width": 5
	},
	"cosmic": {
		"id": "cosmic",
		"texture_type": "cosmic",
		"name": "Cosmic Nebula 🌌",
		"banner": "ASTRAL VOID 🌌",
		"icon": "🌌",
		"colors": [
			Color(0.60, 0.25, 1.00),   # Deep Nebula
			Color(0.20, 0.80, 1.00),   # Star Dust
			Color(1.00, 0.25, 0.70),   # Supernova Pink
			Color(0.40, 1.00, 0.75),   # Aurora Glow
			Color(0.95, 0.85, 0.30),   # Pulsar Gold
			Color(0.35, 0.45, 1.00),   # Event Horizon
		],
		"grid_bg": Color(0.05, 0.03, 0.12, 0.96),
		"grid_border": Color(0.55, 0.28, 0.95, 0.90),
		"tray_bg": Color(0.06, 0.03, 0.14, 0.94),
		"tray_border": Color(0.75, 0.45, 1.00, 0.90),
		"accent": Color(0.75, 0.50, 1.00),
		"corner_radius": 16,
		"border_width": 5
	},
	"mythic": {
		"id": "mythic",
		"texture_type": "mythic",
		"name": "Mythic Dragonscale 🐉",
		"banner": "MYTHIC ASCENSION 🐉",
		"icon": "🐉",
		"colors": [
			Color(1.00, 0.25, 0.45),   # Dragon Heart Red
			Color(0.15, 0.95, 0.75),   # Wyrm Emerald
			Color(0.85, 0.35, 1.00),   # Mythic Violet
			Color(1.00, 0.80, 0.15),   # Elder Gold
			Color(0.25, 0.75, 1.00),   # Leviathan Blue
			Color(1.00, 0.45, 0.15),   # Dragonflame Amber
		],
		"grid_bg": Color(0.08, 0.04, 0.10, 0.96),
		"grid_border": Color(0.85, 0.30, 0.65, 0.90),
		"tray_bg": Color(0.10, 0.04, 0.12, 0.94),
		"tray_border": Color(1.00, 0.55, 0.25, 0.90),
		"accent": Color(1.00, 0.70, 0.30),
		"corner_radius": 20,
		"border_width": 5
	},
	"classic": {
		"id": "classic",
		"texture_type": "classic",
		"name": "Classic Candy 🍬",
		"banner": "CLASSIC MODE",
		"icon": "🍬",
		"colors": [
			Color(1.00, 0.38, 0.47),   # Rose pink
			Color(0.25, 0.72, 0.98),   # Sky blue
			Color(0.35, 0.95, 0.60),   # Mint green
			Color(1.00, 0.78, 0.24),   # Warm gold
			Color(0.82, 0.42, 1.00),   # Lavender purple
			Color(1.00, 0.58, 0.22),   # Tangerine orange
		],
		"grid_bg": Color(0.14, 0.12, 0.22, 0.95),
		"grid_border": Color(0.32, 0.28, 0.48, 0.85),
		"tray_bg": Color(0.10, 0.09, 0.16, 0.94),
		"tray_border": Color(0.28, 0.25, 0.38, 0.85),
		"accent": Color(1.00, 0.78, 0.24),
		"corner_radius": 14,
		"border_width": 4
	}
}

const THEME_CYCLE: Array[String] = [
	"wood", "ice", "marble", "bronze", "cloth",
	"magma", "chrome", "royal_gold", "diamond", "neon", "cosmic", "mythic"
]

func get_next_theme(current_id: String) -> Dictionary:
	var idx := THEME_CYCLE.find(current_id)
	if idx == -1:
		return THEMES["wood"]
	var next_idx: int = (idx + 1) % THEME_CYCLE.size()
	return THEMES[THEME_CYCLE[next_idx]]

func get_theme_for_level(level: int) -> Dictionary:
	if level <= 4:
		return THEMES["wood"]
	elif level <= 8:
		return THEMES["ice"]
	elif level <= 12:
		return THEMES["marble"]
	elif level <= 16:
		return THEMES["bronze"]
	elif level <= 20:
		return THEMES["cloth"]
	elif level <= 25:
		return THEMES["magma"]
	elif level <= 30:
		return THEMES["chrome"]
	elif level <= 35:
		return THEMES["royal_gold"]
	elif level <= 40:
		return THEMES["diamond"]
	elif level <= 50:
		return THEMES["neon"]
	elif level <= 65:
		return THEMES["cosmic"]
	else:
		return THEMES["mythic"]

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
	load_settings()

func load_high_score() -> int:
	var config := ConfigFile.new()
	var err := config.load(SAVE_PATH)
	if err == OK:
		var saved_score = config.get_value("game", "high_score", 0)
		high_score = max(0, int(saved_score))
	else:
		high_score = 0
	return high_score

func save_high_score(new_score: int) -> void:
	if new_score > high_score:
		high_score = max(0, new_score)
		var config := ConfigFile.new()
		config.load(SAVE_PATH)
		config.set_value("game", "high_score", high_score)
		config.save(SAVE_PATH)

func reset_high_score() -> void:
	high_score = 0
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	config.set_value("game", "high_score", 0)
	config.save(SAVE_PATH)

# ── Settings (persisted in the same config file) ─────────────────────────────
var sound_enabled: bool = true

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		sound_enabled = bool(config.get_value("game", "sound_enabled", true))
	_apply_sound_enabled()

func set_sound_enabled(enabled: bool) -> void:
	sound_enabled = enabled
	_apply_sound_enabled()
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	config.set_value("game", "sound_enabled", enabled)
	config.save(SAVE_PATH)

func _apply_sound_enabled() -> void:
	# Single master-bus mute: covers every sound player with zero per-call cost
	var master := AudioServer.get_bus_index("Master")
	if master >= 0:
		AudioServer.set_bus_mute(master, not sound_enabled)

func get_random_fruit_theme() -> Dictionary:
	return FRUIT_GEMS[randi() % FRUIT_GEMS.size()]

# ── Badge/Achievement System ──────────────────────────────────────────────────
const BADGES: Array[Dictionary] = [
	{ "level": 2, "name": "Golden Mango 🥭", "color": Color(1.00, 0.72, 0.15) },
	{ "level": 3, "name": "Ruby Strawberry 🍓", "color": Color(0.96, 0.22, 0.38) },
	{ "level": 4, "name": "Emerald Kiwi 🥝", "color": Color(0.18, 0.88, 0.48) },
	{ "level": 5, "name": "Sapphire Blueberry 🫐", "color": Color(0.22, 0.58, 0.98) },
	{ "level": 7, "name": "Amethyst Plum 🍇", "color": Color(0.72, 0.28, 0.98) },
	{ "level": 10, "name": "Diamond Pineapple 🍍", "color": Color(1.0, 0.84, 0.0) },
	{ "level": 15, "name": "Neon Dragonfruit 🐉", "color": Color(1.0, 0.0, 0.5) },
	{ "level": 20, "name": "Cosmic Starfruit 🌟", "color": Color(0.3, 0.8, 1.0) }
]
