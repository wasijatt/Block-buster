extends Node2D

signal dropped(piece, drop_position)

var shape: Array = []
var color: Color = Color.WHITE
var home_position: Vector2 = Vector2.ZERO
var slot_index: int = -1
var dragging := false
var drag_offset := Vector2.ZERO

# Smooth drag: we track where we WANT to be, then lerp toward it in _process.
var _drag_target: Vector2 = Vector2.ZERO

# ── Public API ─────────────────────────────────────────────────────────────────

# setup() is called by Main.gd after instantiation.
# spawn_delay: seconds to wait before the bounce-in animation starts.
# Stagger values (0.0, 0.10, 0.20) give the tray a cascade effect.
func setup(p_shape: Array, p_color: Color, spawn_delay: float = 0.0) -> void:
	shape = p_shape
	color = p_color
	_build_visuals()
	_animate_spawn(spawn_delay)

# Called by Main.gd when a drop is invalid — smooth spring back + shake.
func return_home() -> void:
	scale = Vector2.ONE                    # ensure scale is clean
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_BACK)
	tw.set_ease(Tween.EASE_OUT)
	# 1. Slide back to home position (local coords)
	tw.tween_property(self, "position", home_position, 0.22)
	# 2. Quick shake to signal "can't go there" — adjust angles/durations to taste
	tw.tween_property(self, "rotation_degrees", -5.0,  0.055)
	tw.tween_property(self, "rotation_degrees",  4.5,  0.055)
	tw.tween_property(self, "rotation_degrees", -2.5,  0.045)
	tw.tween_property(self, "rotation_degrees",  1.0,  0.040)
	tw.tween_property(self, "rotation_degrees",  0.0,  0.040)

# ── Visuals ────────────────────────────────────────────────────────────────────

func _build_visuals() -> void:
	for cell in shape:
		var bx: float = cell.x * Global.CELL_SIZE
		var by: float = cell.y * Global.CELL_SIZE
		var w: float = Global.CELL_SIZE - 6
		var h: float = Global.CELL_SIZE - 6

		# ── Main 3D Gem Block Face (Smooth Rounded Vector StyleBox) ────────────
		var panel := Panel.new()
		panel.size = Vector2(w, h)
		panel.position = Vector2(bx + 3, by + 3)
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var sb := StyleBoxFlat.new()
		sb.bg_color = color
		sb.set_corner_radius_all(14)
		sb.border_width_bottom = 5
		sb.border_width_right = 5
		sb.border_color = Color(color.r * 0.52, color.g * 0.52, color.b * 0.52, 1.0)
		sb.shadow_color = Color(0.0, 0.0, 0.0, 0.40)
		sb.shadow_size = 6
		sb.shadow_offset = Vector2(0, 4)
		sb.anti_aliasing = true
		panel.add_theme_stylebox_override("panel", sb)
		add_child(panel)

		# ── Top-Left Glossy Highlight Edge ─────────────────────────────────────
		var highlight := Panel.new()
		highlight.size = Vector2(w - 12, h * 0.42)
		highlight.position = Vector2(bx + 9, by + 7)
		highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var hsb := StyleBoxFlat.new()
		hsb.bg_color = Color(1.0, 1.0, 1.0, 0.32)
		hsb.set_corner_radius_all(8)
		hsb.anti_aliasing = true
		highlight.add_theme_stylebox_override("panel", hsb)
		add_child(highlight)

		# ── Corner Glint (Crystal Specular Highlight) ──────────────────────────
		var glint := Panel.new()
		glint.size = Vector2(8, 8)
		glint.position = Vector2(bx + 11, by + 9)
		glint.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var gsb := StyleBoxFlat.new()
		gsb.bg_color = Color(1.0, 1.0, 1.0, 0.75)
		gsb.set_corner_radius_all(4)
		gsb.anti_aliasing = true
		glint.add_theme_stylebox_override("panel", gsb)
		add_child(glint)

# ── Animations ─────────────────────────────────────────────────────────────────

# Pieces bounce into existence from scale 0.
# TRANS_ELASTIC gives the springy overshoot; duration 0.55 s feels snappy but not rushed.
func _animate_spawn(delay: float) -> void:
	scale = Vector2.ZERO
	var tw := create_tween()
	if delay > 0.0:
		tw.tween_interval(delay)
	tw.set_trans(Tween.TRANS_ELASTIC)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2.ONE, 0.55)

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
		# Exponential lerp: frame-rate independent, ~22 units/s responsiveness.
		# Lower the 22.0 multiplier for a "floatier" feel; raise it to be more direct.
		global_position = global_position.lerp(_drag_target, min(1.0, delta * 22.0))

# ── Input ──────────────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos := get_global_mouse_position()
		if event.pressed:
			var bounds: Rect2 = Rect2(global_position, get_bounding_size())
			if bounds.has_point(mouse_pos) and not dragging:
				dragging       = true
				drag_offset    = global_position - mouse_pos
				_drag_target   = global_position
				z_index        = 10

				# ── Lift animation: scale up slightly, giving a "picked up" feel ──
				# Change Vector2(1.12, 1.12) to adjust lift scale.
				# Change 0.15 to adjust how quickly the lift happens.
				var tw := create_tween()
				tw.set_trans(Tween.TRANS_BACK)
				tw.set_ease(Tween.EASE_OUT)
				tw.tween_property(self, "scale", Vector2(1.12, 1.12), 0.15)

		else:
			if dragging:
				dragging = false
				z_index  = 0

				# ── Drop animation: snap back to normal size ──────────────────
				var tw := create_tween()
				tw.set_trans(Tween.TRANS_BACK)
				tw.set_ease(Tween.EASE_OUT)
				tw.tween_property(self, "scale", Vector2.ONE, 0.12)

				# Use _drag_target (accurate mouse position) for grid snapping,
				# not global_position (smoothed/trailing).
				dropped.emit(self, _drag_target)

	elif event is InputEventMouseMotion and dragging:
		_drag_target = get_global_mouse_position() + drag_offset
