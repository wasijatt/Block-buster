extends Node2D

signal lines_cleared(count)

var cell_state: Array = []
var cell_visuals: Array = []

func _ready() -> void:
	cell_state.resize(Global.GRID_SIZE)
	cell_visuals.resize(Global.GRID_SIZE)
	for x in Global.GRID_SIZE:
		cell_state[x] = []
		cell_visuals[x] = []
		cell_state[x].resize(Global.GRID_SIZE)
		cell_visuals[x].resize(Global.GRID_SIZE)
		for y in Global.GRID_SIZE:
			cell_state[x][y] = null
			var rect := ColorRect.new()
			rect.size = Vector2(Global.CELL_SIZE - 4, Global.CELL_SIZE - 4)
			rect.position = Vector2(x * Global.CELL_SIZE + 2, y * Global.CELL_SIZE + 2)
			rect.color = Color(0.15, 0.15, 0.18)
			add_child(rect)
			cell_visuals[x][y] = rect

func is_inside_grid(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < Global.GRID_SIZE and cell.y >= 0 and cell.y < Global.GRID_SIZE

func is_valid_placement(shape: Array, origin: Vector2i) -> bool:
	for offset in shape:
		var cell: Vector2i = origin + offset
		if not is_inside_grid(cell):
			return false
		if cell_state[cell.x][cell.y] != null:
			return false
	return true

func place_shape(shape: Array, origin: Vector2i, color: Color) -> void:
	for offset in shape:
		var cell: Vector2i = origin + offset
		cell_state[cell.x][cell.y] = color
		cell_visuals[cell.x][cell.y].color = color

func check_and_clear_lines() -> int:
	var full_rows := []
	var full_cols := []
	for y in Global.GRID_SIZE:
		var full := true
		for x in Global.GRID_SIZE:
			if cell_state[x][y] == null:
				full = false
				break
		if full:
			full_rows.append(y)
	for x in Global.GRID_SIZE:
		var full := true
		for y in Global.GRID_SIZE:
			if cell_state[x][y] == null:
				full = false
				break
		if full:
			full_cols.append(x)

	for y in full_rows:
		for x in Global.GRID_SIZE:
			cell_state[x][y] = null
			cell_visuals[x][y].color = Color(0.15, 0.15, 0.18)
	for x in full_cols:
		for y in Global.GRID_SIZE:
			cell_state[x][y] = null
			cell_visuals[x][y].color = Color(0.15, 0.15, 0.18)

	var cleared: int = full_rows.size() + full_cols.size()
	if cleared > 0:
		lines_cleared.emit(cleared)
	return cleared

func can_place_anywhere(shape: Array) -> bool:
	for x in Global.GRID_SIZE:
		for y in Global.GRID_SIZE:
			if is_valid_placement(shape, Vector2i(x, y)):
				return true
	return false
