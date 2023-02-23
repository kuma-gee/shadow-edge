class_name LevelBuilder
extends Node

const OBSTACLES = {
	0.2: preload("res://src/MSTDungeon/hole.tscn"),
	1.0: preload("res://src/MSTDungeon/spikes.tscn"),
}
const OBSTACLE_SPAWN_CHANCE = 0.03

const MAX_OBSTACLES_IN_ROOM_REL = 0.2
const MAX_ENEMIES_IN_ROOM_REL = 0.2
const MIN_ENEMIES_IN_ROOM = 2

const FLOOR_ID = 2
const FLOOR_TILES = {
	0.8: Vector2i(0, 0),
	0.9: Vector2i(1, 0),
	0.97: Vector2i(2, 0),
	0.98: Vector2i(0, 1),
	0.99: Vector2i(1, 1),
	1.00: Vector2i(2, 1),
}
const FLOOR_LAYER = 0

const WALL_TERRAIN_SET = 0
const WALL_TERRAIN = 0
const WALL_SIZE = Vector2i(20, 20)

@export var level: TileMap

@export_node_path var room_builder_path: NodePath
@onready var room_builder: RoomBuilder = get_node(room_builder_path)

var _obstacles := {}
var _rng: RandomNumberGenerator

func build_level(rng: RandomNumberGenerator):
	_rng = rng
	
	level.clear()
	for point in room_builder.get_level_tiles():
		var selected = _random_item(FLOOR_TILES)
		level.set_cell(FLOOR_LAYER, point, FLOOR_ID, selected)
	
	for room_pos in room_builder.get_rooms():
		var size = room_builder.get_room_size_in_tiles(room_pos)
		var area = size.x * size.y
		var map_pos = level.local_to_map(room_pos)

		var max_obstacles_count = area * MAX_OBSTACLES_IN_ROOM_REL
		var max_enemies_count = area * MAX_OBSTACLES_IN_ROOM_REL

		for enemy_i in range(MIN_ENEMIES_IN_ROOM, max(MIN_ENEMIES_IN_ROOM, max_enemies_count)):
			pass

		for obstacle_i in range(0, max_obstacles_count):
			pass
	
	# for point in _obstacles:
	# 	var selected = _random_item(OBSTACLES) as PackedScene
	# 	var obstacle = selected.instantiate()
	# 	level.add_child(obstacle)
	# 	obstacle.position = level.map_to_local(point) + Vector2(level.tile_set.tile_size / 4)
	
	_fill_walls()

func _spawn(scene: PackedScene, point: Vector2):
	var node = scene.instantiate()
	level.add_child(node)
	node.position = level.map_to_local(point) + Vector2(level.tile_set.tile_size / 4)

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


func _random_item(weighted_items: Dictionary):
	var rand_num = _rng.randf_range(0.0, 1.0)
	
	for chance in weighted_items:
		if rand_num < chance:
			return weighted_items[chance]

