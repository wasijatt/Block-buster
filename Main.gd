extends Node2D

@onready var background: Control = $AnimatedBackground
@onready var grid: Node2D = $Grid
@onready var tray: Node2D = $Tray
@onready var score_label: Label = $ScoreLabel
@onready var high_score_label: Label = $HighScoreLabel
@onready var level_info_label: Label = $LevelInfoLabel
@onready var target_label: Label = $TargetLabel

# ── Modals & Screens ──────────────────────────────────────────────────────────
@onready var welcome_screen: Control = $WelcomeScreen
@onready var welcome_high_score_label: Label = $WelcomeScreen/HighScoreLabel
@onready var classic_button: Button = $WelcomeScreen/ClassicButton
@onready var levels_button: Button = $WelcomeScreen/LevelsButton

@onready var level_selection_screen: Control = $LevelSelectionScreen
@onready var back_button: Button = $LevelSelectionScreen/BackButton
@onready var grid_container: GridContainer = $LevelSelectionScreen/ScrollContainer/GridContainer

@onready var game_over_modal: Control = $GameOverModal
@onready var game_over_card: Panel = $GameOverModal/Card
@onready var game_over_final_score: Label = $GameOverModal/Card/FinalScoreLabel
@onready var game_over_restart_btn: Button = $GameOverModal/Card/ButtonsHBox/RestartButton
@onready var game_over_home_btn: Button = $GameOverModal/Card/ButtonsHBox/HomeButton

@onready var level_complete_modal: Control = $LevelCompleteModal
@onready var level_complete_card: Panel = $LevelCompleteModal/Card
@onready var level_complete_score: Label = $LevelCompleteModal/Card/ScoreDisplayLabel
@onready var level_complete_next_btn: Button = $LevelCompleteModal/Card/ButtonsHBox/NextLevelButton
@onready var level_complete_home_btn: Button = $LevelCompleteModal/Card/ButtonsHBox/HomeButton

# ── Sound Players ─────────────────────────────────────────────────────────────
@onready var click_sound: AudioStreamPlayer = $ClickSound
@onready var drop_sound: AudioStreamPlayer = $DropSound
@onready var clear_sound: AudioStreamPlayer = $ClearSound
@onready var game_over_sound: AudioStreamPlayer = $GameOverSound
@onready var pickup_sound: AudioStreamPlayer = $PickupSound
@onready var combo_sound: AudioStreamPlayer = $ComboSound
@onready var badge_sound: AudioStreamPlayer = $BadgeSound
@onready var invalid_sound: AudioStreamPlayer = $InvalidSound

enum Mode { CLASSIC, LEVELS }
var current_mode: Mode = Mode.CLASSIC
var current_level: int = 1
var target_score: int = 0
var level_completed: bool = false

const PIECE_SCENE := preload("res://Piece.tscn")

var tray_slots: Array = [null, null, null]
var tray_positions: Array = [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
var score := 0

var tray_panel: Panel
var active_fruit_theme: Dictionary = {}
var is_fruit_mode: bool = false

func _ready() -> void:
	game_over_modal.visible = false
	level_complete_modal.visible = false
	welcome_screen.visible = true

	grid.lines_cleared.connect(_on_lines_cleared)

	# Button Signals
	classic_button.pressed.connect(_on_classic_pressed)
	levels_button.pressed.connect(_on_levels_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	next_level_button_connected()
	
	classic_button.pressed.connect(play_click)
	levels_button.pressed.connect(play_click)
	back_button.pressed.connect(play_click)

	game_over_restart_btn.pressed.connect(play_click)
	game_over_restart_btn.pressed.connect(start_game)
	game_over_home_btn.pressed.connect(play_click)
	game_over_home_btn.pressed.connect(_on_home_pressed)

	level_complete_next_btn.pressed.connect(play_click)
	level_complete_next_btn.pressed.connect(_on_next_level_pressed)
	level_complete_home_btn.pressed.connect(play_click)
	level_complete_home_btn.pressed.connect(_on_home_pressed)

	# ── Tray panel backdrop ───────────────────────────────────────────────────
	tray_panel = Panel.new()
	tray_panel.z_index = -1
	add_child(tray_panel)
	move_child(tray_panel, 1)

	_apply_visual_theme()
	_update_responsive_layout()
	_populate_level_grid()
	_update_high_score_display()
	_set_gameplay_ui_visible(false)

	get_viewport().size_changed.connect(_update_responsive_layout)

func next_level_button_connected() -> void:
	pass

# ── Dynamic Responsive Layout ─────────────────────────────────────────────────
func _update_responsive_layout() -> void:
	var vp := get_viewport_rect().size
	var grid_width: float = Global.GRID_SIZE * Global.CELL_SIZE # 656px

	# 1. Full-screen backgrounds and modals
	if background:
		background.position = Vector2.ZERO
		background.size = vp

	if welcome_screen:
		welcome_screen.position = Vector2.ZERO
		welcome_screen.size = vp
		
		var title_lbl: Label = welcome_screen.get_node_or_null("TitleLabel")
		if title_lbl:
			title_lbl.position = Vector2(0, max(120.0, vp.y * 0.20))
			title_lbl.size = Vector2(vp.x, 100.0)
			
		if welcome_high_score_label:
			welcome_high_score_label.position = Vector2(0, max(225.0, vp.y * 0.20 + 105.0))
			welcome_high_score_label.size = Vector2(vp.x, 60.0)
			
		var btn_w: float = min(420.0, vp.x * 0.78)
		var btn_h: float = 96.0
		var btn_x: float = (vp.x - btn_w) * 0.5
		var btn_classic_y: float = max(380.0, vp.y * 0.52)
		var btn_levels_y: float = btn_classic_y + btn_h + 24.0
		
		if classic_button:
			classic_button.size = Vector2(btn_w, btn_h)
			classic_button.position = Vector2(btn_x, btn_classic_y)
			classic_button.pivot_offset = Vector2(btn_w * 0.5, btn_h * 0.5)
			
		if levels_button:
			levels_button.size = Vector2(btn_w, btn_h)
			levels_button.position = Vector2(btn_x, btn_levels_y)
			levels_button.pivot_offset = Vector2(btn_w * 0.5, btn_h * 0.5)

	if level_selection_screen:
		level_selection_screen.position = Vector2.ZERO
		level_selection_screen.size = vp
	if game_over_modal:
		game_over_modal.position = Vector2.ZERO
		game_over_modal.size = vp
	if level_complete_modal:
		level_complete_modal.position = Vector2.ZERO
		level_complete_modal.size = vp


	# ── Balanced Vertical Centering ───────────────────────────────────────────
	# Header: 140px, Grid: 656px, Tray: 215px -> Total: 1011px
	var header_h: float = 140.0
	var tray_h: float = 215.0
	var total_content_h: float = header_h + grid_width + tray_h
	
	# Distribute the available vertical space evenly
	var free_space: float = max(30.0, vp.y - total_content_h)
	var gap: float = free_space / 4.0 # Top margin, Header-Grid gap, Grid-Tray gap, Bottom margin

	# Header placement
	var header_y: float = max(25.0, gap * 0.85)
	level_info_label.position = Vector2(0, header_y)
	level_info_label.size = Vector2(vp.x, 44)

	high_score_label.position = Vector2(0, header_y + 42)
	high_score_label.size = Vector2(vp.x, 44)

	score_label.position = Vector2(0, header_y + 86)
	score_label.size = Vector2(vp.x, 70)

	target_label.position = Vector2(0, header_y + 158)
	target_label.size = Vector2(vp.x, 38)

	# Grid placed with balanced gap
	var grid_x: float = max(10.0, (vp.x - grid_width) / 2.0)
	var grid_y: float = header_y + header_h + gap
	grid.position = Vector2(grid_x, grid_y)

	# Tray pushed comfortably down into the lower area
	var tray_y: float = grid_y + grid_width + gap
	var tray_margin: float = 18.0
	var tray_w: float = vp.x - (tray_margin * 2.0)

	if tray_panel:
		tray_panel.position = Vector2(tray_margin, tray_y)
		tray_panel.size = Vector2(tray_w, tray_h)

	var slot_center_y: float = tray_y + (tray_h * 0.5)
	tray_positions = [
		Vector2(tray_margin + (tray_w * 0.18), slot_center_y),
		Vector2(tray_margin + (tray_w * 0.50), slot_center_y),
		Vector2(tray_margin + (tray_w * 0.82), slot_center_y)
	]

	for i in tray_slots.size():
		if tray_slots[i] != null:
			var piece_preview_size: Vector2 = tray_slots[i].get_bounding_size() * tray_slots[i].TRAY_SCALE
			var slot_origin: Vector2 = tray_positions[i] - (piece_preview_size * 0.5)
			tray_slots[i].home_position = slot_origin
			if not tray_slots[i].dragging:
				tray_slots[i].position = slot_origin


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
	high_score_label.text = "🏆 BEST: %d" % Global.high_score
	welcome_high_score_label.text = "🏆 HIGH SCORE: %d" % Global.high_score

# ── Visual Theme Setup ─────────────────────────────────────────────────────────
func _apply_visual_theme() -> void:
	if ResourceLoader.exists("res://theme.tres"):
		get_tree().root.theme = load("res://theme.tres")

	_reset_tray_panel_style()

	# ── Style Modal Cards ─────────────────────────────────────────────────────
	_style_modal_card(game_over_card, Color(0.12, 0.08, 0.14, 0.96), Color(0.85, 0.25, 0.28, 0.85), Color(0.85, 0.25, 0.28, 0.4))
	_style_modal_card(level_complete_card, Color(0.08, 0.13, 0.12, 0.96), Color(0.25, 0.85, 0.52, 0.85), Color(0.25, 0.85, 0.52, 0.4))

	# ── Custom 3D Button Styling ──────────────────────────────────────────────
	_style_3d_button(classic_button, Color(0.98, 0.55, 0.18), Color(0.72, 0.28, 0.05), 26)
	_style_3d_button(levels_button, Color(0.16, 0.78, 0.45), Color(0.08, 0.48, 0.25), 26)
	_style_3d_button(back_button, Color(0.38, 0.35, 0.65), Color(0.22, 0.20, 0.42), 20)

	_style_3d_button(game_over_restart_btn, Color(0.92, 0.28, 0.32), Color(0.60, 0.12, 0.15), 24)
	_style_3d_button(game_over_home_btn, Color(0.38, 0.35, 0.65), Color(0.22, 0.20, 0.42), 24)

	_style_3d_button(level_complete_next_btn, Color(0.18, 0.85, 0.48), Color(0.08, 0.52, 0.28), 24)
	_style_3d_button(level_complete_home_btn, Color(0.38, 0.35, 0.65), Color(0.22, 0.20, 0.42), 24)

	_setup_button_juice(classic_button)
	_setup_button_juice(levels_button)
	_setup_button_juice(back_button)
	_setup_button_juice(game_over_restart_btn)
	_setup_button_juice(game_over_home_btn)
	_setup_button_juice(level_complete_next_btn)
	_setup_button_juice(level_complete_home_btn)

	# ── Typography & Label Styling ────────────────────────────────────────────
	level_info_label.add_theme_font_size_override("font_size", 38)
	level_info_label.add_theme_color_override("font_color", Color(0.40, 0.85, 1.0, 1.0))
	level_info_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	level_info_label.add_theme_constant_override("shadow_offset_x", 3)
	level_info_label.add_theme_constant_override("shadow_offset_y", 3)

	high_score_label.add_theme_font_size_override("font_size", 36)
	high_score_label.add_theme_color_override("font_color", Color(1.00, 0.84, 0.22, 1.0))
	high_score_label.add_theme_color_override("font_shadow_color", Color(0.45, 0.25, 0.0, 0.85))
	high_score_label.add_theme_constant_override("shadow_offset_x", 3)
	high_score_label.add_theme_constant_override("shadow_offset_y", 3)

	score_label.add_theme_font_size_override("font_size", 76)
	score_label.add_theme_color_override("font_color", Color(1.00, 0.98, 0.92, 1.0))
	score_label.add_theme_color_override("font_shadow_color", Color(0.00, 0.00, 0.00, 0.85))
	score_label.add_theme_constant_override("shadow_offset_x", 4)
	score_label.add_theme_constant_override("shadow_offset_y", 5)

	target_label.add_theme_font_size_override("font_size", 32)
	target_label.add_theme_color_override("font_color", Color(0.35, 0.95, 0.60, 1.0))

	welcome_high_score_label.add_theme_font_size_override("font_size", 42)
	welcome_high_score_label.add_theme_color_override("font_color", Color(1.00, 0.85, 0.25, 1.0))
	welcome_high_score_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	welcome_high_score_label.add_theme_constant_override("shadow_offset_x", 3)
	welcome_high_score_label.add_theme_constant_override("shadow_offset_y", 4)

	var title := welcome_screen.get_node_or_null("TitleLabel") as Label
	if title:
		title.add_theme_font_size_override("font_size", 84)
		title.add_theme_color_override("font_color", Color(1.00, 0.78, 0.24, 1.0))
		title.add_theme_color_override("font_shadow_color", Color(0.50, 0.30, 0.00, 0.75))
		title.add_theme_constant_override("shadow_offset_x", 4)
		title.add_theme_constant_override("shadow_offset_y", 5)

	var sel_title := level_selection_screen.get_node_or_null("TitleLabel") as Label
	if sel_title:
		sel_title.add_theme_font_size_override("font_size", 64)
		sel_title.add_theme_color_override("font_color", Color(1.00, 0.78, 0.24, 1.0))

func _style_modal_card(card: Panel, bg: Color, border: Color, shadow: Color) -> void:
	if card == null:
		return
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(28)
	sb.border_width_bottom = 4
	sb.border_width_top = 4
	sb.border_width_left = 4
	sb.border_width_right = 4
	sb.border_color = border
	sb.shadow_color = shadow
	sb.shadow_size = 20
	sb.shadow_offset = Vector2(0, 8)
	card.add_theme_stylebox_override("panel", sb)

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

# ── Button Juice (Safe Tactile Hover & Punch Tweens) ──────────────────────────
func _setup_button_juice(btn: Button) -> void:
	if btn == null:
		return

	# Gentle scale-up on desktop hover
	btn.mouse_entered.connect(func():
		var tw := create_tween()
		tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "scale", Vector2(1.04, 1.04), 0.12)
	)
	btn.mouse_exited.connect(func():
		var tw := create_tween()
		tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "scale", Vector2.ONE, 0.12)
	)
	# Trigger bounce on successful press (never on button_down so touch hit-box is not shifted)
	btn.pressed.connect(func():
		btn.pivot_offset = btn.size * 0.5
		var tw := create_tween()
		tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "scale", Vector2(0.94, 0.94), 0.06)
		tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "scale", Vector2.ONE, 0.12)
	)


func _reset_tray_panel_style() -> void:
	if tray_panel == null:
		return
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.09, 0.16, 0.94)
	sb.set_corner_radius_all(22)
	sb.border_width_bottom = 4
	sb.border_width_top = 4
	sb.border_width_left = 4
	sb.border_width_right = 4
	sb.border_color = Color(0.28, 0.25, 0.38, 0.85)
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 5)
	tray_panel.add_theme_stylebox_override("panel", sb)

func _apply_fruit_theme_tray_style(theme: Dictionary) -> void:
	if tray_panel == null:
		return
	var sb := StyleBoxFlat.new()
	sb.bg_color = theme.get("bg", Color(0.15, 0.08, 0.18, 0.95))
	sb.set_corner_radius_all(24)
	sb.border_width_bottom = 5
	sb.border_width_top = 5
	sb.border_width_left = 5
	sb.border_width_right = 5
	sb.border_color = theme.get("accent", Color(1.0, 0.8, 0.3))
	sb.shadow_color = theme.get("main", Color(1.0, 0.5, 0.2, 0.5))
	sb.shadow_size = 14
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
		btn.custom_minimum_size = Vector2(95, 95)
		btn.add_theme_font_size_override("font_size", 34)

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
	print("[Main] CLASSIC mode button pressed!")
	current_mode = Mode.CLASSIC
	start_game()

func _on_levels_pressed() -> void:
	print("[Main] LEVELS mode button pressed!")
	current_mode = Mode.LEVELS
	_populate_level_grid()
	welcome_screen.visible = false
	level_selection_screen.visible = true
	_set_gameplay_ui_visible(false)


func _on_back_pressed() -> void:
	level_selection_screen.visible = false
	welcome_screen.visible = true
	_set_gameplay_ui_visible(false)

func _on_home_pressed() -> void:
	game_over_modal.visible = false
	level_complete_modal.visible = false
	_set_gameplay_ui_visible(false)
	welcome_screen.visible = true

func start_level(lvl: int) -> void:
	current_level = lvl
	level_selection_screen.visible = false
	start_game()

func _on_next_level_pressed() -> void:
	level_complete_modal.visible = false
	start_level(current_level + 1)

func start_game() -> void:
	welcome_screen.visible = false
	level_selection_screen.visible = false
	game_over_modal.visible = false
	level_complete_modal.visible = false
	level_completed = false

	_set_gameplay_ui_visible(true)
	_update_responsive_layout()

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
	piece.setup(shape, color, slot * 0.08, current_level)

	# Calculate centered origin so pieces never overlap
	var piece_preview_size: Vector2 = piece.get_bounding_size() * piece.TRAY_SCALE
	var slot_origin: Vector2 = tray_positions[slot] - (piece_preview_size * 0.5)
	piece.position = slot_origin
	piece.home_position = slot_origin
	piece.slot_index = slot

	piece.dropped.connect(_on_piece_dropped)
	piece.picked_up.connect(func(): pickup_sound.play())
	piece.returned_home.connect(func(): invalid_sound.play())
	tray_slots[slot] = piece

func _on_piece_dropped(piece, drop_global_position: Vector2) -> void:
	var local_pos: Vector2 = drop_global_position - grid.global_position
	var origin := Vector2i(roundi(local_pos.x / Global.CELL_SIZE), roundi(local_pos.y / Global.CELL_SIZE))

	if grid.is_valid_placement(piece.shape, origin):
		drop_sound.play()
		grid.place_shape(piece.shape, origin, piece.color, current_level)
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
		piece.return_home()

func _trigger_tray_clear_bonus() -> void:
	combo_sound.play()
	update_score(30) # Tray empty bonus points!

	active_fruit_theme = Global.get_random_fruit_theme()
	is_fruit_mode = true
	_apply_fruit_theme_tray_style(active_fruit_theme)

	# Floating celebratory label
	var float_lbl := Label.new()
	float_lbl.text = "TRAY CLEARED! 🌟\n" + active_fruit_theme.get("name", "SUPER MODE")
	float_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var vp := get_viewport_rect().size
	float_lbl.position = Vector2((vp.x - 450) / 2.0, tray_positions[0].y - 130.0)
	float_lbl.size = Vector2(450, 90)
	float_lbl.add_theme_font_size_override("font_size", 38)
	float_lbl.add_theme_color_override("font_color", active_fruit_theme.get("accent", Color(1, 0.9, 0.3)))
	float_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	float_lbl.add_theme_constant_override("shadow_offset_x", 3)
	float_lbl.add_theme_constant_override("shadow_offset_y", 4)
	add_child(float_lbl)


	var tw := create_tween()
	tw.set_parallel(true)
	tw.set_trans(Tween.TRANS_BACK)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(float_lbl, "position:y", float_lbl.position.y - 70.0, 1.3)
	tw.tween_property(float_lbl, "modulate:a", 0.0, 1.3)
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
	if count >= 2:
		combo_sound.play()
	else:
		clear_sound.play()
	score += count * 10 * count # Bonus multiplier for multi-line clears!
	score_label.text = "Score: %d" % score
	Global.save_high_score(score)
	_update_high_score_display()
	check_level_complete()

func check_level_complete() -> void:
	if current_mode == Mode.LEVELS and not level_completed:
		if score >= target_score:
			level_completed = true
			level_complete_score.text = "Score: %d" % score
			level_complete_modal.visible = true
			LevelManager.unlock_next_level(current_level)
			combo_sound.play()
			
			# Animate Level Complete Modal Card pop-in
			level_complete_card.scale = Vector2(0.7, 0.7)
			var tw := create_tween()
			tw.set_trans(Tween.TRANS_BACK)
			tw.set_ease(Tween.EASE_OUT)
			tw.tween_property(level_complete_card, "scale", Vector2.ONE, 0.3)

			# Check if a badge was unlocked for the NEXT level
			var unlocked_level = current_level + 1
			for badge in Global.BADGES:
				if badge.level == unlocked_level:
					_show_badge_unlocked(badge)
					break

func _show_badge_unlocked(badge: Dictionary) -> void:
	badge_sound.play()

	# Sparkling badge celebration banner
	var badge_card := Panel.new()
	var vp := get_viewport_rect().size
	badge_card.size = Vector2(520, 130)
	badge_card.position = Vector2((vp.x - 520) / 2.0, vp.y * 0.35)
	badge_card.z_index = 60
	
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.08, 0.18, 0.95)
	sb.set_corner_radius_all(22)
	sb.border_width_all = 3
	sb.border_color = badge.color
	sb.shadow_color = Color(badge.color.r, badge.color.g, badge.color.b, 0.5)
	sb.shadow_size = 18
	badge_card.add_theme_stylebox_override("panel", sb)

	var lbl := Label.new()
	lbl.text = "🎉 BADGE UNLOCKED! 🎉\n" + badge.name
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.size = badge_card.size
	lbl.add_theme_font_size_override("font_size", 38)
	lbl.add_theme_color_override("font_color", badge.color)
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	lbl.add_theme_constant_override("shadow_offset_x", 3)
	lbl.add_theme_constant_override("shadow_offset_y", 4)
	badge_card.add_child(lbl)
	add_child(badge_card)

	badge_card.scale = Vector2(0.6, 0.6)
	badge_card.pivot_offset = badge_card.size / 2.0
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_BACK)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(badge_card, "scale", Vector2.ONE, 0.35)
	tw.tween_interval(1.8)
	tw.tween_property(badge_card, "position:y", badge_card.position.y - 60.0, 0.8)
	tw.parallel().tween_property(badge_card, "modulate:a", 0.0, 0.8)
	tw.chain().tween_callback(badge_card.queue_free)

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
		game_over_final_score.text = "%d" % score
		game_over_modal.visible = true
		game_over_sound.play()

		# Animate Game Over Modal Card pop-in
		game_over_card.scale = Vector2(0.7, 0.7)
		game_over_card.pivot_offset = game_over_card.size / 2.0
		var tw := create_tween()
		tw.set_trans(Tween.TRANS_BACK)
		tw.set_ease(Tween.EASE_OUT)
		tw.tween_property(game_over_card, "scale", Vector2.ONE, 0.3)
