extends Node2D

signal genereated

const Room := preload("Room.tscn")

@export var max_rooms := 60
@export var level: TileMap
@export var rooms: Node2D

@export_node_path var room_builder_path: NodePath
@onready var room_builder: RoomBuilder = get_node(room_builder_path)

@export_node_path var level_builder_path: NodePath
@onready var level_builder: LevelBuilder = get_node(level_builder_path)

var _rng := RandomNumberGenerator.new()
var _sleeping_rooms := 0

var _logger = Logger.new("MSTDungeon")

func _ready() -> void:
	_rng.randomize()
	_generate()
	
func _generate() -> void:
	for _i in range(max_rooms):
		var room: MSTDungeonRoom = Room.instantiate()
		room.sleeping_state_changed.connect(func(): _on_Room_sleeping_state_changed(room))
		room.setup(_rng, level)
		rooms.add_child(room)

	await room_builder.rooms_built
	rooms.queue_free()

	level_builder.build_level(_rng)

	queue_redraw()
	genereated.emit()

func _on_Room_sleeping_state_changed(mstRoom: MSTDungeonRoom) -> void:
	_sleeping_rooms += 1
	if _sleeping_rooms < max_rooms:
		return

	room_builder.build_room_data(_rng)

func get_player_spawn():
	return room_builder.get_player_spawn()


func _draw():
	var path = room_builder._path
	var extra = room_builder._draw_extra
	if path == null:
		return
		
	for point1_id in path.get_point_ids():
		var point1_position := path.get_point_position(point1_id)
		for point2_id in path.get_point_connections(point1_id):
			var point2_position := path.get_point_position(point2_id)
			draw_line(point1_position, point2_position, Color.RED, 20)
	if not extra.is_empty():
		for pair in extra:
			draw_line(pair[0], pair[1], Color.GREEN, 20)
