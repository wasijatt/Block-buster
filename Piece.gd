extends Node2D

signal dropped(piece, drop_position)

var shape: Array = []
var color: Color = Color.WHITE
var home_position: Vector2 = Vector2.ZERO
var slot_index: int = -1
var dragging := false
var drag_offset := Vector2.ZERO

func setup(p_shape: Array, p_color: Color) -> void:
	shape = p_shape
	color = p_color
	for cell in shape:
		var rect := ColorRect.new()
		rect.size = Vector2(Global.CELL_SIZE - 4, Global.CELL_SIZE - 4)
		rect.position = Vector2(cell.x * Global.CELL_SIZE + 2, cell.y * Global.CELL_SIZE + 2)
		rect.color = color
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(rect)

func get_bounding_size() -> Vector2:
	var max_x := 0
	var max_y := 0
	for cell in shape:
		max_x = max(max_x, cell.x)
		max_y = max(max_y, cell.y)
	return Vector2((max_x + 1) * Global.CELL_SIZE, (max_y + 1) * Global.CELL_SIZE)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_global_mouse_position()
		if event.pressed:
			var rect := Rect2(global_position, get_bounding_size())
			if rect.has_point(mouse_pos) and not dragging:
				dragging = true
				drag_offset = global_position - mouse_pos
				z_index = 10
		else:
			if dragging:
				dragging = false
				z_index = 0
				dropped.emit(self, global_position)
	elif event is InputEventMouseMotion and dragging:
		var mouse_pos = get_global_mouse_position()
		global_position = mouse_pos + drag_offset
