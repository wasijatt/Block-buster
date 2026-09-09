extends Node2D

signal dropped(piece, drop_position)
signal picked_up()
signal returned_home()
signal drag_moved(piece, target_pos)

var shape: Array = []
var color: Color = Color.WHITE
var home_position: Vector2 = Vector2.ZERO
var slot_index: int = -1
var dragging := false
var drag_offset := Vector2.ZERO
var current_level: int = 1
var active_theme: Dictionary = {}

var TRAY_SCALE: float = 0.55
const DRAG_FINGER_OFFSET_Y: float = -164.0 # Exactly 2.0 * Global.CELL_SIZE for 100% accurate vertical alignment

# Smooth drag: we track where we WANT to be, then lerp toward it in _process.
var _drag_target: Vector2 = Vector2.ZERO

# ── Public API ─────────────────────────────────────────────────────────────────

func setup(p_shape: Array, p_color: Color, spawn_delay: float = 0.0, level: int = 1, p_theme: Dictionary = {}, custom_tray_scale: float = 0.55) -> void:
	shape = p_shape
	color = p_color
	current_level = level
	active_theme = p_theme
	TRAY_SCALE = custom_tray_scale
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
	for child in get_children():
		child.queue_free()

	var tex_type: String = active_theme.get("texture_type", "classic")
	if tex_type == "" or tex_type == "classic":
		if current_level > 5:
			tex_type = "royal_gold"
		else:
			tex_type = active_theme.get("id", "wood")

	for cell in shape:
		var bx: float = cell.x * Global.CELL_SIZE
		var by: float = cell.y * Global.CELL_SIZE
		var w: float = Global.CELL_SIZE - 6
		var h: float = Global.CELL_SIZE - 6

		_create_material_block_face(self, bx + 3, by + 3, w, h, tex_type, color)

func _create_material_block_face(parent: Node2D, px: float, py: float, w: float, h: float, tex_type: String, col: Color) -> void:
	var panel := Panel.new()
	panel.size = Vector2(w, h)
	panel.position = Vector2(px, py)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var sb := StyleBoxFlat.new()
	sb.anti_aliasing = true

	match tex_type:
		"wood":
			sb.bg_color = col
			sb.set_corner_radius_all(10)
			sb.border_width_bottom = 5
			sb.border_width_right = 5
			sb.border_width_top = 2
			sb.border_width_left = 2
			sb.border_color = Color(col.r * 0.45, col.g * 0.28, col.b * 0.15, 1.0)
			sb.shadow_color = Color(0.20, 0.10, 0.04, 0.55)
			sb.shadow_size = 7
			sb.shadow_offset = Vector2(0, 4)

		"ice":
			sb.bg_color = col.lerp(Color(0.85, 0.95, 1.0), 0.25)
			sb.set_corner_radius_all(8)
			sb.border_width_bottom = 5
			sb.border_width_right = 5
			sb.border_width_top = 2
			sb.border_width_left = 2
			sb.border_color = Color.WHITE
			sb.shadow_color = Color(0.20, 0.75, 1.00, 0.55)
			sb.shadow_size = 12
			sb.shadow_offset = Vector2(0, 2)

		"marble":
			sb.bg_color = col
			sb.set_corner_radius_all(6)
			sb.border_width_bottom = 5
			sb.border_width_right = 5
			sb.border_width_top = 2
			sb.border_width_left = 2
			sb.border_color = col.lerp(Color.WHITE, 0.55)
			sb.shadow_color = Color(0.12, 0.12, 0.14, 0.45)
			sb.shadow_size = 8
			sb.shadow_offset = Vector2(0, 3)

		"bronze":
			sb.bg_color = col
			sb.set_corner_radius_all(12)
			sb.border_width_bottom = 6
			sb.border_width_right = 6
			sb.border_width_top = 2
			sb.border_width_left = 2
			sb.border_color = Color(col.r * 0.6, col.g * 0.4, col.b * 0.2, 1.0)
			sb.shadow_color = Color(0.18, 0.08, 0.02, 0.60)
			sb.shadow_size = 9
			sb.shadow_offset = Vector2(0, 4)

		"cloth":
			sb.bg_color = col
			sb.set_corner_radius_all(16)
			sb.set_border_width_all(3)
			sb.border_color = Color(1.0, 0.82, 0.35, 0.90) # Gold brocade stitch
			sb.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
			sb.shadow_size = 8
			sb.shadow_offset = Vector2(0, 4)

		"magma":
			sb.bg_color = Color(0.14, 0.08, 0.08) # Basalt crust
			sb.set_corner_radius_all(10)
			sb.border_width_bottom = 5
			sb.border_width_right = 5
			sb.border_width_top = 2
			sb.border_width_left = 2
			sb.border_color = Color(1.00, 0.45, 0.10, 1.0) # Incandescent lava rim
			sb.shadow_color = Color(1.00, 0.25, 0.00, 0.65) # Fiery glow
			sb.shadow_size = 14
			sb.shadow_offset = Vector2(0, 2)

		"chrome":
			sb.bg_color = col
			sb.set_corner_radius_all(8)
			sb.border_width_bottom = 6
			sb.border_width_right = 6
			sb.border_width_top = 2
			sb.border_width_left = 2
			sb.border_color = Color.WHITE
			sb.shadow_color = Color(0.50, 0.65, 0.85, 0.50)
			sb.shadow_size = 10
			sb.shadow_offset = Vector2(0, 3)

		"royal_gold":
			sb.bg_color = col
			sb.set_corner_radius_all(18)
			sb.border_width_bottom = 6
			sb.border_width_right = 6
			sb.border_width_top = 2
			sb.border_width_left = 2
			sb.border_color = Color(1.00, 0.92, 0.45, 1.0)
			sb.shadow_color = Color(0.85, 0.65, 0.10, 0.60)
			sb.shadow_size = 14
			sb.shadow_offset = Vector2(0, 4)

		"diamond":
			sb.bg_color = col.lerp(Color.WHITE, 0.35)
			sb.set_corner_radius_all(6)
			sb.border_width_bottom = 6
			sb.border_width_right = 6
			sb.border_width_top = 2
			sb.border_width_left = 2
			sb.border_color = Color(1.0, 1.0, 1.0, 0.95)
			sb.shadow_color = Color(0.40, 0.85, 1.00, 0.70)
			sb.shadow_size = 15
			sb.shadow_offset = Vector2.ZERO

		"neon":
			sb.bg_color = Color(0.06, 0.05, 0.10)
			sb.set_corner_radius_all(8)
			sb.set_border_width_all(4)
			sb.border_color = col
			sb.shadow_color = col
			sb.shadow_size = 16
			sb.shadow_offset = Vector2.ZERO

		"cosmic":
			sb.bg_color = Color(0.08, 0.04, 0.14)
			sb.set_corner_radius_all(14)
			sb.set_border_width_all(3)
			sb.border_color = col
			sb.shadow_color = Color(0.65, 0.25, 1.00, 0.65)
			sb.shadow_size = 14
			sb.shadow_offset = Vector2(0, 2)

		"mythic":
			sb.bg_color = col
			sb.set_corner_radius_all(16)
			sb.border_width_bottom = 6
			sb.border_width_right = 6
			sb.border_width_top = 2
			sb.border_width_left = 2
			sb.border_color = Color(1.00, 0.85, 0.35, 1.0)
			sb.shadow_color = Color(0.95, 0.25, 0.65, 0.65)
			sb.shadow_size = 16
			sb.shadow_offset = Vector2(0, 4)

		_:
			# Classic Candy fallback
			sb.bg_color = col
			sb.set_corner_radius_all(16)
			sb.border_width_bottom = 5
			sb.border_width_right = 5
			sb.border_color = Color(col.r * 0.52, col.g * 0.52, col.b * 0.52, 1.0)
			sb.shadow_color = Color(0.0, 0.0, 0.0, 0.40)
			sb.shadow_size = 6
			sb.shadow_offset = Vector2(0, 4)

	panel.add_theme_stylebox_override("panel", sb)
	parent.add_child(panel)

	# ── Material-Specific Textural Overlays ────────────────────────────────────
	match tex_type:
		"wood":
			# Wood grain horizontal strata rings
			for gy in [0.28, 0.52, 0.74]:
				var grain := ColorRect.new()
				grain.position = Vector2(px + 4, py + h * gy)
				grain.size = Vector2(w - 8, 2.0)
				grain.color = Color(0.20, 0.10, 0.04, 0.28)
				grain.mouse_filter = Control.MOUSE_FILTER_IGNORE
				parent.add_child(grain)

			# Warm timber satin sheen
			var sheen := ColorRect.new()
			sheen.position = Vector2(px + 6, py + 5)
			sheen.size = Vector2(w - 12, h * 0.32)
			sheen.color = Color(1.0, 0.88, 0.60, 0.22)
			sheen.mouse_filter = Control.MOUSE_FILTER_IGNORE
			parent.add_child(sheen)

		"ice":
			# Crystalline fracture lines
			var frac1 := Line2D.new()
			frac1.width = 1.8
			frac1.default_color = Color(1.0, 1.0, 1.0, 0.65)
			frac1.points = PackedVector2Array([
				Vector2(px + 8, py + 12),
				Vector2(px + w * 0.45, py + h * 0.40),
				Vector2(px + w * 0.75, py + h * 0.78)
			])
			parent.add_child(frac1)

			var frac2 := Line2D.new()
			frac2.width = 1.2
			frac2.default_color = Color(0.70, 0.92, 1.0, 0.55)
			frac2.points = PackedVector2Array([
				Vector2(px + w * 0.45, py + h * 0.40),
				Vector2(px + w * 0.25, py + h * 0.70)
			])
			parent.add_child(frac2)

			_add_specular_glint(parent, px + 8, py + 8, 9, Color(1, 1, 1, 0.95))

		"marble":
			# Elegant stone veins
			var vein := Line2D.new()
			vein.width = 1.6
			vein.default_color = Color(col.r * 0.75, col.g * 0.75, col.b * 0.75, 0.50)
			vein.points = PackedVector2Array([
				Vector2(px + 6, py + h * 0.70),
				Vector2(px + w * 0.40, py + h * 0.45),
				Vector2(px + w * 0.70, py + 8)
			])
			parent.add_child(vein)

			var vein2 := Line2D.new()
			vein2.width = 1.0
			vein2.default_color = Color(1.0, 0.85, 0.45, 0.40) # Gold marble vein
			vein2.points = PackedVector2Array([
				Vector2(px + w * 0.40, py + h * 0.45),
				Vector2(px + w * 0.82, py + h * 0.55)
			])
			parent.add_child(vein2)

		"bronze":
			# Steampunk corner rivets
			var rivet_positions := [
				Vector2(px + 7, py + 7),
				Vector2(px + w - 11, py + 7),
				Vector2(px + 7, py + h - 11),
				Vector2(px + w - 11, py + h - 11)
			]
			for rpos in rivet_positions:
				var rivet := Panel.new()
				rivet.position = rpos
				rivet.size = Vector2(4, 4)
				rivet.mouse_filter = Control.MOUSE_FILTER_IGNORE
				var rsb := StyleBoxFlat.new()
				rsb.bg_color = Color(0.95, 0.75, 0.35)
				rsb.set_corner_radius_all(2)
				rsb.border_width_bottom = 1
				rsb.border_color = Color(0.2, 0.1, 0.05)
				rivet.add_theme_stylebox_override("panel", rsb)
				parent.add_child(rivet)

			# Burnished metallic reflection bar
			var rbar := ColorRect.new()
			rbar.position = Vector2(px + 8, py + 8)
			rbar.size = Vector2(w - 16, h * 0.30)
			rbar.color = Color(1.0, 0.85, 0.55, 0.25)
			rbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
			parent.add_child(rbar)

		"cloth":
			# Tufted inner cushion
			var tuft := Panel.new()
			tuft.position = Vector2(px + 8, py + 8)
			tuft.size = Vector2(w - 16, h - 16)
			tuft.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var tsb := StyleBoxFlat.new()
			tsb.bg_color = Color(col.r * 0.82, col.g * 0.82, col.b * 0.82, 0.75)
			tsb.set_corner_radius_all(10)
			tsb.border_width_bottom = 2
			tsb.border_width_right = 2
			tsb.border_color = Color(col.r * 0.6, col.g * 0.6, col.b * 0.6, 0.8)
			tuft.add_theme_stylebox_override("panel", tsb)
			parent.add_child(tuft)

		"magma":
			# Glowing magma fissures
			var fissure := Line2D.new()
			fissure.width = 2.4
			fissure.default_color = Color(1.00, 0.85, 0.15, 0.95) # Molten core
			fissure.points = PackedVector2Array([
				Vector2(px + 8, py + h * 0.35),
				Vector2(px + w * 0.40, py + h * 0.50),
				Vector2(px + w * 0.60, py + h * 0.30),
				Vector2(px + w - 8, py + h * 0.65)
			])
			parent.add_child(fissure)

			var branch := Line2D.new()
			branch.width = 1.8
			branch.default_color = Color(1.00, 0.40, 0.05, 0.90)
			branch.points = PackedVector2Array([
				Vector2(px + w * 0.40, py + h * 0.50),
				Vector2(px + w * 0.35, py + h - 8)
			])
			parent.add_child(branch)

		"chrome":
			# Mirror horizon reflection bar
			var mir := ColorRect.new()
			mir.position = Vector2(px + 6, py + h * 0.38)
			mir.size = Vector2(w - 12, 3.0)
			mir.color = Color(1.0, 1.0, 1.0, 0.85)
			mir.mouse_filter = Control.MOUSE_FILTER_IGNORE
			parent.add_child(mir)

			var sky := ColorRect.new()
			sky.position = Vector2(px + 6, py + 6)
			sky.size = Vector2(w - 12, h * 0.30)
			sky.color = Color(1.0, 1.0, 1.0, 0.40)
			sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
			parent.add_child(sky)

		"royal_gold":
			# Filigree inner gold frame
			var ginner := Panel.new()
			ginner.position = Vector2(px + 7, py + 7)
			ginner.size = Vector2(w - 14, h - 14)
			ginner.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var gsb := StyleBoxFlat.new()
			gsb.bg_color = Color.TRANSPARENT
			gsb.set_border_width_all(2)
			gsb.border_color = Color(1.0, 0.95, 0.60, 0.70)
			gsb.set_corner_radius_all(12)
			ginner.add_theme_stylebox_override("panel", gsb)
			parent.add_child(ginner)

			_add_specular_glint(parent, px + 10, py + 10, 8, Color(1.0, 1.0, 0.85, 0.95))

		"diamond":
			# Faceted gem cut diagonals
			var fline1 := Line2D.new()
			fline1.width = 1.4
			fline1.default_color = Color(1.0, 1.0, 1.0, 0.60)
			fline1.points = PackedVector2Array([
				Vector2(px + 6, py + 6),
				Vector2(px + w * 0.5, py + h * 0.5),
				Vector2(px + w - 6, py + h - 6)
			])
			parent.add_child(fline1)

			var fline2 := Line2D.new()
			fline2.width = 1.4
			fline2.default_color = Color(1.0, 1.0, 1.0, 0.60)
			fline2.points = PackedVector2Array([
				Vector2(px + w - 6, py + 6),
				Vector2(px + w * 0.5, py + h * 0.5),
				Vector2(px + 6, py + h - 6)
			])
			parent.add_child(fline2)

			_add_specular_glint(parent, px + w * 0.5 - 4, py + h * 0.5 - 4, 8, Color.WHITE)

		"neon":
			# Inner glowing neon core
			var ncore := Panel.new()
			ncore.position = Vector2(px + 10, py + 10)
			ncore.size = Vector2(w - 20, h - 20)
			ncore.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var ncsb := StyleBoxFlat.new()
			ncsb.bg_color = col.lerp(Color.WHITE, 0.4)
			ncsb.set_corner_radius_all(4)
			ncsb.shadow_color = col
			ncsb.shadow_size = 10
			ncore.add_theme_stylebox_override("panel", ncsb)
			parent.add_child(ncore)

		"cosmic":
			# Twinkling stardust points
			for s in [
				Vector2(px + 14, py + 14),
				Vector2(px + w - 18, py + 18),
				Vector2(px + w * 0.5, py + h * 0.65),
				Vector2(px + 18, py + h - 18)
			]:
				var star := ColorRect.new()
				star.position = s
				star.size = Vector2(3, 3)
				star.color = Color.WHITE
				star.mouse_filter = Control.MOUSE_FILTER_IGNORE
				parent.add_child(star)

			_add_specular_glint(parent, px + w * 0.5 - 3, py + 10, 6, Color(0.85, 0.70, 1.0, 0.95))

		"mythic":
			# Scaled arch
			var arch := Line2D.new()
			arch.width = 2.0
			arch.default_color = Color(1.0, 0.85, 0.35, 0.75)
			arch.points = PackedVector2Array([
				Vector2(px + 8, py + h * 0.65),
				Vector2(px + w * 0.5, py + h * 0.35),
				Vector2(px + w - 8, py + h * 0.65)
			])
			parent.add_child(arch)
			_add_specular_glint(parent, px + 10, py + 10, 8, Color.WHITE)

		_:
			# Standard glossy highlight & glint
			var highlight := Panel.new()
			highlight.size = Vector2(w - 14, h * 0.42)
			highlight.position = Vector2(px + 7, py + 4)
			highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var hsb := StyleBoxFlat.new()
			hsb.bg_color = Color(1.0, 1.0, 1.0, 0.38)
			hsb.set_corner_radius_all(sb.corner_radius_top_left - 4)
			hsb.anti_aliasing = true
			highlight.add_theme_stylebox_override("panel", hsb)
			parent.add_child(highlight)

			_add_specular_glint(parent, px + 9, py + 6, 8, Color(1.0, 1.0, 1.0, 0.85))

func _add_specular_glint(parent: Node2D, gx: float, gy: float, gsz: float, gcol: Color) -> void:
	var glint := Panel.new()
	glint.size = Vector2(gsz, gsz)
	glint.position = Vector2(gx, gy)
	glint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gsb := StyleBoxFlat.new()
	gsb.bg_color = gcol
	gsb.set_corner_radius_all(int(gsz * 0.5))
	gsb.anti_aliasing = true
	glint.add_theme_stylebox_override("panel", gsb)
	parent.add_child(glint)

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
			if scale.x > 0.15: # Ensure piece is spawned before grabbing
				var current_bounds: Rect2 = Rect2(global_position, get_bounding_size() * scale.x).grow(16.0)
				if current_bounds.has_point(mouse_pos) and not dragging:
					dragging     = true
					z_index      = 30
					picked_up.emit()

					# Center piece around touch point with upward offset so finger doesn't block it
					var full_size := get_bounding_size()
					drag_offset   = Vector2(-full_size.x * 0.5, -full_size.y * 0.5)
					_drag_target  = mouse_pos + drag_offset + Vector2(0, DRAG_FINGER_OFFSET_Y)
					global_position = _drag_target
					drag_moved.emit(self, _drag_target)

					# Smoothly scale up to 1:1 gameplay size
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
		drag_moved.emit(self, _drag_target)
