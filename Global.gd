extends Node

const GRID_SIZE := 8
const CELL_SIZE := 60

const SHAPES := {
	"single": [Vector2i(0,0)],
	"domino_h": [Vector2i(0,0), Vector2i(1,0)],
	"domino_v": [Vector2i(0,0), Vector2i(0,1)],
	"line3_h": [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0)],
	"line3_v": [Vector2i(0,0), Vector2i(0,1), Vector2i(0,2)],
	"line4_h": [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0)],
	"line4_v": [Vector2i(0,0), Vector2i(0,1), Vector2i(0,2), Vector2i(0,3)],
	"line5_h": [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), Vector2i(4,0)],
	"square2": [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)],
	"square3": [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2)],
	"l_shape1": [Vector2i(0,0), Vector2i(0,1), Vector2i(0,2), Vector2i(1,2)],
	"l_shape2": [Vector2i(0,0), Vector2i(1,0), Vector2i(1,1), Vector2i(1,2)],
	"t_shape": [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(1,1)],
	"s_shape": [Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(1,1)],
	"z_shape": [Vector2i(0,0), Vector2i(1,0), Vector2i(1,1), Vector2i(2,1)],
	"plus_shape": [Vector2i(1,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(1,2)],
	"corner": [Vector2i(0,0), Vector2i(0,1), Vector2i(1,1)]
}
