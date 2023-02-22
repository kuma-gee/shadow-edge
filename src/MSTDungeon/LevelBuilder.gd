class_name LevelBuilder
extends Node

const FLOOR_ID = 2
const FLOOR_TILES = {
	Vector2i(0, 0): 0.7,
	Vector2i(1, 0): 0.05,
	Vector2i(2, 0): 0.1,
	Vector2i(0, 1): 0.01,
	Vector2i(1, 1): 0.1,
	Vector2i(2, 1): 0.01,
}
const FLOOR_LAYER = 0

const WALL_TERRAIN_SET = 0
const WALL_TERRAIN = 0

const WALL_SIZE = Vector2i(20, 20)


@export_node_path level_path
@onready var level := get_node(level_path)

var _rng: RandomNumberGenerator

func build_level(room_builder: RoomBuilder, rng: RandomNumberGenerator):
    _rng = rng

	var total_weight = 0.0
	var accum_weights = {}
	
	for pos in FLOOR_TILES:
		total_weight += FLOOR_TILES[pos]
		accum_weights[pos] = total_weight
	
	level.clear()
	for point in room_builder.get_level_tiles():
		var rand_num = _rng.randf_range(0.0, total_weight)
		var selected = Vector2.ZERO
		for pos in accum_weights:
			if accum_weights[pos] > rand_num:
				selected = pos
				break
		level.set_cell(FLOOR_LAYER, point, FLOOR_ID, selected)
	
	_fill_walls()

func _fill_walls():
	var rect = level.get_used_rect()
	var wall_cells = []
	var start = rect.position - WALL_SIZE
	var end = rect.end + WALL_SIZE
	
	for x in range(start.x, end.x):
		for y in range(start.y, end.y):
			var pos = Vector2(x, y)
			var source_id = level.get_cell_source_id(FLOOR_LAYER, pos)
			if source_id == -1:
				wall_cells.append(pos)
	
	level.set_cells_terrain_connect(FLOOR_LAYER, wall_cells, WALL_TERRAIN_SET, WALL_TERRAIN)
