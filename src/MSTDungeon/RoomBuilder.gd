class_name RoomBuilder
extends Node

signal rooms_built

#enum RoomType {
#	Normal,
#	Boss,
#	Treasure,
#	Player,
#}

@export var reconnection_factor := 0.0
@export var level: TileMap
@export var rooms: Node2D

var _logger = Logger.new("RoomBuilder")

var _level_data := {}
var _room_data = {}
var _rooms: Array[Node]
var _mean_room_size := Vector2.ZERO
var _draw_extra := []

var _rng: RandomNumberGenerator
var _path: AStar2D

func get_level_tiles() -> Array[Vector2]:
	var result: Array[Vector2] = []
	for pos in _level_data:
		result.append(pos)
	return result

func get_end_room_positions() -> Array[Vector2]:
	var result := []
	var bottom_right := Vector2.ZERO
	var top_left := Vector2.ZERO
	var border_threshold := 5

	for id in _path.get_point_ids():
		var connections = _path.get_point_connections(id)
		var pos = _path.get_point_position(id)

		bottom_right.x = max(bottom_right.x, pos.x)
		bottom_right.y = max(bottom_right.y, pos.y)
		top_left.x = min(top_left.x, pos.x)
		top_left.y = min(top_left.y, pos.y)

		if connections.size() == 1:
			result.append(pos)
	
	for pos in result:
		pos.x

	return result


#func get_player_spawn():
#	return _find_by_type(RoomType.Player)[0]
#
#
#func get_exit_room():
#	return _find_by_type(RoomType.Boss)[0]
#
#
#func get_rooms():
#	var result = []
#	for id in _room_data:
#		result.append(_path.get_point_position(id))
#	return result
#
#
#func get_room_size_in_tiles(pos: Vector2):
#	var id = _find_by_pos(pos)
#	if id == null:
#		_logger.debug("Could not find room id by position %s" % pos)
#
#	return _room_data[id]["size"]


func build_room_data(rng: RandomNumberGenerator):
	_rng = rng
	_rooms = rooms.get_children()
	
	for room in _rooms:
		_mean_room_size += room.size
	_mean_room_size /= _rooms.size()

	var main_rooms := []
	var main_room_positions := []
	for room in _rooms:
		if _is_main_room(room):
			main_rooms.push_back(room)
			main_room_positions.push_back(room.position)
	_path = MSTDungeonUtils.mst(main_room_positions)

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

#	_init_room_data()
#
#	var end_rooms = _get_end_rooms(_room_data)
#	var farthest_connected = _get_farthest_connected(end_rooms)
#
#	if farthest_connected.size() > 0:
#		var player = farthest_connected[0]
#		var exit = farthest_connected[1]
#		_room_data[player]["type"] = RoomType.Player
#		_room_data[exit]["type"] = RoomType.Boss
#
#		end_rooms.erase(player)
#		end_rooms.erase(exit)
#
#		var max_treasure_rooms = floor(end_rooms.size() / 2)
#		if max_treasure_rooms > 0:
#			for i in range(0, _rng.randi_range(1, max_treasure_rooms)):
#				var rand_id = end_rooms[_rng.randi() % end_rooms.size()]
#				_room_data[rand_id]["type"] = RoomType.Treasure
#	else:
#		_logger.debug("Failed to find spawn and exit position")

	rooms_built.emit()

#func _init_room_data():
#	for id in _path.get_point_ids():
#		var pos = _path.get_point_position(id)
#		var room = _find_room_for_position(pos)
#		if room == null:
#			_logger.debug("No room found for position %s" % pos)
#			continue
#
#		var connections = _path.get_point_connections(id)
#		var first_conn = connections.size()
#
#		# var second_conn = 0
#		# for c in connections:
#		# 	second_conn += _path.get_point_connections(c).size()
#
#		_room_data[id] = {
#			"type": RoomType.Normal,
#			"size": room.size,
#			"immediate_conn": first_conn,
#			# "total_conn": first_conn + second_conn
#		}

#func _find_room_for_position(pos: Vector2):
#	for room in _rooms:
#		if room.position == pos:
#			return room
#	return null
#
#func _get_farthest_connected(ids):
#	var id_pair = []
#	var max_distance = -1
#
#	for id in ids:
#		for other_id in ids:
#			if id == other_id:
#				continue
#
#			var points = _path.get_point_path(id, other_id)
#			if points.size() > max_distance:
#				id_pair = [id, other_id]
#
#	return id_pair
#
#
#func _get_end_rooms(room_data):
#	var result = []
#	for id in room_data:
#		if room_data[id]["immediate_conn"] == 1:
#			result.append(id)
#	return result
#
#
#func _find_by_type(type):
#	var result = []
#	for id in _room_data:
#		if _room_data[id]["type"] == type:
#			result.append(_path.get_point_position(id))
#	return result
#
#func _find_by_pos(pos: Vector2):
#	var result = []
#	for id in _room_data:
#		if _path.get_point_position(id) == pos:
#			return id

# Adds room tile positions to `_data`.
func _add_room(room: MSTDungeonRoom) -> void:
	for offset in room.get_positions():
		_level_data[offset] = null


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
		for room in _rooms:
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
		
		_add_corridor_point(point, axis)

func _add_corridor_point(point: Vector2, axis: int):
	var points = [point]

	match axis:
		Vector2.AXIS_X:
			points.append(Vector2(point.x, point.y + 1))
			points.append(Vector2(point.x, point.y - 1))
		Vector2.AXIS_Y:
			points.append(Vector2(point.x + 1, point.y))
			points.append(Vector2(point.x - 1, point.y))

	for p in points:
		_level_data[p] = null

func _is_main_room(room: MSTDungeonRoom) -> bool:
	#return true
	return room.size.x > _mean_room_size.x and room.size.y > _mean_room_size.y
