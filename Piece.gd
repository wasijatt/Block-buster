extends Node2D

signal dropped(piece, drop_position)
signal picked_up()
signal returned_home()

var shape: Array = []
var color: Color = Color.WHITE
var home_position: Vector2 = Vector2.ZERO
var slot_index: int = -1
var dragging := false
var drag_offset := Vector2.ZERO
var current_level: int = 1

const TRAY_SCALE: float = 0.58
const DRAG_FINGER_OFFSET_Y: float = -140.0

# Smooth drag: we track where we WANT to be, then lerp toward it in _process.
var _drag_target: Vector2 = Vector2.ZERO

# ── Public API ─────────────────────────────────────────────────────────────────

# setup() is called by Main.gd after instantiation.
func setup(p_shape: Array, p_color: Color, spawn_delay: float = 0.0, level: int = 1) -> void:
	shape = p_shape
	color = p_color
	current_level = level
	_build_visuals()
	_animate_spawn(spawn_delay)

# Called by Main.gd when a drop is invalid — smooth spring back + shake.
func return_home() -> void:
	returned_home.emit()
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_BACK)
	tw.set_ease(Tween.EASE_OUT)
	# 1. Slide back to home position and shrink back to preview size
	tw.tween_property(self, "position", home_position, 0.22)
	tw.parallel().tween_property(self, "scale", Vector2(TRAY_SCALE, TRAY_SCALE), 0.22)
	# 2. Quick shake to signal "can't go there"
	tw.tween_property(self, "rotation_degrees", -6.0,  0.05)
	tw.tween_property(self, "rotation_degrees",  5.0,  0.05)
	tw.tween_property(self, "rotation_degrees", -3.0,  0.04)
	tw.tween_property(self, "rotation_degrees",  1.5,  0.04)
	tw.tween_property(self, "rotation_degrees",  0.0,  0.03)

# ── Visuals ────────────────────────────────────────────────────────────────────

func _build_visuals() -> void:
	for cell in shape:
		var bx: float = cell.x * Global.CELL_SIZE
		var by: float = cell.y * Global.CELL_SIZE
		var w: float = Global.CELL_SIZE - 6
		var h: float = Global.CELL_SIZE - 6

		# Tier 1 (Level 1-5): Classic
		# Tier 2 (Level 6-15): Premium Gem
		# Tier 3 (Level 16+): Diamond/Neon
		var is_premium: bool = current_level > 5
		var is_diamond: bool = current_level > 15
		
		# ── Main 3D Gem Block Face (Smooth Rounded Vector StyleBox) ────────────
		var panel := Panel.new()
		panel.size = Vector2(w, h)
		panel.position = Vector2(bx + 3, by + 3)
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var sb := StyleBoxFlat.new()
		sb.bg_color = color
		
		if is_diamond:
			sb.set_corner_radius_all(8)
			sb.border_width_bottom = 6
			sb.border_width_right = 6
			sb.border_width_top = 2
			sb.border_width_left = 2
			sb.border_color = color.lerp(Color.WHITE, 0.35)
			sb.shadow_color = color
			sb.shadow_size = 12
			sb.shadow_offset = Vector2(0, 0)
		elif is_premium:
			sb.set_corner_radius_all(22)
			sb.border_width_bottom = 5
			sb.border_width_right = 5
			sb.border_width_top = 2
			sb.border_width_left = 2
			sb.border_color = Color(color.r * 0.4, color.g * 0.4, color.b * 0.4, 1.0)
			sb.shadow_color = Color(0.0, 0.0, 0.0, 0.60)
			sb.shadow_size = 8
			sb.shadow_offset = Vector2(0, 5)
		else:
			sb.set_corner_radius_all(16)
			sb.border_width_bottom = 5
			sb.border_width_right = 5
			sb.border_color = Color(color.r * 0.52, color.g * 0.52, color.b * 0.52, 1.0)
			sb.shadow_color = Color(0.0, 0.0, 0.0, 0.40)
			sb.shadow_size = 6
			sb.shadow_offset = Vector2(0, 4)
			
		sb.anti_aliasing = true
		panel.add_theme_stylebox_override("panel", sb)
		add_child(panel)

		# Inner glow for premium/diamond
		if is_premium or is_diamond:
			var inner := Panel.new()
			inner.size = Vector2(w - 10, h - 10)
			inner.position = Vector2(bx + 8, by + 8)
			inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var isb := StyleBoxFlat.new()
			isb.bg_color = Color.TRANSPARENT
			isb.border_width_all = 3
			isb.border_color = Color(1.0, 1.0, 1.0, 0.28 if is_premium else 0.55)
			isb.set_corner_radius_all(18 if is_premium and not is_diamond else 6)
			isb.border_blend = true
			inner.add_theme_stylebox_override("panel", isb)
			add_child(inner)

		# ── Top-Left Glossy Highlight Edge ─────────────────────────────────────
		var highlight := Panel.new()
		highlight.size = Vector2(w - 14, h * 0.42)
		highlight.position = Vector2(bx + 10, by + 7)
		highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var hsb := StyleBoxFlat.new()
		hsb.bg_color = Color(1.0, 1.0, 1.0, 0.52 if is_diamond else (0.42 if is_premium else 0.34))
		hsb.set_corner_radius_all(10 if not is_diamond else 4)
		hsb.anti_aliasing = true
		highlight.add_theme_stylebox_override("panel", hsb)
		add_child(highlight)

		# ── Corner Glint (Crystal Specular Highlight) ──────────────────────────
		var glint := Panel.new()
		glint.size = Vector2(10, 10)
		glint.position = Vector2(bx + 12, by + 9)
		glint.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var gsb := StyleBoxFlat.new()
		gsb.bg_color = Color(1.0, 1.0, 1.0, 0.95 if is_diamond else (0.88 if is_premium else 0.80))
		gsb.set_corner_radius_all(5)
		gsb.anti_aliasing = true
		glint.add_theme_stylebox_override("panel", gsb)
		add_child(glint)

# ── Animations ─────────────────────────────────────────────────────────────────

func _animate_spawn(delay: float) -> void:
	scale = Vector2.ZERO
	var tw := create_tween()
	if delay > 0.0:
		tw.tween_interval(delay)
	tw.set_trans(Tween.TRANS_ELASTIC)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2(TRAY_SCALE, TRAY_SCALE), 0.55)

# ── Helpers ────────────────────────────────────────────────────────────────────

func get_bounding_size() -> Vector2:
	var max_x: int = 0
	var max_y: int = 0
	for cell in shape:
		max_x = max(max_x, int(cell.x))
		max_y = max(max_y, int(cell.y))
	return Vector2((max_x + 1) * Global.CELL_SIZE, (max_y + 1) * Global.CELL_SIZE)

# ── Per-frame smooth drag ─────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if dragging:
		global_position = global_position.lerp(_drag_target, min(1.0, delta * 26.0))

# ── Input ──────────────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos := get_global_mouse_position()
		if event.pressed:
			var current_bounds: Rect2 = Rect2(global_position, get_bounding_size() * scale.x)
			if current_bounds.has_point(mouse_pos) and not dragging:
				dragging     = true
				z_index      = 30
				picked_up.emit()

				# Center piece around touch point with upward offset so finger doesn't block it
				var full_size := get_bounding_size()
				drag_offset   = Vector2(-full_size.x * 0.5, -full_size.y * 0.5)
				_drag_target  = mouse_pos + drag_offset + Vector2(0, DRAG_FINGER_OFFSET_Y)
				global_position = _drag_target

				# ── Smoothly scale up to 1:1 gameplay size ──
				var tw := create_tween()
				tw.set_trans(Tween.TRANS_BACK)
				tw.set_ease(Tween.EASE_OUT)
				tw.tween_property(self, "scale", Vector2.ONE, 0.14)

		else:
			if dragging:
				dragging = false
				z_index  = 0
				# Use _drag_target for accurate grid snapping
				dropped.emit(self, _drag_target)

	elif event is InputEventMouseMotion and dragging:
		_drag_target = get_global_mouse_position() + drag_offset + Vector2(0, DRAG_FINGER_OFFSET_Y)
