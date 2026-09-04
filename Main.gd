extends Node2D

@onready var grid: Node2D = $Grid
@onready var tray: Node2D = $Tray
@onready var score_label: Label = $ScoreLabel
@onready var game_over_label: Label = $GameOverLabel
@onready var restart_button: Button = $GameOverLabel/RestartButton
@onready var welcome_screen: Control = $WelcomeScreen
@onready var classic_button: Button = $WelcomeScreen/ClassicButton
@onready var levels_button: Button = $WelcomeScreen/LevelsButton
@onready var level_selection_screen: Control = $LevelSelectionScreen
@onready var back_button: Button = $LevelSelectionScreen/BackButton
@onready var grid_container: GridContainer = $LevelSelectionScreen/ScrollContainer/GridContainer
@onready var level_info_label: Label = $LevelInfoLabel
@onready var target_label: Label = $TargetLabel
@onready var level_complete_label: Label = $LevelCompleteLabel
@onready var next_level_button: Button = $LevelCompleteLabel/NextLevelButton
@onready var click_sound: AudioStreamPlayer = $ClickSound
@onready var drop_sound: AudioStreamPlayer = $DropSound
@onready var clear_sound: AudioStreamPlayer = $ClearSound
@onready var game_over_sound: AudioStreamPlayer = $GameOverSound

enum Mode { CLASSIC, LEVELS }
var current_mode: Mode = Mode.CLASSIC
var current_level: int = 1
var target_score: int = 0
var level_completed: bool = false

const PIECE_SCENE := preload("res://Piece.tscn")
const COLORS := [Color(0.9,0.3,0.3), Color(0.3,0.6,0.9), Color(0.3,0.85,0.4), Color(0.95,0.8,0.2), Color(0.7,0.4,0.9)]

var tray_slots: Array = [null, null, null]
var tray_positions: Array = [Vector2(50, 850), Vector2(280, 850), Vector2(510, 850)]
var score := 0

func _ready() -> void:
	game_over_label.visible = false
	welcome_screen.visible = true
	grid.lines_cleared.connect(_on_lines_cleared)
	
	classic_button.pressed.connect(_on_classic_pressed)
	levels_button.pressed.connect(_on_levels_pressed)
	back_button.pressed.connect(_on_back_pressed)
	next_level_button.pressed.connect(_on_next_level_pressed)
	
	classic_button.pressed.connect(play_click)
	levels_button.pressed.connect(play_click)
	back_button.pressed.connect(play_click)
	next_level_button.pressed.connect(play_click)
	restart_button.pressed.connect(play_click)
	restart_button.pressed.connect(start_game)
	
	_populate_level_grid()

func play_click() -> void:
	click_sound.play()

func _populate_level_grid() -> void:
	for child in grid_container.get_children():
		child.queue_free()
	
	for i in range(1, LevelManager.MAX_LEVELS + 1):
		var btn = Button.new()
		btn.text = str(i)
		btn.custom_minimum_size = Vector2(80, 80)
		btn.add_theme_font_size_override("font_size", 32)
		if i > LevelManager.unlocked_level:
			btn.disabled = true
		btn.pressed.connect(func(): play_click(); start_level(i))
		grid_container.add_child(btn)

func _on_classic_pressed() -> void:
	current_mode = Mode.CLASSIC
	start_game()

func _on_levels_pressed() -> void:
	current_mode = Mode.LEVELS
	_populate_level_grid()
	welcome_screen.visible = false
	level_selection_screen.visible = true

func _on_back_pressed() -> void:
	level_selection_screen.visible = false
	welcome_screen.visible = true

func start_level(lvl: int) -> void:
	current_level = lvl
	level_selection_screen.visible = false
	start_game()

func _on_next_level_pressed() -> void:
	start_level(current_level + 1)

func start_game() -> void:
	welcome_screen.visible = false
	game_over_label.visible = false
	level_complete_label.visible = false
	level_completed = false
	
	score = 0
	score_label.text = "Score: %d" % score
	
	if current_mode == Mode.LEVELS:
		target_score = LevelManager.get_target_score(current_level)
		target_label.text = "Target: %d" % target_score
		target_label.visible = true
		level_info_label.text = "Level %d" % current_level
		level_info_label.visible = true
	else:
		target_label.visible = false
		level_info_label.visible = false
	
	grid.clear_grid()
	
	for i in tray_slots.size():
		if tray_slots[i] != null:
			tray_slots[i].queue_free()
			tray_slots[i] = null
			
	fill_tray()

func fill_tray() -> void:
	for i in tray_slots.size():
		if tray_slots[i] == null:
			spawn_piece(i)
	check_game_over()

func spawn_piece(slot: int) -> void:
	var shape_keys := Global.SHAPES.keys()
	var shape: Array = Global.SHAPES[shape_keys[randi() % shape_keys.size()]]
	var color: Color = COLORS[randi() % COLORS.size()]
	var piece = PIECE_SCENE.instantiate()
	tray.add_child(piece)
	piece.setup(shape, color)
	piece.position = tray_positions[slot]
	piece.home_position = tray_positions[slot]
	piece.slot_index = slot
	piece.dropped.connect(_on_piece_dropped)
	tray_slots[slot] = piece

func _on_piece_dropped(piece, drop_global_position: Vector2) -> void:
	var local_pos: Vector2 = drop_global_position - grid.global_position
	var origin := Vector2i(roundi(local_pos.x / Global.CELL_SIZE), roundi(local_pos.y / Global.CELL_SIZE))

	if grid.is_valid_placement(piece.shape, origin):
		drop_sound.play()
		grid.place_shape(piece.shape, origin, piece.color)
		tray_slots[piece.slot_index] = null
		piece.queue_free()
		grid.check_and_clear_lines()
		update_score(piece.shape.size())
		if is_tray_empty():
			fill_tray()
		else:
			check_game_over()
	else:
		piece.position = piece.home_position

func is_tray_empty() -> bool:
	for p in tray_slots:
		if p != null:
			return false
	return true

func update_score(cells_placed: int) -> void:
	score += cells_placed
	score_label.text = "Score: %d" % score
	check_level_complete()

func _on_lines_cleared(count: int) -> void:
	clear_sound.play()
	score += count * 10
	score_label.text = "Score: %d" % score
	check_level_complete()

func check_level_complete() -> void:
	if current_mode == Mode.LEVELS and not level_completed:
		if score >= target_score:
			level_completed = true
			level_complete_label.visible = true
			LevelManager.unlock_next_level(current_level)
			clear_sound.play()

func check_game_over() -> void:
	if level_completed:
		return
	for piece in tray_slots:
		if piece != null and grid.can_place_anywhere(piece.shape):
			return
	game_over_label.visible = true
	game_over_sound.play()
