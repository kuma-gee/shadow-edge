extends Node2D

signal genereated

const Room := preload("Room.tscn")

@export var max_rooms := 60
@export var reconnection_factor := 0.025

var _rng := RandomNumberGenerator.new()
var _sleeping_rooms := 0
var _mean_room_size := Vector2.ZERO
var _draw_extra := []

@onready var rooms: Node2D = $Rooms
@onready var level: TileMap = $Level

var _logger = Logger.new("MSTDungeon")

func _ready() -> void:
	_rng.randomize()
	_generate()
	
func _on_Room_sleeping_state_changed(mstRoom: MSTDungeonRoom) -> void:
	_sleeping_rooms += 1
	if _sleeping_rooms < max_rooms:
		return

	var main_rooms := []
	for room in rooms.get_children():
		if _is_main_room(room):
			main_rooms.push_back(room)
    
    # TODO: room builder
    # TODO: emit rooms built

func _generate() -> void:
	for _i in range(max_rooms):
		var room: MSTDungeonRoom = Room.instantiate()
		room.sleeping_state_changed.connect(func(): _on_Room_sleeping_state_changed(room))
		room.setup(_rng, level)
		rooms.add_child(room)

		_mean_room_size += room.size
	_mean_room_size /= rooms.get_child_count()

    # TODO: await rooms built
	rooms.queue_free()

    # TODO: level builder
	
	queue_redraw()
	genereated.emit()


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

func _draw():
	if _path == null:
		return

	for point1_id in _path.get_point_ids():
		var point1_position := _path.get_point_position(point1_id)
		for point2_id in _path.get_point_connections(point1_id):
			var point2_position := _path.get_point_position(point2_id)
			draw_line(point1_position, point2_position, Color.RED, 20)

	if not _draw_extra.is_empty():
		for pair in _draw_extra:
			draw_line(pair[0], pair[1], Color.GREEN, 20)
