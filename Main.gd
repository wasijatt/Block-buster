extends Node2D

@onready var grid: Node2D = $Grid
@onready var tray: Node2D = $Tray
@onready var score_label: Label = $ScoreLabel
@onready var game_over_label: Label = $GameOverLabel

const PIECE_SCENE := preload("res://Piece.tscn")
const COLORS := [Color(0.9,0.3,0.3), Color(0.3,0.6,0.9), Color(0.3,0.85,0.4), Color(0.95,0.8,0.2), Color(0.7,0.4,0.9)]

var tray_slots: Array = [null, null, null]
var tray_positions: Array = [Vector2(50, 850), Vector2(280, 850), Vector2(510, 850)]
var score := 0

func _ready() -> void:
	game_over_label.visible = false
	grid.lines_cleared.connect(_on_lines_cleared)
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

func _on_lines_cleared(count: int) -> void:
	score += count * 10
	score_label.text = "Score: %d" % score

func check_game_over() -> void:
	for piece in tray_slots:
		if piece != null and grid.can_place_anywhere(piece.shape):
			return
	game_over_label.visible = true
