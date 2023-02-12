# Generates a dungeon using RigidBody2D physics and Minimum Spanning Tree (MST).
#
# The algorithm works like so:
#
# 1. Spawns and spreads collision shapes around the game world using the physics engine.
# 2. Waits for the rooms to be in a more or less resting state.
# 3. Selects some main rooms for the level based on the average room size.
# 4. Creates a Minimum Spanning Tree graph that connects the rooms.
# 5. Adds back some connections after calculating the MST so the player doesn't need to backtrack.
extends Node2D

# Emitted when all the rooms stabilized.
signal rooms_placed

const Room := preload("Room.tscn")
const FLOOR_ID = 6
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

# Maximum number of generated rooms.
@export var max_rooms := 60
# Controls the number of paths we add to the dungeon after generating it,
# limiting player backtracking.
@export var reconnection_factor := 0.025

var _rng := RandomNumberGenerator.new()
var _data := {}
var _path: AStar2D = null
var _sleeping_rooms := 0
var _mean_room_size := Vector2.ZERO
var _draw_extra := []

@onready var rooms: Node2D = $Rooms
@onready var level: TileMap = $Level


func _ready() -> void:
	_rng.randomize()
	_generate()
	
#	print(level.local_to_map(Vector2(0, 0)))
#	print(level.local_to_map(Vector2(16, 16)))


# Calld every time stabilizes (mode changes to RigidBody2D.MODE_STATIC).
#
# Once all rooms have stabilized it calcualtes a playable dungeon `_path` using the MST
# algorithm. Based on the calculated `_path`, it populates `_data` with room and corridor tile
# positions.
#
# It emits the "rooms_placed" signal when it finishes so we can begin the tileset placement.
func _on_Room_sleeping_state_changed(mstRoom: MSTDungeonRoom) -> void:
#	mstRoom.modulate = Color.YELLOW
	_sleeping_rooms += 1
	
	if _sleeping_rooms < max_rooms:
		return

	var main_rooms := []
	var main_rooms_positions := []
	for room in rooms.get_children():
		if _is_main_room(room):
			main_rooms.push_back(room)
			main_rooms_positions.push_back(room.position)
#			room.modulate = Color.RED

	_path = MSTDungeonUtils.mst(main_rooms_positions)

	await get_tree().create_timer(1).timeout

	for point1_id in _path.get_point_ids():
		for point2_id in _path.get_point_ids():
			if (
				point1_id != point2_id
				and not _path.are_points_connected(point1_id, point2_id)
				and _rng.randf() < reconnection_factor
			):
				_path.connect_points(point1_id, point2_id)
				_draw_extra.push_back(
					[_path.get_point_position(point1_id), _path.get_point_position(point2_id)]
				)

	for room in main_rooms:
		_add_room(room)
	_add_corridors()

#	set_process(false)
	rooms_placed.emit()

# Places the rooms and starts the physics simulation. Once the simulation is done
# ("rooms_placed" gets emitted), it continues by assigning tiles in the Level node.
func _generate() -> void:
	for _i in range(max_rooms):
		# Generate `max_rooms` rooms and set them up
		var room: MSTDungeonRoom = Room.instantiate()
		room.sleeping_state_changed.connect(func(): _on_Room_sleeping_state_changed(room))
		room.setup(_rng, level)
		rooms.add_child(room)

		_mean_room_size += room.size
	_mean_room_size /= rooms.get_child_count()
	
	await rooms_placed
	
	rooms.queue_free()
	
	var total_weight = 0.0
	var accum_weights = {}
	
	for pos in FLOOR_TILES:
		total_weight += FLOOR_TILES[pos]
		accum_weights[pos] = total_weight
	
	level.clear()
	for point in _data:
		var rand_num = _rng.randf_range(0.0, total_weight)
		var selected = Vector2.ZERO
		for pos in accum_weights:
			if accum_weights[pos] > rand_num:
				selected = pos
				break
		level.set_cell(FLOOR_LAYER, point, FLOOR_ID, selected)
	
	_fill_walls()

# Adds room tile positions to `_data`.
func _add_room(room: MSTDungeonRoom) -> void:
	for offset in room.get_positions():
		_data[offset] = null


# Adds both secondary room and corridor tile positions to `_data`. Secondary rooms are the ones
# intersecting the corridors.
func _add_corridors():
	# Stores existing connections in its keys.
	var connected := {}

	# Checks if points are connected by a corridor. If not, adds a corridor.
	for point1_id in _path.get_point_ids():
		for point2_id in _path.get_point_connections(point1_id):
			var point1 := _path.get_point_position(point1_id)
			var point2 := _path.get_point_position(point2_id)
			if Vector2(point1_id, point2_id) in connected:
				continue

			point1 = level.local_to_map(point1)
			point2 = level.local_to_map(point2)
			_add_corridor(point1.x, point2.x, point1.y, Vector2.AXIS_X)
			_add_corridor(point1.y, point2.y, point2.x, Vector2.AXIS_Y)

			# Stores the connection between point 1 and 2.
			connected[Vector2(point1_id, point2_id)] = null
			connected[Vector2(point2_id, point1_id)] = null

# Adds a specific corridor (defined by the input parameters) to `_data`. It also adds all
# secondary rooms intersecting the corridor path.
func _add_corridor(start: int, end: int, constant: int, axis: int) -> void:
	var t: int = min(start, end)
	while t <= max(start, end):
		var point := Vector2.ZERO
		match axis:
			Vector2.AXIS_X:
				point = Vector2(t, constant)
			Vector2.AXIS_Y:
				point = Vector2(constant, t)

		t += 1
		for room in rooms.get_children():
			if _is_main_room(room):
				continue

			var half_room_size = Vector2i(room.size / 2)
			var top_left: Vector2 = level.local_to_map(room.position) - half_room_size
			var bottom_right: Vector2 = level.local_to_map(room.position) + half_room_size
			if (
				top_left.x <= point.x
				and point.x < bottom_right.x
				and top_left.y <= point.y
				and point.y < bottom_right.y
			):
				_add_room(room)
				t = bottom_right[axis]
		_data[point] = null


func _is_main_room(room: MSTDungeonRoom) -> bool:
	return room.size.x > _mean_room_size.x and room.size.y > _mean_room_size.y

func _fill_walls():
	var cells = level.get_used_cells(FLOOR_LAYER)
	var wall_cells = []
	
	for cell in cells:
		var potential_walls = _get_all_surrounding_cells(cell)
		for potential_wall in potential_walls:
			if not potential_wall in cells:
				wall_cells.append(potential_wall)
	
	level.set_cells_terrain_connect(FLOOR_LAYER, wall_cells, WALL_TERRAIN_SET, WALL_TERRAIN)

func _get_all_surrounding_cells(cell: Vector2i):
	var neighbors = [
		TileSet.CELL_NEIGHBOR_RIGHT_SIDE,
		TileSet.CELL_NEIGHBOR_LEFT_SIDE,
		TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,
		TileSet.CELL_NEIGHBOR_TOP_SIDE,
		TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER,
		TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER,
		TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER,
		TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER
	]
	
	var result = []
	for n in neighbors:
		result.append(level.get_neighbor_cell(cell, n))
	return result
