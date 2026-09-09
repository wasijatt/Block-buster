extends Node2D

signal lines_cleared(count)

# ── Grid state ─────────────────────────────────────────────────────────────────
var cell_state:   Array = []   # null = empty, Color = occupied
var cell_visuals: Array = []   # background ColorRect (always present)
var cell_blocks:  Array = []   # 3D block Node2D per occupied cell, null if empty
var frame_panel:  Panel = null
var active_theme: Dictionary = {}
var preview_layer: Node2D = null
var cells_being_cleared: Dictionary = {}

# ── Visual constants ───────────────────────────────────────────────────────────
const EMPTY_COLOR  := Color(0.12, 0.11, 0.19, 1.0)  # unlit cell face
const BORDER_COLOR := Color(0.20, 0.18, 0.30, 1.0)  # cell border
const SHINE_COLOR  := Color(0.28, 0.26, 0.40, 0.30)  # top-left depth hint

# 3D extrusion depth in pixels. Raise for chunkier blocks (max ~10 before clipping).
const BLOCK_DEPTH  := 7

func _ready() -> void:
	# ── Main Board Outer Frame Backdrop ───────────────────────────────────────
	var board_total_size: float = Global.GRID_SIZE * Global.CELL_SIZE
	frame_panel = Panel.new()
	frame_panel.size = Vector2(board_total_size + 16, board_total_size + 16)
	frame_panel.position = Vector2(-8, -8)
	frame_panel.z_index = -1
	frame_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var fsb := StyleBoxFlat.new()
	fsb.bg_color = Color(0.06, 0.05, 0.11, 0.96) # Deep dark backdrop for maximum contrast
	fsb.set_corner_radius_all(24)
	fsb.border_width_left = 3
	fsb.border_width_top = 3
	fsb.border_width_right = 3
	fsb.border_width_bottom = 3
	fsb.border_color = Color(0.38, 0.34, 0.58, 0.90) # Crisp glowing border
	fsb.shadow_color = Color(0.0, 0.0, 0.0, 0.70)
	fsb.shadow_size = 20
	fsb.shadow_offset = Vector2(0, 8)
	fsb.anti_aliasing = true
	frame_panel.add_theme_stylebox_override("panel", fsb)
	add_child(frame_panel)

	preview_layer = Node2D.new()
	preview_layer.z_index = 5
	add_child(preview_layer)

	cell_state.resize(Global.GRID_SIZE)
	cell_visuals.resize(Global.GRID_SIZE)
	cell_blocks.resize(Global.GRID_SIZE)
	for x in Global.GRID_SIZE:
		cell_state[x]   = []
		cell_visuals[x] = []
		cell_blocks[x]  = []
		cell_state[x].resize(Global.GRID_SIZE)
		cell_visuals[x].resize(Global.GRID_SIZE)
		cell_blocks[x].resize(Global.GRID_SIZE)
		for y in Global.GRID_SIZE:
			cell_state[x][y] = null
			cell_blocks[x][y] = null
			var bx: float = x * Global.CELL_SIZE
			var by: float = y * Global.CELL_SIZE

			var panel := Panel.new()
			panel.size = Vector2(Global.CELL_SIZE - 6, Global.CELL_SIZE - 6)
			panel.position = Vector2(bx + 3, by + 3)
			panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

			# ── High-Contrast Empty Cell Design ──────────────────────────────
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color(0.14, 0.12, 0.22, 0.95) # Crisp indigo-slate
			sb.set_corner_radius_all(14)
			sb.border_width_bottom = 2
			sb.border_width_right = 2
			sb.border_width_top = 2
			sb.border_width_left = 2
			sb.border_color = Color(0.32, 0.28, 0.48, 0.85) # High visibility cell boundaries
			sb.anti_aliasing = true
			panel.add_theme_stylebox_override("panel", sb)
			add_child(panel)
			cell_visuals[x][y] = panel


# ── Grid reset ─────────────────────────────────────────────────────────────────
func clear_grid() -> void:
	cells_being_cleared.clear()
	for x in Global.GRID_SIZE:
		for y in Global.GRID_SIZE:
			cell_state[x][y] = null
			if cell_blocks[x][y] != null:
				cell_blocks[x][y].queue_free()
				cell_blocks[x][y] = null

# ── Query helpers ──────────────────────────────────────────────────────────────
func is_inside_grid(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < Global.GRID_SIZE \
		and cell.y >= 0 and cell.y < Global.GRID_SIZE

func is_valid_placement(shape: Array, origin: Vector2i) -> bool:
	for offset in shape:
		var cell: Vector2i = origin + offset
		if not is_inside_grid(cell): return false
		if cells_being_cleared.has(cell): return false
		if cell_state[cell.x][cell.y] != null: return false
	return true

func can_place_anywhere(shape: Array) -> bool:
	for x in Global.GRID_SIZE:
		for y in Global.GRID_SIZE:
			if is_valid_placement(shape, Vector2i(x, y)):
				return true
	return false

# ── Placement ─────────────────────────────────────────────────────────────────
func place_shape(shape: Array, origin: Vector2i, color: Color, level: int = 1) -> void:
	for offset in shape:
		var cell: Vector2i = origin + offset
		cell_state[cell.x][cell.y] = color
		# Remove any existing block (shouldn't happen, but safety net)
		if cell_blocks[cell.x][cell.y] != null:
			cell_blocks[cell.x][cell.y].queue_free()
		# Build 3D block node at cell center and pop it in
		var block := _create_3d_block(cell.x, cell.y, color, level)
		add_child(block)
		cell_blocks[cell.x][cell.y] = block
		_tween_pop_in(block)

# ── Drag Placement Preview ───────────────────────────────────────────────────
func show_drag_preview(shape: Array, origin: Vector2i, color: Color) -> void:
	clear_drag_preview()
	var valid: bool = is_valid_placement(shape, origin)
	for offset in shape:
		var cell: Vector2i = origin + offset
		if is_inside_grid(cell):
			var p := Panel.new()
			p.size = Vector2(Global.CELL_SIZE - 6, Global.CELL_SIZE - 6)
			p.position = Vector2(cell.x * Global.CELL_SIZE + 3, cell.y * Global.CELL_SIZE + 3)
			p.mouse_filter = Control.MOUSE_FILTER_IGNORE

			var sb := StyleBoxFlat.new()
			if valid:
				sb.bg_color = Color(color.r, color.g, color.b, 0.45)
				sb.border_color = Color(1.0, 1.0, 1.0, 0.85)
			else:
				sb.bg_color = Color(0.95, 0.20, 0.25, 0.40)
				sb.border_color = Color(1.0, 0.35, 0.35, 0.90)
			sb.set_border_width_all(3)
			sb.set_corner_radius_all(14)
			sb.anti_aliasing = true
			p.add_theme_stylebox_override("panel", sb)
			preview_layer.add_child(p)

func clear_drag_preview() -> void:
	if preview_layer:
		for child in preview_layer.get_children():
			child.queue_free()

# ── Dynamic Theme Application ─────────────────────────────────────────────────
func apply_theme(p_theme: Dictionary) -> void:
	active_theme = p_theme
	var tex_type: String = p_theme.get("texture_type", "classic")
	var grid_bg: Color = p_theme.get("grid_bg", Color(0.06, 0.05, 0.11, 0.96))
	var grid_border: Color = p_theme.get("grid_border", Color(0.38, 0.34, 0.58, 0.90))
	var accent: Color = p_theme.get("accent", Color(1.0, 0.85, 0.3))
	var radius: int = p_theme.get("corner_radius", 14)

	if frame_panel:
		var fsb := StyleBoxFlat.new()
		fsb.bg_color = grid_bg
		fsb.set_corner_radius_all(24)
		fsb.set_border_width_all(4)
		fsb.border_color = grid_border
		fsb.shadow_color = accent.lerp(Color.BLACK, 0.65)
		fsb.shadow_size = 22
		fsb.shadow_offset = Vector2(0, 8)
		fsb.anti_aliasing = true
		frame_panel.add_theme_stylebox_override("panel", fsb)

	# Update empty cell backgrounds with material-specific recessed styling
	for x in Global.GRID_SIZE:
		for y in Global.GRID_SIZE:
			var panel: Panel = cell_visuals[x][y]
			if panel:
				var sb := StyleBoxFlat.new()
				sb.bg_color = grid_bg.lightened(0.08)
				sb.set_corner_radius_all(radius)
				sb.border_width_bottom = 2
				sb.border_width_right = 2
				sb.border_width_top = 2
				sb.border_width_left = 2
				sb.border_color = grid_border.lerp(Color.BLACK, 0.25)
				sb.shadow_color = Color(0, 0, 0, 0.35)
				sb.shadow_size = 3
				sb.anti_aliasing = true
				panel.add_theme_stylebox_override("panel", sb)

# ── Level Starting Pattern Spawner ───────────────────────────────────────────
func spawn_initial_pattern(pattern: Array[Vector2i], colors: Array[Color], level: int) -> void:
	if pattern.is_empty():
		return

	if colors.is_empty():
		colors = Global.COLORS

	var grid_centre := Vector2(Global.GRID_SIZE * 0.5, Global.GRID_SIZE * 0.5)
	var sorted_pattern: Array[Vector2i] = pattern.duplicate()
	sorted_pattern.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return Vector2(a).distance_to(grid_centre) < Vector2(b).distance_to(grid_centre)
	)

	for i in sorted_pattern.size():
		var cell: Vector2i = sorted_pattern[i]
		if not is_inside_grid(cell):
			continue
		var col: Color = colors[(cell.x + cell.y * 3 + level) % colors.size()]
		cell_state[cell.x][cell.y] = col

		if cell_blocks[cell.x][cell.y] != null:
			cell_blocks[cell.x][cell.y].queue_free()

		var block := _create_3d_block(cell.x, cell.y, col, level)
		add_child(block)
		cell_blocks[cell.x][cell.y] = block

		# Staggered pop-in animation from centre outwards
		var delay: float = i * 0.035
		block.scale = Vector2.ZERO
		var tw := create_tween()
		if delay > 0.0:
			tw.tween_interval(delay)
		tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(block, "scale", Vector2.ONE, 0.26)

# ── 3D Block builder ───────────────────────────────────────────────────────────
func _create_3d_block(x: int, y: int, col: Color, level: int = 1) -> Node2D:
	var block := Node2D.new()
	block.z_index = 2

	var cx: float = x * Global.CELL_SIZE + Global.CELL_SIZE * 0.5
	var cy: float = y * Global.CELL_SIZE + Global.CELL_SIZE * 0.5
	block.position = Vector2(cx, cy)

	var sz: float = Global.CELL_SIZE - 6
	var hf: float = sz * 0.5

	var tex_type: String = active_theme.get("texture_type", "classic")
	if tex_type == "" or tex_type == "classic":
		if level > 5:
			tex_type = "royal_gold"
		else:
			tex_type = active_theme.get("id", "wood")

	# ── Main 3D Block Face ─────────────────────────────────────────────────────
	var panel := Panel.new()
	panel.size = Vector2(sz, sz)
	panel.position = Vector2(-hf, -hf)
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
			sb.border_color = Color(1.0, 0.82, 0.35, 0.90)
			sb.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
			sb.shadow_size = 8
			sb.shadow_offset = Vector2(0, 4)

		"magma":
			sb.bg_color = Color(0.14, 0.08, 0.08)
			sb.set_corner_radius_all(10)
			sb.border_width_bottom = 5
			sb.border_width_right = 5
			sb.border_width_top = 2
			sb.border_width_left = 2
			sb.border_color = Color(1.00, 0.45, 0.10, 1.0)
			sb.shadow_color = Color(1.00, 0.25, 0.00, 0.65)
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
			sb.bg_color = col
			sb.set_corner_radius_all(16)
			sb.border_width_bottom = 5
			sb.border_width_right = 5
			sb.border_color = Color(col.r * 0.52, col.g * 0.52, col.b * 0.52, 1.0)
			sb.shadow_color = Color(0.0, 0.0, 0.0, 0.40)
			sb.shadow_size = 6
			sb.shadow_offset = Vector2(0, 4)

	panel.add_theme_stylebox_override("panel", sb)
	block.add_child(panel)

	# ── Material-Specific Textural Overlays ────────────────────────────────────
	match tex_type:
		"wood":
			for gy in [0.28, 0.52, 0.74]:
				var grain := ColorRect.new()
				grain.position = Vector2(-hf + 4, -hf + sz * gy)
				grain.size = Vector2(sz - 8, 2.0)
				grain.color = Color(0.20, 0.10, 0.04, 0.28)
				grain.mouse_filter = Control.MOUSE_FILTER_IGNORE
				block.add_child(grain)

			var sheen := ColorRect.new()
			sheen.position = Vector2(-hf + 6, -hf + 5)
			sheen.size = Vector2(sz - 12, sz * 0.32)
			sheen.color = Color(1.0, 0.88, 0.60, 0.22)
			sheen.mouse_filter = Control.MOUSE_FILTER_IGNORE
			block.add_child(sheen)

		"ice":
			var frac1 := Line2D.new()
			frac1.width = 1.8
			frac1.default_color = Color(1.0, 1.0, 1.0, 0.65)
			frac1.points = PackedVector2Array([
				Vector2(-hf + 8, -hf + 12),
				Vector2(-hf + sz * 0.45, -hf + sz * 0.40),
				Vector2(-hf + sz * 0.75, -hf + sz * 0.78)
			])
			block.add_child(frac1)

			_add_block_specular_glint(block, -hf + 8, -hf + 8, 9, Color(1, 1, 1, 0.95))

		"marble":
			var vein := Line2D.new()
			vein.width = 1.6
			vein.default_color = Color(col.r * 0.75, col.g * 0.75, col.b * 0.75, 0.50)
			vein.points = PackedVector2Array([
				Vector2(-hf + 6, -hf + sz * 0.70),
				Vector2(-hf + sz * 0.40, -hf + sz * 0.45),
				Vector2(-hf + sz * 0.70, -hf + 8)
			])
			block.add_child(vein)

		"bronze":
			for rpos in [
				Vector2(-hf + 7, -hf + 7),
				Vector2(-hf + sz - 11, -hf + 7),
				Vector2(-hf + 7, -hf + sz - 11),
				Vector2(-hf + sz - 11, -hf + sz - 11)
			]:
				var rivet := Panel.new()
				rivet.position = rpos
				rivet.size = Vector2(4, 4)
				rivet.mouse_filter = Control.MOUSE_FILTER_IGNORE
				var rsb := StyleBoxFlat.new()
				rsb.bg_color = Color(0.95, 0.75, 0.35)
				rsb.set_corner_radius_all(2)
				rivet.add_theme_stylebox_override("panel", rsb)
				block.add_child(rivet)

			var rbar := ColorRect.new()
			rbar.position = Vector2(-hf + 8, -hf + 8)
			rbar.size = Vector2(sz - 16, sz * 0.30)
			rbar.color = Color(1.0, 0.85, 0.55, 0.25)
			rbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
			block.add_child(rbar)

		"cloth":
			var tuft := Panel.new()
			tuft.position = Vector2(-hf + 8, -hf + 8)
			tuft.size = Vector2(sz - 16, sz - 16)
			tuft.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var tsb := StyleBoxFlat.new()
			tsb.bg_color = Color(col.r * 0.82, col.g * 0.82, col.b * 0.82, 0.75)
			tsb.set_corner_radius_all(10)
			tuft.add_theme_stylebox_override("panel", tsb)
			block.add_child(tuft)

		"magma":
			var fissure := Line2D.new()
			fissure.width = 2.4
			fissure.default_color = Color(1.00, 0.85, 0.15, 0.95)
			fissure.points = PackedVector2Array([
				Vector2(-hf + 8, -hf + sz * 0.35),
				Vector2(-hf + sz * 0.40, -hf + sz * 0.50),
				Vector2(-hf + sz * 0.60, -hf + sz * 0.30),
				Vector2(-hf + sz - 8, -hf + sz * 0.65)
			])
			block.add_child(fissure)

		"chrome":
			var mir := ColorRect.new()
			mir.position = Vector2(-hf + 6, -hf + sz * 0.38)
			mir.size = Vector2(sz - 12, 3.0)
			mir.color = Color(1.0, 1.0, 1.0, 0.85)
			mir.mouse_filter = Control.MOUSE_FILTER_IGNORE
			block.add_child(mir)

		"royal_gold":
			var ginner := Panel.new()
			ginner.position = Vector2(-hf + 7, -hf + 7)
			ginner.size = Vector2(sz - 14, sz - 14)
			ginner.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var gsb := StyleBoxFlat.new()
			gsb.bg_color = Color.TRANSPARENT
			gsb.set_border_width_all(2)
			gsb.border_color = Color(1.0, 0.95, 0.60, 0.70)
			gsb.set_corner_radius_all(12)
			ginner.add_theme_stylebox_override("panel", gsb)
			block.add_child(ginner)
			_add_block_specular_glint(block, -hf + 10, -hf + 10, 8, Color(1.0, 1.0, 0.85, 0.95))

		"diamond":
			var fline1 := Line2D.new()
			fline1.width = 1.4
			fline1.default_color = Color(1.0, 1.0, 1.0, 0.60)
			fline1.points = PackedVector2Array([
				Vector2(-hf + 6, -hf + 6),
				Vector2(0, 0),
				Vector2(hf - 6, hf - 6)
			])
			block.add_child(fline1)

			var fline2 := Line2D.new()
			fline2.width = 1.4
			fline2.default_color = Color(1.0, 1.0, 1.0, 0.60)
			fline2.points = PackedVector2Array([
				Vector2(hf - 6, -hf + 6),
				Vector2(0, 0),
				Vector2(-hf + 6, hf - 6)
			])
			block.add_child(fline2)
			_add_block_specular_glint(block, -4, -4, 8, Color.WHITE)

		"neon":
			var ncore := Panel.new()
			ncore.position = Vector2(-hf + 10, -hf + 10)
			ncore.size = Vector2(sz - 20, sz - 20)
			ncore.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var ncsb := StyleBoxFlat.new()
			ncsb.bg_color = col.lerp(Color.WHITE, 0.4)
			ncsb.set_corner_radius_all(4)
			ncsb.shadow_color = col
			ncsb.shadow_size = 10
			ncore.add_theme_stylebox_override("panel", ncsb)
			block.add_child(ncore)

		"cosmic":
			for s in [
				Vector2(-hf + 14, -hf + 14),
				Vector2(-hf + sz - 18, -hf + 18),
				Vector2(0, -hf + sz * 0.65),
				Vector2(-hf + 18, -hf + sz - 18)
			]:
				var star := ColorRect.new()
				star.position = s
				star.size = Vector2(3, 3)
				star.color = Color.WHITE
				star.mouse_filter = Control.MOUSE_FILTER_IGNORE
				block.add_child(star)
			_add_block_specular_glint(block, -3, -hf + 10, 6, Color(0.85, 0.70, 1.0, 0.95))

		"mythic":
			var arch := Line2D.new()
			arch.width = 2.0
			arch.default_color = Color(1.0, 0.85, 0.35, 0.75)
			arch.points = PackedVector2Array([
				Vector2(-hf + 8, -hf + sz * 0.65),
				Vector2(0, -hf + sz * 0.35),
				Vector2(-hf + sz - 8, -hf + sz * 0.65)
			])
			block.add_child(arch)
			_add_block_specular_glint(block, -hf + 10, -hf + 10, 8, Color.WHITE)

		_:
			var highlight := Panel.new()
			highlight.size = Vector2(sz - 12, sz * 0.42)
			highlight.position = Vector2(-hf + 6, -hf + 4)
			highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var hsb := StyleBoxFlat.new()
			hsb.bg_color = Color(1.0, 1.0, 1.0, 0.36)
			hsb.set_corner_radius_all(max(2, sb.corner_radius_top_left - 6))
			hsb.anti_aliasing = true
			highlight.add_theme_stylebox_override("panel", hsb)
			block.add_child(highlight)
			_add_block_specular_glint(block, -hf + 8, -hf + 6, 8, Color(1.0, 1.0, 1.0, 0.85))

	return block

func _add_block_specular_glint(parent: Node2D, gx: float, gy: float, gsz: float, gcol: Color) -> void:
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

# Helper: add a ColorRect child to a Node2D parent.
func _brect(parent: Node2D, pos: Vector2, size: Vector2, col: Color) -> void:
	var r := ColorRect.new()
	r.position = pos
	r.size     = size
	r.color    = col
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)

# ── Pop-in animation ──────────────────────────────────────────────────────────
# Placed blocks spring in from scale 1.28 → 1.0. Adjust 1.28 or 0.22 to taste.
func _tween_pop_in(block: Node2D) -> void:
	block.scale = Vector2(1.28, 1.28)
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_BACK)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(block, "scale", Vector2.ONE, 0.22)

# ── Line clearing ──────────────────────────────────────────────────────────────
func check_and_clear_lines() -> int:
	var full_rows: Array[int] = []
	var full_cols: Array[int] = []

	for y in Global.GRID_SIZE:
		var full := true
		for x in Global.GRID_SIZE:
			if cell_state[x][y] == null: full = false; break
		if full: full_rows.append(y)

	for x in Global.GRID_SIZE:
		var full := true
		for y in Global.GRID_SIZE:
			if cell_state[x][y] == null: full = false; break
		if full: full_cols.append(x)

	var cleared: int = full_rows.size() + full_cols.size()
	if cleared == 0:
		return 0

	# Build a deduplicated set of cells to animate (avoid double-animating corners).
	var cells_to_clear: Dictionary = {}
	for y in full_rows:
		for x in Global.GRID_SIZE:
			cells_to_clear[Vector2i(x, y)] = \
				cell_state[x][y] if cell_state[x][y] else Color.WHITE
	for x in full_cols:
		for y in Global.GRID_SIZE:
			var key := Vector2i(x, y)
			if not cells_to_clear.has(key):
				cells_to_clear[key] = cell_state[x][y] if cell_state[x][y] else Color.WHITE

	# Sort from grid-centre outward for an explosion/ripple feel.
	var grid_centre := Vector2(Global.GRID_SIZE * 0.5, Global.GRID_SIZE * 0.5)
	var sorted_keys: Array = cells_to_clear.keys()
	sorted_keys.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return Vector2(a).distance_to(grid_centre) < Vector2(b).distance_to(grid_centre))

	# Stagger each cell's animation and free logical cell state immediately
	for i in sorted_keys.size():
		var key: Vector2i = sorted_keys[i]
		cells_being_cleared[key] = true
		cell_state[key.x][key.y] = null  # Free grid logical state immediately for placement checks
		var delay: float   = i * 0.028
		var col: Color     = cells_to_clear[key]
		var block: Node2D  = cell_blocks[key.x][key.y]
		if block != null:
			_animate_clear_block(block, col, delay)
		# Burst particles at every 3rd cell (performance vs. visual density balance).
		if i % 3 == 0:
			var world_pos: Vector2 = Vector2(
				key.x * Global.CELL_SIZE + Global.CELL_SIZE * 0.5,
				key.y * Global.CELL_SIZE + Global.CELL_SIZE * 0.5)
			_burst_delayed(world_pos, col, delay)

	# Fire the actual state-reset after the last animation finishes.
	var anim_end: float = (sorted_keys.size() - 1) * 0.028 + 0.35
	var clear_tw := create_tween()
	clear_tw.tween_interval(anim_end)
	clear_tw.tween_callback(_do_clear.bind(full_rows, full_cols))

	lines_cleared.emit(cleared)
	return cleared

# Animate one 3D block node out: flash white → scale/fade to zero.
# delay: seconds before this particular cell starts animating.
func _animate_clear_block(block: Node2D, _col: Color, delay: float) -> void:
	var tw := create_tween()
	if delay > 0.0:
		tw.tween_interval(delay)
	# Flash white
	tw.tween_property(block, "modulate", Color(2.0, 2.0, 2.0, 1.0), 0.07)
	# Shrink + fade out simultaneously
	tw.tween_property(block, "scale",    Vector2.ZERO,              0.20)
	tw.parallel().tween_property(block, "modulate", Color(1, 1, 1, 0.0), 0.20)

# Spawn a CPUParticles2D burst after `delay` seconds.
func _burst_delayed(pos: Vector2, col: Color, delay: float) -> void:
	var tw := create_tween()
	tw.tween_interval(delay)
	tw.tween_callback(func(): _burst_particles(pos, col))

# One-shot particle burst at a grid-local position.
# Tweak amount, velocity_max, and lifetime here for different densities.
func _burst_particles(pos: Vector2, burst_color: Color) -> void:
	var p := CPUParticles2D.new()
	p.position              = pos
	p.z_index               = 5
	p.one_shot              = true
	p.explosiveness         = 1.0
	p.amount                = 14
	p.lifetime              = 0.55
	p.direction             = Vector2(0, -1)
	p.spread                = 180.0
	p.initial_velocity_min  = 60.0
	p.initial_velocity_max  = 160.0
	p.gravity               = Vector2(0, 240)
	p.scale_amount_min      = 4.0
	p.scale_amount_max      = 8.0
	p.color                 = burst_color
	add_child(p)
	p.emitting = true
	get_tree().create_timer(0.85).timeout.connect(p.queue_free)

# Executed after the clear animation completes — resets state.
func _do_clear(full_rows: Array, full_cols: Array) -> void:
	for y in full_rows:
		for x in Global.GRID_SIZE:
			cells_being_cleared.erase(Vector2i(x, y))
			cell_state[x][y] = null
			if cell_blocks[x][y] != null:
				cell_blocks[x][y].queue_free()
				cell_blocks[x][y] = null
	for x in full_cols:
		for y in Global.GRID_SIZE:
			cells_being_cleared.erase(Vector2i(x, y))
			cell_state[x][y] = null
			if cell_blocks[x][y] != null:
				cell_blocks[x][y].queue_free()
				cell_blocks[x][y] = null
