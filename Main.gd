extends Node2D

@onready var background: Control = $AnimatedBackground
@onready var grid: Node2D = $Grid
@onready var tray: Node2D = $Tray
@onready var score_label: Label = $ScoreLabel
@onready var high_score_label: Label = $HighScoreLabel
@onready var level_info_label: Label = $LevelInfoLabel
@onready var target_label: Label = $TargetLabel
@onready var hud_back_button: Button = $HudBackButton

# ── Modals & Screens ──────────────────────────────────────────────────────────
@onready var welcome_screen: Control = $WelcomeScreen
@onready var welcome_high_score_label: Label = $WelcomeScreen/HighScoreLabel
@onready var classic_button: Button = $WelcomeScreen/ClassicButton
@onready var levels_button: Button = $WelcomeScreen/LevelsButton

@onready var level_selection_screen: Control = $LevelSelectionScreen
@onready var back_button: Button = $LevelSelectionScreen/BackButton
@onready var scroll_container: ScrollContainer = $LevelSelectionScreen/ScrollContainer
@onready var level_map_container: Control = $LevelSelectionScreen/ScrollContainer/LevelMapContainer

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
const LEVEL_MAP_CHUNK_SIZE := 5

var tray_slots: Array = [null, null, null]
var tray_positions: Array = [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
var score := 0

var tray_panel: Panel
var active_fruit_theme: Dictionary = {}
var is_fruit_mode: bool = false

# Classic mode dynamic theme & 500-milestone celebration
var last_celebrated_500: int = 0
var current_theme_id: String = "classic"
var active_theme: Dictionary = {}

# Saga Map node positions
var level_node_positions: Dictionary = {}
var _level_map_built: Dictionary = {}
var _level_map_build_generation := 0
var _level_map_build_cursor := 0
var _level_map_build_order: Array[int] = []
var is_dragging_map: bool = false
var map_drag_start_y: float = 0.0
var map_scroll_start_y: float = 0.0
var map_drag_distance: float = 0.0
var map_scroll_velocity_y: float = 0.0

func _ready() -> void:
	randomize()

	game_over_modal.visible = false
	level_complete_modal.visible = false
	welcome_screen.visible = true

	grid.lines_cleared.connect(_on_lines_cleared)

	# Button Signals
	classic_button.pressed.connect(_on_classic_pressed)
	levels_button.pressed.connect(_on_levels_pressed)
	back_button.pressed.connect(_on_back_pressed)
	hud_back_button.pressed.connect(_handle_back_navigation)

	classic_button.pressed.connect(play_click)
	levels_button.pressed.connect(play_click)
	back_button.pressed.connect(play_click)
	hud_back_button.pressed.connect(play_click)

	game_over_restart_btn.pressed.connect(play_click)
	game_over_restart_btn.pressed.connect(start_game)
	game_over_home_btn.pressed.connect(play_click)
	game_over_home_btn.pressed.connect(_on_home_pressed)

	level_complete_next_btn.pressed.connect(play_click)
	level_complete_next_btn.pressed.connect(_on_next_level_pressed)
	level_complete_home_btn.pressed.connect(play_click)
	level_complete_home_btn.pressed.connect(_on_home_pressed)

	# Connect Level Map Custom Drawing
	level_map_container.draw.connect(_on_level_map_draw)

	# ── Tray panel backdrop ───────────────────────────────────────────────────
	tray_panel = Panel.new()
	tray_panel.z_index = -1
	add_child(tray_panel)
	move_child(tray_panel, 1)

	_apply_visual_theme()
	_update_responsive_layout()
	_update_high_score_display()
	_set_gameplay_ui_visible(false)

	get_viewport().size_changed.connect(_update_responsive_layout)

func _process(delta: float) -> void:
	if level_selection_screen.visible:
		# Smooth touch drag inertia fling scrolling
		if not is_dragging_map and abs(map_scroll_velocity_y) > 5.0:
			var max_scroll: float = max(0.0, level_map_container.custom_minimum_size.y - scroll_container.size.y)
			scroll_container.scroll_vertical = clamp(scroll_container.scroll_vertical + int(map_scroll_velocity_y * delta), 0, int(max_scroll))
			map_scroll_velocity_y = lerp(map_scroll_velocity_y, 0.0, delta * 6.0)

func _input(event: InputEvent) -> void:
	if level_selection_screen.visible:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging_map = true
				map_drag_start_y = event.position.y
				map_scroll_start_y = scroll_container.scroll_vertical
				map_drag_distance = 0.0
				map_scroll_velocity_y = 0.0
			else:
				is_dragging_map = false

		elif event is InputEventMouseMotion and is_dragging_map:
			var delta_y: float = event.position.y - map_drag_start_y
			map_drag_distance += abs(event.relative.y)
			var max_scroll: float = max(0.0, level_map_container.custom_minimum_size.y - scroll_container.size.y)
			scroll_container.scroll_vertical = clamp(int(map_scroll_start_y - delta_y), 0, int(max_scroll))
			map_scroll_velocity_y = -event.relative.y * 36.0

# ── Android Hardware / Gesture Back Button Handling ───────────────────────────
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_handle_back_navigation()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_handle_back_navigation()

func _handle_back_navigation() -> void:
	# 1. Modals (Dismiss first)
	if game_over_modal.visible:
		game_over_modal.visible = false
		_on_home_pressed()
		return

	if level_complete_modal.visible:
		level_complete_modal.visible = false
		_on_home_pressed()
		return

	# 2. Level Selection Screen -> Back to Welcome Screen
	if level_selection_screen.visible:
		_on_back_pressed()
		return

	# 3. Active Gameplay -> Back to Level Select (if in Levels mode) or Welcome Screen
	if grid.visible:
		grid.clear_drag_preview()
		_set_gameplay_ui_visible(false)
		if current_mode == Mode.LEVELS:
			_on_levels_pressed()
		else:
			welcome_screen.visible = true
		return

	# 4. Root Welcome Screen -> Exit app cleanly
	if welcome_screen.visible:
		get_tree().quit()

# ── Dynamic Responsive Layout ─────────────────────────────────────────────────
func _update_responsive_layout() -> void:
	var vp := get_viewport_rect().size
	var grid_width: float = Global.GRID_SIZE * Global.CELL_SIZE # 656px

	# Full-screen backgrounds and modals
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
		if scroll_container:
			scroll_container.position = Vector2(0, 120.0)
			scroll_container.size = Vector2(vp.x, vp.y - 120.0)

	if game_over_modal:
		game_over_modal.position = Vector2.ZERO
		game_over_modal.size = vp
	if level_complete_modal:
		level_complete_modal.position = Vector2.ZERO
		level_complete_modal.size = vp

	# ── Clean Non-Overlapping Gameplay Header Layout ───────────────────────────
	var header_total_h: float = 135.0
	var tray_h: float = 215.0
	var total_content_h: float = header_total_h + grid_width + tray_h
	var free_space: float = max(24.0, vp.y - total_content_h)
	var gap: float = free_space / 4.0

	var header_y: float = max(20.0, gap * 0.75)

	# Row 1: Back Button (Left), Mode/Level Badge (Center), Target/Best (Right)
	hud_back_button.position = Vector2(18.0, header_y)
	hud_back_button.size = Vector2(115.0, 50.0)

	if current_mode == Mode.LEVELS:
		level_info_label.position = Vector2(vp.x * 0.5 - 110.0, header_y)
		level_info_label.size = Vector2(220.0, 50.0)
		target_label.position = Vector2(vp.x - 175.0, header_y)
		target_label.size = Vector2(155.0, 50.0)
	else:
		level_info_label.position = Vector2(vp.x * 0.5 - 130.0, header_y)
		level_info_label.size = Vector2(260.0, 50.0)
		high_score_label.position = Vector2(vp.x - 185.0, header_y)
		high_score_label.size = Vector2(165.0, 50.0)

	# Row 2: Score Display directly below Row 1 without overlap
	var score_y: float = header_y + 56.0
	score_label.position = Vector2(0, score_y)
	score_label.size = Vector2(vp.x, 70.0)

	# Grid placed with safe clearance below the header
	var grid_x: float = max(10.0, (vp.x - grid_width) / 2.0)
	var grid_y: float = header_y + header_total_h + max(12.0, gap)
	grid.position = Vector2(grid_x, grid_y)

	# Tray pushed comfortably down into the lower area
	var tray_y: float = grid_y + grid_width + max(14.0, gap)
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
	hud_back_button.visible = p_visible
	if tray_panel:
		tray_panel.visible = p_visible

	if p_visible:
		if current_mode == Mode.LEVELS:
			level_info_label.visible = true
			target_label.visible = true
			high_score_label.visible = false
		else:
			level_info_label.visible = true # Shows current active theme in Classic!
			target_label.visible = false
			high_score_label.visible = true
	else:
		level_info_label.visible = false
		target_label.visible = false
		high_score_label.visible = false

func play_click() -> void:
	click_sound.play()

# ── High Score Display ────────────────────────────────────────────────────────
func _update_high_score_display() -> void:
	high_score_label.text = "🏆 %d" % Global.high_score
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
	_style_3d_button(hud_back_button, Color(0.38, 0.35, 0.65), Color(0.22, 0.20, 0.42), 18)

	_style_3d_button(game_over_restart_btn, Color(0.92, 0.28, 0.32), Color(0.60, 0.12, 0.15), 24)
	_style_3d_button(game_over_home_btn, Color(0.38, 0.35, 0.65), Color(0.22, 0.20, 0.42), 24)

	_style_3d_button(level_complete_next_btn, Color(0.18, 0.85, 0.48), Color(0.08, 0.52, 0.28), 24)
	_style_3d_button(level_complete_home_btn, Color(0.38, 0.35, 0.65), Color(0.22, 0.20, 0.42), 24)

	_setup_button_juice(classic_button)
	_setup_button_juice(levels_button)
	_setup_button_juice(back_button)
	_setup_button_juice(hud_back_button)
	_setup_button_juice(game_over_restart_btn)
	_setup_button_juice(game_over_home_btn)
	_setup_button_juice(level_complete_next_btn)
	_setup_button_juice(level_complete_home_btn)

	# ── Typography & Label Styling ────────────────────────────────────────────
	level_info_label.add_theme_font_size_override("font_size", 28)
	level_info_label.add_theme_color_override("font_color", Color(0.40, 0.85, 1.0, 1.0))
	level_info_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	level_info_label.add_theme_constant_override("shadow_offset_x", 2)
	level_info_label.add_theme_constant_override("shadow_offset_y", 2)
	level_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_info_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	high_score_label.add_theme_font_size_override("font_size", 26)
	high_score_label.add_theme_color_override("font_color", Color(1.00, 0.84, 0.22, 1.0))
	high_score_label.add_theme_color_override("font_shadow_color", Color(0.45, 0.25, 0.0, 0.85))
	high_score_label.add_theme_constant_override("shadow_offset_x", 2)
	high_score_label.add_theme_constant_override("shadow_offset_y", 2)
	high_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	high_score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	score_label.add_theme_font_size_override("font_size", 68)
	score_label.add_theme_color_override("font_color", Color(1.00, 0.98, 0.92, 1.0))
	score_label.add_theme_color_override("font_shadow_color", Color(0.00, 0.00, 0.00, 0.85))
	score_label.add_theme_constant_override("shadow_offset_x", 3)
	score_label.add_theme_constant_override("shadow_offset_y", 4)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	target_label.add_theme_font_size_override("font_size", 26)
	target_label.add_theme_color_override("font_color", Color(0.35, 0.95, 0.60, 1.0))
	target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	target_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

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
		sel_title.add_theme_font_size_override("font_size", 54)
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

func _setup_button_juice(btn: Button) -> void:
	if btn == null:
		return

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
	for child in tray_panel.get_children():
		child.queue_free()
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

func _apply_theme_to_tray(theme: Dictionary) -> void:
	if tray_panel == null:
		return

	for child in tray_panel.get_children():
		child.queue_free()

	var tex_type: String = theme.get("texture_type", "classic")
	var tray_bg: Color = theme.get("tray_bg", Color(0.10, 0.09, 0.16, 0.94))
	var tray_border: Color = theme.get("tray_border", Color(0.28, 0.25, 0.38, 0.85))
	var accent: Color = theme.get("accent", Color(1.0, 0.85, 0.3))
	var radius: int = theme.get("corner_radius", 20)

	var sb := StyleBoxFlat.new()
	sb.bg_color = tray_bg
	sb.set_corner_radius_all(radius + 4)
	sb.set_border_width_all(theme.get("border_width", 4))
	sb.border_color = tray_border
	sb.shadow_color = accent.lerp(Color.BLACK, 0.60)
	sb.shadow_size = 18
	sb.shadow_offset = Vector2(0, 6)
	sb.anti_aliasing = true
	tray_panel.add_theme_stylebox_override("panel", sb)

	# ── Material-Specific Tray Decorative Trim ────────────────────────────────
	var tw_w: float = tray_panel.size.x
	var tw_h: float = tray_panel.size.y
	if tw_w > 0 and tw_h > 0:
		match tex_type:
			"wood":
				# Brass/copper inlaid header strip
				var trim := ColorRect.new()
				trim.position = Vector2(16, 8)
				trim.size = Vector2(tw_w - 32, 2)
				trim.color = Color(0.95, 0.75, 0.35, 0.45)
				trim.mouse_filter = Control.MOUSE_FILTER_IGNORE
				tray_panel.add_child(trim)
			"ice":
				# Frosted crystal top edge
				var frost := ColorRect.new()
				frost.position = Vector2(20, 6)
				frost.size = Vector2(tw_w - 40, 3)
				frost.color = Color(0.80, 0.95, 1.0, 0.65)
				frost.mouse_filter = Control.MOUSE_FILTER_IGNORE
				tray_panel.add_child(frost)
			"magma":
				# Molten lava under-rim glow
				var lava_glow := ColorRect.new()
				lava_glow.position = Vector2(18, tw_h - 10)
				lava_glow.size = Vector2(tw_w - 36, 3)
				lava_glow.color = Color(1.0, 0.45, 0.05, 0.75)
				lava_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
				tray_panel.add_child(lava_glow)
			"royal_gold":
				# Double gold filigree strip
				var gtrim := ColorRect.new()
				gtrim.position = Vector2(18, 8)
				gtrim.size = Vector2(tw_w - 36, 2)
				gtrim.color = Color(1.0, 0.92, 0.45, 0.85)
				gtrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
				tray_panel.add_child(gtrim)
			"neon":
				# High-intensity laser line
				var nline := ColorRect.new()
				nline.position = Vector2(22, 6)
				nline.size = Vector2(tw_w - 44, 2)
				nline.color = accent
				nline.mouse_filter = Control.MOUSE_FILTER_IGNORE
				tray_panel.add_child(nline)

	var tw := create_tween()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tray_panel.scale = Vector2(1.03, 1.03)
	tw.tween_property(tray_panel, "scale", Vector2.ONE, 0.3)

# ── Candy Crush Saga-Style Winding Snake Map (Levels 1 to 100) ────────────────
# Level buttons are created in small per-frame chunks so the LEVELS screen opens
# instantly instead of freezing while all 100 styled nodes are built.
func _populate_level_grid() -> void:
	# Bumping the generation aborts any chunked build still running from a
	# previous visit to this screen.
	_level_map_build_generation += 1

	for child in level_map_container.get_children():
		child.queue_free()
	level_node_positions.clear()
	_level_map_built.clear()
	_level_map_build_cursor = 0
	_level_map_build_order.clear()

	var vp := get_viewport_rect().size
	var step_y: float = 150.0
	var bottom_padding: float = 180.0
	var top_padding: float = 200.0
	var total_h: float = bottom_padding + (LevelManager.MAX_LEVELS * step_y) + top_padding
	level_map_container.custom_minimum_size = Vector2(vp.x, total_h)

	var bottom_y: float = total_h - bottom_padding
	for i in range(1, LevelManager.MAX_LEVELS + 1):
		# Sinusoidal snake curve climbing upwards from bottom (Level 1) to top (Level 100)
		var wave_phase: float = (i - 1) * 0.46
		var nx: float = (vp.x * 0.5) + sin(wave_phase) * (vp.x * 0.32)
		var ny: float = bottom_y - (i - 1) * step_y
		level_node_positions[i] = Vector2(nx, ny)

	# Build nodes closest to the current unlocked level first so the visible
	# part of the map (after auto-scroll) fills in almost immediately.
	for i in range(1, LevelManager.MAX_LEVELS + 1):
		_level_map_build_order.append(i)
	_level_map_build_order.sort_custom(func(a: int, b: int) -> bool:
		return abs(a - LevelManager.unlocked_level) < abs(b - LevelManager.unlocked_level))

	_begin_level_map_chunked_build()

func _begin_level_map_chunked_build() -> void:
	var generation: int = _level_map_build_generation
	while _level_map_build_cursor < _level_map_build_order.size():
		if generation != _level_map_build_generation:
			return
		var chunk_end: int = mini(_level_map_build_cursor + LEVEL_MAP_CHUNK_SIZE, _level_map_build_order.size())
		while _level_map_build_cursor < chunk_end:
			_create_level_node(_level_map_build_order[_level_map_build_cursor])
			_level_map_build_cursor += 1
		level_map_container.queue_redraw()
		if _level_map_build_cursor < _level_map_build_order.size():
			await get_tree().process_frame
	level_map_container.queue_redraw()

func _create_level_node(i: int) -> void:
	var lvl_theme: Dictionary = Global.get_theme_for_level(i)
	var theme_icon: String = lvl_theme.get("icon", "★")
	var theme_accent: Color = lvl_theme.get("accent", Color(1.0, 0.8, 0.2))
	var theme_border: Color = lvl_theme.get("grid_border", Color(0.5, 0.4, 0.7))

	var is_milestone: bool = (i % 10 == 0 or i == 5 or i == 25 or i == 50 or i == 100)
	var btn_size := Vector2(134, 134) if is_milestone else Vector2(112, 112)
	var pos: Vector2 = level_node_positions.get(i, Vector2.ZERO)
	var btn := Button.new()
	btn.custom_minimum_size = btn_size
	btn.size = btn_size
	btn.position = pos - (btn_size * 0.5)
	btn.pivot_offset = btn_size * 0.5
	btn.mouse_filter = Control.MOUSE_FILTER_PASS

	if i > LevelManager.unlocked_level:
		# Locked level: Stone with lock and material icon
		btn.text = "🔒\n%s %d" % [theme_icon, i]
		btn.disabled = true
		btn.add_theme_font_size_override("font_size", 24)
		_style_3d_button(btn, Color(0.18, 0.16, 0.24, 0.90), Color(0.09, 0.07, 0.13), int(btn_size.x * 0.5))
	elif i == LevelManager.unlocked_level:
		# Current unlocked level: Radiant glowing gem themed to the unlocked material
		btn.text = "%s\n%d" % [theme_icon, i]
		btn.add_theme_font_size_override("font_size", 32)
		_style_3d_button(btn, theme_accent, theme_border, int(btn_size.x * 0.5))
		_setup_button_juice(btn)

		var tw := create_tween().set_loops()
		tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(btn, "scale", Vector2(1.10, 1.10), 0.65)
		tw.tween_property(btn, "scale", Vector2.ONE, 0.65)

		# Floating beacon label
		var ptr := Label.new()
		ptr.text = "HERE ➔"
		ptr.add_theme_font_size_override("font_size", 26)
		ptr.add_theme_color_override("font_color", theme_accent)
		ptr.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
		ptr.position = Vector2(pos.x - 130, pos.y - 16)
		ptr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		level_map_container.add_child(ptr)

		var ptw := create_tween().set_loops()
		ptw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		ptw.tween_property(ptr, "position:x", ptr.position.x - 10, 0.5)
		ptw.tween_property(ptr, "position:x", ptr.position.x, 0.5)
	else:
		# Cleared level: Decorated with stars and material icon
		btn.text = "%s\n%d" % [theme_icon, i]
		btn.add_theme_font_size_override("font_size", 28)
		if is_milestone:
			_style_3d_button(btn, Color(0.96, 0.36, 0.62), Color(0.66, 0.15, 0.38), int(btn_size.x * 0.5))
		else:
			_style_3d_button(btn, theme_accent.darkened(0.25), theme_border.darkened(0.3), int(btn_size.x * 0.5))
		_setup_button_juice(btn)

	var lvl_num := i
	btn.pressed.connect(func():
		if map_drag_distance > 18.0:
			return
		play_click()
		start_level(lvl_num)
	)
	level_map_container.add_child(btn)
	_level_map_built[i] = true

func _on_level_map_draw() -> void:
	if level_node_positions.is_empty():
		return
	var total_levels := LevelManager.MAX_LEVELS
	for i in range(1, total_levels):
		if level_node_positions.has(i) and level_node_positions.has(i + 1) \
			and _level_map_built.has(i) and _level_map_built.has(i + 1):
			var p1: Vector2 = level_node_positions[i]
			var p2: Vector2 = level_node_positions[i + 1]

			var is_cleared: bool = (i < LevelManager.unlocked_level)
			var road_color := Color(0.24, 0.20, 0.36, 0.85) if not is_cleared else Color(0.18, 0.64, 0.44, 0.90)
			var core_color := Color(0.48, 0.40, 0.68, 0.90) if not is_cleared else Color(1.00, 0.88, 0.34, 0.98)

			# Outer smooth road
			level_map_container.draw_line(p1, p2, road_color, 26.0, true)
			# Inner core line
			level_map_container.draw_line(p1, p2, core_color, 10.0, true)
			# Stepping stone pearls along the road segment
			var dot1: Vector2 = p1.lerp(p2, 0.25)
			var dot2: Vector2 = p1.lerp(p2, 0.5)
			var dot3: Vector2 = p1.lerp(p2, 0.75)
			level_map_container.draw_circle(dot1, 5.0, Color.WHITE)
			level_map_container.draw_circle(dot2, 6.0, Color.WHITE)
			level_map_container.draw_circle(dot3, 5.0, Color.WHITE)

# ── Screen transitions ─────────────────────────────────────────────────────────
func _on_classic_pressed() -> void:
	current_mode = Mode.CLASSIC
	start_game()

func _on_levels_pressed() -> void:
	current_mode = Mode.LEVELS
	AdsManager.set_banner_visible(true)
	_populate_level_grid()
	welcome_screen.visible = false
	level_selection_screen.visible = true
	_set_gameplay_ui_visible(false)

	# Auto-scroll directly to the player's current unlocked level
	var vp := get_viewport_rect().size
	var step_y: float = 150.0
	var bottom_padding: float = 180.0
	var total_h: float = level_map_container.custom_minimum_size.y
	var bottom_y: float = total_h - bottom_padding
	var target_y: float = bottom_y - (LevelManager.unlocked_level - 1) * step_y - (vp.y * 0.5)

	get_tree().create_timer(0.05).timeout.connect(func():
		if scroll_container:
			scroll_container.scroll_vertical = clamp(int(target_y), 0, int(total_h - vp.y))
	)

func _on_back_pressed() -> void:
	AdsManager.set_banner_visible(true)
	level_selection_screen.visible = false
	welcome_screen.visible = true
	_set_gameplay_ui_visible(false)

func _on_home_pressed() -> void:
	AdsManager.set_banner_visible(true)
	grid.clear_drag_preview()
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
	AdsManager.set_banner_visible(false)
	level_completed = false

	_set_gameplay_ui_visible(true)
	_update_responsive_layout()

	is_fruit_mode = false
	active_fruit_theme = {}
	last_celebrated_500 = 0
	current_theme_id = "classic"

	if current_mode == Mode.CLASSIC:
		_apply_game_theme(Global.THEMES["classic"])
	else:
		var lvl_theme: Dictionary = Global.get_theme_for_level(current_level)
		_apply_game_theme(lvl_theme)

	score = 0
	score_label.text = "Score: %d" % score
	_update_high_score_display()

	if current_mode == Mode.LEVELS:
		target_score = LevelManager.get_target_score(current_level)
		target_label.text = "🎯 %d" % target_score
		target_label.visible = true
		level_info_label.text = "%s LVL %d" % [active_theme.get("icon", "★"), current_level]
		level_info_label.visible = true
		level_info_label.add_theme_color_override("font_color", active_theme.get("accent", Color(0.40, 0.85, 1.0, 1.0)))
	else:
		target_label.visible = false
		level_info_label.text = "🍬 CLASSIC"
		level_info_label.visible = true
		level_info_label.add_theme_color_override("font_color", Color(1.00, 0.78, 0.24, 1.0))

	grid.clear_grid()
	grid.clear_drag_preview()

	if current_mode == Mode.LEVELS:
		var pattern: Array[Vector2i] = LevelManager.get_level_pattern(current_level)
		var colors: Array[Color] = []
		for color in active_theme.get("colors", Global.COLORS):
			if color is Color:
				colors.append(color)
		if colors.is_empty():
			colors = Global.COLORS
		grid.spawn_initial_pattern(pattern, colors, current_level)
		_show_level_intro_banner(current_level, active_theme)

	for i in tray_slots.size():
		if tray_slots[i] != null:
			tray_slots[i].queue_free()
			tray_slots[i] = null

	fill_tray()

# ── Dynamic Theme Application for 500-Point Milestone ─────────────────────────
func _apply_game_theme(theme: Dictionary) -> void:
	active_theme = theme
	grid.apply_theme(theme)
	_apply_theme_to_tray(theme)

	if current_mode == Mode.CLASSIC:
		level_info_label.text = theme.get("name", "Classic")
		level_info_label.add_theme_color_override("font_color", theme.get("accent", Color.WHITE))

	# Update pieces currently in tray to match the new theme
	for piece in tray_slots:
		if piece != null:
			piece.active_theme = theme
			piece._build_visuals()

# ── Tray Management & Piece Generation Fix ────────────────────────────────────
func fill_tray() -> void:
	var empty_slots: Array[int] = []
	for i in tray_slots.size():
		if tray_slots[i] == null:
			empty_slots.append(i)

	if empty_slots.is_empty():
		return

	# Determine available shape pool based on mode and difficulty
	var available_shape_keys: Array = []
	if current_mode == Mode.CLASSIC:
		available_shape_keys = Global.get_shapes_for_score(score)
	else:
		if current_level <= 3:
			available_shape_keys = Global.SHAPES_EASY.duplicate()
		elif current_level <= 8:
			available_shape_keys = Global.SHAPES_MEDIUM.duplicate()
		elif current_level <= 18:
			available_shape_keys = Global.SHAPES_HARD.duplicate()
		else:
			available_shape_keys = Global.SHAPES.keys().duplicate()

	# Pick distinct shapes so no two empty slots get identical shapes!
	var chosen_shapes: Array[String] = []
	var pool_copy: Array = available_shape_keys.duplicate()
	pool_copy.shuffle()

	for slot in empty_slots:
		var picked: String = ""
		for candidate in pool_copy:
			if candidate not in chosen_shapes:
				picked = candidate
				break
		if picked == "":
			picked = pool_copy[randi() % pool_copy.size()]
		chosen_shapes.append(picked)

	# Guarantee that at least one of the shapes can be placed on the current grid!
	var any_playable := false
	for shape_name in chosen_shapes:
		if grid.can_place_anywhere(Global.SHAPES[shape_name]):
			any_playable = true
			break

	if not any_playable:
		# Replace the last shape with a small shape that CAN fit!
		var small_candidates := ["single", "domino_h", "domino_v", "line3_h", "line3_v", "square2", "corner"]
		small_candidates.shuffle()
		for cand in small_candidates:
			if grid.can_place_anywhere(Global.SHAPES[cand]):
				chosen_shapes[chosen_shapes.size() - 1] = cand
				break

	# Spawn the pieces in their respective slots
	for idx in range(empty_slots.size()):
		var slot: int = empty_slots[idx]
		var shape_name: String = chosen_shapes[idx]
		spawn_piece(slot, shape_name)

	check_game_over()

func spawn_piece(slot: int, shape_name: String = "") -> void:
	if shape_name == "":
		var pool := Global.get_shapes_for_score(score) if current_mode == Mode.CLASSIC else Global.SHAPES.keys()
		shape_name = pool[randi() % pool.size()]

	var shape: Array = Global.SHAPES[shape_name]

	# Color selection
	var color: Color
	if current_mode == Mode.CLASSIC and active_theme.has("colors"):
		var col_list: Array = active_theme["colors"]
		color = col_list[randi() % col_list.size()]
	elif is_fruit_mode and active_fruit_theme.has("main"):
		color = active_fruit_theme["main"]
	else:
		color = Global.COLORS[randi() % Global.COLORS.size()]

	var piece = PIECE_SCENE.instantiate()
	tray.add_child(piece)

	# Calculate dynamic scale so wide pieces never overlap neighboring slots
	var vp := get_viewport_rect().size
	var tray_margin: float = 18.0
	var tray_w: float = vp.x - (tray_margin * 2.0)
	var max_slot_w: float = (tray_w / 3.0) * 0.85
	var max_slot_h: float = 215.0 * 0.75
	var b_size: Vector2 = Vector2.ZERO
	for cell in shape:
		b_size.x = max(b_size.x, (cell.x + 1) * Global.CELL_SIZE)
		b_size.y = max(b_size.y, (cell.y + 1) * Global.CELL_SIZE)

	var p_scale: float = 0.55
	if b_size.x * p_scale > max_slot_w:
		p_scale = max_slot_w / b_size.x
	if b_size.y * p_scale > max_slot_h:
		p_scale = min(p_scale, max_slot_h / b_size.y)
	p_scale = clamp(p_scale, 0.32, 0.58)

	piece.setup(shape, color, slot * 0.08, current_level, active_theme, p_scale)

	# Position centered in slot
	var piece_preview_size: Vector2 = b_size * p_scale
	var slot_origin: Vector2 = tray_positions[slot] - (piece_preview_size * 0.5)
	piece.position = slot_origin
	piece.home_position = slot_origin
	piece.slot_index = slot

	piece.dropped.connect(_on_piece_dropped)
	piece.drag_moved.connect(_on_piece_drag_moved)
	piece.picked_up.connect(func(): pickup_sound.play())
	piece.returned_home.connect(func():
		grid.clear_drag_preview()
		invalid_sound.play()
	)
	tray_slots[slot] = piece

func _on_piece_drag_moved(piece, drag_pos: Vector2) -> void:
	var local_pos: Vector2 = drag_pos - grid.global_position
	var origin := Vector2i(roundi(local_pos.x / Global.CELL_SIZE), roundi(local_pos.y / Global.CELL_SIZE))
	grid.show_drag_preview(piece.shape, origin, piece.color)

func _on_piece_dropped(piece, drop_global_position: Vector2) -> void:
	grid.clear_drag_preview()
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
	_apply_theme_to_tray(active_fruit_theme)

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

# ── Score & Progression ───────────────────────────────────────────────────────
func update_score(cells_placed: int) -> void:
	score += cells_placed
	score_label.text = "Score: %d" % score
	Global.save_high_score(score)
	_update_high_score_display()

	if current_mode == Mode.CLASSIC:
		var current_500: int = score / 500
		if current_500 > last_celebrated_500:
			last_celebrated_500 = current_500
			_trigger_500_score_celebration()
	else:
		check_level_complete()

func _on_lines_cleared(count: int) -> void:
	if count >= 2:
		combo_sound.play()
	else:
		clear_sound.play()
	score += count * 10 * count
	score_label.text = "Score: %d" % score
	Global.save_high_score(score)
	_update_high_score_display()

	if current_mode == Mode.CLASSIC:
		var current_500: int = score / 500
		if current_500 > last_celebrated_500:
			last_celebrated_500 = current_500
			_trigger_500_score_celebration()
	else:
		check_level_complete()

func _trigger_500_score_celebration() -> void:
	combo_sound.play()
	var new_theme: Dictionary = Global.get_next_theme(current_theme_id)
	current_theme_id = new_theme.get("id", "classic")
	_apply_game_theme(new_theme)

	# Floating celebratory banner
	var banner := Panel.new()
	var vp := get_viewport_rect().size
	var banner_w: float = min(560.0, vp.x * 0.88)
	banner.size = Vector2(banner_w, 140.0)
	banner.position = Vector2((vp.x - banner_w) * 0.5, vp.y * 0.32)
	banner.z_index = 80

	var sb := StyleBoxFlat.new()
	sb.bg_color = new_theme.get("grid_bg", Color(0.1, 0.08, 0.16, 0.96)).lightened(0.08)
	sb.set_corner_radius_all(24)
	sb.set_border_width_all(4)
	sb.border_color = new_theme.get("accent", Color(1, 0.85, 0.3))
	sb.shadow_color = new_theme.get("accent", Color(1, 0.85, 0.3, 0.5))
	sb.shadow_size = 20
	banner.add_theme_stylebox_override("panel", sb)

	var lbl := Label.new()
	lbl.text = "🎉 500 PTS MILESTONE! 🎉\n" + new_theme.get("banner", "NEW THEME!")
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.size = banner.size
	lbl.add_theme_font_size_override("font_size", 34)
	lbl.add_theme_color_override("font_color", new_theme.get("accent", Color.WHITE))
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	lbl.add_theme_constant_override("shadow_offset_x", 3)
	lbl.add_theme_constant_override("shadow_offset_y", 4)
	banner.add_child(lbl)
	add_child(banner)

	banner.scale = Vector2(0.6, 0.6)
	banner.pivot_offset = banner.size * 0.5
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(banner, "scale", Vector2.ONE, 0.35)
	tw.tween_interval(1.8)
	tw.tween_property(banner, "position:y", banner.position.y - 70.0, 0.8)
	tw.parallel().tween_property(banner, "modulate:a", 0.0, 0.8)
	tw.chain().tween_callback(banner.queue_free)

func check_level_complete() -> void:
	if current_mode == Mode.LEVELS and not level_completed:
		if score >= target_score:
			level_completed = true
			level_complete_score.text = "Score: %d" % score
			level_complete_modal.visible = true
			LevelManager.unlock_next_level(current_level)
			combo_sound.play()

			level_complete_card.scale = Vector2(0.7, 0.7)
			level_complete_card.pivot_offset = level_complete_card.size / 2.0
			var tw := create_tween()
			tw.set_trans(Tween.TRANS_BACK)
			tw.set_ease(Tween.EASE_OUT)
			tw.tween_property(level_complete_card, "scale", Vector2.ONE, 0.3)

			var unlocked_level = current_level + 1
			for badge in Global.BADGES:
				if badge.level == unlocked_level:
					_show_badge_unlocked(badge)
					break

func _show_badge_unlocked(badge: Dictionary) -> void:
	badge_sound.play()

	var badge_card := Panel.new()
	var vp := get_viewport_rect().size
	badge_card.size = Vector2(520, 130)
	badge_card.position = Vector2((vp.x - 520) / 2.0, vp.y * 0.35)
	badge_card.z_index = 60

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.08, 0.18, 0.95)
	sb.set_corner_radius_all(22)
	sb.set_border_width_all(3)
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

# ── Level Intro Banner ────────────────────────────────────────────────────────
# Shows an animated overlay card when a level starts, revealing the material
# theme, pattern challenge name, and the score target the player must reach.
func _show_level_intro_banner(level: int, theme: Dictionary) -> void:
	var vp := get_viewport_rect().size
	var banner_w: float = min(580.0, vp.x * 0.90)
	var banner_h: float = 200.0

	# ── Outer card ──────────────────────────────────────────────────────────
	var card := Panel.new()
	card.size = Vector2(banner_w, banner_h)
	card.position = Vector2((vp.x - banner_w) * 0.5, vp.y * 0.28)
	card.z_index = 90

	var accent: Color = theme.get("accent", Color(1.0, 0.85, 0.3))
	var bg: Color = theme.get("grid_bg", Color(0.07, 0.05, 0.14, 0.97)).darkened(0.08)

	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(30)
	sb.set_border_width_all(4)
	sb.border_color = accent
	sb.shadow_color = Color(accent.r, accent.g, accent.b, 0.55)
	sb.shadow_size = 28
	sb.shadow_offset = Vector2(0, 6)
	sb.anti_aliasing = true
	card.add_theme_stylebox_override("panel", sb)

	# ── Shimmering inner stripe ──────────────────────────────────────────────
	var stripe := ColorRect.new()
	stripe.size = Vector2(banner_w, 4)
	stripe.position = Vector2(0, 60)
	stripe.color = Color(accent.r, accent.g, accent.b, 0.35)
	card.add_child(stripe)

	var stripe2 := ColorRect.new()
	stripe2.size = Vector2(banner_w, 4)
	stripe2.position = Vector2(0, banner_h - 64)
	stripe2.color = Color(accent.r, accent.g, accent.b, 0.35)
	card.add_child(stripe2)

	# ── "LEVEL X" header ────────────────────────────────────────────────────
	var header := Label.new()
	var icon: String = theme.get("icon", "★")
	header.text = "%s  LEVEL %d  %s" % [icon, level, icon]
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.position = Vector2(0, 8)
	header.size = Vector2(banner_w, 54)
	header.add_theme_font_size_override("font_size", 40)
	header.add_theme_color_override("font_color", accent)
	header.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	header.add_theme_constant_override("shadow_offset_x", 3)
	header.add_theme_constant_override("shadow_offset_y", 4)
	card.add_child(header)

	# ── Material theme name ─────────────────────────────────────────────────
	var theme_name: String = theme.get("name", "Classic")
	var banner_text: String = theme.get("banner", theme_name)
	var mat_lbl := Label.new()
	mat_lbl.text = banner_text
	mat_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mat_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mat_lbl.position = Vector2(0, 68)
	mat_lbl.size = Vector2(banner_w, 46)
	mat_lbl.add_theme_font_size_override("font_size", 26)
	mat_lbl.add_theme_color_override("font_color", accent.lightened(0.18))
	mat_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	mat_lbl.add_theme_constant_override("shadow_offset_x", 2)
	mat_lbl.add_theme_constant_override("shadow_offset_y", 3)
	card.add_child(mat_lbl)

	# ── Target score line ───────────────────────────────────────────────────
	var tgt: int = LevelManager.get_target_score(level)
	var score_lbl := Label.new()
	score_lbl.text = "🎯  Clear the pattern — reach %d pts" % tgt
	score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	score_lbl.position = Vector2(0, banner_h - 60)
	score_lbl.size = Vector2(banner_w, 52)
	score_lbl.add_theme_font_size_override("font_size", 20)
	score_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.82))
	score_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
	score_lbl.add_theme_constant_override("shadow_offset_x", 2)
	score_lbl.add_theme_constant_override("shadow_offset_y", 2)
	card.add_child(score_lbl)

	add_child(card)

	# ── Pop-in animation ────────────────────────────────────────────────────
	card.modulate.a = 0.0
	card.scale = Vector2(0.72, 0.72)
	card.pivot_offset = card.size * 0.5

	var tw := create_tween()
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.set_parallel(true)
	tw.tween_property(card, "scale", Vector2.ONE, 0.38)
	tw.tween_property(card, "modulate:a", 1.0, 0.28)
	tw.chain().tween_interval(1.9)

	# ── Shimmering accent pulse while visible ────────────────────────────────
	var pulse_tw := create_tween()
	pulse_tw.set_loops(3)
	pulse_tw.tween_property(stripe, "color:a", 0.75, 0.35)
	pulse_tw.tween_property(stripe, "color:a", 0.35, 0.35)

	# ── Fly-out & fade ──────────────────────────────────────────────────────
	tw.chain().set_parallel(true)
	tw.tween_property(card, "position:y", card.position.y - 80.0, 0.6)
	tw.tween_property(card, "modulate:a", 0.0, 0.6)
	tw.chain().tween_callback(card.queue_free)

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
		AdsManager.set_banner_visible(true)
		AdsManager.consider_interstitial_after_game_over()
		game_over_sound.play()

		game_over_card.scale = Vector2(0.7, 0.7)
		game_over_card.pivot_offset = game_over_card.size / 2.0
		var tw := create_tween()
		tw.set_trans(Tween.TRANS_BACK)
		tw.set_ease(Tween.EASE_OUT)
		tw.tween_property(game_over_card, "scale", Vector2.ONE, 0.3)
