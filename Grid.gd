extends Node2D

signal lines_cleared(count)

# ── Grid state ─────────────────────────────────────────────────────────────────
var cell_state:   Array = []   # null = empty, Color = occupied
var cell_visuals: Array = []   # background ColorRect (always present)
var cell_blocks:  Array = []   # 3D block Node2D per occupied cell, null if empty

# ── Visual constants ───────────────────────────────────────────────────────────
const EMPTY_COLOR  := Color(0.12, 0.11, 0.19, 1.0)  # unlit cell face
const BORDER_COLOR := Color(0.20, 0.18, 0.30, 1.0)  # cell border
const SHINE_COLOR  := Color(0.28, 0.26, 0.40, 0.30)  # top-left depth hint

# 3D extrusion depth in pixels. Raise for chunkier blocks (max ~10 before clipping).
const BLOCK_DEPTH  := 7

func _ready() -> void:
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
			panel.size = Vector2(Global.CELL_SIZE - 4, Global.CELL_SIZE - 4)
			panel.position = Vector2(bx + 2, by + 2)
			panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

			var sb := StyleBoxFlat.new()
			sb.bg_color = Color(0.12, 0.11, 0.18, 0.90)
			sb.set_corner_radius_all(12)
			sb.border_width_bottom = 2
			sb.border_width_right = 2
			sb.border_width_top = 1
			sb.border_width_left = 1
			sb.border_color = Color(0.25, 0.22, 0.35, 0.60)
			sb.anti_aliasing = true
			panel.add_theme_stylebox_override("panel", sb)
			add_child(panel)
			cell_visuals[x][y] = panel

# ── Grid reset ─────────────────────────────────────────────────────────────────
func clear_grid() -> void:
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
		if cell_state[cell.x][cell.y] != null: return false
	return true

func can_place_anywhere(shape: Array) -> bool:
	for x in Global.GRID_SIZE:
		for y in Global.GRID_SIZE:
			if is_valid_placement(shape, Vector2i(x, y)):
				return true
	return false

# ── Placement ─────────────────────────────────────────────────────────────────
func place_shape(shape: Array, origin: Vector2i, color: Color) -> void:
	for offset in shape:
		var cell: Vector2i = origin + offset
		cell_state[cell.x][cell.y] = color
		# Remove any existing block (shouldn't happen, but safety net)
		if cell_blocks[cell.x][cell.y] != null:
			cell_blocks[cell.x][cell.y].queue_free()
		# Build 3D block node at cell center and pop it in
		var block := _create_3d_block(cell.x, cell.y, color)
		add_child(block)
		cell_blocks[cell.x][cell.y] = block
		_tween_pop_in(block)

# ── 3D Block builder ───────────────────────────────────────────────────────────
# Creates a Node2D centred on the cell, with all 3D faces as ColorRect children.
# The node's position == cell centre so scale tweens expand/collapse from centre.
func _create_3d_block(x: int, y: int, col: Color) -> Node2D:
	var block := Node2D.new()
	block.z_index = 2

	var cx: float = x * Global.CELL_SIZE + Global.CELL_SIZE * 0.5
	var cy: float = y * Global.CELL_SIZE + Global.CELL_SIZE * 0.5
	block.position = Vector2(cx, cy)

	var sz: float = Global.CELL_SIZE - 6
	var hf: float = sz * 0.5

	# ── Main 3D Gem Face (Rounded Vector StyleBox) ──────────────────────────
	var panel := Panel.new()
	panel.size = Vector2(sz, sz)
	panel.position = Vector2(-hf, -hf)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(14)
	sb.border_width_bottom = 5
	sb.border_width_right = 5
	sb.border_color = Color(col.r * 0.52, col.g * 0.52, col.b * 0.52, 1.0)
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.40)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 4)
	sb.anti_aliasing = true
	panel.add_theme_stylebox_override("panel", sb)
	block.add_child(panel)

	# ── Top-Left Glossy Highlight Edge ─────────────────────────────────────
	var highlight := Panel.new()
	highlight.size = Vector2(sz - 12, sz * 0.42)
	highlight.position = Vector2(-hf + 6, -hf + 4)
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var hsb := StyleBoxFlat.new()
	hsb.bg_color = Color(1.0, 1.0, 1.0, 0.32)
	hsb.set_corner_radius_all(8)
	hsb.anti_aliasing = true
	highlight.add_theme_stylebox_override("panel", hsb)
	block.add_child(highlight)

	# ── Corner Glint (Specular Crystal Highlight) ──────────────────────────
	var glint := Panel.new()
	glint.size = Vector2(8, 8)
	glint.position = Vector2(-hf + 8, -hf + 6)
	glint.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var gsb := StyleBoxFlat.new()
	gsb.bg_color = Color(1.0, 1.0, 1.0, 0.75)
	gsb.set_corner_radius_all(4)
	gsb.anti_aliasing = true
	glint.add_theme_stylebox_override("panel", gsb)
	block.add_child(glint)

	return block

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
			cell_state[x][y] = null
			if cell_blocks[x][y] != null:
				cell_blocks[x][y].queue_free()
				cell_blocks[x][y] = null
	for x in full_cols:
		for y in Global.GRID_SIZE:
			cell_state[x][y] = null
			if cell_blocks[x][y] != null:
				cell_blocks[x][y].queue_free()
				cell_blocks[x][y] = null
