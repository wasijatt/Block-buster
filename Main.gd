extends Node2D

@onready var grid: Node2D = $Grid
@onready var tray: Node2D = $Tray
@onready var score_label: Label = $ScoreLabel
@onready var high_score_label: Label = $HighScoreLabel
@onready var game_over_label: Label = $GameOverLabel
@onready var restart_button: Button = $GameOverLabel/RestartButton
@onready var welcome_screen: Control = $WelcomeScreen
@onready var welcome_high_score_label: Label = $WelcomeScreen/HighScoreLabel
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

var tray_slots: Array = [null, null, null]
var tray_positions: Array = [Vector2(65, 805), Vector2(290, 805), Vector2(515, 805)]
var score := 0

var tray_panel: Panel
var active_fruit_theme: Dictionary = {}
var is_fruit_mode: bool = false

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
	_apply_visual_theme()
	_update_high_score_display()
	_set_gameplay_ui_visible(false)

func _set_gameplay_ui_visible(p_visible: bool) -> void:
	grid.visible = p_visible
	tray.visible = p_visible
	score_label.visible = p_visible
	high_score_label.visible = p_visible
	if tray_panel:
		tray_panel.visible = p_visible

func play_click() -> void:
	click_sound.play()

# ── High Score Display ────────────────────────────────────────────────────────
func _update_high_score_display() -> void:
	high_score_label.text = "BEST: %d" % Global.high_score
	welcome_high_score_label.text = "HIGH SCORE: %d" % Global.high_score

# ── Visual Theme Setup ─────────────────────────────────────────────────────────
func _apply_visual_theme() -> void:
	if ResourceLoader.exists("res://theme.tres"):
		get_tree().root.theme = load("res://theme.tres")

	# ── Tray panel backdrop ───────────────────────────────────────────────────
	tray_panel = Panel.new()
	tray_panel.position = Vector2(20, 780)
	tray_panel.size = Vector2(680, 220)
	tray_panel.z_index = -1            # render behind pieces and grid
	add_child(tray_panel)
	move_child(tray_panel, 1)          # keep it right after background

	_reset_tray_panel_style()

	# ── Custom 3D Button Styling ──────────────────────────────────────────────
	_style_3d_button(classic_button, Color(0.98, 0.55, 0.18), Color(0.72, 0.28, 0.05), 24)
	_style_3d_button(levels_button, Color(0.16, 0.78, 0.45), Color(0.08, 0.48, 0.25), 24)
	_style_3d_button(back_button, Color(0.38, 0.35, 0.65), Color(0.22, 0.20, 0.42), 20)
	_style_3d_button(next_level_button, Color(0.18, 0.85, 0.48), Color(0.08, 0.52, 0.28), 24)
	_style_3d_button(restart_button, Color(0.92, 0.28, 0.32), Color(0.60, 0.12, 0.15), 24)

	_setup_button_juice(classic_button)
	_setup_button_juice(levels_button)
	_setup_button_juice(back_button)
	_setup_button_juice(next_level_button)
	_setup_button_juice(restart_button)

	# ── Score label styling ───────────────────────────────────────────────────
	high_score_label.add_theme_font_size_override("font_size", 34)
	high_score_label.add_theme_color_override("font_color", Color(1.00, 0.85, 0.30, 1.0))
	high_score_label.add_theme_color_override("font_shadow_color", Color(0.00, 0.00, 0.00, 0.65))
	high_score_label.add_theme_constant_override("shadow_offset_x", 2)
	high_score_label.add_theme_constant_override("shadow_offset_y", 3)

	score_label.add_theme_font_size_override("font_size", 64)
	score_label.add_theme_color_override("font_color", Color(1.00, 0.95, 0.80, 1.0))
	score_label.add_theme_color_override("font_shadow_color", Color(0.00, 0.00, 0.00, 0.65))
	score_label.add_theme_constant_override("shadow_offset_x", 3)
	score_label.add_theme_constant_override("shadow_offset_y", 4)

	# ── Game-Over & Level-Complete labels ──────────────────────────────────────
	game_over_label.add_theme_font_size_override("font_size", 82)
	game_over_label.add_theme_color_override("font_color", Color(1.00, 0.38, 0.38, 1.0))
	game_over_label.add_theme_color_override("font_shadow_color", Color(0.50, 0.08, 0.08, 0.80))
	game_over_label.add_theme_constant_override("shadow_offset_x", 4)
	game_over_label.add_theme_constant_override("shadow_offset_y", 5)

	level_complete_label.add_theme_font_size_override("font_size", 82)
	level_complete_label.add_theme_color_override("font_color", Color(0.35, 0.95, 0.60, 1.0))
	level_complete_label.add_theme_color_override("font_shadow_color", Color(0.00, 0.30, 0.10, 0.80))
	level_complete_label.add_theme_constant_override("shadow_offset_x", 4)
	level_complete_label.add_theme_constant_override("shadow_offset_y", 5)

	var title := welcome_screen.get_node_or_null("TitleLabel") as Label
	if title:
		title.add_theme_color_override("font_color", Color(1.00, 0.78, 0.24, 1.0))
		title.add_theme_color_override("font_shadow_color", Color(0.50, 0.30, 0.00, 0.60))
		title.add_theme_constant_override("shadow_offset_x", 3)
		title.add_theme_constant_override("shadow_offset_y", 4)

	var sel_title := level_selection_screen.get_node_or_null("TitleLabel") as Label
	if sel_title:
		sel_title.add_theme_color_override("font_color", Color(1.00, 0.78, 0.24, 1.0))

# ── Button 3D Styling Helper ─────────────────────────────────────────────────
func _style_3d_button(btn: Button, main_color: Color, bevel_color: Color, corner_radius: int = 24) -> void:
	if btn == null:
		return

	btn.pivot_offset = btn.size / 2.0

	var norm := StyleBoxFlat.new()
	norm.bg_color = main_color
	norm.set_corner_radius_all(corner_radius)
	norm.border_width_bottom = 6
	norm.border_color = bevel_color
	norm.shadow_color = Color(0, 0, 0, 0.45)
	norm.shadow_size = 8
	norm.shadow_offset = Vector2(0, 5)

	var hov := StyleBoxFlat.new()
	hov.bg_color = Color(min(1.0, main_color.r * 1.15), min(1.0, main_color.g * 1.15), min(1.0, main_color.b * 1.15))
	hov.set_corner_radius_all(corner_radius)
	hov.border_width_bottom = 6
	hov.border_color = Color(min(1.0, bevel_color.r * 1.2), min(1.0, bevel_color.g * 1.2), min(1.0, bevel_color.b * 1.2))
	hov.shadow_color = Color(main_color.r, main_color.g, main_color.b, 0.45)
	hov.shadow_size = 12
	hov.shadow_offset = Vector2(0, 6)

	var press := StyleBoxFlat.new()
	press.bg_color = Color(main_color.r * 0.85, main_color.g * 0.85, main_color.b * 0.85)
	press.set_corner_radius_all(corner_radius)
	press.border_width_bottom = 2
	press.border_color = Color(bevel_color.r * 0.7, bevel_color.g * 0.7, bevel_color.b * 0.7)
	press.shadow_size = 3
	press.shadow_offset = Vector2(0, 2)

	var dis := StyleBoxFlat.new()
	dis.bg_color = Color(0.18, 0.16, 0.24, 0.85)
	dis.set_corner_radius_all(corner_radius)
	dis.border_width_bottom = 4
	dis.border_color = Color(0.10, 0.08, 0.14, 0.9)

	btn.add_theme_stylebox_override("normal", norm)
	btn.add_theme_stylebox_override("hover", hov)
	btn.add_theme_stylebox_override("pressed", press)
	btn.add_theme_stylebox_override("disabled", dis)

	btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	btn.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.65))
	btn.add_theme_constant_override("shadow_offset_x", 2)
	btn.add_theme_constant_override("shadow_offset_y", 2)

# ── Button Juice (Juicy Hover & Click Scale Tweens) ──────────────────────────
func _setup_button_juice(btn: Button) -> void:
	if btn == null:
		return

	btn.pivot_offset = btn.size / 2.0
	btn.mouse_entered.connect(func():
		var tw := create_tween()
		tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.15)
	)
	btn.mouse_exited.connect(func():
		var tw := create_tween()
		tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "scale", Vector2.ONE, 0.15)
	)
	btn.button_down.connect(func():
		var tw := create_tween()
		tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "scale", Vector2(0.94, 0.94), 0.08)
	)
	btn.button_up.connect(func():
		var tw := create_tween()
		tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "scale", Vector2.ONE, 0.12)
	)

func _reset_tray_panel_style() -> void:
	if tray_panel == null:
		return
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.09, 0.16, 0.92)
	sb.set_corner_radius_all(18)
	sb.border_width_bottom = 3
	sb.border_width_top = 3
	sb.border_width_left = 3
	sb.border_width_right = 3
	sb.border_color = Color(0.25, 0.22, 0.35, 0.8)
	tray_panel.add_theme_stylebox_override("panel", sb)

func _apply_fruit_theme_tray_style(theme: Dictionary) -> void:
	if tray_panel == null:
		return
	var sb := StyleBoxFlat.new()
	sb.bg_color = theme.get("bg", Color(0.15, 0.08, 0.18, 0.95))
	sb.set_corner_radius_all(22)
	sb.border_width_bottom = 5
	sb.border_width_top = 5
	sb.border_width_left = 5
	sb.border_width_right = 5
	sb.border_color = theme.get("accent", Color(1.0, 0.8, 0.3))
	sb.shadow_color = theme.get("main", Color(1.0, 0.5, 0.2, 0.5))
	sb.shadow_size = 12
	tray_panel.add_theme_stylebox_override("panel", sb)

	# Pulse animation for tray panel
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_SINE)
	tw.set_ease(Tween.EASE_OUT)
	tray_panel.scale = Vector2(1.04, 1.04)
	tw.tween_property(tray_panel, "scale", Vector2.ONE, 0.35)

# ── Level population ──────────────────────────────────────────────────────────
func _populate_level_grid() -> void:
	for child in grid_container.get_children():
		child.queue_free()

	for i in range(1, LevelManager.MAX_LEVELS + 1):
		var btn := Button.new()
		btn.text = str(i)
		btn.custom_minimum_size = Vector2(85, 85)
		btn.add_theme_font_size_override("font_size", 32)

		if i > LevelManager.unlocked_level:
			btn.disabled = true
			_style_3d_button(btn, Color(0.16, 0.14, 0.22, 0.8), Color(0.10, 0.08, 0.14), 18)
		elif i == LevelManager.unlocked_level:
			# Highest unlocked level: Shimmering Gold badge
			_style_3d_button(btn, Color(1.00, 0.75, 0.18), Color(0.78, 0.45, 0.05), 18)
			_setup_button_juice(btn)
		else:
			# Previously unlocked levels: Royal Violet badge
			_style_3d_button(btn, Color(0.55, 0.32, 0.85), Color(0.35, 0.16, 0.58), 18)
			_setup_button_juice(btn)

		btn.pressed.connect(func(): play_click(); start_level(i))
		grid_container.add_child(btn)

# ── Screen transitions ─────────────────────────────────────────────────────────
func _on_classic_pressed() -> void:
	current_mode = Mode.CLASSIC
	start_game()

func _on_levels_pressed() -> void:
	current_mode = Mode.LEVELS
	_populate_level_grid()
	welcome_screen.visible = false
	level_selection_screen.visible = true
	_set_gameplay_ui_visible(false)

func _on_back_pressed() -> void:
	level_selection_screen.visible = false
	welcome_screen.visible = true
	_set_gameplay_ui_visible(false)

func start_level(lvl: int) -> void:
	current_level = lvl
	level_selection_screen.visible = false
	start_game()

func _on_next_level_pressed() -> void:
	start_level(current_level + 1)

func start_game() -> void:
	welcome_screen.visible = false
	level_selection_screen.visible = false
	game_over_label.visible = false
	level_complete_label.visible = false
	level_completed = false

	_set_gameplay_ui_visible(true)

	is_fruit_mode = false
	active_fruit_theme = {}
	_reset_tray_panel_style()

	score = 0
	score_label.text = "Score: %d" % score
	_update_high_score_display()

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

# ── Tray management ───────────────────────────────────────────────────────────
func fill_tray() -> void:
	for i in tray_slots.size():
		if tray_slots[i] == null:
			spawn_piece(i)
	check_game_over()

func spawn_piece(slot: int) -> void:
	var shape_keys := Global.SHAPES.keys()
	var shape: Array = Global.SHAPES[shape_keys[randi() % shape_keys.size()]]
	var color: Color
	if is_fruit_mode and active_fruit_theme.has("main"):
		color = active_fruit_theme["main"]
	else:
		color = Global.COLORS[randi() % Global.COLORS.size()]

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
			_trigger_tray_clear_bonus()
			fill_tray()
		else:
			check_game_over()
	else:
		piece.position = piece.home_position

func _trigger_tray_clear_bonus() -> void:
	clear_sound.play()
	update_score(30) # Tray empty bonus points!

	active_fruit_theme = Global.get_random_fruit_theme()
	is_fruit_mode = true
	_apply_fruit_theme_tray_style(active_fruit_theme)

	# Floating celebratory label
	var float_lbl := Label.new()
	float_lbl.text = "TRAY CLEARED! 🌟\n" + active_fruit_theme.get("name", "SUPER MODE")
	float_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	float_lbl.position = Vector2(160, 740)
	float_lbl.size = Vector2(400, 80)
	float_lbl.add_theme_font_size_override("font_size", 36)
	float_lbl.add_theme_color_override("font_color", active_fruit_theme.get("accent", Color(1, 0.9, 0.3)))
	float_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	float_lbl.add_theme_constant_override("shadow_offset_x", 3)
	float_lbl.add_theme_constant_override("shadow_offset_y", 3)
	add_child(float_lbl)

	var tw := create_tween()
	tw.set_parallel(true)
	tw.set_trans(Tween.TRANS_BACK)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(float_lbl, "position:y", 680.0, 1.2)
	tw.tween_property(float_lbl, "modulate:a", 0.0, 1.2)
	tw.chain().tween_callback(float_lbl.queue_free)

func is_tray_empty() -> bool:
	for p in tray_slots:
		if p != null:
			return false
	return true

# ── Score & progression ───────────────────────────────────────────────────────
func update_score(cells_placed: int) -> void:
	score += cells_placed
	score_label.text = "Score: %d" % score
	Global.save_high_score(score)
	_update_high_score_display()
	check_level_complete()

func _on_lines_cleared(count: int) -> void:
	clear_sound.play()
	score += count * 10
	score_label.text = "Score: %d" % score
	Global.save_high_score(score)
	_update_high_score_display()
	check_level_complete()

func check_level_complete() -> void:
	if current_mode == Mode.LEVELS and not level_completed:
		if score >= target_score:
			level_completed = true
			level_complete_label.visible = true
			LevelManager.unlock_next_level(current_level)
			clear_sound.play()

func check_game_over() -> void:
	if level_completed or is_tray_empty():
		return
	var piece_count := 0
	for piece in tray_slots:
		if piece != null:
			piece_count += 1
			if grid.can_place_anywhere(piece.shape):
				return
	if piece_count > 0:
		game_over_label.visible = true
		game_over_sound.play()
